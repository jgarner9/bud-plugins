# Notes: before and after

## Before: find what he already knows

- Search Basic Memory first, the token-efficient way `bud:tools` describes: `search_notes` with two or three keywords for the topic, `page_size` 3 to 5. Look in `learning/` first.
- A note on the topic means he's been here before: build on it, don't repeat it, and point out what's new. A stale note is still context (say "as of <date>").
- Pitch it at a software engineer whose main language is Go, unless he says otherwise or the topic is far from that. Use an analogy from systems or code only when it really fits.

## After: save what he learned, every time

He doesn't need to ask. Write the note at the end of the reply, after the answer, following his Knowledge Base Conventions note:

1. **Search first** (step 1's search is usually enough). Update the existing note on the topic with `edit_note` rather than adding a second one. Later questions in the same conversation update the note this one wrote.
2. **New note:** `write_note` in `learning/` (or `learning/<field>` when one exists), titled with the topic, not the question ("How DNA ancestry tests work", not "my question about 23andMe").
3. **Frontmatter:** `type: learning`, `last_verified` today (the date you checked the facts), `stale_after_days: 180`, or 30 for a fast-moving field.
4. **Body,** under about 500 words: a short summary in your own words, the key ideas as `- [concept] ...` observations, the misconceptions as `- [misconception] ...`, what he's still unsure of or wants to come back to as `- [question] ...`, any flashcards you made, the sources, and `## Relations` with `[[wiki links]]` to related notes.
5. **Updating:** add what's new, and mark anything you corrected `- [superseded YYYY-MM-DD] Was: X. Now: Y.` instead of deleting it.
6. **Never save** secrets, anything from a work codebase or work tracker, or sensitive personal details.
7. Close with one line: `◇ saved → learning/<note>` (or `◇ updated → ...`). If Basic Memory isn't connected, say so in that line instead.
