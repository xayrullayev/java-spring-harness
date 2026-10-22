# Java / Spring Boot Harness (ECC asosida)

[affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code) (ECC) repo'sidan Java va Spring Boot dasturchisiga kerak bo'ladigan agent, skill, rule va command'lar ajratib olingan va Claude Code uchun **o'rnatishga tayyor** ko'rinishga keltirilgan.

- Manba: ECC `v2.2.3`, commit `90606c8` (2026-10-20), MIT litsenziya (`upstream-docs/LICENSE`)
- Tarkib: 20 agent, 25 skill, 15 command, 15 rule, 3 hook, settings, CLAUDE.md shabloni

## Tezkor boshlash

```bash
cd ~/ecc/java-spring-harness

# 1) Bitta loyihaga (tavsiya etiladi — jamoa bilan git orqali bo'lishiladi)
./install.sh project ~/work/mob-core --with-claude-md

# 2) Yoki barcha loyihalar uchun (~/.claude)
./install.sh user
```

Keyin loyihada `claude` ni ishga tushiring va sinab ko'ring:

```
/java-review            # o'zgargan Java kodni review qilish
/java-build             # qizil build'ni minimal o'zgarish bilan tuzatish
/java-test  "OrderService.cancel shipped order'ni rad etishi kerak"
/plan  "escrow modulida partial release qo'shish"
/review-pr  123
```

`install.sh` mavjud fayllarni jimgina ustidan yozmaydi — farq qilgan faylni `*.bak.<vaqt>` qilib saqlaydi. Loyihada `settings.json` allaqachon bo'lsa, `settings.java-harness.json` ni yonida qoldiradi — hook va permission'larni qo'lda birlashtirasiz.

## Tuzilma

```
java-spring-harness/
├── .claude/
│   ├── agents/      20 ta subagent
│   ├── skills/      25 ta skill (har biri SKILL.md)
│   ├── commands/    15 ta slash-command
│   ├── rules/       common/ (10) + java/ (5)
│   ├── hooks/       java-post-edit.sh, java-stop-compile.sh
│   └── settings.json   permissions + hooks
├── templates/
│   ├── CLAUDE.md    Spring Boot servisi uchun loyiha CLAUDE.md shabloni
│   └── mcp.json     Context7 MCP (docs-lookup agenti uchun)
├── upstream-docs/   ECC qo'llanmalari (short/long/security guide), stack mapping, LICENSE
├── install.sh
├── MANIFEST.md      har bir faylning manbasi va qilingan o'zgarishlar
└── README.md
```

## Nima kiritildi

### 1. Java/Spring yadrosi (ECC'dagi Java-ga xos hamma narsa)

| Tur | Nomi | Vazifasi |
|-----|------|----------|
| agent | `java-reviewer` | Spring Boot review: qatlamlar, `@Transactional`, JPA N+1, security, concurrency |
| agent | `java-build-resolver` | Maven/Gradle/javac xatolarini bosqichma-bosqich tuzatish |
| skill | `java-coding-standards` | Nomlash, immutability, Optional, stream, DI, exception, logging |
| skill | `springboot-patterns` | REST, service+transaction, DTO/validation, caching, async, rate limit, observability |
| skill | `springboot-security` | Spring Security, JWT, CORS/CSRF, secrets, method security |
| skill | `springboot-tdd` | JUnit 5, Mockito, MockMvc, Testcontainers, JaCoCo |
| skill | `springboot-verification` | Build → static analysis → test → security scan → PR readiness |
| skill | `jpa-patterns` | Entity dizayni, N+1, fetch strategy, pagination, auditing |
| skill | `mybatis-patterns` | MyBatis mapper, dynamic SQL, result map |
| skill | `hexagonal-architecture` | Ports & adapters (Java misollari bilan) |
| rule | `java/coding-style`, `patterns`, `security`, `testing`, `hooks` | `**/*.java` fayllarga avtomatik qo'llanadi |

### 2. Tilga bog'liq bo'lmagan, backend uchun foydali qism

- **Agentlar:** `planner`, `architect`, `code-architect`, `code-explorer`, `tdd-guide`, `code-reviewer`, `security-reviewer`, `database-reviewer`, `silent-failure-hunter`, `pr-test-analyzer`, `type-design-analyzer`, `comment-analyzer`, `code-simplifier`, `refactor-cleaner`, `doc-updater`, `docs-lookup`, `spec-miner`, `commit-reviewer`
- **Skill'lar:** `tdd-workflow`, `verification-loop`, `security-review`, `api-design`, `database-migrations`, `postgres-patterns`, `error-handling`, `contract-first`, `architecture-decision-records`, `codebase-onboarding`, `change-impact`, `docker-patterns`, `kubernetes-patterns`, `git-workflow`, `search-first`, `strategic-compact`, `documentation-lookup`
- **Command'lar:** `/plan`, `/feature-dev`, `/code-review`, `/review-pr`, `/build-fix`, `/test-coverage`, `/refactor-clean`, `/checkpoint`, `/save-session`, `/resume-session`, `/update-codemaps`, `/learn`

### 3. Harness uchun yangi yozilganlar (ECC'da yo'q edi)

ECC'da Go/Rust/Kotlin uchun `/xxx-review`, `/xxx-build`, `/xxx-test` bor, lekin **Java uchun yo'q** (`/gradle-build` esa Android/KMP uchun). Shu bo'shliq to'ldirildi:

| Fayl | Izoh |
|------|------|
| `commands/java-review.md` | `java-reviewer` agentini chaqiradi; WebFlux/Reactor bloklash, `BigDecimal` kabi tekshiruvlar qo'shilgan |
| `commands/java-build.md` | `java-build-resolver` ni chaqiradi; multi-module (`-pl -am`), BOM, Lombok/MapStruct xatolari |
| `commands/java-test.md` | TDD sikli: test slice tanlash jadvali, `StepVerifier` misoli, JaCoCo |
| `hooks/java-post-edit.sh` | `.java` tahriridan keyin: `google-java-format` (faqat `JAVA_HARNESS_FORMAT=1` bo'lsa) + `System.out`, field `@Autowired`, bo'sh `catch`, pul uchun `double`, Reactor ichida `.block()` haqida ogohlantirish; hardcoded secret topilsa bloklaydi (exit 2) |
| `hooks/harness-notify.sh` | Har bir hook o'z holatini `http://localhost:4477/api/hook` ga `{agent, task, status}` ko'rinishida POST qiladi (2 s timeout, server ishlamasa jim o'tadi). `HARNESS_NOTIFY=0` — o'chirish, `HARNESS_NOTIFY_URL` — boshqa manzil, `HARNESS_AGENT_NAME` — agent nomi |
| `hooks/java-stop-compile.sh` | Sessiya oxirida `.java` o'zgargan bo'lsa offline compile (ixtiyoriy: `JAVA_HARNESS_COMPILE_ON_STOP=1`) |
| `settings.json` | `mvnw/gradlew/java` ruxsat; `deploy/publish/release`, `.env`, `*.jks`, `application-prod*.yml` taqiqlangan |
| `templates/CLAUDE.md` | Spring Boot servis uchun shablon (WebFlux bo'limi bilan) |

ECC original fayllariga kiritilgan kichik o'zgarishlar (`rules/common/agents.md`, `code-review.md`, `development-workflow.md`, `performance.md`) — `MANIFEST.md` da batafsil.

### Ataylab kiritilmaganlar

- **Quarkus** skill'lari (`quarkus-*`) — Spring stack'ingizga kerak emas; `java-reviewer` va `rules/java` ularga faqat "see skill" deb havola qiladi, bu zararsiz
- **Kotlin** (`kotlin-*`), **tinystruct** — Java emas / boshqa framework
- ECC **hook'lari** — barchasi ECC plugin'ining Node skriptlariga (`CLAUDE_PLUGIN_ROOT`) bog'langan, alohida ishlamaydi; o'rniga yengil shell hook'lar yozildi
- `/quality-gate`, `/security-scan`, `/project-init` — ECC'ning o'z skript va npm paketlariga bog'liq
- `build-error-resolver`, `performance-optimizer` — TypeScript yo'naltirilgan

## Ish oqimi (tavsiya)

```
Yangi feature:   /plan  →  /java-test  →  (qizil bo'lsa) /java-build  →  /java-review  →  /review-pr
Notanish modul:  code-explorer agent  →  /update-codemaps
Legacy servis:   codebase-onboarding skill  →  spec-miner agent
PR oldidan:      springboot-verification skill
```

## Keyingi qadam uchun bo'shliqlar

ECC'dagi Spring materiali asosan **Spring MVC (servlet) + JPA** ga yo'naltirilgan. `mob-core` kabi **WebFlux / Reactor Netty / WebClient** stack'i uchun alohida skill yo'q — bu o'zingiz yozadigan birinchi moslashtirilgan skill bo'lishi mumkin (masalan `webflux-reactor-patterns`: timeout/retry, `onErrorResume`, `Schedulers.boundedElastic`, context propagation, `StepVerifier`). Xuddi shunday, jamoaning `corp-logging-starter` / Log4j2 standarti uchun ham skill/rule qo'shish mantiqli.
