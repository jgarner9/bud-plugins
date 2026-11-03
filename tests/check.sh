#!/usr/bin/env bash
# Checks the marketplace before a push: JSON parses, every skill and agent has
# the frontmatter Claude needs, links inside skills resolve, core.md fits
# Desktop's 3,000-character limit, and (when claude is installed) Claude
# Code's own validator passes.
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
status=0

fail() {
	echo "✗ $*"
	status=1
}

for f in "$root/.claude-plugin/marketplace.json" "$root"/plugins/*/.claude-plugin/plugin.json; do
	jq -e . "$f" >/dev/null 2>&1 || fail "$f isn't valid JSON"
done

# The marketplace entry and the plugin's manifest must agree on the name.
for p in "$root"/plugins/*/; do
	name=$(basename "$p")
	[ "$(jq -r .name "$p/.claude-plugin/plugin.json")" = "$name" ] || fail "plugins/$name: plugin.json name isn't $name"
	jq -e --arg n "$name" '.plugins | map(.name) | index($n)' "$root/.claude-plugin/marketplace.json" >/dev/null ||
		fail "plugins/$name isn't listed in marketplace.json"
	jq -e 'has("version") | not' "$p/.claude-plugin/plugin.json" >/dev/null ||
		fail "plugins/$name: plugin.json sets a version, so pushes stop reaching installs until it's bumped"
done

frontmatter() { # file field
	awk -v k="$2" 'NR == 1 && $0 != "---" { exit } NR > 1 && $0 == "---" { exit } NR > 1 && index($0, k ": ") == 1 { print substr($0, length(k) + 3); exit }' "$1"
}

for f in "$root"/plugins/*/skills/*/SKILL.md "$root"/plugins/*/agents/*.md; do
	[ -f "$f" ] || continue
	rel=${f#"$root"/}
	[ -n "$(frontmatter "$f" name)" ] || fail "$rel: no name in its frontmatter"
	desc=$(frontmatter "$f" description)
	[ -n "$desc" ] || fail "$rel: no description in its frontmatter"
	[ "${#desc}" -le 1024 ] || fail "$rel: description is ${#desc} characters (over 1024)"
	case $f in */SKILL.md)
		[ "$(frontmatter "$f" name)" = "$(basename "$(dirname "$f")")" ] || fail "$rel: name doesn't match its folder"
		;;
	esac
	# Relative links to files next to the skill must exist.
	while IFS= read -r link; do
		[ -n "$link" ] && [ ! -f "$(dirname "$f")/$link" ] && fail "$rel: links to $link, which doesn't exist"
	done < <(grep -o '](\([^):#]*\.md\))' "$f" | sed 's/^](//; s/)$//')
done

chars=$(wc -m <"$root/core.md" | tr -d ' ')
[ "$chars" -le 3000 ] || fail "core.md is $chars characters; Desktop's organization instructions take at most 3,000"

if command -v claude >/dev/null 2>&1; then
	out=$(claude plugin validate "$root" 2>&1) || fail "claude plugin validate failed:
$out"
else
	echo "· claude isn't installed; skipped claude plugin validate"
fi

[ "$status" = 0 ] && echo "✓ checks passed (core.md: $chars characters)"
exit "$status"
