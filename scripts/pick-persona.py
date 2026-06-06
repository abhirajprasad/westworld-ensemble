#!/usr/bin/env python3
"""
pick-persona.py — selects which persona to run this cycle.

Reads `personas-state.json` (or creates it from `personas/` directory listing),
picks the persona with the oldest `last_cycle_at`, updates the state file,
prints the picked persona's slug to stdout.

Called by `chain-runner.yml`'s "Pick persona" step. The chain skills then
read `$PERSONA` env var (set from this script's stdout).

If `personas/` doesn't exist (single-persona mode), prints nothing.
Workflow detects empty stdout and runs in legacy mode.
"""

import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

STATE_FILE = Path("personas-state.json")
PERSONAS_DIR = Path("personas")
EPOCH = "1970-01-01T00:00:00Z"


def discover_personas():
    """List subdirectories of personas/ that contain a SOUL.md."""
    if not PERSONAS_DIR.exists():
        return []
    return sorted(
        p.name
        for p in PERSONAS_DIR.iterdir()
        if p.is_dir() and (p / "SOUL.md").exists()
    )


def load_state():
    """Load or initialize the state file."""
    if STATE_FILE.exists():
        with open(STATE_FILE) as f:
            return json.load(f)
    return {"personas": [], "last_updated": None}


def save_state(state):
    """Persist state. Atomic via tmp + rename."""
    tmp = STATE_FILE.with_suffix(".tmp")
    with open(tmp, "w") as f:
        json.dump(state, f, indent=2)
    tmp.replace(STATE_FILE)


def now_iso():
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def main():
    discovered = discover_personas()

    if not discovered:
        # Single-persona mode (or empty personas/ dir). Print nothing.
        # The workflow treats empty stdout as "run in legacy mode".
        sys.exit(0)

    state = load_state()
    state_personas = {p["slug"]: p for p in state.get("personas", [])}

    # Sync state with discovered personas — add new, remove deleted
    for slug in discovered:
        if slug not in state_personas:
            state_personas[slug] = {
                "slug": slug,
                "last_cycle_at": EPOCH,
                "cycles_run": 0,
            }
    for slug in list(state_personas):
        if slug not in discovered:
            del state_personas[slug]

    # Pick the persona with the oldest last_cycle_at
    picked = min(state_personas.values(), key=lambda p: p["last_cycle_at"] or EPOCH)

    # Update its timestamp + counter
    picked["last_cycle_at"] = now_iso()
    picked["cycles_run"] = picked.get("cycles_run", 0) + 1

    state["personas"] = sorted(state_personas.values(), key=lambda p: p["slug"])
    state["last_updated"] = now_iso()
    save_state(state)

    # Print to stdout — captured by the workflow into $PERSONA
    print(picked["slug"])


if __name__ == "__main__":
    main()
