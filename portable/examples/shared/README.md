# Shared by OpenCode, Codex and OpenClaw

`~/.agents/skills/` is read by all three (OpenCode checked, Codex and OpenClaw from their docs), so `bud kit sync` writes each skill here once. Claude Code gets the same skill from the plugin.

`plan-to-linear` shows a command turned into a skill (decision 2): its body is the command's, with `$ARGUMENTS` replaced by "the plan you were given", and its description says when to use it, so every harness can invoke it by name (`/plan-to-linear` in Claude Code and OpenClaw, `$plan-to-linear` in Codex, the skill tool in OpenCode).
