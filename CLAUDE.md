# Claude Code — standing orders for the Crew repo

1. READ docs/crew-mvp-spec.md before any work. Appendix C is your contract.

   Re-read Appendix A (Decision Registry) + Appendix C at the start of EVERY session.

2. This codebase is CONCRETE BY LAW (spec Part V 5.1, C1–C14). Never introduce a

   protocol/interface with one implementation, a generic, a repository/DI/use-case

   layer, a mock, a middleware chain, or a barrel file. Extraction only on the

   third occurrence, and only into a plain function.

3. Every number comes from shared/spec-constants.json via the Generated files.

   Never type a spec number inline. Never edit anything under Generated/.

4. Every function implementing a spec rule carries a `// SPEC:` tag.

5. Work one feature folder at a time. Before coding, state the plan as:

   files touched → tests added → vectors affected. If a needed behavior is

   undefined in the spec: STOP and output `SPECIFICATION GAP: [description]`.

6. Definition of done: Part VII screen criteria pass + Part VI standards hold +

   Part VIII tests green + `npm run vectors` AND the Swift VectorRunner both green.

   A red vector on either engine blocks everything.

7. Vectors are append-only. Changing behavior = new Decision Registry entry +

   new vector. Never edit an existing vector.

8. Commands: web → `npm run dev|test|vectors|e2e|lint|typecheck|generate`

   ios → `xcodebuild test -scheme Crew` (unit+vectors) · UI tests scheme CrewUITests

9. Record every compromise in docs/debt.md in the same commit that creates it.

10. Never build toward anything on the rejected lists (Flows 4, Part II, Part IV).

    "Preparing for" a rejected feature is scope expansion.

11. docs/progress.md is your cross-session memory. Read it at session start,

    update it at session end (task states, blockers, next task). Never rely on

    chat history for state.

12. Work the Part XI task ledger STRICTLY in order, one task at a time. A task

    is done only when its Verify command has been RUN and its output shown.

    Too big for one session? Split it in progress.md first, then start.
