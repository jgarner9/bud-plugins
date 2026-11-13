#!/usr/bin/env bash
# Tests plugins/bud/hooks/gate.sh with a throwaway repo and state dir. No
# network, no claude: each case feeds the hook the JSON Claude Code would.
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
gate=$root/plugins/bud/hooks/gate.sh
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export CLAUDE_PLUGIN_DATA=$tmp/data
unset BUD_GATE
status=0

fail() {
	echo "✗ gate: $*"
	status=1
}

repo=$tmp/repo
git init -q "$repo"
commit() { # subject [committer date]
	GIT_COMMITTER_DATE=${2:-$(date +%s)} git -C "$repo" -c user.name=t -c user.email=t@example.com commit -q --allow-empty -m "$1"
}

run() { # event, then jq args that add fields; prints the hook's output, returns its status
	local event=$1
	shift
	jq -n --arg e "$event" --arg cwd "$repo" "$@" \
		'{hook_event_name: $e, session_id: "s1", cwd: $cwd} + $ARGS.named' | "$gate" 2>&1
}
committed() { run PostToolUse --arg tool_name Bash --argjson tool_input '{"command": "git commit -m x"}' "$@" >/dev/null; }
prompt() { run UserPromptSubmit --arg prompt "$1"; }

out=$(prompt "start JGA-2") || fail "a prompt was refused before any commit"
[ -z "$out" ] || fail "a fresh session got context: $out"

commit "old work (JGA-1)" "2020-01-01T00:00:00Z"
committed
[ ! -e "$CLAUDE_PLUGIN_DATA/gate/s1" ] || fail "a failed commit (HEAD is old) marked the session"

commit "feat: the thing (JGA-1)"
committed --arg agent_id a1
[ ! -e "$CLAUDE_PLUGIN_DATA/gate/s1" ] || fail "a subagent's commit marked the session"

run PostToolUse --arg tool_name Bash --argjson tool_input '{"command": "git status"}' >/dev/null
[ ! -e "$CLAUDE_PLUGIN_DATA/gate/s1" ] || fail "a command that isn't a commit marked the session"

committed
[ -f "$CLAUDE_PLUGIN_DATA/gate/s1" ] || fail "a commit didn't mark the session"

out=$(prompt "now do JGA-2") && fail "a prompt naming another issue was let through"
case $out in *"/clear"*"JGA-2"*) ;; *) fail "the refusal doesn't say what to do: $out" ;; esac

out=$(prompt "fix the typo in JGA-1's test") || fail "a follow-up to the committed issue was refused"
case $out in *"already committed"*) ;; *) fail "a follow-up got no context line: $out" ;; esac

out=$(prompt "/compact") || fail "a slash command was refused"
[ -z "$out" ] || fail "a slash command got context: $out"

out=$(run UserPromptSubmit --arg prompt "JGA-2 changed" --arg source system) || fail "a system-injected turn was refused"

out=$(export BUD_GATE=off && prompt "now do JGA-2") || fail "BUD_GATE=off didn't turn the gate off"

run SessionStart --arg source compact >/dev/null
[ ! -e "$CLAUDE_PLUGIN_DATA/gate/s1" ] || fail "compacting didn't clear the mark"
out=$(prompt "now do JGA-2") || fail "a prompt was refused after compacting"

[ "$status" = 0 ] && echo "✓ gate tests passed"
exit "$status"
