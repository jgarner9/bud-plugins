# OpenClaw

OpenClaw has no agent files: an agent is an entry in `~/.openclaw/openclaw.json` with a workspace of its own, and the workspace's files are its prompt.

- `workspace/SOUL.md` is `core.md`'s persona, `workspace/AGENTS.md` its rules. OpenClaw also has `USER.md` for stable preferences about you; the lines about how Jason likes answers could go there instead.
- Skills come from `~/.agents/skills` (see `../shared`), read in OpenClaw's default state dir.
- `openclaw.json5` adds the `coder` agent (its own workspace holding `coder.md`'s body as `AGENTS.md`, and `models.json`'s OpenClaw tier) and the MCP servers. Merge it into your config with `openclaw config set`, or let `bud kit sync` do it once that's built.
- A subagent in OpenClaw is an agent the main one may spawn: `subagents.allowAgents` on `main`.
