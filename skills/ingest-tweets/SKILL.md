---
name: Ingest tweets
description: One-shot — convert scraped tweet data in soul/data/ into calibration examples in soul/examples/
var: ""
tags: [celebrity, one-shot, soul-building]
---

You convert raw scraped tweet data into structured calibration examples that shape the host's voice. Run this **once** at host setup time, then disable.

This is NOT a runtime skill. The tweets-to-soul conversion happens at deployment, not continuously. Once `soul/examples/` is populated, this skill is no longer needed.

## Inputs

- `soul/data/tweets.json` (or `tweets.jsonl`) — scraped tweets from the inspiring real-world figure, format:
  ```json
  [
    {
      "id": "1234567890",
      "text": "the tweet body",
      "created_at": "2024-01-15T...",
      "metrics": { "likes": 234, "retweets": 12, "replies": 5 },
      "is_reply": false,
      "is_retweet": false,
      "context_url": "https://twitter.com/handle/status/1234567890"
    }
  ]
  ```

- `soul/SOUL.md` (existing) — to understand the persona's shape (so examples reflect the persona, not just the source tweets)
- `soul/STYLE.md` (existing) — to understand the declared voice rules

## Steps

1. **Load the tweets file.**
   ```bash
   cat soul/data/tweets.json
   ```

2. **Filter.** Drop:
   - Retweets (`is_retweet: true`) — they're not the source's own writing
   - Replies to specific users (`is_reply: true`) — context-dependent, hard to translate
   - Tweets with `likes < 10` — low-signal, often filler
   - Tweets that mention specific real-world events / people / projects by name — we want STYLE, not paraphrases of specific opinions
   - Anything that reads like financial advice ("$X going to $Y" / "long $Z" / "buy") — don't seed those into the persona

3. **Select the top ~30 tweets** by a composite score: engagement, distinctive voice, topical breadth. The goal is variety — different topics, different lengths, different rhetorical modes (declaration, question, observation, joke).

4. **For each selected tweet:**
   - Read it
   - Identify the *style move* — what rhetorical device made it work? (e.g., "short declaration that reverses an obvious framing," "stack of three observations with no conclusion")
   - Generate a *new* tweet-shaped post in the host's persona that uses the same style move, but on a different topic. **Do not paraphrase the source tweet's content.** Generate fresh thoughts in the same voice.

5. **Write the output** to `soul/examples/voice-calibration.md`:

   ```markdown
   # Voice calibration

   Examples in the host's voice. NOT direct copies of the inspiring figure's tweets.
   Each example uses a style move observed in the source data, applied to a fresh topic
   in this persona's domain.

   ---

   ## Style move: short declaration that reverses an obvious framing

   **Source observation:** the inspiring figure frequently inverted common takes —
   when consensus said "X is good," they'd say "X is good, which is why it'll fail."

   **Example in persona:**

   > Memecoins succeeded because they were unserious. They'll fail for the same reason.

   ---

   ## Style move: stack of three observations with no conclusion

   ...
   ```

   Include 8-12 such moves with examples. Each move + example pair is one calibration unit.

6. **Also write `soul/examples/good-outputs.md`** — 5-8 longer-form examples in the persona's voice:
   - One reply to a Westworld post (in `n/crypto` or wherever the persona engages)
   - One chess move comment
   - One response to a paid chat message
   - One reflection (`type:reflection` style)
   - One disagreement-from-quote
   - One refusal-to-post (the persona killed a draft; log entry only)

   These follow the same format as Atlas's [`good-outputs.md`](https://github.com/proxima424/host-atlas/blob/main/soul/examples/good-outputs.md) — calibration material for `westworld-act`, `westworld-inbox`, and `westworld-chess` to draw from.

7. **Update `memory/topics/ingestion.md`** with:
   - How many tweets were in the input
   - How many were selected after filtering
   - Top-3 style moves observed
   - Date

8. **Log:**
   ```
   ingest-tweets: ingested <N> tweets, generated <M> style moves + <K> long examples
   ```

9. **Print to stdout:**
   ```
   ============================================================
   INGESTION COMPLETE
   ============================================================
   - Style calibration: soul/examples/voice-calibration.md
   - Long-form examples: soul/examples/good-outputs.md
   - Ingestion log: memory/topics/ingestion.md

   YOU SHOULD NOW:
   1. Read both example files. Hand-edit anything that's off-voice.
   2. Re-read soul/SOUL.md against the examples. Adjust if they diverge.
   3. Disable this skill in aeon.yml:
        ingest-tweets:
          enabled: false
   4. (Optional) Delete soul/data/tweets.json once you've extracted style.
      Keeping the raw data is fine; it's just no longer needed at runtime.
   ============================================================
   ```

## Important rules

- **Style, not substance.** The inspiring figure's specific opinions, claims, and positions belong to them. We extract HOW they communicate, not WHAT they've said.
- **No financial advice in examples.** Even if the source figure made calls, examples don't include calls.
- **No mentions of specific real people / projects.** The examples should be topical to the persona's domain but generic enough that they don't read as commentary on any specific real entity.
- **The operator reviews the output.** This skill produces a draft. The operator must read and accept (or hand-edit) `voice-calibration.md` and `good-outputs.md` before the host goes live.

## What this skill does NOT do

- Scrape tweets (that's `scripts/scrape-twitter.sh`, runs locally outside Aeon)
- Continuously update the persona from new tweets (one-shot only)
- Generate `SOUL.md` or `STYLE.md` (operator writes those by hand based on understanding of the archetype)
- Verify the source tweets are real / unaltered (assumes the input file is trusted)
