# <service-name> — Project CLAUDE.md

> Spring Boot service template. Copy to the project root as `CLAUDE.md` and fill in the `<...>` parts.
> Rules in `.claude/rules/` and skills in `.claude/skills/` load automatically — keep this file short and project-specific.

## Project Overview

**Stack:** Java <21>, Spring Boot <3.x>, <Spring WebFlux | Spring MVC>, <PostgreSQL | Oracle>, <JPA | R2DBC | MyBatis>, Maven (`./mvnw`)
**Role:** <one sentence — what this service owns, who calls it, what it calls downstream>
**Layout:** `controller` → `service` → `repository` / `client`; DTOs are `record`s; mapping at service boundary.

## Commands

```bash
./mvnw -q -DskipTests compile        # fast compile
./mvnw -q test                        # unit tests
./mvnw -q verify                      # full build + integration tests
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
```

## Critical Rules

### Java / Spring
- Constructor injection only (`final` fields); no `@Autowired` on fields
- `@Transactional` only on service layer public methods
- Never return entities from controllers — use DTO / record
- Money is `BigDecimal` with explicit scale and `RoundingMode`
- Bean Validation (`@Valid`) on every request DTO
- Logging via SLF4J with placeholders; never log PAN, tokens, passwords, full phone numbers

### Reactive (delete if Spring MVC)
- No blocking calls in Reactor pipelines (`.block()`, JDBC, `Thread.sleep`)
- Every `WebClient` call has a timeout and an explicit error mapping (`onStatus`, `onErrorResume`)
- Never `subscribe()` inside a pipeline; return the `Mono` / `Flux`

### Errors
- Domain exceptions extend a single base (`<BaseBusinessException>`); mapped centrally in `@RestControllerAdvice`
- Never swallow exceptions; never `printStackTrace()`

### Testing
- JUnit 5 + AssertJ + Mockito; `StepVerifier` for reactive code; Testcontainers for DB
- Test names: `method_condition_expectedResult` + `@DisplayName`

## Workflow

1. Non-trivial change → `/plan` first, wait for confirmation
2. Implement test-first → `/java-test`
3. Build red → `/java-build`
4. Before commit → `/java-review`; before PR → `/review-pr`
5. Pre-PR verification → ask for the `springboot-verification` skill

## Do Not Touch

- `<generated sources, e.g. target/generated-sources>`
- `<shared contracts module / parent pom versions — change via bus-parent>`
- `application-prod*.yml`
