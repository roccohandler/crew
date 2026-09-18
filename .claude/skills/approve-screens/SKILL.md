---
name: approve-screens
description: Owner-only. Copy the screenshots the owner names (or "all") from the tour folder into design/baselines/ and commit them as "Approve baselines: <list>".
disable-model-invocation: true
argument-hint: all | <screen> [<screen> …]
---

# /approve-screens — the owner approves how screens look

This runs ONLY when the owner types `/approve-screens …`. Never run it, or its script, on your own initiative — not to make a
CHANGES.md quieter, not because ui-reviewer passed a screen. Approval is the owner's act (Appendix A 2026-09-18 A24 (5)).

Arguments: `$ARGUMENTS`

1. If the arguments are empty, ask which screens (or "all") and stop.
2. Run: `node .claude/skills/approve-screens/approve.mjs $ARGUMENTS`
   - a name matches with or without its `NN_` step prefix and `.png`: `plan_editor_filled`, `03_plan_editor_filled.png`, or
     `tour_plantests/03_plan_editor_filled.png`;
   - `all` copies every tour shot and deletes baselines the latest tour no longer produces.
   The script copies from the tour folder (`design/tour/latest/`, or `<CREW_TOUR_DIR>/<current branch>/` when that is set), stages only those files, and commits `Approve baselines: <list>`.
3. If it reports unknown names, show the owner the available names it printed and stop — do not guess.
4. Report the commit (`git log -1 --oneline`) and which run the screenshots came from (`.run-id` in the tour folder). Pushing is
   a separate step: push only if the owner asked for it in the same message.
