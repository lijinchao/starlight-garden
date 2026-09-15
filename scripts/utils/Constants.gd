## Constants - 游戏常量定义
class_name Constants

# ==================== 网格配置 ====================
const GRID_ROWS: int = 7
const GRID_COLS: int = 7
const TILE_SIZE: int = 96
const TILE_GAP: int = 4

# ==================== 元素类型 ====================
enum TileType {
	NONE = 0,
	RED_ROSE = 1,           # 红玫瑰 - 热情
	BLUE_FORGET_ME_NOT = 2, # 蓝勿忘我 - 思念
	PURPLE_LAVENDER = 3,    # 紫薰衣草 - 宁静
	YELLOW_SUNFLOWER = 4,   # 黄向日葵 - 阳光
	WHITE_JASMINE = 5,      # 白茉莉 - 纯真
	PINK_CHERRY = 6,        # 粉樱花 - 浪漫
	BOMB = 7,               # 星光炸弹
	RAINBOW = 8,            # 彩虹花
	BLOCKER = 9             # 不可移动石块
}

# 元素颜色（用于程序化生成）
const TILE_COLORS: Dictionary = {
	TileType.RED_ROSE: Color("#FF6B6B"),
	TileType.BLUE_FORGET_ME_NOT: Color("#74B9FF"),
	TileType.PURPLE_LAVENDER: Color("#A29BFE"),
	TileType.YELLOW_SUNFLOWER: Color("#FDCB6E"),
	TileType.WHITE_JASMINE: Color("#DFE6E9"),
	TileType.PINK_CHERRY: Color("#FD79A8"),
	TileType.BOMB: Color("#2D3436"),
	TileType.RAINBOW: Color("#FFEAA7")
}

# 元素名称
const TILE_NAMES: Dictionary = {
	TileType.RED_ROSE: "红玫瑰",
	TileType.BLUE_FORGET_ME_NOT: "蓝勿忘我",
	TileType.PURPLE_LAVENDER: "紫薰衣草",
	TileType.YELLOW_SUNFLOWER: "黄向日葵",
	TileType.WHITE_JASMINE: "白茉莉",
	TileType.PINK_CHERRY: "粉樱花"
}

# 花语
const TILE_LANGUAGES: Dictionary = {
	TileType.RED_ROSE: "热烈的爱，永不褪色",
	TileType.BLUE_FORGET_ME_NOT: "请记得，我一直在",
	TileType.PURPLE_LAVENDER: "等待也是一种浪漫",
	TileType.YELLOW_SUNFLOWER: "向着光，就不会有阴影",
	TileType.WHITE_JASMINE: "纯洁的心，最珍贵",
	TileType.PINK_CHERRY: "短暂的美，值得珍惜"
}

# ==================== 游戏配置 ====================
const MIN_MATCH_COUNT: int = 3
const BASE_SCORE_PER_TILE: int = 10
const COMBO_MULTIPLIER: float = 1.5
const MAX_MOVES_DEFAULT: int = 30

# ==================== 动画配置 ====================
const SWAP_DURATION: float = 0.2
const FALL_DURATION: float = 0.15
const MATCH_DURATION: float = 0.3
const CHAIN_DELAY: float = 0.1

# ==================== 花园配置 ====================
const MAX_FLOWER_LEVEL: int = 5
const GARDEN_SLOTS: int = 4
const SYNTHESIS_TIME: float = 5.0  # 合成时间（秒）
const FLOWER_GROWTH_DURATION: float = 30.0

# ==================== 关卡类型 ====================
enum LevelType {
	COLLECT,    # 收集指定数量
	SCORE,      # 达到目标分数
	TIMED,      # 限时挑战
	SPECIAL     # 特殊目标
}
