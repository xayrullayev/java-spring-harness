---
description: Comprehensive Java / Spring Boot code review — layering, @Transactional, JPA N+1, security, concurrency, Reactor pitfalls. Invokes the java-reviewer agent.
---

# Java Code Review

This command invokes the **java-reviewer** agent for a Java / Spring Boot specific review.

Arguments: `$ARGUMENTS` (optional — file paths, a package, or a git range such as `main...HEAD`).

## What This Command Does

1. **Identify Java changes**: `git diff --name-only HEAD` (or the given range) filtered to `*.java`, `pom.xml`, `build.gradle*`, `application*.yml|properties`
2. **Detect framework**: read `pom.xml` / `build.gradle*` — Spring MVC vs WebFlux, Spring Boot version, Java version
3. **Run static analysis** (only what the build already has configured):
   ```bash
   ./mvnw -q -DskipTests verify            # or ./gradlew check -x test
   ./mvnw -q spotbugs:check                 # if plugin present
   ./mvnw -q checkstyle:check               # if plugin present
   ./mvnw -q pmd:check                      # if plugin present
   ```
4. **Delegate** to the `java-reviewer` agent with the diff and detected context
5. **Report** findings grouped by severity, each with `file:line`, the problem, and a concrete fix

## Review Categories

### CRITICAL (must fix)
- SQL / JPQL injection (string-concatenated queries, `@Query(nativeQuery=true)` with concatenation)
- Hardcoded secrets, tokens, passwords; PII or card data in logs
- Missing authorization on endpoints that change state
- Blocking calls (`.block()`, JDBC, `Thread.sleep`, blocking `RestTemplate`) inside a reactive (WebFlux / Reactor) pipeline
- Lost money/precision: `double`/`float` for amounts instead of `BigDecimal`

### HIGH (should fix)
- `@Transactional` on controller or on private / self-invoked methods (proxy is bypassed)
- JPA entity returned directly from a controller — use DTO / record
- N+1 queries (lazy collection iterated in a loop, missing fetch join / `@EntityGraph`)
- Field injection (`@Autowired` on fields) instead of constructor injection
- Swallowed exceptions (`catch (Exception e) {}`), `e.printStackTrace()`, `System.out.println`
- Reactor: `subscribe()` inside a pipeline, missing `onErrorResume`/timeouts on WebClient calls
- Missing Bean Validation (`@Valid`) on request DTOs

### MEDIUM (consider)
- Mutable DTOs where a `record` would do
- `Optional` used as field or parameter
- Missing `@DisplayName` / non-descriptive test names
- Large methods (> 50 lines) or classes (> 400 lines)

## When to Use

- After writing or modifying Java code
- Before committing or opening a PR
- When onboarding to an unfamiliar Spring Boot service

## Related

- Agent: `java-reviewer`
- Skills: `java-coding-standards`, `springboot-patterns`, `springboot-security`, `jpa-patterns`
- Rules: `rules/java/*`
- Fix build first if it is red: `/java-build`
