# 🌸 星光花园 (Starlight Garden)

一款通过短局花朵三消逐步唤醒花园角落的治愈系小游戏原型

## 🤖 AI辅助开发

本项目采用 **AI辅助开发** 模式，使用以下工具：

| 工具 | 用途 |
|------|------|
| **OpenCode** | 代码生成、bug修复 |
| **SearXNG** | 资料搜索、方案调研 |
| **人工审核** | 代码审查、质量把控 |

详见 [AI辅助开发规划](./docs/AI_DEVELOPMENT_PLAN.md)

## 📋 项目概述

- **游戏类型**: 休闲益智 - 花园修复三消
- **目标平台**: 微信/抖音小游戏方向验证；当前仅完成 Godot Web 原型
- **开发引擎**: Godot 4.x
- **导出方式**: HTML5 Web导出
- **开发方式**: AI辅助开发 (OpenCode + 人工审核)

## 🎮 核心玩法

1. **短局三消**: 7×7 网格、6 种花朵、交换消除与连锁。
2. **主题目标**: 前 5 关围绕唤醒具体花园角落，不只收集颜色。
3. **清风路径**: 三连清扫邻近落叶，四连沿横/竖方向吹过整条路径。
4. **每日风庭**: 每天同一座可复现落叶花庭，扫开晨露花苞触发十字连锁；今日花礼页可直接开始或重试。
5. **花园恢复**: 前三局持续呈现花园阶段变化，承接胜利和失败结果。
6. **照料对象**: 棋盘下方有一位具名花灵，消除会喂给它并得到即时回应，状态跨局留存。
7. **延后 Meta**: 合成、花语、每日、装饰、祝福和续关已有最小实现，但不作为首屏核心卖点。

## 📚 项目文档

| 文档 | 说明 |
|------|------|
| [当前产品与技术架构对齐审视](./docs/CURRENT_PRODUCT_AND_ARCHITECTURE.md) | 当前产品裁决、运行链路与技术债务 |
| [主题与玩法复盘](./docs/PRODUCT_THEME_AND_GAMEPLAY_REVIEW.md) | 目标用户、场景与玩法取舍 |
| [核心玩法根因审视与重设方向](./docs/CORE_LOOP_RETHINK.md) | 为什么当前机制没有乐趣与情绪价值，以及 A/B/C 三条重设方向 |
| [当前功能与迭代规划](./docs/STATUS_AND_ITERATION_PLAN.md) | 当前完成度与迭代规划 |
| [早期迭代 A-H](./docs/) | 历史目标对齐与验证清单（A/B/C/D/F/G/H） |
| [迭代I第4局后闭环重构](./docs/ITERATION_I_PRODUCT_LOOP_PLAN.md) | 关卡目标差异、花园可见结果、返回路径与渐进解锁的阶段计划 |
| [迭代J花园空间玩法收敛](./docs/ITERATION_J_GARDEN_SPATIAL_PLAY_PLAN.md) | 背景热点、花种选择、永久二选一装饰与试玩门槛 |
| [迭代K清风路径玩法验证](./docs/ITERATION_K_BREEZE_PATH_PLAN.md) | 落叶空间目标、方向四连与清风路径评估门槛 |
| [迭代L每日风庭玩法验证](./docs/ITERATION_L_DAILY_BREEZE_GARDEN_PLAN.md) | 晨露连锁、每日布局差异与可验证试玩门槛 |
| [迭代M核心手感减法与情感闭环](./docs/ITERATION_M_CORE_FEEL_PLAN.md) | 局内规则减法、消除→可见收获的即时反馈与情绪节奏 |
| [迭代N具名照料对象](./docs/ITERATION_N_COMPANION_CARE_PLAN.md) | 方向 A 最小切片：把消除变成照料一个具名对象，并在局内得到回应 |
| [迭代O A-real照料对象](./docs/ITERATION_O_A_REAL_COMPANION_PLAN.md) | 有需要 / 有自主 / 有取舍：它提出请求、按颜色喂食、时间推移与回访观察 |
| [迭代P单一闭环谜题版](./docs/ITERATION_P_SINGLE_LOOP_PUZZLE_PLAN.md) | 一局一个目标：清光全部落叶 + 紧张步数，移出所有并列系统 |
| [迭代模板](./docs/ITERATION_TEMPLATE.md) | 后续所有迭代统一使用的“目标-功能-验证-评估”模板 |
| [Harness 工程](./docs/HARNESS_ENGINEERING.md) | 目标、约束与验证入口 |
| [手动验证指引](./docs/MANUAL_VERIFICATION_GUIDE.md) | 逐项验证结算、花园、合成、星光用途、失败保底、清风路径与每日风庭 |
| [Image 2 素材提示词与接入清单](./docs/IMAGE2_ASSET_PROMPTS.md) | 当前版本素材生成提示词、命名规范、尺寸与落盘路径 |
| [游戏设计文档](./docs/GAME_DESIGN.md) | 游戏概念、玩法、系统设计 |
| [市场调研报告](./docs/MARKET_RESEARCH.md) | 市场分析、竞品研究 |
| [美术风格指南](./docs/ART_STYLE_GUIDE.md) | 色彩、元素、UI设计 |
| [开发计划](./docs/DEVELOPMENT_PLAN.md) | 历史版本规划与里程碑，仅作参考 |
| [AI辅助开发规划](./docs/AI_DEVELOPMENT_PLAN.md) | 历史 AI 工作流规划，仅作参考 |
| [代码规范](./docs/CODE_STANDARDS.md) | 编码标准、最佳实践 |
| [GDScript规则](./docs/GDSCRIPT_RULES.md) | Godot脚本开发规范 |
| [运行指南](./docs/RUN_GUIDE.md) | 环境配置、运行步骤 |

## 📁 项目结构

```
starlight-garden/
├── project.godot           # Godot项目配置
├── export_presets.cfg      # 导出配置
├── harness.manifest.json   # 门禁与治理契约
├── harness                 # coding-harness CLI
├── AGENTS.delta.md         # Agent 约定生成源（AGENTS.md 由它合成）
├── README.md               # 项目说明
│
├── docs/                   # 📚 文档目录
│   ├── STATUS_AND_ITERATION_PLAN.md
│   ├── CURRENT_PRODUCT_AND_ARCHITECTURE.md
│   ├── ITERATION_*_*.md    # 各迭代目标对齐与验证清单
│   ├── ITERATION_TEMPLATE.md
│   ├── MANUAL_VERIFICATION_GUIDE.md
│   ├── HARNESS_ENGINEERING.md
│   ├── GAME_DESIGN.md
│   └── postmortems/        # 事故复盘
│
├── scenes/                 # 场景文件
│   └── main.tscn           # 唯一入口场景
├── scripts/                # 脚本文件
│   ├── autoload/          # 自动加载单例
│   ├── core/              # 核心逻辑（Board）
│   ├── systems/           # 系统模块（LevelSystem / SceneManager）
│   ├── ui/                # UI与局内控制器
│   ├── tools/             # Harness 检查与工具
│   └── utils/             # 工具类
├── assets/                 # 资源文件
├── levels/                 # 关卡配置
└── tests/                  # 测试入口与 suites/
```

## 🚀 快速开始

### 环境要求

- Godot 4.3+
- 微信开发者工具（用于测试小游戏）

### 运行步骤

1. **打开项目**
   ```bash
   open -a Godot ~/workspace/starlight-garden
   ```

2. **运行游戏**
   - 在Godot编辑器中点击"播放"按钮
   - 或按 F5 运行

3. **导出Web版本**
   - 菜单: Project → Export
   - 选择"Web"预设
   - 输出到 `build/web/index.html`

详见 [运行指南](./docs/RUN_GUIDE.md)

### Harness 回归

后续迭代交付前，优先运行统一 Harness：

```bash
GODOT_BIN="/Users/jacklee/Downloads/Godot.app/Contents/MacOS/Godot" ./run_harness.sh
```

该入口会先做 coding-harness 漂移检查，再导入新增资源，然后检查文档、产品目标、关卡配置和核心服务注册，最后运行 Godot 自动化测试。详见 [Harness 工程](./docs/HARNESS_ENGINEERING.md)。

## 🎯 开发进度

### 当前版本状态

当前受管理版本：`0.1.0-pre.11`。版本历史见 [CHANGELOG.md](./CHANGELOG.md)，机器可读版本见 [VERSION](./VERSION)。

- [x] 核心消除玩法
- [x] 基础关卡系统（20关）
- [x] 基础花园种植/成长/收获
- [x] 花园合成系统（最小版）
- [x] 失败继续与“休息时刻”规则化基础流程
- [x] 星光第二用途（开局祝福 +3 步）
- [x] 通关奖励进入花园库存
- [x] 关卡奖励配置化
- [x] 花语碎片收集与花语日记最小版
- [x] 每日任务与今日花礼最小版
- [x] 花园装饰系统（最小版）
- [x] 新玩家入口渐进解锁与结算降噪
- [x] 花园恢复阶段反馈、具象角落变化与前三局体验减法
- [x] 前 5 关主题化目标与清风唤醒机制
- [x] 每日风庭与晨露连锁最小闭环
- [x] 新手引导
- [x] 基础UI界面
- [x] 进度保存
- [ ] 剧情系统
- [ ] 广告真实接入
- [ ] 微信生态/社交能力

当前版本更准确的定位是“治愈题材三消原型 + 基础花园循环雏形”。

建议优先阅读 [当前功能与迭代规划](./docs/STATUS_AND_ITERATION_PLAN.md)，再结合 [游戏设计文档](./docs/GAME_DESIGN.md) 理解产品目标。

## 📄 许可证

MIT License

---

**开发团队**: Starlight Garden Team
**开发方式**: AI辅助开发 🤖
