# bud-plugins

How I want Claude to work: one plugin, `bud`, that every Claude surface loads
from this repo. Edit a skill, push, and claude.ai, the phone, Claude Desktop,
Cowork and Claude Code all pick it up.

| Skill | Use |
| --- | --- |
| `bud:code-style` | Writing, testing, reviewing and committing code |
| `bud:planning` | Specs, design docs with a decision log, tasks, Linear issues |
| `bud:tools` | Which tool to use: code navigation, the lookup ladder, Basic Memory, Linear |
| `bud:debugging` | Find the cause before fixing: reproduce, read the evidence, narrow, name the cause, fix it with a test |
| `bud:verify` | Run the check and show its output before saying work is done |
| `bud:learn` | Learning how or why something works: the explanation first, tutoring only on request, study aids, and a note saved to Basic Memory's `learning/` every time. Replaces Anthropic's `learn` skill, so turn that one off on claude.ai |
| `bud:bootstrap-project` | `/bud:bootstrap-project`: write a repo's `CLAUDE.md` with you |
| `bud:release` | Cutting a release (`/bud:release`): code review and security review of everything since the last tag, the docs checked against the code and fixed, then the repo's own release steps. Claude Code only, since it runs Claude Code's `code-review` and `security-review` |

Plus a `code-reviewer` agent (Claude Code and Cowork; chat ignores agents) and
`/bud:plan-to-linear`.

A second plugin, `bud-ide`, is only for Claude Code inside the
[bud](https://github.com/jgarner9/bud) Neovim IDE, which installs it: the
`bud-ide:bud-dev` and `bud-ide:file-issue` skills (`/bud-ide:file-issue` runs
it by hand), the `bud-ide:chat` agent that bud's chat (the dashboard's `c`,
`bud chat`) starts Claude Code's TUI as (conversational, can read and look
things up but not edit or run commands), and a `SessionStart` hook that gives
sessions bud starts (`BUD_BIN` set) the notes on working inside bud. Don't add it on
claude.ai.

Skills load when a task matches them. [`core.md`](core.md) is the short,
always-on part that names them, so they load reliably.

Everything here is work-safe on purpose. Personal pieces (notes, finances,
machine setup) stay in private repos.

## Set it up

**claude.ai (web, phone, Desktop signed in), and Claude Code signed in to the same account:**

1. [Customize → Plugins](https://claude.ai/customize/plugins) → **Add → Add
   marketplace** → `jgarner9/bud-plugins`, then turn on **Sync automatically**.
2. Add `bud` from it.
3. Settings → Profile → personal preferences: paste [`core.md`](core.md).

Claude Code gets the plugin as a synced plugin at its next session start.

**Claude Code without claude.ai (Bedrock):** clod's `install.sh` clones this
repo and loads the plugin from that checkout, so each session reads the
current files. By hand, it's:

```sh
claude plugin marketplace add jgarner9/bud-plugins
claude plugin install bud@bud-plugins
```

**Claude Desktop on Bedrock:** clod's import file adds this repo under
`allowedPluginMarketplaces` and puts `core.md` in `organizationInstructions`.

## Change it

Edit, then check:

```sh
tests/check.sh
```

Push to `main`. There's no `version` in `plugin.json` on purpose: installs
track commits, so every push is an update.

Keep `core.md` under 3,000 characters (Desktop's limit for organization
instructions) and keep it short anyway, since it's in every conversation.

## License

[MIT](LICENSE).
