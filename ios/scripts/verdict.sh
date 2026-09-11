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
# What run 34540455856 then taught (2026-09-10, second pass). A single failing UI assertion was reported as
# "1 error(s) · 0 failing test(s)", under a "Failing tests:" heading with nothing beneath it. Two bugs, one cause — the
# script did not know the difference between a COMPILE ERROR and an ASSERTION FAILURE:
#   1. xcodebuild prints an XCTest assertion in the compiler's own shape, `file:line: error: -[Class test] : XCTAssert…`,
#      so it was counted as a compile error. A green build was reported as having an error in it.
#   2. The failing-test count came from the trailing "Failing tests:" block, whose real format is
#      `\tJourney2_FastLogTests.testReturningUserFastLogs…()` — no bundle prefix, a DIGIT in the class name, and a `.`
#      separator. The regex wanted `[A-Za-z]+Tests\.[A-Za-z_]+/test`, which matches none of those three things.
# Failing tests are now counted off `Test Case '-[…]' failed (`, which xcodebuild prints per failure and has not changed
# shape across Xcode versions, and the two kinds of finding are counted, headlined and annotated separately.
#
# And the last-resort rule, because a verdict that finds nothing must not print nothing: if the step failed but no error and
# no failing test could be parsed out of its log (a simulator that never booted, a linker error, a timeout), the tail of
# that log is printed. Silence is the one thing this step is not allowed to do.
#
# ONE log since 2026-09-10 (run 34542854485): the job is one `xcodebuild test` on the CrewAll scheme, because splitting it
# into a build plus two `test-without-building` runs tripled the simulator preparation and made the job 86% slower. Both
# test bundles run in that single pass, so this one log carries the compile, the unit suite and the journeys.
#
# Usage: bash ios/scripts/verdict.sh <test-step-outcome> [dir holding test.log, default ios]
# Testable from Windows against a saved log:
#   GITHUB_WORKSPACE=/Users/runner/work/crew/crew bash ios/scripts/verdict.sh failure /tmp/fixture/ios
set -uo pipefail
outcome="${1:-unknown}"
dir="${2:-ios}"
log="$dir/test.log"
workspace="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/../.." && pwd)}"

# file:line(:col): error: … — the shape a compiler error AND an XCTest assertion failure share. What separates them is that
# the assertion names the test it came from: `error: -[CrewUITests.Journey2_FastLogTests testFoo] : XCTAssertTrue failed`.
ERROR_LINE='^/.+\.swift:[0-9]+(:[0-9]+)?: error: '
ASSERT_MARK=': error: -\['
# One per failure, printed as each test finishes. Version-stable, unlike the trailing "Failing tests:" summary block.
FAILED_CASE="^Test Case '-\[.*\]' failed \("

compile_errors() { grep -E "$ERROR_LINE" "$1" 2>/dev/null | grep -v "$ASSERT_MARK" | awk '!seen[$0]++'; }
assert_failures() { grep -E "$ERROR_LINE" "$1" 2>/dev/null | grep -E "$ASSERT_MARK" | awk '!seen[$0]++'; }
failed_cases() { grep -E "$FAILED_CASE" "$1" 2>/dev/null | awk '!seen[$0]++'; }
count() { "$1" "$2" | grep -c . ; }

# The lines worth reading, once each, in order of appearance: errors, failing tests, per-suite totals, the BUILD/TEST verdicts.
# `Failing tests:` is followed by one indented `Class.test()` per failure — matched loosely enough to survive Xcode renaming it.
# `** TEST BUILD SUCCEEDED **` is a real xcodebuild verdict too, so BUILD/TEST are matched in either order.
salient() {
  grep -E "error: |Failing tests:|^[[:space:]]+[A-Za-z0-9_]+[./][A-Za-z0-9_./]*[Tt]est[A-Za-z0-9_]*\(?\)?$|$FAILED_CASE|Executed [0-9]+ tests, with|\*\* (TEST )?(BUILD )?(FAILED|SUCCEEDED)" "$1" 2>/dev/null \
    | grep -v "CoreData: error" | awk '!seen[$0]++' | head -80
}

# `/Users/runner/work/crew/crew/ios/X.swift:12:3: error: msg` → `ios/X.swift`, `12`, `3`, `msg`
split_error() { # sets file lineno col message
  local line="$1"
  file="${line%%:*}"; local rest="${line#*:}"
  lineno="${rest%%:*}"; rest="${rest#*:}"
  col=""
  if [[ "$rest" =~ ^[0-9]+: ]]; then col="${rest%%:*}"; rest="${rest#*:}"; fi
  message="${rest# error: }"
  file="${file#"$workspace"/}"
}

# One annotation per finding, at the file:line it happened — a compile error and an assertion failure are both clickable.
annotate() {
  compile_errors "$1" | head -40 | while IFS= read -r line; do
    split_error "$line"
    if [ -n "$col" ]; then printf '::error file=%s,line=%s,col=%s::%s\n' "$file" "$lineno" "$col" "$message"
    else printf '::error file=%s,line=%s::%s\n' "$file" "$lineno" "$message"; fi
  done
  assert_failures "$1" | head -40 | while IFS= read -r line; do
    split_error "$line"
    printf '::error file=%s,line=%s,title=Failing test::%s\n' "$file" "$lineno" "$message"
  done
}

report() {
  if [ ! -f "$log" ]; then
    echo "## ios — $log was never written (the test step did not run; outcome: $outcome)"
    return
  fi
  local errors failures first
  errors=$(count compile_errors "$log")
  failures=$(count failed_cases "$log")
  echo "## ios — $errors compile error(s) · $failures failing test(s) · outcome: $outcome"
  first=$(compile_errors "$log" | head -1 | sed -E "s#^$workspace/##")
  [ -n "$first" ] && echo "first compile error: $first"
  first=$(assert_failures "$log" | head -1 | sed -E "s#^$workspace/##")
  [ -n "$first" ] && echo "first failing assertion: $first"
  echo '```'; salient "$log"; echo '```'
  # A step that failed with nothing parseable in it must still say something — the tail is better than silence.
  if [ "$outcome" = failure ] && [ "$errors" = 0 ] && [ "$failures" = 0 ]; then
    echo "NO compile error and NO failing test could be parsed out of a log whose step FAILED — the last 30 lines:"
    echo '```'; tail -30 "$log"; echo '```'
  fi
}

report | tee -a "${GITHUB_STEP_SUMMARY:-/dev/null}"
[ -f "$log" ] && annotate "$log"
[ "$outcome" = success ]
