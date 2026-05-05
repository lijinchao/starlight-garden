# 📋 星光花园 - 代码规范

## 命名规范

### 变量命名
```gdscript
# ✅ 正确
var player_name: String = "Player"
var max_health: int = 100
var is_game_over: bool = false

# ❌ 错误
var playerName: String = "Player"  # 驼峰命名（不推荐）
var MaxHealth: int = 100          # 首字母大写
```

### 函数命名
```gdscript
# ✅ 正确
func get_player_score() -> int:
func set_health(value: int) -> void:
func is_alive() -> bool:

# ❌ 错误
func GetPlayerScore():  # 驼峰命名
func setHealth():       # 驼峰命名
```

### 常量命名
```gdscript
# ✅ 正确
const MAX_PLAYERS: int = 4
const DEFAULT_SPEED: float = 100.0
const TILE_SIZE: int = 96

# ❌ 错误
const maxPlayers: int = 4    # 驼峰命名
const Tile_Size: int = 96    # 混合命名
```

### 信号命名
```gdscript
# ✅ 正确
signal player_died
signal score_changed(new_score: int)
signal level_completed(stars: int)

# ❌ 错误
signal PlayerDied          # 驼峰命名
signal on_player_died      # 前缀 on_
```

### 枚举命名
```gdscript
# ✅ 正确
enum TileType {
	NONE,
	RED_ROSE,
	BLUE_FORGET_ME_NOT
}

# ❌ 错误
enum tile_type {           # 小写
	None,                  # 首字母大写
	red_rose
}
```

---

## 代码格式

### 缩进
```gdscript
# ✅ 正确 - 使用Tab缩进
func example():
	if condition:
		do_something()

# ❌ 错误 - 使用空格
func example():
	if condition:
		do_something()
```

### 行长度
- 每行不超过 **100个字符**
- 超长行需要换行

```gdscript
# ✅ 正确
var result = very_long_function_name(
	parameter1,
	parameter2,
	parameter3
)

# ❌ 错误 - 一行太长
var result = very_long_function_name(parameter1, parameter2, parameter3, parameter4, parameter5)
```

### 空行
- 函数之间：**2行空行**
- 代码块之间：**1行空行**

```gdscript
# ✅ 正确
func first_function():
	pass


func second_function():
	pass
```

---

## 类型注解

### 必须添加类型注解
```gdscript
# ✅ 正确 - 明确的类型注解
var health: int = 100
var player_name: String = "Player"
var is_alive: bool = true

func calculate_damage(base: int, multiplier: float) -> int:
	return int(base * multiplier)

# ❌ 错误 - 缺少类型注解
var health = 100
var player_name = "Player"

func calculate_damage(base, multiplier):
	return int(base * multiplier)
```

### 未使用参数
```gdscript
# ✅ 正确 - 未使用参数以下划线开头
func _on_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	handle_event(event)

# ❌ 错误 - 未使用参数没有下划线前缀
func _on_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	handle_event(event)  # viewport 和 shape_idx 未使用
```

---

## 注释规范

### 文件头注释
```gdscript
## ClassName - 简短描述
## 详细描述（可选）
extends Node
```

### 函数注释
```gdscript
# 计算玩家伤害
# 参数：
#   base_damage: 基础伤害值
#   multiplier: 伤害倍率
# 返回：
#   最终伤害值
func calculate_damage(base_damage: int, multiplier: float) -> int:
	return int(base_damage * multiplier)
```

### 代码块注释
```gdscript
# ==================== 初始化 ====================
func _ready() -> void:
	pass

# ==================== 游戏逻辑 ====================
func update_game() -> void:
	pass
```

---

## 错误处理

### 空值检查
```gdscript
# ✅ 正确
func get_player() -> Player:
	if player == null:
		push_error("Player is null")
		return null
	return player

# ❌ 错误
func get_player() -> Player:
	return player  # 可能为null
```

### 数组边界检查
```gdscript
# ✅ 正确
func get_tile(index: int) -> Tile:
	if index < 0 or index >= tiles.size():
		push_error("Index out of bounds: %d" % index)
		return null
	return tiles[index]

# ❌ 错误
func get_tile(index: int) -> Tile:
	return tiles[index]  # 可能越界
```

### 字典键检查
```gdscript
# ✅ 正确
func get_value(key: String) -> Variant:
	if not data.has(key):
		push_error("Key not found: %s" % key)
		return null
	return data[key]

# ❌ 错误
func get_value(key: String) -> Variant:
	return data[key]  # 键可能不存在
```

---

## 信号规范

### 信号定义
```gdscript
# ✅ 正确 - 使用snake_case，描述性命名
signal health_changed(new_health: int)
signal player_died
signal level_completed(stars: int, score: int)

# ❌ 错误
signal HealthChanged          # 驼峰命名
signal onPlayerDied           # 前缀 on_
signal completed              # 不够描述性
```

### 信号连接
```gdscript
# ✅ 正确
player.health_changed.connect(_on_health_changed)
button.pressed.connect(_on_button_pressed)

# ❌ 错误
player.connect("health_changed", self, "_on_health_changed")  # 旧语法
```

---

## 性能优化

### 避免频繁创建对象
```gdscript
# ✅ 正确 - 复用对象
var temp_vector: Vector2 = Vector2.ZERO

func update():
	temp_vector.x = get_input_x()
	temp_vector.y = get_input_y()
	move(temp_vector)

# ❌ 错误 - 每帧创建新对象
func update():
	var temp_vector = Vector2(get_input_x(), get_input_y())
	move(temp_vector)
```

### 使用缓存
```gdscript
# ✅ 正确 - 缓存节点引用
@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	sprite.modulate = Color.RED

# ❌ 错误 - 每次访问都查找节点
func _ready():
	$Sprite2D.modulate = Color.RED
```

---

## 文件组织

### 目录结构
```
scripts/
├── autoload/          # 自动加载单例
├── core/             # 核心游戏逻辑
├── systems/          # 游戏系统
├── ui/               # 用户界面
├── utils/            # 工具类
└── tools/            # 开发工具
```

### 文件命名
- 使用 **PascalCase** 命名文件
- 文件名应与类名一致

```
# ✅ 正确
GameManager.gd
LevelSystem.gd
MainMenu.gd

# ❌ 错误
game_manager.gd
level-system.gd
mainmenu.gd
```

---

## 常见问题

### Q1: 什么时候使用 `class_name`？
- 当类需要被其他脚本引用时
- 当类是独立的功能模块时

### Q2: 什么时候使用 `@onready`？
- 当需要在 `_ready()` 之前获取节点引用时
- 当节点引用在多个函数中使用时

### Q3: 如何处理异步操作？
```gdscript
# 使用 await
func load_data():
	await get_tree().create_timer(1.0).timeout
	data_loaded.emit()
```

---

## 检查清单

提交代码前请检查：

- [ ] 所有变量有类型注解
- [ ] 未使用参数以下划线开头
- [ ] 函数有返回类型注解
- [ ] 数组访问有边界检查
- [ ] 字典访问有键检查
- [ ] 信号使用snake_case命名
- [ ] 文件头有注释说明
- [ ] 代码格式符合规范

---

**遵循规范，保持代码质量！** 📋
