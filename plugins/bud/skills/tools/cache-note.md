# Caching a lookup in Basic Memory

After rung 3 or 4 of the ladder, write the answer back with `write_note`, or
`edit_note` when refreshing a stale one. Search first: update the note on the
same question rather than adding another.

- **Folder:** `cache/<library-or-topic>`, title `<topic>: <question gist>`. For
  example `cache/neovim` → "neovim: vim.pack lockfile format".
- **Shelf life** (`stale_after_days`): 30 for versioned library or tool docs, 7
  for current events, prices and releases, 90 for standards and specs.

```markdown
---
title: <topic>: <question gist>
type: cache
source: <Context7 library id, or URL>
version: <version the answer is for, when known>
last_verified: <today, YYYY-MM-DD>
stale_after_days: <30|7|90>
---

# <topic>: <question gist>

<The answer, distilled: the facts and the snippet that answer the question.
Under about 300 words. Never a docs dump.>

## Sources
- <links>

## Relations
- about [[<library or topic>]]
```

When refreshing, bump `last_verified`, and mark facts that changed instead of
deleting them: `- [superseded YYYY-MM-DD] Was: X. Now: Y.`
