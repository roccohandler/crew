# design/baselines/

The approved look of every tour screen: `<tour class>/NN_<tab>_<screen>_<state>.png`, exactly as the `ui-tour` artifact names them.
CI (`ios/scripts/tour-diff.mjs`) compares each new tour shot with the file of the same name here and writes CHANGES.md.

Only `/approve-screens` writes to this folder, and only when the owner invokes it (Appendix A 2026-09-18 A24 (5)).
