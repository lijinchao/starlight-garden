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
3. **清风唤醒**: 四连触发主题反馈并真实推进关卡目标。
4. **花园恢复**: 前三局持续呈现花园阶段变化，承接胜利和失败结果。
5. **延后 Meta**: 合成、花语、每日、装饰、祝福和续关已有最小实现，但不作为首屏核心卖点。

## 📚 项目文档

| 文档 | 说明 |
|------|------|
| [当前产品与技术架构对齐审视](./docs/CURRENT_PRODUCT_AND_ARCHITECTURE.md) | 当前产品裁决、唯一运行链路、技术债务和文档冲突处理依据 |
| [主题与玩法复盘](./docs/PRODUCT_THEME_AND_GAMEPLAY_REVIEW.md) | 目标用户、碎片场景、流行玩法取舍和下一迭代验证门槛 |
| [当前功能与迭代规划](./docs/STATUS_AND_ITERATION_PLAN.md) | 当前版本真实完成度、功能盘点、下一步策划与需求 |
| [迭代A目标对齐与验证清单](./docs/ITERATION_A_TASK_BREAKDOWN.md) | 闭合最小主循环的目标映射、验证标准、程序任务与评估口径 |
| [迭代B目标对齐与验证清单](./docs/ITERATION_B_TASK_BREAKDOWN.md) | 花语碎片、治愈日记与内容留存的目标映射和验证标准 |
| [迭代C目标对齐与验证清单](./docs/ITERATION_C_TASK_BREAKDOWN.md) | 每日任务、今日花礼与次日回访的目标映射和验证标准 |
| [迭代D目标对齐与验证清单](./docs/ITERATION_D_TASK_BREAKDOWN.md) | 花园装饰、星光消耗与氛围值的目标映射和验证标准 |
| [迭代F目标对齐与验证清单](./docs/ITERATION_F_TASK_BREAKDOWN.md) | 前三局体验减法、花园恢复反馈与平台化差异定位 |
| [迭代G目标对齐与验证清单](./docs/ITERATION_G_TASK_BREAKDOWN.md) | 局内爽感、清风唤醒与主题化目标验证 |
| [迭代H目标对齐与验证清单](./docs/ITERATION_H_TASK_BREAKDOWN.md) | 本地试玩证据采集、汇总工具与产品验证门槛 |
| [迭代模板](./docs/ITERATION_TEMPLATE.md) | 后续所有迭代统一使用的“目标-功能-验证-评估”模板 |
| [Harness 工程](./docs/HARNESS_ENGINEERING.md) | Agent 可读的目标、约束、验证入口与机械检查基线 |
| [手动验证指引](./docs/MANUAL_VERIFICATION_GUIDE.md) | 逐项验证结算、合成、星光用途、失败保底与连续失败鼓励 |
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

该入口会先导入新增资源，再检查文档、产品目标、关卡配置和核心服务注册，最后运行 Godot 自动化测试。详见 [Harness 工程](./docs/HARNESS_ENGINEERING.md)。

## 🎯 开发进度

### 当前版本状态

当前受管理版本：`0.1.0-pre.2`。版本历史见 [CHANGELOG.md](./CHANGELOG.md)，机器可读版本见 [VERSION](./VERSION)。

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
