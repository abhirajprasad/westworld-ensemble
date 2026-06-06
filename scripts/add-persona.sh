#!/usr/bin/env bash
#
# add-persona.sh — bulk-add a persona to this multi-persona host from
# an existing celebrities/examples/ soul. Adds frontmatter, copies STYLE/examples,
# bootstraps memory/.
#
# Usage:
#   ./scripts/add-persona.sh <slug> [display_name] [voice_intensity] [chess_engagement]
#
# Example:
#   ./scripts/add-persona.sh hitchens "Hitchens" medium passive
#
# Sources souls from the bundled examples/personas-bank/ directory in this template.
# 11 personas are pre-bundled — see `ls examples/personas-bank/` for the catalog.

set -euo pipefail

SLUG="${1:-}"
DISPLAY_NAME="${2:-}"
VOICE_INTENSITY="${3:-medium}"
CHESS_ENGAGEMENT="${4:-passive}"

if [ -z "$SLUG" ]; then
  echo "Usage: $0 <slug> [display_name] [voice_intensity] [chess_engagement]" >&2
  echo "" >&2
  echo "  voice_intensity: low | medium | high  (default: medium)" >&2
  echo "  chess_engagement: passive | active | aggressive  (default: passive)" >&2
  echo "" >&2
  echo "Example: $0 hitchens 'Hitchens' medium passive" >&2
  exit 1
fi

# Default display_name = capitalized slug
if [ -z "$DISPLAY_NAME" ]; then
  DISPLAY_NAME="$(echo "$SLUG" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1)) substr($i,2)}}1')"
fi

# Source soul is bundled in this template at examples/personas-bank/<slug>/SOUL.md
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_BASE="$REPO_ROOT/examples/personas-bank/$SLUG"

if [ ! -d "$SOURCE_BASE" ] || [ ! -f "$SOURCE_BASE/SOUL.md" ]; then
  echo "Error: no bundled example for '$SLUG'" >&2
  echo "" >&2
  echo "Available bundled personas:" >&2
  ls "$REPO_ROOT/examples/personas-bank/" 2>/dev/null | sed 's/^/  /' >&2
  echo "" >&2
  echo "To use a custom persona not in the bank, create personas/$SLUG/ by hand." >&2
  exit 1
fi

TARGET="personas/$SLUG"

if [ -d "$TARGET" ]; then
  echo "Error: $TARGET already exists. Delete it first if you want to re-create." >&2
  exit 1
fi

echo "Adding persona: $SLUG"
echo "  display_name:    $DISPLAY_NAME"
echo "  voice_intensity: $VOICE_INTENSITY"
echo "  chess_engagement: $CHESS_ENGAGEMENT"
echo "  source:          $SOURCE_BASE"
echo

mkdir -p "$TARGET/memory/logs" "$TARGET/memory/topics" "$TARGET/examples"
touch "$TARGET/memory/logs/.gitkeep"

# Build SOUL.md = frontmatter + original soul body
{
  cat <<EOF
---
persona: $SLUG
display_name: $DISPLAY_NAME
tier: Glass-box
voice_intensity: $VOICE_INTENSITY
chess_engagement: $CHESS_ENGAGEMENT
narratives: [r/general, r/meta]
---

EOF
  cat "$SOURCE_BASE/SOUL.md"
} > "$TARGET/SOUL.md"

# Minimum STYLE.md — operator should expand
cat > "$TARGET/STYLE.md" <<EOF
# STYLE — $DISPLAY_NAME

Voice rules for this persona. Expand from the "Voice in one line" section of SOUL.md
and the "Anti-patterns" section. Without STYLE.md the persona still works, but voice
fidelity is weaker.

## Sentence structure
(derive from SOUL.md)

## Vocabulary
(derive from SOUL.md anti-patterns)

## Punctuation
(derive from SOUL.md examples if available)

## Anti-patterns to rewrite

- "as an AI"
- "from my perspective"
- "many ways to think about this"
- "I hope this helps"
- "great question"
(add persona-specific ones)
EOF

# Stub examples — operator should fill in
cat > "$TARGET/examples/good-outputs.md" <<EOF
# $DISPLAY_NAME — calibration examples

Hand-write 3-5 sample outputs here in voice. The skill works with sparse examples but
quality is much stronger with 3+ real examples covering: a Westworld post, a reply,
a chess move comment, and a refusal-to-post (silence cycle).

## Example 1 — (your sample post here)

## Example 2 — (your sample reply here)

## Example 3 — (your sample chess move here)
EOF

# Memory bootstrap
cat > "$TARGET/memory/MEMORY.md" <<EOF
# $DISPLAY_NAME — memory index

Persona-specific memory. The host running this fork may have other personas;
respect the memory isolation (do not cross-reference other personas' memory).

## Focal points
- (populate after first cycles)

## Topics
- topics/westworld.md
EOF

cat > "$TARGET/memory/topics/westworld.md" <<EOF
# Westworld engagement state — $DISPLAY_NAME

## Counters
- last_substantive_action_at: (not yet set)
- total_posts: 0
- total_substantive_replies: 0
- total_chess_moves: 0

## Sub engagement (rolling 30-day counts)
- r/general: 0
- r/politics: 0
- r/crypto: 0
- r/war: 0
- r/meta: 0

## Ongoing threads
_Empty at bootstrap._

## Recent host interactions
_Empty at bootstrap._

## Self-observations
_Empty at bootstrap. Append patterns this persona notices about its own behavior._
EOF

echo "Done. Created:"
find "$TARGET" -type f | sort | sed 's/^/  /'
echo
echo "Next: hand-edit $TARGET/STYLE.md and $TARGET/examples/good-outputs.md for voice strength."
