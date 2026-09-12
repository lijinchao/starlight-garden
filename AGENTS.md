# Shared harness base

This file is composed into a repository's `AGENTS.md` above the repository delta. Edit the base in the shared harness repository, never in a consuming repository.

## Commands

- Build: `make build` — must end with `Build succeeded`.
- Test: `make test` — all green; never delete or skip a failing test.
- Lint: `make lint` — zero warnings.

Run all three before reporting any task complete, and paste the output.

## Conventions

- One change, one plan: commit a plan before implementation, and update it in the same commit when the implementation departs from it.
- A rule that must always hold belongs in a gate, not in this file.
- When the same mistake happens twice, the correction goes into this base or the repository delta, not only into the code.
- State a target that can be checked without asking, for example: "the endpoint returns 200 with the new field".

## Things the agent gets wrong

- Do not edit generated files; edit the generator.
- Do not weaken or delete a test to make a change pass.
- Do not add a dependency without the owner's approval.
- Do not restate the repository's architecture from memory; read the code.

# Repository delta — 星光花园 (starlight-garden)

Everything above this file comes from the shared coding-harness base. This file holds only what is true for this repository.

> **本文件是生成源。** 仓库根目录的 `AGENTS.md` 由共享 base 与本文件合成；`REVIEW.md` 由共享 base 生成。
> 要修改它们，编辑本文件或 `harness.manifest.json`，再运行：
> `node ../coding-harness/bin/harness.mjs sync --manifest harness.manifest.json`。
> 直接手改 `AGENTS.md` / `REVIEW.md` 会被 `harness check` 判为 drift。
>
> 共享 base 顶部的 `make build` / `make test` / `make lint` 是通用占位符，本仓库不适用；本仓库的真实命令见第 9 节。

本文件定义本仓库中使用 CODEX / AI Agent 进行开发时必须遵循的工作约定。

目标不是限制开发速度，而是确保：

- 开发结果始终与产品目标一致
- 每一轮迭代都可验证、可评估
- 文档、代码、测试三者保持一致

---

## 1. 首次进入仓库必须优先查阅的文档

任何 Agent 在开始分析、修改、补功能前，优先阅读以下文档：

1. [README.md](README.md)
2. [docs/STATUS_AND_ITERATION_PLAN.md](docs/STATUS_AND_ITERATION_PLAN.md)
3. [docs/CURRENT_PRODUCT_AND_ARCHITECTURE.md](docs/CURRENT_PRODUCT_AND_ARCHITECTURE.md)
4. [docs/PRODUCT_THEME_AND_GAMEPLAY_REVIEW.md](docs/PRODUCT_THEME_AND_GAMEPLAY_REVIEW.md)
5. 当前正在执行的迭代文档
   默认优先看 [docs/ITERATION_L_DAILY_BREEZE_GARDEN_PLAN.md](docs/ITERATION_L_DAILY_BREEZE_GARDEN_PLAN.md)
6. [docs/HARNESS_ENGINEERING.md](docs/HARNESS_ENGINEERING.md)
7. 如果要新增后续迭代，使用 [docs/ITERATION_TEMPLATE.md](docs/ITERATION_TEMPLATE.md)

如果代码实现与旧文档冲突，以“当前代码 + 最新状态文档”为准，不盲从历史描述。

---

## 2. 所有开发必须遵循的核心准则

### 准则一：先对齐目标，再写代码

每次开发前，必须先回答：

- 这次改动服务哪个产品目标？
- 这次改动补的是主循环、内容层，还是体验层？
- 如果这项功能做完，玩家会感知到什么变化？

如果回答不清楚，不应该直接开始实现。

主题、用户和玩法取舍必须在每个新迭代立项前复核，不因工程实现完成而默认继续沿用。

### 准则二：不接受“只完成代码，不完成价值”

以下情况不算完成：

- 代码写完，但玩家无感知
- UI 做了，但资源流没闭合
- 文案补了，但规则没落地
- 数据配置有了，但玩法没有真实生效

### 准则三：所有功能都必须可验证

每项交付至少要有以下之一：

- 自动化测试
- 稳定可重复的手动验证步骤
- 清晰的验收标准

如果无法验证，就不能判定为完成。

### 准则四：所有功能都必须可评估

每项功能上线前，都要能回答：

- 它改善了哪段体验？
- 如果移除它，主循环是否明显变弱？
- 玩家是否会因此多打一局、少流失一次、或者更理解目标？

### 准则五：优先闭合主循环，不优先堆外围系统

当前项目优先级长期遵循：

1. 核心循环闭合
2. 局外成长有效
3. 治愈感系统化
4. 内容扩展
5. 商业化深化
6. 社交扩展

在主循环未稳固前，不优先做重社交、重剧情、复杂活动系统。

---

## 3. 当前项目的产品判断基线

当前项目的真实定位不是完整正式版，而是：

> “治愈题材三消原型 + 基础花园循环雏形”

因此后续开发必须围绕以下核心问题推进：

- 玩家为什么要继续打一局？
- 局内奖励如何进入局外成长？
- 局外成长如何反哺下一局？
- “休息时刻”如何从文案变成规则？

如果某次开发无法回答这四个问题中的至少一个，优先级通常不应高于当前主线迭代。

---

## 4. 迭代文档使用规范

### 当前迭代执行方式

- 每个迭代必须有独立文档
- 迭代文档必须使用统一结构
- 结构模板来自 [docs/ITERATION_TEMPLATE.md](docs/ITERATION_TEMPLATE.md)

### 迭代文档必须包含的内容

- 迭代目标
- 服务的产品目标
- 本轮不做什么
- 功能项与目标映射
- 用户可感知结果
- 验收标准
- 自动化测试或手动验证方式
- 完成后如何评估

### 禁止行为

- 直接按“想法”开发，不补迭代文档
- 只写任务列表，不写目标映射
- 只写功能说明，不写验证标准
- 代码和文档明显不一致却不修正文档

---

## 5. 文档更新约定

发生以下情况时，必须同步更新文档：

- 新增或删减主循环能力
- 调整核心资源流
- 改变功能完成度判断
- 增加一个新的迭代主题

最少需要检查的文档：

- [README.md](README.md)
- [docs/STATUS_AND_ITERATION_PLAN.md](docs/STATUS_AND_ITERATION_PLAN.md)
- 当前迭代文档

---

## 6. 开发交付约定

每次交付建议按以下顺序执行：

1. 阅读目标文档
2. 识别本次改动对应的产品目标
3. 检查当前代码是否已部分实现
4. 先补文档或更新验收口径
5. 再做代码实现
6. 最后补测试与验证结论

如果是纯修 bug，也要说明：

- 这个 bug 影响哪段产品体验
- 修复后如何验证

---

## 7. 测试约定

新增功能时，优先补以下类型测试：

- 资源流测试
- 奖励唯一性测试
- 存档一致性测试
- 失败/续关/恢复流程测试
- 配置驱动行为测试

不接受只做 UI 表现、不验证数据结果的交付。

---

## 8. 对 Agent 的明确要求

Agent 在执行任务时，应尽量做到：

- 优先用最小改动实现最大产品增益
- 不新增与当前目标无关的系统复杂度
- 不把“未来可能需要”当成本轮必须实现
- 不把“文档写得好看”误当成“产品已经闭环”

如果发现需求与当前产品目标冲突，应明确指出，并优先保护主循环一致性。

---

## 9. 仓库当前默认工作方式

当前仓库采用：

- 文档驱动目标对齐
- CODEX 驱动实现
- 测试驱动验证

三者缺一不可。

完整交付前优先运行：

`./run_harness.sh`

该入口会检查文档发现性、迭代目标契约、手动验证覆盖、关卡奖励配置、核心服务注册，并运行自动化测试。Harness 规则详见 [docs/HARNESS_ENGINEERING.md](docs/HARNESS_ENGINEERING.md)。

本仓库还接入共享 coding-harness 基座（见 `harness.manifest.json`）：

- 漂移检查：`node ../coding-harness/bin/harness.mjs check --manifest harness.manifest.json`
- 重新合成：`node ../coding-harness/bin/harness.mjs sync --manifest harness.manifest.json`
- 本地回归入口 `./run_harness.sh` 会先运行漂移检查，再执行 Godot 检查与测试。

如果后续需要切换工作方式，应先更新本文件（`AGENTS.delta.md`），而不是生成物 `AGENTS.md`。

<!-- deliberate drift proof: remove after the run -->
