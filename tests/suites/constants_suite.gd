## Constants suite
extends "res://tests/suites/test_suite.gd"


func test_constants() -> void:
	assert_true(Constants.GRID_ROWS == 7, "网格行数应为7")
	assert_true(Constants.GRID_COLS == 7, "网格列数应为7")
	assert_true(Constants.MIN_MATCH_COUNT == 3, "最小匹配数应为3")
	assert_true(Constants.TILE_SIZE == 96, "元素大小应为96")
	assert_true(Constants.TILE_COLORS.size() >= 6, "至少定义6种颜色")
