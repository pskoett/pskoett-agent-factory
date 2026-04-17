# Contributing

This repository is a template source for an agent factory. Changes should keep the template internally consistent and installable.

## Scope

In-scope changes:

- workflow source updates in `workflows/`
- plain Actions support updates in `workflow-support/`
- installer improvements in `install.sh`
- skill updates in `skills/`
- docs that explain the tested flow

Out-of-scope changes:

- reintroducing `/plan` and sub-issue routing
- reintroducing sequential plan numbering
- documenting automation that the factory cannot actually complete

## Required Checks

Before opening a PR:

1. Review all changed workflow sources for path and label correctness.
2. If you changed install behavior, verify `install.sh` still copies every required file.
3. If you changed docs, confirm they match the current flow.
4. Run shell syntax checks on any changed shell scripts:

```bash
bash -n install.sh
bash -n scripts/check-workflow-lock-sync.sh
```

## Contribution Rules

- Keep `README.md`, `docs/AGENT_FACTORY.md`, `docs/chain.md`, and `AGENTS.md` aligned.
- When adding workflow labels, add them to `install.sh`.
- When adding workflow support files, add them under `workflow-support/` and update the installer.
- Keep comments and docs direct and factual.
