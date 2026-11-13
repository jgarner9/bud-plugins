# Codex (`~/.codex/`)

- `AGENTS.md` is `core.md`.
- Skills come from `~/.agents/skills` (see `../shared`). Codex's custom prompts are deprecated in favour of skills, which is one reason to fold commands into skills.
- `agents/coder.toml`: Codex's agent format, from guides rather than OpenAI's own docs, so check it before relying on it. `access: edit` is `sandbox_mode = "workspace-write"`; `read` would be `"read-only"`. The model is `models.json`'s Codex tier, a placeholder until you set it.
- `config.toml` holds the MCP servers. Codex doesn't expand `${VAR}`, so `bud kit sync` writes the value.
