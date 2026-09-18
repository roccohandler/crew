---
name: ui-check
description: Push the current branch, run the iOS UI tour for it in GitHub CI, download the screenshots into design/tour/latest/, send only the changed screens to the ui-reviewer subagent, and report PASS/FAIL per screen. Run after any change to iOS UI code, before reporting the task done.
---

# /ui-check — see the real iOS UI, then have it reviewed

The iPhone UI renders only in GitHub CI (macOS). The tour rides the `ci` workflow's `ios` job (Appendix A 2026-09-18 A24 (3));
its output is the `ui-tour` artifact: `<tour class>/NN_<tab>_<screen>_<state>.png`, `TOUR.md`, `CHANGES.md`.

Do the steps in order. Every command below is a plain `git` / `gh` / `node` call and works on Windows.

1. **Local checks first** (a tour costs ~10 macOS minutes; do not spend them on a lint error):
   `node shared/scripts/doctrine-lint.mjs` and `node shared/scripts/swift-xref.mjs`. Stop and fix if either fails.
2. **Commit state.** `git status --short`. Uncommitted UI changes are not in the tour — commit them first (never commit files you
   did not change). Then `git rev-parse --abbrev-ref HEAD` → BRANCH and `git rev-parse HEAD` → SHA.
3. **Push:** `git push -u origin BRANCH` (never force).
4. **Find or start the run.** A push that touched UI paths starts `ci` by itself. Wait ~15 s, then:
   `gh run list --workflow ci.yml --branch BRANCH --commit SHA --json databaseId,status,event --limit 5`
   - a run exists → take its `databaseId`;
   - none (nothing to push, or no UI path in the push) → `gh workflow run ci.yml --ref BRANCH`, wait ~10 s, and list again with
     `--event workflow_dispatch` to get the id.
5. **Wait:** `gh run watch RUN_ID --exit-status --interval 30` (run it in the background; a typical run is 10–14 min).
6. **If the run failed:** `gh run view RUN_ID --log-failed`, and read the step named "verdict — read this first" — it prints the
   compile errors and failing tests. Report the cause (file:line and message). Still do step 7: the artifact is uploaded even on
   a red run, and the screenshots usually show what went wrong. If the `ios` job was skipped, say so: the push had no UI path
   and nothing was dispatched.
7. **Download:** `node .claude/hooks/fetch-tour.mjs --run RUN_ID` — replaces `design/tour/latest/` and prints the CHANGES.md summary.
8. **Pick the screens to review** from `design/tour/latest/CHANGES.md`: everything under **Changed** and **New**. Screens under
   "expected drift" are reviewed only if the code change touched that screen. **Removed** screens are not reviewable — report
   them: a tour step lost its element, which usually means a label changed; fix the step in `ios/CrewUITests/Tour_*Tests.swift`.
   If nothing is Changed or New, say "no visual changes" and stop — do not review unchanged screens.
9. **Review:** launch the `ui-reviewer` subagent once with the full list of paths (`design/tour/latest/<class>/<file>.png`) and
   one line on what the code change was meant to do. Do not judge the screens yourself in its place.
10. **Report** to the user: run id and duration · CI result (and cause if red) · the CHANGES.md summary line · ui-reviewer's
    verdict per screen with its issues verbatim · removed screens. A screen is done only when ui-reviewer passes it; on FAIL,
    fix the code and run /ui-check again.

Never copy anything into `design/baselines/` — that is `/approve-screens`, and only the owner invokes it.
