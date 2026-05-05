## UITheme - UI主题配置
class_name UITheme

# ==================== 颜色定义 ====================
# 主色调 - 马卡龙色系
const COLOR_PRIMARY = Color("#FFB6C1")      # 浅粉
const COLOR_SECONDARY = Color("#DDA0DD")    # 梅红
const COLOR_ACCENT = Color("#87CEEB")       # 天蓝

# 背景色
const COLOR_BG_LIGHT = Color("#FFF5F8")     # 浅粉背景
const COLOR_BG_GARDEN = Color("#E8F5E9")    # 浅绿背景
const COLOR_BG_GAME = Color("#F3E5F5")      # 浅紫背景

# 文字色
const COLOR_TEXT_PRIMARY = Color("#2D3436")   # 深灰
const COLOR_TEXT_SECONDARY = Color("#636E72") # 中灰
const COLOR_TEXT_LIGHT = Color("#B2BEC3")     # 浅灰

# 状态色
const COLOR_SUCCESS = Color("#00B894")      # 成功绿
const COLOR_WARNING = Color("#FDCB6E")      # 警告黄
const COLOR_ERROR = Color("#FF7675")        # 错误红
const COLOR_INFO = Color("#74B9FF")         # 信息蓝

# ==================== 字体大小 ====================
const FONT_SIZE_TITLE = 48
const FONT_SIZE_SUBTITLE = 32
const FONT_SIZE_BODY = 22
const FONT_SIZE_SMALL = 18
const FONT_SIZE_TINY = 14

# ==================== 间距 ====================
const SPACING_SMALL = 10
const SPACING_MEDIUM = 20
const SPACING_LARGE = 30
const SPACING_XLARGE = 50

# ==================== 圆角 ====================
const BORDER_RADIUS_SMALL = 8
const BORDER_RADIUS_MEDIUM = 16
const BORDER_RADIUS_LARGE = 24
const BORDER_RADIUS_ROUND = 999

# ==================== 阴影 ====================
const SHADOW_SMALL = {
	"offset": Vector2(0, 2),
	"color": Color(0, 0, 0, 0.1),
	"radius": 4
}

const SHADOW_MEDIUM = {
	"offset": Vector2(0, 4),
	"color": Color(0, 0, 0, 0.15),
	"radius": 8
}

const SHADOW_LARGE = {
	"offset": Vector2(0, 8),
	"color": Color(0, 0, 0, 0.2),
	"radius": 16
}

# ==================== 按钮样式 ====================
static func create_button_style(bg_color: Color = COLOR_PRIMARY, _text_color: Color = COLOR_TEXT_PRIMARY) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = BORDER_RADIUS_MEDIUM
	style.corner_radius_top_right = BORDER_RADIUS_MEDIUM
	style.corner_radius_bottom_left = BORDER_RADIUS_MEDIUM
	style.corner_radius_bottom_right = BORDER_RADIUS_MEDIUM
	style.content_margin_left = SPACING_MEDIUM
	style.content_margin_right = SPACING_MEDIUM
	style.content_margin_top = SPACING_SMALL
	style.content_margin_bottom = SPACING_SMALL
	return style

static func create_button_hover_style(bg_color: Color = COLOR_SECONDARY) -> StyleBoxFlat:
	var style = create_button_style(bg_color)
	style.bg_color = bg_color.lightened(0.1)
	return style

static func create_button_pressed_style(bg_color: Color = COLOR_SECONDARY) -> StyleBoxFlat:
	var style = create_button_style(bg_color)
	style.bg_color = bg_color.darkened(0.1)
	return style

# ==================== 面板样式 ====================
static func create_panel_style(bg_color: Color = Color.WHITE, alpha: float = 0.9) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.bg_color.a = alpha
	style.corner_radius_top_left = BORDER_RADIUS_LARGE
	style.corner_radius_top_right = BORDER_RADIUS_LARGE
	style.corner_radius_bottom_left = BORDER_RADIUS_LARGE
	style.corner_radius_bottom_right = BORDER_RADIUS_LARGE
	style.content_margin_left = SPACING_LARGE
	style.content_margin_right = SPACING_LARGE
	style.content_margin_top = SPACING_LARGE
	style.content_margin_bottom = SPACING_LARGE
	style.shadow_color = SHADOW_MEDIUM["color"]
	style.shadow_size = SHADOW_MEDIUM["radius"]
	return style

# ==================== 输入框样式 ====================
static func create_line_edit_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.border_color = COLOR_PRIMARY
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = BORDER_RADIUS_SMALL
	style.corner_radius_top_right = BORDER_RADIUS_SMALL
	style.corner_radius_bottom_left = BORDER_RADIUS_SMALL
	style.corner_radius_bottom_right = BORDER_RADIUS_SMALL
	style.content_margin_left = SPACING_MEDIUM
	style.content_margin_right = SPACING_MEDIUM
	style.content_margin_top = SPACING_SMALL
	style.content_margin_bottom = SPACING_SMALL
	return style

# ==================== 进度条样式 ====================
static func create_progress_bar_style(_fill_color: Color = COLOR_SUCCESS) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_BG_LIGHT
	style.corner_radius_top_left = BORDER_RADIUS_ROUND
	style.corner_radius_top_right = BORDER_RADIUS_ROUND
	style.corner_radius_bottom_left = BORDER_RADIUS_ROUND
	style.corner_radius_bottom_right = BORDER_RADIUS_ROUND
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style

# ==================== 工具方法 ====================
static func apply_button_style(button: Button, bg_color: Color = COLOR_PRIMARY) -> void:
	button.add_theme_stylebox_override("normal", create_button_style(bg_color))
	button.add_theme_stylebox_override("hover", create_button_hover_style(bg_color))
	button.add_theme_stylebox_override("pressed", create_button_pressed_style(bg_color))
	button.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)

static func apply_label_style(label: Label, font_size: int = FONT_SIZE_BODY, color: Color = COLOR_TEXT_PRIMARY) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
