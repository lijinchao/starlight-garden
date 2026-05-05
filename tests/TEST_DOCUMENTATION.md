# 🧪 星光花园 - 测试文档

## 测试策略

### 1. 单元测试
测试独立的函数和类，确保核心逻辑正确。

### 2. 集成测试
测试多个组件协同工作。

### 3. 功能测试
测试完整的游戏流程。

---

## 测试覆盖范围

### 核心系统测试

#### ✅ Constants（常量）
- [x] 网格尺寸正确
- [x] 元素类型定义完整
- [x] 颜色映射正确
- [x] 动画时长合理

#### ✅ Board（棋盘逻辑）
- [x] 网格初始化正确
- [x] 位置验证准确
- [x] 相邻判断正确
- [x] 交换逻辑正确
- [x] 匹配检测准确
- [x] 连锁处理正确
- [x] 下落填充正确

#### ✅ LevelSystem（关卡系统）
- [x] 关卡配置加载
- [x] 难度曲线合理
- [x] 胜利条件检查
- [x] 失败条件检查
- [x] 星级计算正确

#### ✅ SaveManager（存档系统）
- [x] 数据保存成功
- [x] 数据加载正确
- [x] 默认数据生成
- [x] 数据重置功能
- [x] 花语碎片与解锁数据结构

#### ✅ GameManager（游戏管理器）
- [x] 状态切换正确
- [x] 信号发射正确
- [x] 关卡流程完整

#### ✅ FlowerLanguageService（花语系统）
- [x] 胜利结算发放花语碎片
- [x] 首通额外碎片只发放一次
- [x] 失败保底发放花语碎片
- [x] 5 个碎片自动解锁花语
- [x] 花语日记展示 6 种基础花

#### ✅ DailyService（每日系统）
- [x] 默认每日任务数据
- [x] 日期变化刷新任务
- [x] 胜利/失败推进完成任意 1 局任务
- [x] 花园收获推进收获任务
- [x] 花语碎片推进碎片任务
- [x] 今日花礼领取与防重复领取

#### ✅ DecorationService（花园装饰系统）
- [x] 装饰目录存在且至少 4 个装饰
- [x] 默认氛围值为 0
- [x] 星光不足时购买失败且不写入存档
- [x] 星光足够时购买成功并扣费
- [x] 重复购买失败且不重复扣费
- [x] 展示数据包含氛围值与当前星光

---

## 运行测试

### 推荐：运行完整 Harness
```bash
GODOT_BIN="/Users/jacklee/Downloads/Godot.app/Contents/MacOS/Godot" ./run_harness.sh
```

完整 Harness 会先检查产品目标、文档入口、关卡配置和核心服务注册，再运行下方 Godot 自动化测试。

### 方法1：使用测试脚本
```bash
~/workspace/starlight-garden/run_tests.sh
```

### 方法2：在Godot中运行
1. 打开Godot
2. 运行 `tests/test_scene.tscn`
3. 查看控制台输出

### 方法3：使用Godot命令行
```bash
godot --headless --path ~/workspace/starlight-garden -s "tests/test_scene.tscn"
```

---

## 测试用例详情

### 棋盘逻辑测试

```gdscript
func test_board_logic() -> void:
    # 测试网格初始化
    assert_equal(board.grid.size(), 7, "网格行数正确")
    
    # 测试位置有效性
    assert_true(board._is_valid_position(Vector2i(0, 0)), "位置(0,0)有效")
    assert_true(not board._is_valid_position(Vector2i(-1, 0)), "位置(-1,0)无效")
    
    # 测试相邻判断（使用公开接口）
    assert_true(board.is_adjacent(Vector2i(3, 3), Vector2i(3, 4)), "水平相邻")
    assert_true(not board.is_adjacent(Vector2i(3, 3), Vector2i(4, 4)), "不相邻(对角)")
```

### 匹配检测测试

```gdscript
func test_match_detection() -> void:
    # 设置水平3连
    board.grid[0][0] = TileType.RED_ROSE
    board.grid[0][1] = TileType.RED_ROSE
    board.grid[0][2] = TileType.RED_ROSE
    
    var matches = board.find_all_matches()
    assert_true(matches.size() > 0, "检测到水平匹配")
```

### 关卡系统测试

```gdscript
func test_level_system() -> void:
    # 测试关卡配置
    var config = level_system.get_level_config(1)
    assert_true(config.has("moves"), "关卡配置包含步数")
    
    # 测试难度递增
    var config_1 = level_system.get_level_config(1)
    var config_10 = level_system.get_level_config(10)
    assert_true(config_1["moves"] >= config_10["moves"], "高关卡步数更少")
```

---

## 测试结果格式

```
=====================================
   星光花园 - 测试套件
=====================================

📦 测试套件: Constants
  ✅ PASS: 网格行数应为7
  ✅ PASS: 网格列数应为7
  ✅ PASS: 最小匹配数应为3

📦 测试套件: Board Logic
  ✅ PASS: 网格行数正确
  ✅ PASS: 位置(0,0)有效
  ✅ PASS: 水平相邻

=====================================
   测试结果汇总
=====================================
总计: 15
通过: 15 ✅
失败: 0 ❌
=====================================
```

---

## 持续集成

### 添加新的测试用例

1. 在 `tests/TestRunner.gd` 中添加测试函数
2. 在 `run_all_tests()` 中调用新测试
3. 使用断言方法验证结果

### 断言方法

```gdscript
# 真值断言
assert_true(condition, message)

# 相等断言
assert_equal(actual, expected, message)

# 不等断言
assert_not_equal(actual, expected, message)

# 大于断言
assert_greater(actual, threshold, message)
```

---

## 测试最佳实践

1. **每个功能一个测试**：保持测试独立性
2. **清晰的测试名称**：描述测试的内容
3. **边界条件测试**：测试极限情况
4. **错误处理测试**：测试异常情况
5. **定期运行测试**：每次修改后运行

---

**测试是质量的保证！** 🧪
