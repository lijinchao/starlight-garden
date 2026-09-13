# Postmortem — 绿色 CI 掩盖了 SCRIPT ERROR

Date: 2026-09-12
Owner: @lijinchao

## Impact

在升级到 `base@0.1.10` 之前，CI 的 `godot` 门禁一直是绿的，但日志里始终有 `SCRIPT ERROR: Parse Error: Preload file "res://assets/audio/soft_garden_loop.wav" has no resource loaders`，并连带 `AudioManager` autoload 编译失败。也就是说：CI 通过并不代表音频系统真的能加载，回归信号是假的。

## Detection

门禁开始声明 `expect.forbid` 后，首次运行即失败并打印 `fail godot (forbidden output: SCRIPT ERROR:)`。此前没有任何检查读取输出，只看退出码。

## Timeline

- 之前 — Godot 门禁加入，只按退出码判定。
- `0.1.10` — 门禁声明 `expect: { forbid: ["SCRIPT ERROR:"] }`；首次运行暴露错误输出。
- 同日 — `AudioManager.gd` 改为运行时 `load()`，编辑器导入阶段不再 `preload` 尚未导入的音频。

## Root cause

`run_harness.sh` 的编辑器导入步骤即使 autoload 解析失败也返回退出码 0；退出码被当成"干净运行"的唯一证据。缺的是检查，不是修复。

## Response

框架侧把"退出码为零但打印错误"变成失败（`expect.forbid` 与 `requireOutputAssertions`）；本仓库给 `godot` 门禁声明 `SCRIPT ERROR:`，并修掉真正的产品缺陷（autoload 在音频导入前 `preload`）。

## Regression test

Regression: godot

## Action items

- [x] `godot` 门禁声明 `SCRIPT ERROR:` 输出断言 — @lijinchao, 0.1.10
- [x] `AudioManager` 改为运行时加载 BGM — @lijinchao, 0.1.10
