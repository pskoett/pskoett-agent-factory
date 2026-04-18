# Plan Files

Plan files live here at `docs/plans/plan-NNN-<slug>.md`, where `NNN` is the source issue number, zero-padded to at least three digits.

Examples:

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

## Lifecycle Metadata

Plan files may carry YAML frontmatter at the top of the file that encodes their lifecycle state:

```yaml
---
plan-id: plan-097
status: shipped
shipped-in: "#97"
---
```

### Supported `status` values

| Value | Meaning |
|-------|---------|
| `active` | current design or open planning artifact |
| `shipped` | the plan was implemented and merged |
| `superseded` | the plan was replaced by a newer plan or design |
| `abandoned` | the plan was intentionally not completed |

### Companion fields

- `shipped-in`: the source issue number that the plan shipped under, for example `"#97"`
- `superseded-by`: the plan ID that replaced this one, for example `plan-136`

### Rule for agents

`status: shipped`, `status: superseded`, and `status: abandoned` plans are historical artifacts. Do not treat them as current design without checking the live code or a newer `active` plan.

### Automation

`plan-merged-dispatcher` automatically prepends `status: shipped` and `shipped-in: "#NN"` to every newly merged plan file when that frontmatter is missing. This is idempotent.

The source issue remains open while the plan PR is reviewed. The plan PR must reference the source issue with a non-closing link such as `Refs #61`.
