# Java / Spring Boot Harness — Foydalanish qo'llanmasi (money-manager backend)

Bu papka (`backend/.claude/`) Claude Code uchun harness hisoblanadi. U [everything-claude-code](https://github.com/affaan-m/everything-claude-code) (ECC) repo'sidagi Java va Spring Boot agent, skill, rule va command'lari asosida yig'ilgan va money-manager loyihasiga moslashtirilgan.

- Tarkib: 20 agent, 25 skill, 15 command, 16 rule, 4 hook
- Manba: ECC `v2.2.3` (commit `90606c8`), MIT litsenziya
- Asl to'plam: `~/ecc/java-spring-harness/`

---

## Mundarija

0. [Asosiy tushuncha](#0-asosiy-tushuncha-5-qism-2-xil-ishlash-usuli)
1. [Birinchi ishga tushirish](#1-birinchi-ishga-tushirish-va-tekshirish)
2. [Kundalik ish oqimi](#2-kundalik-ish-oqimi-trello-kartasi-misolida)
3. [Agent'larni to'g'ridan-to'g'ri chaqirish](#3-agentlarni-togridan-togri-chaqirish)
4. [Skill'larni nomi bilan chaqirish](#4-skilllarni-nomi-bilan-chaqirish)
5. [Sessiya boshqaruvi](#5-uzoq-ishlar-uchun-sessiya-boshqaruvi)
6. [Sozlash (environment)](#6-sozlash-environment-ozgaruvchilari)
7. [O'zingizga moslashtirish](#7-ozingizga-moslashtirish)
8. [Papka tuzilmasi](#8-papka-tuzilmasi)
9. [Muammolar va yechimlar](#9-muammolar-va-yechimlar)
10. [Cheat sheet](#cheat-sheet)

---

## 0. Asosiy tushuncha: 5 qism, 2 xil ishlash usuli

| Qism | Qayerda | Qanday ishlaydi |
|---|---|---|
| **Rules** | `.claude/rules/` | **O'zi yuklanadi.** `common/*` va `money-manager.md` doim yuklanadi, `java/*` esa `.java` fayl bilan ishlaganda |
| **Hooks** | `.claude/hooks/` + `settings.json` | **O'zi ishlaydi.** Har bir tahrirdan keyin va javob tugaganda |
| **Skills** | `.claude/skills/` | Vazifaga mos kelsa Claude **o'zi chaqiradi**, siz nomini aytib ham chaqirishingiz mumkin |
| **Agents** | `.claude/agents/` | Siz so'raysiz yoki Claude o'zi topshiradi (har biri alohida kontekstda ishlaydi) |
| **Commands** | `.claude/commands/` | **Siz chaqirasiz:** `/java-review`, `/plan` ... |

Ya'ni rules, hooks va skills'ni eslab yurish shart emas, ular fonda ishlaydi. Siz asosan **command** va kerak bo'lganda **agent** bilan ishlaysiz.

> **Muhim — loyiha qoidalari ustun turadi.** `rules/money-manager.md` ECC'ning umumiy qoidalari bilan loyiha hujjatlari (`docs/AGENTS.md`, `docs/API_CONVENTIONS.md`) o'rtasidagi ziddiyatlarni loyiha foydasiga hal qiladi:
> - javob umumiy qobiqqa (envelope) o'ralmaydi, xatolar `ApiException` va `ApiError` orqali qaytadi;
> - boshqa userning resursiga **404** qaytariladi (403 emas);
> - 80% coverage majburiy emas, loyihaning Definition of Done'i amal qiladi;
> - hujjat o'rniga faqat `openapi.yaml` yangilanadi;
> - ledger o'zgarmas.

---

## 1. Birinchi ishga tushirish va tekshirish

Claude Code'ni **`backend/` papkasi ichidan** ishga tushiring:

```bash
cd ~/IdeaProjects/money-manager/backend
claude
```

> Loyiha ildizidan (`money-manager/`) ochilsa, bu papkadagi agent, command va settings **yuklanmaydi**.

Sessiya ichida hammasi yuklanganini tekshiring:

```
/agents      → 20 ta agent ro'yxati (java-reviewer, planner, ...)
/hooks       → PreToolUse: protect-migrations, PostToolUse: java-post-edit, Stop: java-stop-compile
/context     → qaysi rule fayllar kontekstga yuklanganini ko'rsatadi
/            → "/" yozsangiz, java-review, java-build, java-test va boshqa command'lar chiqadi
```

---

## 2. Kundalik ish oqimi: Trello kartasi misolida

Faraz qilaylik, karta **"Bakend-21: Budget'ga ixtiyoriy `note` maydoni qo'shish"**.

```
/plan  →  /java-test  →  (qizil bo'lsa) /java-build  →  /java-review  →  /review-pr
```

### 1-qadam. Rejalashtirish: `/plan`

```
/plan Bakend-21: budgets jadvaliga ixtiyoriy note (max 200 belgi) qo'shish,
create/update/get javoblarida qaytsin. Kartaning qabul mezonlari: ...
```

Nima bo'ladi: `planner` agenti kodni o'qiydi va reja tuzadi. Rejada odatda yangi `V{n}__add_budget_note.sql` migratsiyasi, `BudgetEntity`, `CreateBudgetRequest` record, `BudgetResponse`, `openapi.yaml` va testlar bo'ladi. **Siz "ha" demaguningizcha kodga tegmaydi.** Rejani o'qing va xato bo'lsa tuzating: "note loglanmasin, AGENTS.md §6".

### 2-qadam. Avval test: `/java-test`

```
/java-test BudgetService.create note'ni saqlashi va 201 belgidan uzun note'ga 400 VALIDATION_FAILED qaytarishi kerak
```

Nima bo'ladi:

1. Avval yiqiladigan test yoziladi (RED): `@WebMvcTest` yoki integration test
2. `./mvnw -q test -Dtest=BudgetControllerTest` ishga tushadi va test **to'g'ri sabab bilan** yiqilishi kerak. Compile xatosi to'g'ri RED hisoblanmaydi.
3. Minimal kod yoziladi (GREEN), keyin tozalanadi (REFACTOR)

Bu bosqichda Claude `springboot-tdd` skill'ini o'zi yuklaydi, siz aytishingiz shart emas.

**Fonda hook'lar ishlaydi:**

| Hook | Qachon | Nima qiladi |
|---|---|---|
| `protect-migrations.sh` | Tahrirdan **oldin** | Mavjud `db/migration/V*.sql` ni tahrirlashdan oldin ruxsat so'raydi. Yangi `V{n}` fayli esa erkin yaratiladi |
| `java-post-edit.sh` | `.java` tahriridan **keyin** | `System.out`, `printStackTrace`, bo'sh `catch`, pul uchun `double`, field `@Autowired` haqida ogohlantiradi va Claude o'zi tuzatadi. Kodda `password = "..."` kabi yozib qo'yilgan secret topilsa, tahrir **bloklanadi** |
| `java-stop-compile.sh` | Javob tugaganda | Holatni dashboard'ga yuboradi. Yoqilgan bo'lsa (6-bo'lim) offline compile ham qiladi |
| `harness-notify.sh` | Yuqoridagilar ichidan | Holatni `localhost:4477` ga yuboradi |

### 3-qadam. Build qizil bo'lsa: `/java-build`

```
/java-build
```

`java-build-resolver` xatolarni bittadan, eng kichik o'zgarish bilan tuzatadi. Testlarni o'chirish yoki `@SuppressWarnings` qo'shish taqiqlangan. `pom.xml` ga tegish kerak bo'lsa, `settings.json` dagi "ask" qoidasi sababli **sizdan ruxsat so'raydi**.

### 4-qadam. Review: `/java-review`

```
/java-review                     # commit qilinmagan o'zgarishlar
/java-review main...HEAD         # branch bo'yicha hammasi
/java-review src/main/java/uz/aab/moneymanager/budgets
```

Natija CRITICAL, HIGH va MEDIUM bo'yicha guruhlanadi. Har bir topilmada `file:line`, muammo va tuzatish bo'ladi. `money-manager.md` rule'i tufayli reviewer loyihaga xos narsalarni ham tekshiradi: boshqa userning resursiga 404, `ApiException`, javobni qobiqqa o'ramaslik, `userId` faqat `@AuthenticationPrincipal` dan olinishi, ledger o'zgarmasligi.

### 5-qadam. PR oldidan: `/review-pr`

```
/review-pr
```

Bu bir nechta agentni parallel ishga tushiradi:

- `code-reviewer`: umumiy sifat;
- `silent-failure-hunter`: yutib yuborilgan xatolar;
- `pr-test-analyzer`: testlar yetarlimi;
- `type-design-analyzer`: DTO va record dizayni;
- `comment-analyzer`: izohlar to'g'rimi;
- `code-simplifier`: soddalashtirish imkoniyatlari.

Oxirgi tekshiruv uchun shunday deb yozing:

```
springboot-verification skill bilan to'liq tekshiruv qil, natijani hisobot qilib ber
```

Va `docs/AGENTS.md` §9 bo'yicha `./mvnw test` natijasini kartaga yozing.

---

## 3. Agent'larni to'g'ridan-to'g'ri chaqirish

Command bo'lmagan holatlarda agentni nomi bilan so'raysiz:

```
code-explorer agenti bilan tranzaksiya yaratilganda account_entries'ga yozuv qanday tushishini
controller'dan repository'gacha kuzatib ber
```
```
database-reviewer agentiga oxirgi 3 ta migratsiya va TransactionRepository'dagi query'larni
indeks va N+1 nuqtai nazaridan ko'rsat
```
```
security-reviewer agenti bilan identity modulini tekshir: OTP, session, CSRF
```
```
silent-failure-hunter bilan checks modulini ko'r
```

**Qaysi agent qachon kerak:**

| Vaziyat | Agent |
|---|---|
| Java kod review (har o'zgarishdan keyin) | `java-reviewer` |
| Maven / javac xatolari | `java-build-resolver` |
| Murakkab feature rejasi | `planner` |
| Notanish modulni tushunish | `code-explorer` |
| Yangi modul yoki katta o'zgarish dizayni | `architect`, `code-architect` |
| TDD bo'yicha yo'l-yo'riq | `tdd-guide` |
| Migratsiya yoki SQL | `database-reviewer` |
| Auth, OTP, session | `security-reviewer` |
| Yutib yuborilgan xatolar | `silent-failure-hunter` |
| PR'dagi testlar sifati | `pr-test-analyzer` |
| DTO va domen tiplari dizayni | `type-design-analyzer` |
| Ishlayotgan kodni soddalashtirish | `code-simplifier` |
| O'lik kodni tozalash | `refactor-cleaner` |
| Spring 4.1 / Hibernate API'si bo'yicha savol | `docs-lookup` (Context7 MCP kerak, 6-bo'lim) |
| Legacy koddan spec chiqarish | `spec-miner` |
| Commit xabarini tekshirish | `commit-reviewer` |

---

## 4. Skill'larni nomi bilan chaqirish

Claude skill'ni odatda o'zi tanlaydi, lekin aniq so'rasangiz ishonchliroq bo'ladi:

```
jpa-patterns skill'iga asoslanib ReportingService'dagi dashboard query'larini N+1 bo'yicha tekshir
```
```
api-design skill'i bo'yicha yangi /savings/goals endpoint'ini loyihalashtir
(lekin money-manager.md'dagi xato modeliga amal qil)
```
```
change-impact skill bilan: accounts.currency ustunini o'zgartirsak nimalar buziladi?
```

**Skill'lar ro'yxati:**

| Guruh | Skill'lar |
|---|---|
| Java / Spring yadrosi | `java-coding-standards`, `springboot-patterns`, `springboot-security`, `springboot-tdd`, `springboot-verification`, `jpa-patterns`, `mybatis-patterns`, `hexagonal-architecture` |
| Ma'lumotlar bazasi | `database-migrations`, `postgres-patterns` |
| API va kontrakt | `api-design`, `contract-first`, `error-handling` |
| Sifat va tekshiruv | `tdd-workflow`, `verification-loop`, `security-review`, `change-impact` |
| Arxitektura va onboarding | `architecture-decision-records`, `codebase-onboarding` |
| Infra | `docker-patterns`, `kubernetes-patterns` |
| Boshqa | `git-workflow`, `search-first`, `strategic-compact`, `documentation-lookup` |

Eng foydalilari: `springboot-tdd`, `jpa-patterns`, `springboot-security`, `springboot-verification`, `database-migrations`, `change-impact`.

---

## 5. Uzoq ishlar uchun sessiya boshqaruvi

| Command | Vazifasi |
|---|---|
| `/save-session` | Holatni `~/.claude/session-data/` ga yozadi (kecha shu yerda to'xtadim) |
| `/resume-session` | Ertasi kuni davom ettirish |
| `/checkpoint create <nom>` | Muhim nuqtani belgilash, masalan `budget-note-green` |
| `/update-codemaps` | Modullar xaritasini yangilash (yangi dasturchi yoki yangi sessiya uchun) |
| `/learn` | Sessiyadan qayta ishlatsa bo'ladigan pattern'ni skill qilib saqlash |

**Barcha command'lar:**

| Command | Vazifasi |
|---|---|
| `/java-review` | Java / Spring review (`java-reviewer`) |
| `/java-build` | Maven / javac xatolarini tuzatish (`java-build-resolver`) |
| `/java-test` | TDD sikli: JUnit 5, MockMvc, Testcontainers, JaCoCo |
| `/plan` | Reja tuzadi, tasdiqlashni kutadi |
| `/feature-dev` | Kodni o'rganib, arxitektura bilan feature qurish |
| `/code-review` | Umumiy review (lokal yoki PR raqami bilan) |
| `/review-pr` | Ko'p agentli PR review |
| `/build-fix` | Umumiy build tuzatish |
| `/test-coverage` | Coverage bo'shliqlarini topib, testlar yozish |
| `/refactor-clean` | O'lik kodni xavfsiz olib tashlash |
| `/checkpoint`, `/save-session`, `/resume-session` | Sessiya boshqaruvi |
| `/update-codemaps`, `/learn` | Hujjatlashtirish va o'rganish |

---

## 6. Sozlash: environment o'zgaruvchilari

Bularni `~/.zshrc` ga yoki bir martalik `VAR=1 claude` ko'rinishida beriladi:

| O'zgaruvchi | Default | Nima qiladi |
|---|---|---|
| `JAVA_HARNESS_COMPILE_ON_STOP=1` | o'chiq | Har javob oxirida `.java` o'zgargan bo'lsa offline compile qiladi |
| `JAVA_HARNESS_FORMAT=1` | o'chiq | Tahrirdan keyin `google-java-format` ishlaydi. Kodingiz allaqachon Google uslubida (2 bo'shliq), shuning uchun yoqsa bo'ladi |
| `HARNESS_NOTIFY=0` | yoniq | `localhost:4477` ga holat yuborishni o'chiradi |
| `HARNESS_NOTIFY_URL=...` | `http://localhost:4477/api/hook` | Holat yuboriladigan boshqa manzil |
| `HARNESS_AGENT_NAME=...` | `java-harness` | Dashboard'da ko'rinadigan agent nomi |

Dashboard'ga keladigan holatlar quyidagicha:

```json
{"agent":"java-harness","task":"Edited BudgetService.java","status":"working"}
{"agent":"java-harness","task":"Existing migration edit needs approval: V7__budgets.sql","status":"blocked"}
{"agent":"java-harness","task":"Hardcoded secret blocked: Foo.java","status":"blocked"}
{"agent":"java-harness","task":"Compile failed after edits","status":"error"}
{"agent":"java-harness","task":"Session turn finished","status":"done"}
```

Server ishlamasa so'rov 2 soniyada jim o'tib ketadi va ishga xalaqit bermaydi.

**Context7** (`docs-lookup` agenti uchun) bir marta qo'shiladi:

```bash
claude mcp add context7 -- npx -y @upstash/context7-mcp@latest
```

**Permission'lar (`settings.json`):**

| Turi | Nimalar |
|---|---|
| Ruxsat berilgan | `./mvnw *` (JAVA_HOME bilan ham), `docker compose up/ps/logs/down`, `curl localhost:8080`, `git status/diff/log/show/branch` |
| Avval so'raladi | `pom.xml`, `docker-compose.yml`, `SecurityConfig.java`, `CsrfCookieFilter.java`, `application-prod.yml` |
| Taqiqlangan | `mvn deploy/release`, `.env` va `.env.local` ni o'qish yoki tahrirlash |

---

## 7. O'zingizga moslashtirish

Harness sizning fayllaringiz, ularni bemalol tahrirlang:

- **Yangi qoida:** `.claude/rules/money-manager.md` ga qator qo'shing, masalan "Har yangi endpoint'da idempotency-key tekshiriladi". Keyingi sessiyadan kuchga kiradi.
- **Agent'ni kuchaytirish:** `.claude/agents/java-reviewer.md` oxiriga loyihaga xos tekshiruvlarni qo'shing.
- **Yangi command:** `.claude/commands/new-endpoint.md` faylini yarating. `$ARGUMENTS` siz yozgan matn bilan almashtiriladi:

  ```markdown
  ---
  description: Yangi endpoint — test, implementatsiya, openapi, cross-user test
  ---
  Endpoint: $ARGUMENTS
  1. api/openapi.yaml'ga sxema qo'sh
  2. Cross-user 404 testini yoz (AGENTS.md §6)
  3. /java-test oqimi bilan implement qil
  4. OpenApiContractTest va OpenApiResponseShapeTest o'tishini tekshir
  ```

  Keyin shunday chaqirasiz: `/new-endpoint GET /savings/goals/{id}`

- **Yangi skill:** `.claude/skills/<nom>/SKILL.md` papkasini yarating. Frontmatter'da `name` papka nomi bilan bir xil bo'lsin va `description` da "qachon ishlatish kerak" aniq yozilsin, chunki Claude skill'ni shu tavsif bo'yicha tanlaydi.

---

## 8. Papka tuzilmasi

```
backend/.claude/
├── README.md               ← shu fayl
├── settings.json           permissions + hooks
├── agents/                 20 ta subagent
├── commands/               15 ta slash-command (java-review, java-build, java-test, plan, ...)
├── skills/                 25 ta skill (har biri <nom>/SKILL.md)
├── rules/
│   ├── money-manager.md    loyihaga xos qoidalar (ENG YUQORI USTUVORLIK)
│   ├── common/             10 ta umumiy qoida
│   └── java/               5 ta Java qoidasi (**/*.java uchun)
└── hooks/
    ├── protect-migrations.sh
    ├── java-post-edit.sh
    ├── java-stop-compile.sh
    └── harness-notify.sh
```

---

## 9. Muammolar va yechimlar

| Belgi | Sabab va yechim |
|---|---|
| `/java-review` ro'yxatda yo'q | Claude `backend/` dan emas, ildizdan ochilgan. `cd backend && claude` |
| Hook ishlamayapti | `/hooks` da ko'rinishini tekshiring; `chmod +x .claude/hooks/*.sh` |
| Hook xatosi `python3: command not found` | `xcode-select --install` (macOS'da python3 shu bilan keladi) |
| `./mvnw` JDK topmayapti | `JAVA_HOME=/Library/Java/JavaVirtualMachines/temurin-21.jdk/Contents/Home ./mvnw test` |
| Testlar Testcontainers'da yiqiladi | Docker ishlayotganini tekshiring: `docker compose ps` |
| Claude ECC qoidasiga amal qilib loyiha qoidasini buzyapti | Unga ayting: "money-manager.md ustun". Kerak bo'lsa qoidani `money-manager.md` ga aniqroq yozing |
| Dashboard'ga hech narsa kelmayapti | `localhost:4477` server ishlayaptimi? `HARNESS_NOTIFY` `0` emasmi? |

---

## Cheat sheet

```
Yangi karta:       /plan <karta>  →  /java-test <xulq>  →  /java-build  →  /java-review  →  /review-pr
Tushunish:         "code-explorer bilan X oqimini kuzat"
DB ishi:           "database-reviewer bilan migratsiyani tekshir"
Xavfsizlik:        "security-reviewer bilan identity modulini tekshir"
Tugatishdan oldin: "springboot-verification bilan tekshir"  +  ./mvnw test natijasi
Ertaga davom:      /save-session  →  /resume-session
```

**Birinchi mashq uchun taklif:** `silent-failure-hunter bilan checks/source/PinnedOfdTransport.java ni ko'r` deb yozib ko'ring. Hook allaqachon u yerda bo'sh `catch` topgan, shuning uchun natijani hook topgani bilan solishtirish oson bo'ladi.
