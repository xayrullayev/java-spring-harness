#!/usr/bin/env bash
# PostToolUse hook (Edit|Write|MultiEdit) for Java files.
# - Formats the edited .java file with google-java-format if it is installed
# - Warns (stderr -> shown to Claude) about common Java anti-patterns
# Never blocks: always exits 0 unless a CRITICAL pattern (hardcoded secret) is found -> exit 2.
set -u
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
notify() { "$HOOK_DIR/harness-notify.sh" "$1" "$2" & }
input="$(cat)"
file="$(printf '%s' "$input" | python3 -c 'import sys,json
try:
  d=json.load(sys.stdin); ti=d.get("tool_input",{}); print(ti.get("file_path") or ti.get("path") or "")
except Exception: print("")' 2>/dev/null)"
case "$file" in *.java) ;; *) exit 0 ;; esac
[ -f "$file" ] || exit 0
name="$(basename "$file")"

# Opt-in: reformatting a whole file can create noisy diffs if the project is not already google-java-format clean.
if [ "${JAVA_HARNESS_FORMAT:-0}" = "1" ] && command -v google-java-format >/dev/null 2>&1; then
  google-java-format --replace "$file" 2>/dev/null || true
fi

warn=()
grep -nE 'System\.(out|err)\.print' "$file" | grep -v '^\s*//' >/dev/null && warn+=("System.out/err.println found - use SLF4J logger")
grep -nE '\.printStackTrace\(\)' "$file" >/dev/null && warn+=("printStackTrace() found - log with logger.error(msg, e)")
grep -nE '@Autowired' "$file" | grep -vE '^\s*[0-9]+:\s*(public|protected|private)?\s*[A-Z][A-Za-z0-9_]*\s*\(' >/dev/null && \
  grep -nA1 '@Autowired' "$file" | grep -qE '(private|protected)\s+[A-Za-z<>?, ]+\s+[a-z][A-Za-z0-9]*\s*;' && warn+=("Field injection (@Autowired on field) - use constructor injection")
grep -nE 'catch\s*\([^)]*\)\s*\{\s*\}' "$file" >/dev/null && warn+=("Empty catch block - handle or rethrow")
grep -nE '\b(double|float|Double|Float)\s+[a-z]*(amount|balance|sum|price|total)' -i "$file" >/dev/null && warn+=("double/float used for money - use BigDecimal")
grep -nE '\.block\(\)' "$file" >/dev/null && grep -qE 'import reactor\.core' "$file" && warn+=(".block() inside Reactor code - keep the pipeline non-blocking")

if grep -nE '(password|secret|apiKey|api_key|token)\s*=\s*"[^"$]{6,}"' -i "$file" | grep -viE 'test|example|placeholder' >/dev/null; then
  echo "[java-harness] CRITICAL: possible hardcoded secret in $file - move it to env/config/secret manager." >&2
  notify "Hardcoded secret blocked: $name" blocked; wait
  exit 2
fi

if [ ${#warn[@]} -gt 0 ]; then
  { echo "[java-harness] $file:"; for w in "${warn[@]}"; do echo "  - $w"; done; } >&2
  notify "Edited $name (${#warn[@]} warning)" working
else
  notify "Edited $name" working
fi
wait
exit 0
