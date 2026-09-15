# Postmortem — 先实现后测试，测试绑定实现而非目标

Date: 2026-08-25
Owner: @lijinchao

## Impact

清风块“点击无反应、被消掉看不出效果”等交互与迭代文档描述不一致的问题，在实现完成之后才由 owner 试玩发现。当时自动化测试全绿，因为它们断言的是已经写好的实现行为，而不是迭代文档承诺的目标。

## Detection

owner 试玩反馈：会攒清风块，但“点击后没有任何效果”，且“带有它的花被消掉后，也被消掉”。测试套件里没有任何测试覆盖“点击清风块会触发”这个目标，所以全绿也拦不住。

## Timeline

- 迭代 P / B-2 先写实现（Board 生成与触发清风块），再补/改测试去匹配实现。
- 测试全绿、Harness 通过。
- owner 试玩发现交互与文档描述不一致。

## Root cause

流程是“先实现、后测试”，且测试只验证实现细节（例如某个内部函数能清行），没有把迭代文档里的目标（玩家点一下清风块就能发动）**先**写成会失败的验收测试。缺少“目标 → 测试”的机械映射，于是目标可以完全没被覆盖而套件仍然全绿。

## Response

- 在 `AGENTS.delta.md` 第 7 节增加“目标级测试先行”强制约束：先写目标级测试并确认红，再实现到绿。
- 在 `docs/ITERATION_TEMPLATE.md` 加入必填的 `## 验收测试映射` 章节。
- 在 `scripts/tools/harness_check.gd` 增加机械检查：当前迭代文档必须声明映射，且表中每个 `test_*` 都已注册在 `TestRunner` 并在 `tests/suites/` 中实现。
- 已按门禁要求“打响”：临时禁用映射章节时检查失败（exit 1），恢复后通过（220 项 / 0 失败）。

## Regression test

Regression: godot

## Action items

- [x] AGENTS.delta 增加目标级测试先行约定 — @lijinchao, 2026-08-25
- [x] 迭代模板与当前迭代文档加入验收测试映射 — @lijinchao, 2026-08-25
- [x] harness_check 增加映射机械检查，并证明它会失败 — @lijinchao, 2026-08-25
