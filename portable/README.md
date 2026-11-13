# Portable setup: one source, every harness

How bud-plugins' instructions, skills, commands, agents and MCP servers can work with any harness (Claude Code, OpenCode, Codex, OpenClaw) and any model. This is a proposal: the decisions at the end are Jason's, and nothing under `plugins/` changes until they're made. `examples/` shows what each harness would get for the same source files.

Checked on 2026-11-13: OpenCode 2.2.7 and OpenClaw 2026.11.3 against running copies, Codex against its docs and third-party guides (marked where so), Claude Code against this repo's working plugins.

## The harness does it, not the model

A model only ever sees text: a system prompt, a list of tool definitions, and the conversation. Everything else is the harness:

| Piece | What the harness does with it | What the model sees |
| --- | --- | --- |
| Instructions (`AGENTS.md`, `CLAUDE.md`) | Finds the files and puts their text in the system prompt | Text |
| Skills (`SKILL.md`) | Lists each skill's name and description; loads the body when the model asks for it (a `skill` tool) or you invoke it | A tool, and a short list |
| Commands (`/name`) | Expands the file's body, with `$ARGUMENTS` filled in, into your message | Your message |
| Agents | Picks the system prompt, the model and the allowed tools for a session or a subagent | Its own prompt and tools |
| MCP servers | Starts them and turns their tools into tool definitions | Tools |
| Hooks | Runs scripts on harness events; the model never knows | Nothing, or text a hook adds |

So the portable layer is a **file format and a renderer per harness**, not anything model-specific. The model only matters in two places: which model each agent runs on, and how hard it thinks (effort). Those become abstract tiers in the source, mapped to real model ids per harness and provider (`models.json`).

The content of instructions and skills is already model-neutral, provided it's written in plain terms ("run the check and show its output") rather than naming one harness's tool ("use the Bash tool").

## What each harness reads

| | Claude Code | OpenCode 2.x | Codex | OpenClaw |
| --- | --- | --- | --- | --- |
| Instructions | `CLAUDE.md`, `~/.claude/CLAUDE.md` | `AGENTS.md` (falls back to `CLAUDE.md`), `~/.config/opencode/AGENTS.md`, `instructions` in `opencode.json` | `AGENTS.md`, `~/.codex/AGENTS.md` (`AGENTS.override.md` first) | The agent's workspace: `AGENTS.md` (rules), `SOUL.md` (persona), `USER.md` (your preferences) |
| Skills | Plugins, `~/.claude/skills/<name>/SKILL.md` | `~/.config/opencode/skills`, **`~/.agents/skills`**, `~/.claude/skills` (all checked) | **`~/.agents/skills`**, `.agents/skills` up to the repo root, `/etc/codex/skills` (OpenAI's docs) | `<workspace>/skills`, **`~/.agents/skills`**, `~/.openclaw/skills`, `skills.load.extraDirs` (its docs) |
| Skill format | AgentSkills `SKILL.md`: `name`, `description` | Same (checked) | Same; extras in `agents/openai.yaml` | Same (AgentSkills spec) |
| Commands | `commands/<name>.md`, `$ARGUMENTS`; skills are also `/name` | `commands/<name>.md`, `$ARGUMENTS` (checked) | `~/.codex/prompts/*.md`, deprecated in favour of skills (`$name`, `/skills`) | Skills marked user-invocable become slash commands |
| Agents | `agents/<name>.md`: `tools`, `model`, `effort` | `agents/<name>.md`: `mode`, `model` (`provider/model`), `permissions` (checked) | `~/.codex/agents/<name>.toml`: `model`, `model_reasoning_effort`, `sandbox_mode`, `developer_instructions` (guides; verify) | Config entries, `agents.entries.<id>` with `model` and a workspace of its own; no agent files |
| MCP servers | `.mcp.json`, `claude mcp add` | `mcp.servers` in `opencode.json` | `[mcp_servers.<name>]` in `config.toml` | Its MCP config and plugins |
| Hooks | `hooks.json`, shell scripts | JS plugins | Plugins | Hooks and plugins |

Two things stand out:

- **`~/.agents/skills` is the shared skill folder.** OpenCode, Codex and OpenClaw all read it, so one copy of each skill there serves three harnesses. Claude Code keeps getting them from the plugin.
- **Skills can replace commands.** Every harness lets you invoke a skill by name, and Codex has deprecated its prompts in favour of skills. A command that only says "use skill X on $ARGUMENTS" (like `plan-to-linear`) works better as a skill with that description.

## The proposal

**One source in this repo, rendered per harness by `bud kit sync`.** The Claude plugin tree under `plugins/` stays committed as it is, because claude.ai, Desktop and Cowork load the marketplace straight from the repo. The other harnesses get files that `bud kit sync` writes from that source, under the ledger 4.1 already has. Nothing generated is committed.

What the renderer does:

1. **Instructions:** `core.md` becomes `~/.config/opencode/AGENTS.md` and `~/.codex/AGENTS.md`. On OpenClaw, its persona lines go in the workspace's `SOUL.md` and its rules in `AGENTS.md`. `inside-bud.md` stays bud's to deliver (see hooks below).
2. **Skills:** each `plugins/*/skills/<name>/` is linked or copied to `~/.agents/skills/<name>/`, which OpenCode, Codex and OpenClaw all read. Name references are rewritten in the copy: `bud:verify` becomes `verify` (section 7.2 of bud's `BASE.md`).
3. **Commands:** folded into skills (decision 2), so no renderer.
4. **Agents:** written in the neutral format in `agents/` here (frontmatter `role`, `tier`, `effort`, `access`) and rendered: Claude Code's `agents/*.md`, OpenCode's `agents/*.md`, Codex's `agents/*.toml`, and OpenClaw's `agents.entries`. Tiers map through `models.json`.
5. **MCP servers:** from bud's `kit/kit.json` `servers` section (JGA-249) into each harness's config.
6. **Hooks:** stay per harness. The session gate's rule ("one task per context") already lives in the `build` skill as text every model reads; the Claude hook only enforces it. For bud's own chat, bud can enforce the same gate itself, since it sees every prompt it sends over ACP, so it works on every backend without a hook per harness.

`examples/` shows the result for `core.md`, the `coder` agent, `plan-to-linear` as a skill, and one MCP server, per harness. The agent sources in `agents/` are the neutral format; `models.json` is the tier map.

## Building your own TUIs on it

bud's chat (`bud.ai.view`) talks ACP, so it doesn't need to know any of these formats. The harness loads instructions and skills itself, and sends its commands to bud in `available_commands_update`, which bud's chat already completes after `/`. Its modes and settings arrive as ACP config options, which `:BudAgent option` sets. A TUI of yours gets the same things from the same protocol: write it against `bud.ai.agent`'s events and calls, and it works on whichever harness `ai.backend` names.

## Decisions for Jason

1. **Where the source of truth lives.**
   - Keep the Claude plugin tree as the source and render the rest from it, plus neutral fields for agents. The plugin tree has to stay committed anyway for claude.ai.
   - A neutral tree (like `agents/` here) as the source, with the Claude plugin tree generated from it and committed. One format to edit, but two copies in the repo and a generator to keep honest.
   - Recommendation: the first. Only agents need fields Claude's format lacks, and they can carry them in their frontmatter.
2. **Commands.**
   - Fold them into skills. Every harness invokes skills by name, and Codex has deprecated prompts.
   - Keep commands, rendered per harness.
   - Recommendation: fold them. There's one today (`plan-to-linear`).
3. **Where skills go for the other harnesses.**
   - `~/.agents/skills`, read by OpenCode, Codex and OpenClaw.
   - Each harness's own folder.
   - Recommendation: `~/.agents/skills`, one copy. OpenClaw reads it only in its default state dir, which is what bud's setup uses.
4. **Models.**
   - Abstract tiers (`fast`, `balanced`, `deep`) in agents, mapped per harness in `models.json`.
   - Real model ids per harness in each agent file.
   - Recommendation: tiers. Changing models becomes one file, and a local model can be a tier's value.
5. **Hooks.**
   - The rule lives in skills, and bud enforces the gate in its own chat. Each harness's hook is optional.
   - Port the gate to each harness's plugin system.
   - Recommendation: the first. Four hook systems for one rule isn't worth it.
