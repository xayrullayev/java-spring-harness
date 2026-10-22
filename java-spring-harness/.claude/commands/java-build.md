---
description: Fix Maven / Gradle / javac build errors incrementally with minimal, surgical changes. Invokes the java-build-resolver agent.
---

# Java Build and Fix

This command invokes the **java-build-resolver** agent to get a red Java build green with the smallest possible changes.

Arguments: `$ARGUMENTS` (optional — a module name, e.g. `bus-abs`, or a specific goal such as `test-compile`).

## What This Command Does

1. **Detect build tool**: `mvnw` → `pom.xml` → `gradlew` → `build.gradle(.kts)`; multi-module? (`<modules>` / `settings.gradle`)
2. **Run diagnostics** (stop at the first failing stage):
   ```bash
   ./mvnw -q -DskipTests compile          # main sources
   ./mvnw -q -DskipTests test-compile     # test sources
   ./mvnw -q dependency:tree -Dverbose | head -150   # only for dependency / version conflicts
   # Gradle
   ./gradlew compileJava compileTestJava --console=plain
   ./gradlew dependencies --configuration runtimeClasspath | head -150
   ```
   For a single module in a multi-module build: `./mvnw -q -pl <module> -am compile`
3. **Parse and group errors** by file; configuration / dependency errors first, then compiler errors in dependency order
4. **Fix one error at a time**, re-running the build after each fix
5. **Summarize**: what was fixed, what remains, any change that touched `pom.xml` / `build.gradle`

## Guardrails

- Never add `@SuppressWarnings`, `-Dmaven.test.skip`, or delete tests to get green
- Never bump a dependency's major version without saying so explicitly in the summary
- Prefer aligning with the parent BOM / `dependencyManagement` over pinning versions locally
- Stop and ask if the fix needs an architectural change or touches more than ~5 files

## Common Errors

| Error | Usual fix |
|-------|-----------|
| `cannot find symbol` | Missing import, renamed method, or missing dependency |
| `incompatible types` | Generic mismatch, `Mono<T>` vs `T`, boxed vs primitive |
| `package ... does not exist` | Dependency missing or `<scope>test</scope>` used in main |
| `NoSuchMethodError` at test time | Version conflict — inspect `dependency:tree`, align via BOM |
| `release version 21 not supported` | JDK on PATH older than `maven.compiler.release` |
| Lombok symbols missing | Annotation processor path not configured |
| MapStruct `Unmapped target property` | Add `@Mapping` or set `unmappedTargetPolicy` |

## Related

- Agent: `java-build-resolver`
- Generic fallback: `/build-fix`
- After green: `/java-test`, then `/java-review`
