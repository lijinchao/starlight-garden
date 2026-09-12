## VisualAssetCatalog - 集中管理可选位图素材及程序纹理回退入口
class_name VisualAssetCatalog

const GAME_BACKGROUND_SOFT := "res://assets/sprites/backgrounds/bg_puzzle_garden_soft.png"
const GAME_BACKGROUND_EARLY := "res://assets/sprites/backgrounds/bg_puzzle_garden_awaken_early.png"
const GARDEN_BACKGROUND_STAGE_1 := "res://assets/sprites/backgrounds/bg_garden_stage_1.png"
const GARDEN_BACKGROUND_STAGE_2 := "res://assets/sprites/backgrounds/bg_garden_stage_2.png"
const GARDEN_BACKGROUND_STAGE_3 := "res://assets/sprites/backgrounds/bg_garden_stage_3.png"
const BREEZE_TRAIL := "res://assets/sprites/vfx/fx_breeze_trail.png"
const BREEZE_BURST := "res://assets/sprites/vfx/fx_breeze_burst.png"

const TILE_TEXTURE_PATHS: Dictionary = {
	Constants.TileType.RED_ROSE: "res://assets/sprites/tiles/tile_red_rose.png",
	Constants.TileType.BLUE_FORGET_ME_NOT: "res://assets/sprites/tiles/tile_blue_forget_me_not.png",
	Constants.TileType.PURPLE_LAVENDER: "res://assets/sprites/tiles/tile_purple_lavender.png",
	Constants.TileType.YELLOW_SUNFLOWER: "res://assets/sprites/tiles/tile_yellow_sunflower.png",
	Constants.TileType.WHITE_JASMINE: "res://assets/sprites/tiles/tile_white_jasmine.png",
	Constants.TileType.PINK_CHERRY: "res://assets/sprites/tiles/tile_pink_cherry.png"
}

const DECORATION_TEXTURE_PATHS: Dictionary = {
	"bench": "res://assets/sprites/decorations/decor_bench.png",
	"lantern": "res://assets/sprites/decorations/decor_lantern.png",
	"fountain": "res://assets/sprites/decorations/decor_fountain.png",
	"hedge": "res://assets/sprites/decorations/decor_hedge.png"
}


static func get_game_background(level_id: int) -> Texture2D:
	return _load_texture(GAME_BACKGROUND_EARLY if level_id <= 3 else GAME_BACKGROUND_SOFT)


static func get_garden_background(restoration_stage: int) -> Texture2D:
	if restoration_stage <= 1:
		return _load_texture(GARDEN_BACKGROUND_STAGE_1)
	if restoration_stage == 2:
		return _load_texture(GARDEN_BACKGROUND_STAGE_2)
	return _load_texture(GARDEN_BACKGROUND_STAGE_3)


static func get_tile_texture(tile_type: int) -> Texture2D:
	var path = str(TILE_TEXTURE_PATHS.get(tile_type, ""))
	return _load_texture(path)


static func get_decoration_texture(decoration_id: String) -> Texture2D:
	var path = str(DECORATION_TEXTURE_PATHS.get(decoration_id, ""))
	return _load_texture(path)


static func get_breeze_trail_texture() -> Texture2D:
	return _load_texture(BREEZE_TRAIL)


static func get_breeze_burst_texture() -> Texture2D:
	return _load_texture(BREEZE_BURST)


static func _load_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
