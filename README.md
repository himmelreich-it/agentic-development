# agentic-development

A Claude Code **plugin marketplace** of agentic development workflow skills: design/plan/resolve
loops, PR review, and git worktree workflows.

The marketplace catalog lives in [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json)
and contains three plugins.

## Plugins

| Plugin | Skills | What it does |
| --- | --- | --- |
| **design-flow** | `ideation`, `confluence-ideation`, `design-for-review`, `plan-for-review`, `resolve-review`, `implement-feature` | Collaborative and async design → plan → resolve loop, interactive ideation, Confluence-published design sessions, and end-to-end feature orchestration. |
| **pr-review** | `review-pr`, `handle-code-review` | Run a comprehensive scoped PR review, and critically evaluate / process incoming review feedback. |
| **git-workflow** | `worktree`, `sync-main` | Create an isolated git worktree with local settings copied; safely sync a feature branch with `main` while preserving PR functionality. |

Plugin skills are **namespaced** by plugin name, e.g. `/design-flow:ideation`,
`/pr-review:review-pr`, `/git-workflow:worktree`.

## Install

In a Claude Code session:

```text
/plugin marketplace add himmelreich-it/agentic-development
/plugin install design-flow@agentic-development
/plugin install pr-review@agentic-development
/plugin install git-workflow@agentic-development
```

Install only the plugins you want — they are independent.

### Non-interactive (CLI)

```bash
claude plugin marketplace add himmelreich-it/agentic-development
claude plugin install design-flow@agentic-development
claude plugin install pr-review@agentic-development
claude plugin install git-workflow@agentic-development
```

After installing, run `/reload-plugins` (or restart Claude Code) and check `/help` to see the
namespaced skills.

## Updating

Plugins use **git-SHA versioning** — no pinned version, so every pushed commit is a new version.
Refresh the marketplace to pull the latest:

```text
/plugin marketplace update agentic-development
```

## Local development / testing

From a clone of this repo:

```bash
# Validate the marketplace + all plugin manifests and skill frontmatter
claude plugin validate .

# Add this checkout as a local marketplace
/plugin marketplace add ./
/plugin install design-flow@agentic-development

# Or load a single plugin directly without installing
claude --plugin-dir ./plugins/design-flow
```

## Repository layout

```
.claude-plugin/marketplace.json     marketplace catalog
plugins/
  design-flow/   .claude-plugin/plugin.json + skills/<skill>/SKILL.md
  pr-review/     .claude-plugin/plugin.json + skills/<skill>/SKILL.md
  git-workflow/  .claude-plugin/plugin.json + skills/<skill>/SKILL.md
```

## License

MIT
