# 0001 — The harness gate list is the project's gate list

Status: implemented

## Problem

The rules this project follows lived in prose: code standards, GDScript rules, iteration plans, and a harness-engineering note. Nothing failed when a rule stopped holding, the lists drifted from each other, and a change could satisfy review while breaking a rule written two documents away.

## Decision

The repository declares its checks once, in `harness.manifest.json`, and both the local run and CI execute that list. `harness-drift` fails when the composed instruction files no longer match the pinned base and this repository's delta; `doctor` fails when a declared fact disagrees with the repository; `godot` runs the structural contract and the play suites. Guides may carry judgement, but a rule that must always hold belongs to a gate, and a gate nobody has watched fail is not a gate.

## Alternatives

- Keep the checklists in prose and rely on review: the drift this record exists to stop.
- Write a bespoke script per rule: one more place for the same rule, and no proof that it fires.
- Adopt the harness without the gates: a pinned base that checks nothing is decoration.

## Consequences

- Every check has a name, a proof, and one place to change it; adding a rule means adding a gate that is watched to fail.
- The instruction files are generated from the base plus `AGENTS.delta.md`, so editing `AGENTS.md` is a mistake rather than a shortcut.
- The gate list needs the Godot toolchain; a change that cannot run it is verified by CI, not by hand-waving.
