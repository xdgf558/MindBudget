# Commercialization Source Provenance

## Frozen audit input

- Owner-provided filename: `MindBudget%20商业化与%20Pro%20云端%20AI%20开发方案%20v1.4.md`
- Display title: `MindBudget 商业化与 Pro 云端 AI 开发方案 v1.4.md`
- SHA-256: `290bc07fe87fe644f201ef33cba342d3dce0368c64a5d020005873014dd342a0`
- Byte length at the COM-C0A audit: `213855`
- Audit date: `2026-08-10`

The detailed owner specification remains outside this public repository, as required by the root
project contract. The hash is an audit fingerprint for the exact input used to create the frozen
repository snapshot; it is not a claim that CI can read or automatically detect changes to the
owner's external source file.

## Repository snapshot derived from that input

- `Docs/COMMERCIALIZATION_TASKS.md`
- `Docs/Commercialization/REQUIREMENTS_INDEX.md`
- `Docs/Commercialization/SPEC_CONFLICTS.md`
- `Docs/Commercialization/COM_C0A_REPORT.md`
- accepted entries in `Docs/Commercialization/DECISIONS.md`

`Scripts/check-commercialization-docs.sh` reads the fingerprint from this file and verifies that
the authoritative repository snapshot cites the same value. That gate catches internal drift; it
does not authenticate an unavailable external file.

## External change procedure

If the owner supplies a changed or replacement specification, stop the affected COM phase before
implementation. Recompute SHA-256 and byte length from the newly supplied file, compare it with
this lock, audit the semantic delta into stable Requirement/conflict/decision records, obtain any
required owner decisions, and update this provenance file and all derived artifacts together.
Never silently replace the fingerprint or infer that an unchanged filename means unchanged input.
