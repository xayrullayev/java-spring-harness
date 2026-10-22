#!/usr/bin/env bash
# Java / Spring Boot harness installer (built from affaan-m/everything-claude-code).
#
#   ./install.sh project <path-to-spring-project>   # copy into <project>/.claude (recommended, team-shareable)
#   ./install.sh user                               # copy agents/skills/commands/rules into ~/.claude (all projects)
#   ./install.sh project <path> --with-claude-md    # also drop templates/CLAUDE.md if the project has none
#
# Existing files are never overwritten silently: a differing file is backed up as <file>.bak.<timestamp>.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$HERE/.claude"
mode="${1:-}"; target=""; with_md=0
case "$mode" in
  project) target="${2:?project path required}/.claude"; [ "${3:-}" = "--with-claude-md" ] && with_md=1 ;;
  user)    target="$HOME/.claude" ;;
  *) sed -n 2,8p "$0"; exit 1 ;;
esac
ts="$(date +%Y%m%d%H%M%S)"
mkdir -p "$target"
copy_tree() {
  local rel="$1"
  ( cd "$SRC" && find "$rel" -type f ) | while read -r f; do
    mkdir -p "$target/$(dirname "$f")"
    if [ -f "$target/$f" ] && ! cmp -s "$SRC/$f" "$target/$f"; then
      cp "$target/$f" "$target/$f.bak.$ts"; echo "  backup: $f.bak.$ts"
    fi
    cp "$SRC/$f" "$target/$f"
  done
}
for d in agents skills commands rules hooks; do echo "-> $d"; copy_tree "$d"; done
chmod +x "$target/hooks/"*.sh

if [ "$mode" = "project" ]; then
  if [ -f "$target/settings.json" ]; then
    cp "$SRC/settings.json" "$target/settings.java-harness.json"
    echo "!! $target/settings.json already exists - merge hooks/permissions from settings.java-harness.json by hand"
  else
    cp "$SRC/settings.json" "$target/settings.json"
  fi
  proj="$(dirname "$target")"
  if [ $with_md -eq 1 ] && [ ! -f "$proj/CLAUDE.md" ]; then cp "$HERE/templates/CLAUDE.md" "$proj/CLAUDE.md"; echo "-> CLAUDE.md template created"; fi
else
  # user scope: hook paths must point at ~/.claude, not the project dir
  sed -e 's#\\"\$CLAUDE_PROJECT_DIR\\"/\.claude/hooks#'"$HOME"'/.claude/hooks#g' "$SRC/settings.json" > "$target/settings.java-harness.json"
  echo "!! user scope: merge $target/settings.java-harness.json into ~/.claude/settings.json by hand"
fi
echo "Done. Installed into $target"
echo "Try in Claude Code: /java-review, /java-build, /java-test, /plan, /review-pr"
