#!/usr/bin/env bash
# The ios job's verdict — the ONE step that passes or fails the job, and the first thing to read when it is red.
# SPEC: 8.4 (the iOS test layers) · docs/testing-without-a-mac.md Stage 0/1 (reading the macOS job from Windows)
#
# Why this is a script and not inline YAML (2026-09-10, run 34491587098): the verdict used to write its findings ONLY to the
# job summary page and then `exit 1`, so the red ✗ landed on a step whose own log said nothing but "Process completed with
# exit code 1" — and the owner, reading that step log, scrolled 3,000 lines of xcodebuild warnings and never met the one
# compile error. The same findings now go to THREE places: this step's own log (the headline is its first line), the job
# summary page, and GitHub annotations (::error file=…,line=…) so every compile error, assertion failure and failing test
# is clickable at the top of the run and inline on the commit.
#
# Usage: bash ios/scripts/verdict.sh <unit-outcome> <ui-outcome> [dir holding unit.log and ui.log, default ios]
# Testable from Windows against a saved log: GITHUB_WORKSPACE=/Users/runner/work/crew/crew bash ios/scripts/verdict.sh failure failure /tmp/fixture/ios
set -uo pipefail
unit_outcome="${1:-unknown}"
ui_outcome="${2:-unknown}"
dir="${3:-ios}"
workspace="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/../.." && pwd)}"

# file:line(:col): error: … — a compiler error and an XCTest assertion failure share this shape
ERROR_LINE='^/.+\.swift:[0-9]+(:[0-9]+)?: error: '
# the "Failing tests:" block xcodebuild prints at the end: one indented Suite.Class/test() per failure
FAILING_LINE='^[[:space:]]+[A-Za-z]+Tests\.[A-Za-z_]+/test'

# The lines worth reading, once each, in order of appearance: errors, failing tests, per-suite totals, the BUILD/TEST verdicts
salient() {
  grep -E "error: |Failing tests:|$FAILING_LINE|Test Case .* failed \(|Executed [0-9]+ tests, with|\*\* (BUILD|TEST) (FAILED|SUCCEEDED)" "$1" 2>/dev/null \
    | grep -v "CoreData: error" | awk '!seen[$0]++' | head -80
}

unique_count() { grep -E "$1" "$2" 2>/dev/null | awk '!seen[$0]++' | wc -l | tr -d ' '; }

# One GitHub annotation per error (repo-relative path, so it lands on the file) and one per failing test
annotate() {
  grep -E "$ERROR_LINE" "$1" 2>/dev/null | awk '!seen[$0]++' | head -40 | while IFS= read -r line; do
    file="${line%%:*}"; rest="${line#*:}"
    lineno="${rest%%:*}"; rest="${rest#*:}"
    col=""
    if [[ "$rest" =~ ^[0-9]+: ]]; then col="${rest%%:*}"; rest="${rest#*:}"; fi
    message="${rest# error: }"
    file="${file#"$workspace"/}"
    if [ -n "$col" ]; then printf '::error file=%s,line=%s,col=%s::%s\n' "$file" "$lineno" "$col" "$message"
    else printf '::error file=%s,line=%s::%s\n' "$file" "$lineno" "$message"; fi
  done
  grep -E "$FAILING_LINE" "$1" 2>/dev/null | awk '!seen[$0]++' | head -40 | sed -E 's/^[[:space:]]+//' | while IFS= read -r test; do
    printf '::error title=Failing test::%s\n' "$test"
  done
}

# The headline first — what failed, how many, and the first error — then the salient lines under it
report() {
  echo "## ios — unit: $unit_outcome · journeys: $ui_outcome"
  for log in "$dir/unit.log" "$dir/ui.log"; do
    echo
    if [ ! -f "$log" ]; then echo "### $log — not written (the step never ran)"; continue; fi
    local errors failing first
    errors=$(unique_count "$ERROR_LINE" "$log")
    failing=$(unique_count "$FAILING_LINE" "$log")
    first=$(grep -E "$ERROR_LINE" "$log" 2>/dev/null | head -1 | sed -E "s#^$workspace/##")
    echo "### $log — $errors error(s) · $failing failing test(s)"
    [ -n "$first" ] && echo "first error: $first"
    echo '```'; salient "$log"; echo '```'
  done
}

report | tee -a "${GITHUB_STEP_SUMMARY:-/dev/null}"
# One annotation per DISTINCT error: a compile error appears in both logs (each scheme compiles the app), so dedupe across them
{ for log in "$dir/unit.log" "$dir/ui.log"; do [ -f "$log" ] && annotate "$log"; done; } | awk '!seen[$0]++'
[ "$unit_outcome" = success ] && [ "$ui_outcome" = success ]
