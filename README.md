# 🌸 星光花园 (Starlight Garden)

一款治愈系女性向消除+合成休闲游戏

## 🤖 AI辅助开发

本项目采用 **AI辅助开发** 模式，使用以下工具：

| 工具 | 用途 |
|------|------|
| **OpenCode** | 代码生成、bug修复 |
| **SearXNG** | 资料搜索、方案调研 |
| **人工审核** | 代码审查、质量把控 |

详见 [AI辅助开发规划](./docs/AI_DEVELOPMENT_PLAN.md)

## 📋 项目概述

- **游戏类型**: 休闲益智 - 消除+合成
- **目标平台**: 微信小游戏
- **开发引擎**: Godot 4.x
- **导出方式**: HTML5 Web导出
- **开发方式**: AI辅助开发 (OpenCode + 人工审核)

## 🎮 核心玩法

1. **消除系统**: 7×7网格，6种花朵元素，3连及以上消除
2. **关卡系统**: 20个关卡配置，当前以收集目标为主
3. **花园系统**: 通关获得花种，种植、成长并收获星光
4. **局外循环**: 星光可用于失败续关、开局祝福，形成基础成长反哺
5. **花园成长**: 支持配置化奖励、3级内合成、连续失败鼓励
6. **花语收集**: 通关与失败都会推进花语碎片，解锁后可在花语日记回看
7. **每日回访**: 今日花礼提供每日任务与轻量奖励
8. **花园装饰**: 星光可购买固定装饰并提升花园氛围值

## 📚 项目文档

| 文档 | 说明 |
|------|------|
| [当前功能与迭代规划](./docs/STATUS_AND_ITERATION_PLAN.md) | 当前版本真实完成度、功能盘点、下一步策划与需求 |
| [迭代A目标对齐与验证清单](./docs/ITERATION_A_TASK_BREAKDOWN.md) | 闭合最小主循环的目标映射、验证标准、程序任务与评估口径 |
| [迭代B目标对齐与验证清单](./docs/ITERATION_B_TASK_BREAKDOWN.md) | 花语碎片、治愈日记与内容留存的目标映射和验证标准 |
| [迭代C目标对齐与验证清单](./docs/ITERATION_C_TASK_BREAKDOWN.md) | 每日任务、今日花礼与次日回访的目标映射和验证标准 |
| [迭代D目标对齐与验证清单](./docs/ITERATION_D_TASK_BREAKDOWN.md) | 花园装饰、星光消耗与氛围值的目标映射和验证标准 |
| [迭代模板](./docs/ITERATION_TEMPLATE.md) | 后续所有迭代统一使用的“目标-功能-验证-评估”模板 |
| [Harness 工程](./docs/HARNESS_ENGINEERING.md) | Agent 可读的目标、约束、验证入口与机械检查基线 |
| [手动验证指引](./docs/MANUAL_VERIFICATION_GUIDE.md) | 逐项验证结算、合成、星光用途、失败保底与连续失败鼓励 |
| [游戏设计文档](./docs/GAME_DESIGN.md) | 游戏概念、玩法、系统设计 |
| [市场调研报告](./docs/MARKET_RESEARCH.md) | 市场分析、竞品研究 |
| [美术风格指南](./docs/ART_STYLE_GUIDE.md) | 色彩、元素、UI设计 |
| [开发计划](./docs/DEVELOPMENT_PLAN.md) | 版本规划、里程碑 |
| [AI辅助开发规划](./docs/AI_DEVELOPMENT_PLAN.md) | AI工具使用、工作流程 |
| [代码规范](./docs/CODE_STANDARDS.md) | 编码标准、最佳实践 |
| [GDScript规则](./docs/GDSCRIPT_RULES.md) | Godot脚本开发规范 |
| [运行指南](./docs/RUN_GUIDE.md) | 环境配置、运行步骤 |

## 📁 项目结构

```
starlight-garden/
├── project.godot           # Godot项目配置
├── export_presets.cfg      # 导出配置
├── README.md               # 项目说明
│
├── docs/                   # 📚 文档目录
│   ├── AI_DEVELOPMENT_PLAN.md
│   ├── STATUS_AND_ITERATION_PLAN.md
│   ├── ITERATION_A_TASK_BREAKDOWN.md
│   ├── ITERATION_TEMPLATE.md
│   ├── MANUAL_VERIFICATION_GUIDE.md
│   ├── GAME_DESIGN.md
│   ├── MARKET_RESEARCH.md
│   ├── ART_STYLE_GUIDE.md
│   ├── DEVELOPMENT_PLAN.md
│   ├── CODE_STANDARDS.md
│   ├── GDSCRIPT_RULES.md
│   └── RUN_GUIDE.md
│
├── scenes/                 # 场景文件
│   ├── main.tscn
│   └── game/
├── scripts/                # 脚本文件
│   ├── autoload/          # 自动加载单例
│   ├── core/              # 核心逻辑
│   ├── systems/           # 系统模块
│   ├── ui/                # UI脚本
│   └── utils/             # 工具类
├── assets/                 # 资源文件
├── levels/                 # 关卡配置
└── tests/                  # 测试文件
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

该入口会先检查文档、产品目标、关卡配置和核心服务注册，再运行 Godot 自动化测试。详见 [Harness 工程](./docs/HARNESS_ENGINEERING.md)。

## 🎯 开发进度

### 当前版本状态

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
- [x] 新手引导
- [x] 基础UI界面
- [x] 进度保存
- [x] 花语收集系统（最小版）
- [x] 治愈日记系统（最小版）
- [x] 每日回访系统（最小版）
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
