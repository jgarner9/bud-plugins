#!/usr/bin/env bash
# The session gate: one task per context (bud:build). Claude Code runs this
# as a hook, with the event as JSON on stdin.
#
#   PostToolUse (Bash)       a git commit just made in the session's directory
#                            marks the session as having finished a task
#   SessionStart             after /clear or /compact, the mark is removed
#   UserPromptSubmit         in a marked session, a prompt that names an issue
#                            the commit doesn't is refused (exit 2); any other
#                            prompt gets one line of context saying so
#
# It never blocks a tool, never touches the repo, and fails open: with no jq,
# no session id or BUD_GATE=off it does nothing.
set -uo pipefail

[ "${BUD_GATE:-on}" = off ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
field() { printf '%s' "$input" | jq -r "$1 // empty" 2>/dev/null; }

session=$(field .session_id)
case $session in "" | */* | .*) exit 0 ;; esac
dir=${CLAUDE_PLUGIN_DATA:-${XDG_STATE_HOME:-$HOME/.local/state}/bud-plugins}/gate
mark=$dir/$session

case $(field .hook_event_name) in
PostToolUse)
	# a subagent's commit isn't the session finishing a task
	[ -z "$(field .agent_id)" ] || exit 0
	case $(field .tool_input.command) in *"git commit"*) ;; *) exit 0 ;; esac
	cwd=$(field .cwd)
	# only a commit made just now: the command may have failed
	made=$(git -C "$cwd" log -1 --format=%ct 2>/dev/null) || exit 0
	[ $(($(date +%s) - made)) -le 120 ] || exit 0
	mkdir -p "$dir" && git -C "$cwd" log -1 --format=%s >"$mark"
	;;
SessionStart)
	rm -f "$mark"
	# a cleared session gets a new id, so its old mark is never looked at again
	find "$dir" -type f -mtime +7 -exec rm -f {} + 2>/dev/null
	;;
UserPromptSubmit)
	[ -f "$mark" ] || exit 0
	prompt=$(field .prompt)
	case $prompt in /*) exit 0 ;; esac
	case $(field .source) in "" | user | sdk) ;; *) exit 0 ;; esac
	subject=$(cat "$mark")
	for id in $(printf '%s' "$prompt" | grep -oE '[A-Z]{2,}-[0-9]+' | sort -u); do
		case $subject in *"$id"*) continue ;; esac
		echo "This context already finished a task (\"$subject\"). Run /clear, or /compact to keep a summary, before starting $id. BUD_GATE=off turns this off." >&2
		exit 2
	done
	echo "This session already committed \"$subject\". If this prompt starts a different task, don't begin it: say that the context should be cleared (/clear) or compacted (/compact) first. A follow-up to the committed task is fine."
	;;
esac

exit 0
