# 🚀 星光花园 - 快速开始指南

## 项目概览

**星光花园**是一款治愈系女性向消除+合成休闲游戏，基于Godot 4.x开发。

---

## 环境要求

- **Godot Engine**: 4.3 或更高版本
- **操作系统**: macOS / Windows / Linux
- **微信开发者工具**: 用于测试小程序版本（可选）

---

## 快速开始

### 1. 打开项目

```bash
# 方法1：使用启动脚本
~/workspace/starlight-garden/start.sh

# 方法2：直接打开
open -a Godot ~/workspace/starlight-garden/project.godot
```

### 2. 运行游戏

在Godot中：
1. 点击右上角 ▶️ 播放按钮
2. 或按 `F5` 运行
3. 或按 `F6` 运行当前场景

### 3. 运行测试

```bash
# 方法1：使用测试脚本
~/workspace/starlight-garden/run_tests.sh

# 方法2：在Godot中
打开 tests/test_scene.tscn 并运行
```

---

## 项目结构

```
starlight-garden/
├── project.godot              # Godot项目配置
├── export_presets.cfg         # Web导出配置
├── start.sh                   # 启动脚本
├── run_tests.sh              # 测试脚本
│
├── scripts/
│   ├── autoload/             # 自动加载单例
│   │   ├── GameManager.gd    # 游戏管理器
│   │   ├── AudioManager.gd   # 音频管理器
│   │   ├── SaveManager.gd    # 存档管理器
│   │   └── TutorialManager.gd # 引导管理器
│   │
│   ├── core/                 # 核心逻辑
│   │   └── Board.gd          # 消除棋盘
│   │
│   ├── systems/              # 系统模块
│   │   ├── LevelSystem.gd    # 关卡系统
│   │   ├── SceneManager.gd   # 场景管理器
│   │   └── TutorialSystem.gd # 新手引导
│   │
│   ├── ui/                   # UI脚本
│   │   ├── MainMenu.gd       # 主菜单
│   │   ├── GameHUD.gd        # 游戏HUD
│   │   ├── GardenUI.gd       # 花园界面
│   │   ├── SettingsUI.gd     # 设置界面
│   │   ├── PopupManager.gd   # 弹窗管理
│   │   ├── BoardVisual.gd    # 棋盘可视化
│   │   ├── Tile.gd           # 元素节点
│   │   └── TileVisual.gd     # 元素可视化
│   │
│   └── utils/                # 工具类
│       ├── Constants.gd      # 常量定义
│       ├── UITheme.gd        # UI主题
│       └── SpriteGenerator.gd # 精灵生成器
│
├── scenes/
│   ├── main.tscn             # 主场景
│   └── game/
│       ├── game.tscn         # 游戏场景
│       └── game_complete.tscn # 完整游戏场景
│
├── tests/
│   ├── TestRunner.gd         # 测试运行器
│   ├── test_scene.tscn       # 测试场景
│   └── TEST_DOCUMENTATION.md # 测试文档
│
├── levels/
│   ├── level_001.json        # 关卡1
│   ├── level_002.json        # 关卡2
│   └── level_003.json        # 关卡3
│
└── assets/                   # 资源文件（待添加）
	├── sprites/
	├── audio/
	├── fonts/
	└── data/
```

---

## 核心功能

### ✅ 已完成

1. **消除系统**
   - 7×7网格，6种花朵元素
   - 3连及以上消除
   - 连锁消除检测
   - 下落填充动画

2. **关卡系统**
   - 程序化关卡生成
   - 难度曲线
   - 胜利/失败判定
   - 星级评分

3. **UI界面**
   - 主菜单
   - 游戏HUD
   - 花园界面
   - 设置界面
   - 弹窗系统

4. **新手引导**
   - 分步引导
   - 可跳过
   - 状态保存

5. **美术资源**
   - 程序化花朵生成
   - 6种花朵样式
   - 动画效果

6. **测试框架**
   - 单元测试
   - 集成测试
   - 测试运行器

---

## 开发计划

### Phase 1: MVP（当前）
- [x] 核心消除玩法
- [x] UI界面系统
- [x] 新手引导
- [x] 程序化美术
- [x] 测试框架

### Phase 2: 内容扩展
- [ ] 更多关卡（20关）
- [ ] 音效和音乐
- [ ] 花语系统
- [ ] 花园装饰

### Phase 3: 社交功能
- [ ] 好友系统
- [ ] 排行榜
- [ ] 赛季系统

---

## 导出为微信小游戏

### 1. 导出Web版本

在Godot中：
1. `Project` → `Export`
2. 选择 `Web` 预设
3. 点击 `Export Project`
4. 保存到 `build/web/index.html`

### 2. 测试微信小游戏

1. 打开微信开发者工具
2. 导入项目 → 选择 `build/web` 目录
3. 配置 `game.json`
4. 预览运行

### 3. 微信小游戏配置

```json
{
  "deviceOrientation": "portrait",
  "showStatusBar": false
}
```

---

## 常见问题

### Q: 如何修改网格大小？
A: 编辑 `scripts/utils/Constants.gd` 中的 `GRID_ROWS` 和 `GRID_COLS`

### Q: 如何添加新元素？
A: 
1. 在 `Constants.TileType` 枚举中添加新类型
2. 在 `Constants.TILE_COLORS` 中添加颜色
3. 在 `SpriteGenerator.gd` 中添加绘制函数

### Q: 如何添加新关卡？
A: 
1. 在 `levels/` 目录创建新的JSON文件
2. 按照 `level_001.json` 格式编写

### Q: 如何运行测试？
A: 运行 `~/workspace/starlight-garden/run_tests.sh`

---

## 联系方式

- **项目目录**: `/Users/jacklee/workspace/starlight-garden`
- **文档**: README.md, tests/TEST_DOCUMENTATION.md

---

**祝开发愉快！** 🌸
