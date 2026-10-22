#!/usr/bin/env bash
# Stop hook: if Java sources changed in the working tree, run a quiet compile once.
# Opt-in: set JAVA_HARNESS_COMPILE_ON_STOP=1 (compiling a large multi-module build on every stop can be slow).
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
notify() { "$HOOK_DIR/harness-notify.sh" "$1" "$2"; }
[ "${JAVA_HARNESS_COMPILE_ON_STOP:-0}" = "1" ] || { notify "Session turn finished" done; exit 0; }
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
git diff --name-only HEAD 2>/dev/null | grep -q '\.java$' || { notify "Session turn finished" done; exit 0; }
if [ -x ./mvnw ]; then out="$(./mvnw -q -o -DskipTests compile 2>&1)"
elif [ -f pom.xml ]; then out="$(mvn -q -o -DskipTests compile 2>&1)"
elif [ -x ./gradlew ]; then out="$(./gradlew -q compileJava --offline 2>&1)"
else notify "Session turn finished" done; exit 0; fi
if [ $? -ne 0 ]; then
  notify "Compile failed after edits" error
  echo "[java-harness] Compile failed after this session's edits. Run /java-build." >&2
  printf '%s\n' "$out" | grep -E 'ERROR|error:' | head -15 >&2
else
  notify "Compile OK, session turn finished" done
fi
exit 0
