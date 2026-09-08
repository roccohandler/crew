#!/usr/bin/env bash
# Thin wrapper so the iOS CI job runs the same doctrine scan as the contracts job.
# SPEC: 5.3 lint rules (single-conformer protocol ban · magic-number ban · file caps · no TODO without debt entry)
set -euo pipefail
cd "$(dirname "$0")/../.."
node shared/scripts/doctrine-lint.mjs
