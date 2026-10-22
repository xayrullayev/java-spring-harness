# Agent Orchestration

## Available Agents

This harness installs agents under bare names (no `ecc:` prefix) into `.claude/agents/`.
They are invoked through the Agent tool with that `subagent_type`:

```text
Agent(subagent_type: "java-reviewer", prompt: "...")
```

| Agent | Purpose | When to Use |
|-------|---------|-------------|
| java-reviewer | Java / Spring Boot code review | After ANY Java change (MUST) |
| java-build-resolver | Maven/Gradle/javac error fixing | When build or compile fails |
| planner | Implementation planning | Complex features, refactoring |
| architect | System design | Architectural decisions |
| code-architect | Feature blueprint from existing patterns | Before implementing a feature |
| code-explorer | Trace execution paths through code | Understanding unfamiliar modules |
| tdd-guide | Test-driven development | New features, bug fixes |
| code-reviewer | Generic code review | Non-Java files, config, scripts |
| security-reviewer | Security analysis | Auth, input handling, before commits |
| database-reviewer | SQL / schema / query review | Migrations, JPA queries, indexes |
| silent-failure-hunter | Swallowed errors, bad fallbacks | Error-handling heavy code |
| pr-test-analyzer | Test coverage quality of a PR | Before merge |
| type-design-analyzer | Type / invariant design | New domain models, DTOs |
| comment-analyzer | Comment accuracy | Doc-heavy changes |
| code-simplifier | Simplify without behavior change | After a feature works |
| refactor-cleaner | Dead code cleanup | Code maintenance |
| doc-updater | Documentation / codemaps | Updating docs |
| docs-lookup | Live library docs via Context7 MCP | Spring/Hibernate API questions |
| spec-miner | Extract behavioral specs from legacy code | Brownfield onboarding |
| commit-reviewer | Commit message / scope review | Before pushing |

## Immediate Agent Usage

No user prompt needed:
1. Complex feature requests - Use **planner** agent
2. Code just written/modified - Use **java-reviewer** (Java) / **code-reviewer** (other) agent
3. Bug fix or new feature - Use **tdd-guide** agent
4. Architectural decision - Use **architect** agent

## Parallel Task Execution

ALWAYS use parallel Task execution for independent operations:

```markdown
# GOOD: Parallel execution
Launch 3 agents in parallel:
1. Agent 1: Security analysis of auth module
2. Agent 2: Performance review of cache system
3. Agent 3: Type checking of utilities

# BAD: Sequential when unnecessary
First agent 1, then agent 2, then agent 3
```

## Delegation Completion Contract

Applies to every agent at every depth (parent, child, grandchild):

1. **Your final message IS the deliverable.** Never end your turn with "waiting for background agents" — a spawned task is not a completed task. Ending your turn while children are running orphans their results (completed children cannot notify a parent whose turn has ended).
2. **If you delegate, you own collection.** Wait for results, integrate them, then return. Fire-and-forget delegation is forbidden.
3. **Decompose only when the work cannot fit in one context.** Do not re-delegate a task already sized for a single agent — depth is an outcome, not a plan.

> Rationale: observed failure mode — research agents followed "Parallel Task Execution" above, spawned children, and returned "waiting" as their final answer. All children completed successfully but their results were orphaned. The parallel rule without a completion contract produces zombie tasks.

## Multi-Perspective Analysis

For complex problems, use split role sub-agents:
- Factual reviewer
- Senior engineer
- Security expert
- Consistency reviewer
- Redundancy checker
