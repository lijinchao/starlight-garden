# 📋 星光花园 - GDScript 开发规则

## 🚨 必须遵守的规则

### 1. 变量命名规则

#### ❌ 禁止使用的变量名（会遮蔽基类属性）
```gdscript
# 这些变量名会与 Node 基类冲突
var name: String        # ❌ 遮蔽 Node.name
var title: String       # ❌ 遮蔽 Window.title
var text: String        # ❌ 遮蔽 Label.text
var position: Vector2   # ❌ 遮蔽 Node2D.position
var rotation: float     # ❌ 遮蔽 Node2D.rotation
var scale: Vector2      # ❌ 遮蔽 Node2D.scale
var visible: bool       # ❌ 遮蔽 CanvasItem.visible
```

#### ✅ 推荐的替代命名
```gdscript
# 使用更具描述性的名称
var player_name: String
var window_title: String
var label_text: String
var node_position: Vector2
var node_rotation: float
var node_scale: Vector2
var is_visible: bool
```

### 2. 未使用参数规则

#### ❌ 错误示例
```gdscript
func _on_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	handle_event(event)  # viewport 和 shape_idx 未使用
```

#### ✅ 正确示例
```gdscript
func _on_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	handle_event(event)  # 以下划线标记未使用参数
```

### 3. 整数除法规则

#### ❌ 错误示例
```gdscript
var center_x = size / 2      # 整数除法，小数部分被丢弃
var center_y = size / 2
```

#### ✅ 正确示例
```gdscript
var center_x = int(size / 2.0)  # 浮点数除法后转整数
var center_y = int(size / 2.0)
# 或者使用
var center_x = size >> 1        # 位运算（仅适用于2的幂次）
```

### 4. 数组边界检查规则

#### ❌ 错误示例
```gdscript
var value = array[0]  # 可能越界
```

#### ✅ 正确示例
```gdscript
if array.size() > 0:
	var value = array[0]
else:
	push_error("Array is empty")
```

### 5. 节点引用规则

#### ❌ 错误示例
```gdscript
var icon = slot.get_node("PotIcon")  # 可能返回 null
icon.text = "🌸"  # 如果 icon 为 null 会报错
```

#### ✅ 正确示例
```gdscript
var icon = slot.get_node_or_null("PotIcon")
if icon:
	icon.text = "🌸"
```

---

## 📝 代码质量检查清单

### 提交前必须检查
- [ ] 所有变量名不与基类属性冲突
- [ ] 未使用的参数以下划线开头
- [ ] 整数除法使用浮点数或显式转换
- [ ] 数组访问有边界检查
- [ ] 节点引用使用 `get_node_or_null()`
- [ ] 函数有返回类型注解
- [ ] 变量有类型注解

### 命名规范
- 变量：`snake_case`（如 `player_name`）
- 函数：`snake_case`（如 `get_player_score()`）
- 常量：`UPPER_SNAKE_CASE`（如 `MAX_PLAYERS`）
- 信号：`snake_case`（如 `health_changed`）
- 枚举：`PascalCase`（如 `TileType`）

---

## 🔧 常见警告及修复

### 警告1：未使用参数
```
The parameter "xxx" is never used
```
**修复**：在参数名前加下划线 `_xxx`

### 警告2：变量遮蔽
```
The local variable "xxx" is shadowing an already-declared property
```
**修复**：使用更具描述性的名称，如 `player_name` 而不是 `name`

### 警告3：整数除法
```
Integer division. Decimal part will be discarded
```
**修复**：使用 `int(x / 2.0)` 或 `x / 2.0`

### 警告4：未使用变量
```
The local variable "xxx" is declared but never used
```
**修复**：在变量名前加下划线 `_xxx` 或删除该变量

### 错误5：节点未找到
```
Node not found: "xxx"
```
**修复**：使用 `get_node_or_null()` 并添加空值检查

### 错误6：数组越界
```
Out of bounds get index 'x' (on base: 'Array')
```
**修复**：在访问数组前检查 `array.size() > x`

---

## 🎯 最佳实践

### 1. 防御性编程
```gdscript
# 总是检查可能为 null 的值
var node = get_node_or_null("SomeNode")
if node:
	node.do_something()

# 总是检查数组边界
if index >= 0 and index < array.size():
	var value = array[index]
```

### 2. 类型安全
```gdscript
# 明确的类型注解
var health: int = 100
var player_name: String = "Player"
var is_alive: bool = true

# 函数返回类型
func get_health() -> int:
	return health
```

### 3. 信号连接
```gdscript
# 使用新语法
button.pressed.connect(_on_button_pressed)

# 而不是旧语法
button.connect("pressed", self, "_on_button_pressed")
```

---

## 📊 警告统计

| 警告类型 | 数量 | 状态 |
|---------|------|------|
| 未使用参数 | 23 | ✅ 已修复 |
| 变量遮蔽 | 4 | ✅ 已修复 |
| 整数除法 | 18 | ✅ 已修复 |
| 未使用变量 | 1 | ✅ 已修复 |
| 节点引用 | 3 | ✅ 已修复 |
| 数组越界 | 2 | ✅ 已修复 |

---

**遵循规则，保持代码质量！** 📋
