# Plan Files

Plan files live here as `docs/plans/plan-NNN-<slug>.md`.

In the tested factory flow, `NNN` is the source issue number, zero-padded to at least three digits:

- issue `#7` -> `plan-007-...`
- issue `#61` -> `plan-061-...`
- issue `#1042` -> `plan-1042-...`

Do not scan `docs/plans/` for the next sequential number.

Each plan file contains:

- structured requirements from the plan-interview skill
- success criteria
- risk assessment
- affected files and areas
- an implementation checklist
- a recommended implementer section

The source issue remains open while the plan PR is reviewed. The plan PR must reference the source issue with a non-closing link such as `Refs #61`.
