# MANIFEST

Upstream: https://github.com/affaan-m/everything-claude-code @ 90606c8 (v2.2.3, 2026-10-20). Generated 2026-10-22.

## Modified upstream files

- `rules/common/agents.md` — roster replaced with this harness's 20 agents; `ecc:` prefixes removed
- `rules/common/code-review.md` — agent table: TS/Python/Go/Rust reviewers → java-reviewer, database-reviewer, silent-failure-hunter; console.log → System.out/printStackTrace
- `rules/common/development-workflow.md` — code review step points to java-reviewer; npm/PyPI → Maven Central
- `rules/common/performance.md` — build-error-resolver → java-build-resolver

## New files (not in upstream)

- `.claude/commands/java-review.md`
- `.claude/commands/java-build.md`
- `.claude/commands/java-test.md`
- `.claude/hooks/java-post-edit.sh`
- `.claude/hooks/java-stop-compile.sh`
- `.claude/hooks/harness-notify.sh`
- `.claude/settings.json`
- `templates/CLAUDE.md`
- `templates/mcp.json`
- `install.sh`
- `README.md`

## Upstream files copied verbatim

### agents

- architect
- code-architect
- code-explorer
- code-reviewer
- code-simplifier
- comment-analyzer
- commit-reviewer
- database-reviewer
- doc-updater
- docs-lookup
- java-build-resolver
- java-reviewer
- planner
- pr-test-analyzer
- refactor-cleaner
- security-reviewer
- silent-failure-hunter
- spec-miner
- tdd-guide
- type-design-analyzer

### commands

- build-fix
- checkpoint
- code-review
- feature-dev
- learn
- plan
- refactor-clean
- resume-session
- review-pr
- save-session
- test-coverage
- update-codemaps

### skills

- api-design
- architecture-decision-records
- change-impact
- codebase-onboarding
- contract-first
- database-migrations
- docker-patterns
- documentation-lookup
- error-handling
- git-workflow
- hexagonal-architecture
- java-coding-standards
- jpa-patterns
- kubernetes-patterns
- mybatis-patterns
- postgres-patterns
- search-first
- security-review
- springboot-patterns
- springboot-security
- springboot-tdd
- springboot-verification
- strategic-compact
- tdd-workflow
- verification-loop

### rules

- common/agents.md
- common/code-review.md
- common/coding-style.md
- common/development-workflow.md
- common/git-workflow.md
- common/hooks.md
- common/patterns.md
- common/performance.md
- common/security.md
- common/testing.md
- java/coding-style.md
- java/hooks.md
- java/patterns.md
- java/security.md
- java/testing.md

### upstream-docs

- LICENSE
- project-stack-mappings.json
- the-longform-guide.md
- the-security-guide.md
- the-shortform-guide.md
