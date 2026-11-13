# OpenCode (`~/.config/opencode/`)

- `AGENTS.md` is `core.md`. OpenCode also reads a project's `CLAUDE.md` when it has no `AGENTS.md`.
- Skills come from `~/.agents/skills` (see `../shared`); OpenCode also reads `~/.claude/skills`. Checked with 2.2.7.
- `agents/coder.md`: `role: subagent` is `mode: subagent`, `tier: fast` is `models.json`'s OpenCode id, and `access: edit` needs no rules (OpenCode allows by default). A read-only agent gets `permissions` denying `edit` and `shell`.
- `opencode.json` holds the MCP servers.

Checked: both agent files load in OpenCode 2.2.7 as written (`mode: subagent`, the model resolved, the reviewer's `edit` deny rule applied).
