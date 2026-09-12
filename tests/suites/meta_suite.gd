## Meta suite
extends "res://tests/suites/test_suite.gd"


func test_flower_language() -> void:
	SaveManager.reset_save()

	var flower_language = SaveManager.get_flower_language_data()
	assert_true(flower_language.has("fragments"), "花语数据包含碎片表")
	assert_true(flower_language.has("unlocked"), "花语数据包含解锁列表")

	var level_system = LevelSystem.new()
	add_child(level_system)
	level_system.start_level(1)

	var victory = SettlementService.build_victory_settlement(1, 3, 100, level_system.level_config)
	SettlementService.apply_victory_settlement(victory)
	var reward = victory.get("flower_language_reward", {})
	assert_true(reward.get("success", false), "胜利结算会发放花语碎片")
	assert_equal(
		FlowerLanguageService.get_fragment_count(Constants.TileType.RED_ROSE),
		3,
		"首次通关会发放基础和首通花语碎片"
	)
	assert_true(
		"\n".join(SettlementService.format_rewards_summary(victory)).contains("花语碎片"),
		"胜利结算摘要包含花语碎片"
	)
	assert_true(
		not "\n".join(SettlementService.format_primary_rewards_summary(victory)).contains("花语碎片"),
		"首层胜利结算摘要隐藏普通花语碎片进度"
	)
	assert_true(
		"\n".join(SettlementService.format_primary_rewards_summary(victory)).contains("花园恢复"),
		"前三局首层胜利结算摘要优先展示花园恢复"
	)

	var repeat_victory = SettlementService.build_victory_settlement(1, 3, 100, level_system.level_config)
	SettlementService.apply_victory_settlement(repeat_victory)
	assert_equal(
		FlowerLanguageService.get_fragment_count(Constants.TileType.RED_ROSE),
		5,
		"重复通关只发放基础花语碎片并达到解锁条件"
	)
	assert_true(
		FlowerLanguageService.is_unlocked(Constants.TileType.RED_ROSE),
		"5个碎片会自动解锁花语"
	)

	level_system.start_level(2)
	level_system.moves_left = 0
	level_system._fail_level()
	var failure = SettlementService.build_failure_settlement(level_system, 10)
	SettlementService.apply_failure_settlement(failure)
	assert_equal(
		FlowerLanguageService.get_fragment_count(Constants.TileType.BLUE_FORGET_ME_NOT),
		1,
		"失败保底会发放对应花语碎片"
	)
	assert_true(
		"\n".join(SettlementService.format_rewards_summary(failure)).contains("花语碎片"),
		"失败结算摘要包含花语碎片"
	)

	var entries = FlowerLanguageService.get_journal_entries()
	assert_equal(entries.size(), 6, "花语日记包含6种基础花")

	level_system.free()
	SaveManager.reset_save()


func test_fragment_generation() -> void:
	var flower_types = [
		Constants.TileType.RED_ROSE,
		Constants.TileType.BLUE_FORGET_ME_NOT,
		Constants.TileType.PURPLE_LAVENDER,
		Constants.TileType.YELLOW_SUNFLOWER,
		Constants.TileType.WHITE_JASMINE,
		Constants.TileType.PINK_CHERRY
	]

	for flower_type in flower_types:
		var texture = SpriteGenerator.generate_fragment_texture(flower_type, 32)
		assert_true(texture != null and texture is ImageTexture, "花语碎片纹理生成成功")

	var synthesis_texture = SpriteGenerator.generate_synthesis_texture(64)
	assert_true(synthesis_texture != null and synthesis_texture is ImageTexture, "合成特效纹理生成成功")

	var flower_texture = SpriteGenerator.generate_flower_texture(Constants.TileType.RED_ROSE, 96)
	assert_true(flower_texture != null and flower_texture is ImageTexture, "花朵纹理生成成功")


func test_daily_service() -> void:
	SaveManager.reset_save()

	var daily = DailyService.get_daily_state()
	assert_true(daily.has("date"), "每日数据包含日期")
	assert_true(daily.has("tasks"), "每日数据包含任务")
	assert_true(daily.get("tasks", {}).has(DailyService.TASK_PLAY_LEVEL), "每日任务包含完成任意1局")
	assert_true(not DailyService.can_claim_gift(), "任务未完成时不能领取今日花礼")

	DailyService.record_event(DailyService.TASK_PLAY_LEVEL)
	DailyService.record_event(DailyService.TASK_HARVEST_FLOWER)
	assert_true(not DailyService.can_claim_gift(), "只完成部分任务时不能领取今日花礼")

	DailyService.record_event(DailyService.TASK_COLLECT_FLOWER_FRAGMENT)
	assert_true(DailyService.can_claim_gift(), "完成全部任务后可以领取今日花礼")

	var claim_result = DailyService.claim_gift()
	assert_true(claim_result.get("success", false), "今日花礼领取成功")
	assert_equal(EconomyService.get_stars(), DailyService.GIFT_STARS, "今日花礼发放星光")
	var garden = SaveManager.get_garden_data()
	assert_equal(garden.get("inventory", []).size(), 1, "今日花礼发放花种")
	assert_true(not DailyService.claim_gift().get("success", true), "今日花礼不可重复领取")

	var old_daily = SaveManager.get_daily_data()
	old_daily["date"] = "2000-01-01"
	old_daily["gift_claimed"] = true
	old_daily["tasks"][DailyService.TASK_PLAY_LEVEL]["progress"] = 1
	old_daily["tasks"][DailyService.TASK_PLAY_LEVEL]["completed"] = true
	SaveManager.update_daily_data(old_daily)

	var refreshed = DailyService.get_daily_state()
	assert_equal(refreshed.get("date", ""), DailyService.get_today_key(), "日期变化时每日数据刷新为今天")
	assert_true(not refreshed.get("gift_claimed", true), "日期变化后礼包领取状态重置")
	assert_equal(
		refreshed.get("tasks", {}).get(DailyService.TASK_PLAY_LEVEL, {}).get("progress", -1),
		0,
		"日期变化后任务进度重置"
	)

	var variant_keys: Dictionary = {}
	for day in range(1, 13):
		var challenge_date = "2026-08-%02d" % day
		var challenge = DailyChallengeService.get_challenge_for_date(challenge_date)
		var config = challenge.get("config", {})
		var descriptor = challenge.get("challenge", {})
		variant_keys["%s:%s" % [descriptor.get("layout_id", ""), descriptor.get("transform", "")]] = true
		var first_board = Board.new()
		var second_board = Board.new()
		first_board.initialize_grid(config)
		second_board.initialize_grid(config)
		assert_true(first_board.has_valid_moves(), "每日风庭布局存在有效交换: %s" % challenge_date)
		assert_equal(first_board.grid, second_board.grid, "同日每日风庭初始棋盘可复现: %s" % challenge_date)
		first_board.free()
		second_board.free()
	assert_equal(variant_keys.size(), 12, "连续日期覆盖 3 个母版与 4 种空间变换")

	var today_challenge = DailyChallengeService.get_today_challenge()
	var today_descriptor = today_challenge.get("challenge", {})
	var daily_result = DailyChallengeService.record_result(today_descriptor, false, 0, {
		"garden_layers_cleared": 4,
		"garden_layers_total": 8,
		"max_dew_chain": 2
	})
	assert_equal(daily_result.get("attempts", 0), 1, "每日风庭记录本日尝试次数")
	assert_equal(daily_result.get("best_chain", 0), 2, "每日风庭记录本日最大连锁")
	var changed_date_daily = SaveManager.get_daily_data()
	changed_date_daily["date"] = "2000-01-01"
	SaveManager.update_daily_data(changed_date_daily)
	assert_true(DailyChallengeService.get_today_progress().is_empty(), "日期切换后每日风庭成绩不会串入新日期")

	SaveManager.reset_save()


func test_decoration_service() -> void:
	SaveManager.reset_save()

	var catalog = DecorationService.get_decoration_catalog()
	assert_greater(catalog.size(), 3, "装饰目录至少包含4个装饰")
	assert_equal(DecorationService.get_decoration("lantern").get("name", ""), "星光灯笼", "装饰可按ID读取预览配置")
	assert_equal(DecorationService.get_atmosphere_value(), 0, "默认花园氛围值为0")
	assert_true(not DecorationService.is_owned("bench"), "默认未拥有长椅装饰")

	var invalid_result = DecorationService.purchase_decoration("missing")
	assert_true(not invalid_result.get("success", true), "非法装饰ID无法购买")
	assert_equal(invalid_result.get("reason", ""), "invalid_id", "非法装饰ID返回明确原因")

	var insufficient_result = DecorationService.purchase_decoration("bench")
	assert_true(not insufficient_result.get("success", true), "星光不足时无法购买装饰")
	assert_equal(insufficient_result.get("reason", ""), "not_enough_stars", "星光不足返回明确原因")
	assert_equal(SaveManager.get_garden_data().get("decorations", []).size(), 0, "购买失败不写入装饰存档")

	EconomyService.add_stars(40)
	var purchase_result = DecorationService.purchase_decoration("bench")
	assert_true(purchase_result.get("success", false), "星光足够时装饰购买成功")
	assert_equal(EconomyService.get_stars(), 10, "购买装饰后扣除星光")
	assert_true(DecorationService.is_owned("bench"), "购买后装饰变为已拥有")
	assert_equal(DecorationService.get_atmosphere_value(), 2, "购买装饰后氛围值提升")
	assert_equal(SaveManager.get_garden_data().get("decorations", []).size(), 1, "购买成功写入装饰存档")

	var repeat_result = DecorationService.purchase_decoration("bench")
	assert_true(not repeat_result.get("success", true), "已拥有装饰不可重复购买")
	assert_equal(repeat_result.get("reason", ""), "already_owned", "重复购买返回明确原因")
	assert_equal(EconomyService.get_stars(), 10, "重复购买不会重复扣费")
	assert_equal(SaveManager.get_garden_data().get("decorations", []).size(), 1, "重复购买不会重复写入")
	EconomyService.add_stars(50)
	var locked_choice = DecorationService.purchase_decoration("fountain")
	assert_true(not locked_choice.get("success", true), "同一庭院热点不能同时选择长椅和喷泉")
	assert_equal(locked_choice.get("reason", ""), "choice_locked", "第二个布置选择返回明确锁定原因")
	assert_equal(EconomyService.get_stars(), 60, "互斥选择失败不会扣除星光")

	var display_data = DecorationService.get_display_data()
	assert_equal(display_data.get("atmosphere", 0), 2, "装饰展示数据包含氛围值")
	assert_equal(display_data.get("stars", 0), 60, "装饰展示数据包含当前星光")

	SaveManager.reset_save()
	_unlock_meta_feature_for_test(MetaUnlockService.FEATURE_DECORATION)
	EconomyService.add_stars(40)
	var garden_ui = GardenUI.new()
	add_child(garden_ui)
	assert_true(garden_ui.decoration_container.visible, "装饰解锁后展示有限二选一托盘")
	assert_equal(garden_ui.decoration_choice_buttons.size(), 2, "庭院每次只提供两个可检查的外观选择")
	assert_true(not garden_ui.inventory_container.visible, "花园首屏不再展示背包和合成列表")
	garden_ui._begin_decoration_drag("bench")
	assert_true(not DecorationService.is_owned("bench"), "开始拖动不会立即购买或写入存档")
	assert_equal(EconomyService.get_stars(), 40, "拖动预览不会扣除星光")
	assert_true(garden_ui.decoration_drag_ghost.visible, "拖动时显示跟随手指的装饰实物")
	assert_true(garden_ui.decoration_drop_zone.visible, "拖动时显示庭院固定落点")
	assert_true(garden_ui.decoration_visuals["bench"].visible, "拖动时固定落点显示布置轮廓")
	garden_ui._finish_decoration_drag(Vector2(740, 1200))
	assert_true(not DecorationService.is_owned("bench"), "放在落点外不会购买装饰")
	garden_ui._begin_decoration_drag("bench")
	garden_ui._finish_decoration_drag(garden_ui.decoration_drop_zone.get_global_rect().get_center())
	assert_true(DecorationService.is_owned("bench"), "拖入固定落点后装饰写入存档")
	assert_true(garden_ui.decoration_visuals["bench"].visible, "确认购买后固定落点保持可见")
	assert_true(not garden_ui.decoration_container.visible, "完成二选一后收起装饰托盘")
	garden_ui.free()

	garden_ui = GardenUI.new()
	add_child(garden_ui)
	assert_true(garden_ui.decoration_visuals["bench"].visible, "重进花园后已购装饰仍然可见")
	garden_ui.free()
	SaveManager.reset_save()


func test_economy_and_boost() -> void:
	SaveManager.reset_save()
	assert_true(EconomyService.add_stars(20), "可增加星光")
	assert_equal(EconomyService.get_stars(), 20, "增加星光后数值正确")
	assert_true(EconomyService.spend_stars(12), "星光足够时可消耗")
	assert_equal(EconomyService.get_stars(), 8, "消耗星光后数值正确")
	assert_true(not EconomyService.spend_stars(12), "星光不足时不可消耗")

	var level_system = LevelSystem.new()
	add_child(level_system)
	level_system.start_level(1, 3)
	assert_equal(level_system.moves_left, 33, "开局祝福会增加初始步数")
	level_system.free()
	SaveManager.reset_save()


func test_progressive_disclosure() -> void:
	SaveManager.reset_save()

	var main_menu = MainMenu.new()
	assert_true(not main_menu.is_flower_journal_unlocked(), "默认不显示花语日记入口")
	assert_true(not main_menu.is_daily_gift_unlocked(), "默认不显示今日花礼入口")

	FlowerLanguageService.add_fragments(Constants.TileType.RED_ROSE, 1)
	assert_true(not main_menu.is_flower_journal_unlocked(), "未集齐花语时不显示花语日记入口")

	var player_data = SaveManager.get_player_data()
	player_data["total_runs"] = 3
	SaveManager.update_player_data(player_data)
	var garden_ui = GardenUI.new()
	assert_true(not main_menu.is_daily_gift_unlocked(), "单纯完成3局不会自动开放今日花礼")
	assert_true(not garden_ui.is_synthesis_unlocked(), "单纯完成3局不会自动开放合成")
	assert_true(not garden_ui.is_decoration_unlocked(), "单纯完成3局不会自动开放装饰")

	SaveManager.add_garden_inventory_item(Constants.TileType.RED_ROSE, 1, 2)
	FlowerLanguageService.add_fragments(Constants.TileType.RED_ROSE, 4)
	EconomyService.add_stars(30)
	MetaUnlockService.record_behavior(MetaUnlockService.BEHAVIOR_FLOWER_HARVESTED)
	MetaUnlockService.record_behavior(MetaUnlockService.BEHAVIOR_LEVEL_FAILED)
	var state = SaveManager.get_meta_progression_data()
	assert_equal(state.get("pending", []).size(), 5, "多个行为条件同时满足时能力先进入等待队列")

	var prompt = MetaUnlockService.begin_home_visit()
	assert_equal(prompt.get("feature_id", ""), MetaUnlockService.FEATURE_SYNTHESIS, "首次回首页只开放队首合成能力")
	var repeated_prompt = MetaUnlockService.begin_home_visit()
	assert_equal(repeated_prompt.get("feature_id", ""), MetaUnlockService.FEATURE_SYNTHESIS, "首次任务未完成时重复回首页不会跳到下一能力")
	assert_true(not repeated_prompt.get("newly_presented", true), "重复展示当前任务不计为新入口提示")
	assert_true(garden_ui.is_synthesis_unlocked(), "队首能力晋升后合成入口可用")
	assert_true(not main_menu.is_flower_journal_unlocked(), "同一次返回不同时开放花语入口")
	assert_true(not main_menu.is_daily_gift_unlocked(), "同一次返回不同时开放花礼入口")
	assert_true(not garden_ui.is_decoration_unlocked(), "同一次返回不同时开放装饰入口")
	add_child(main_menu)
	main_menu._update_display()
	assert_true(main_menu.recommendation_label.text.contains("花种合成"), "首页唯一推荐与当前首次任务一致")
	assert_true(not main_menu.flower_journal_btn.visible and not main_menu.daily_gift_btn.visible, "等待队列中的入口不会提前显示")

	assert_true(MetaUnlockService.complete_feature_task(MetaUnlockService.FEATURE_SYNTHESIS), "完成首次合成任务会清除当前提示")
	prompt = MetaUnlockService.begin_home_visit()
	assert_equal(prompt.get("feature_id", ""), MetaUnlockService.FEATURE_FLOWER_JOURNAL, "下一次回首页才开放花语日记")
	assert_true(main_menu.is_flower_journal_unlocked(), "花语日记晋升后入口可见")
	var flower_ui = FlowerLanguageUI.new()
	add_child(flower_ui)
	assert_true(flower_ui.action_btn.visible, "花语页仍有未解锁内容时提供可执行入口")
	assert_true(flower_ui.action_btn.text.contains("去第"), "花语页行动入口明确指向关卡")
	flower_ui.free()
	assert_true(MetaUnlockService.complete_feature_task(MetaUnlockService.FEATURE_FLOWER_JOURNAL), "查看花语可完成首次任务")

	prompt = MetaUnlockService.begin_home_visit()
	assert_equal(prompt.get("feature_id", ""), MetaUnlockService.FEATURE_DAILY_GIFT, "首次收获后按队列开放今日花礼")
	assert_true(main_menu.is_daily_gift_unlocked(), "今日花礼晋升后入口可见")
	var daily_ui = DailyGiftUI.new()
	add_child(daily_ui)
	assert_true(daily_ui.challenge_btn.visible, "今日花礼页提供今日风庭入口")
	assert_true(daily_ui.challenge_btn.text.contains("今日风庭"), "今日风庭入口明确说明行动")
	assert_true(not daily_ui.claim_btn.disabled, "花礼未完成时行动按钮仍可操作")
	assert_true(daily_ui.claim_btn.text.contains("去"), "花礼行动按钮明确给出下一步去向")
	daily_ui.free()
	assert_true(MetaUnlockService.complete_feature_task(MetaUnlockService.FEATURE_DAILY_GIFT), "查看花礼可完成首次任务")

	prompt = MetaUnlockService.begin_home_visit()
	assert_equal(prompt.get("feature_id", ""), MetaUnlockService.FEATURE_DECORATION, "收获且星光足够后按队列开放装饰")
	assert_true(garden_ui.is_decoration_unlocked(), "装饰晋升后入口可见")
	assert_true(MetaUnlockService.complete_feature_task(MetaUnlockService.FEATURE_DECORATION), "点亮装饰可完成首次任务")

	prompt = MetaUnlockService.begin_home_visit()
	assert_equal(prompt.get("feature_id", ""), MetaUnlockService.FEATURE_STAR_BLESSING, "首次失败后最终开放星光祝福")
	assert_equal(SaveManager.get_meta_progression_data().get("pending", []).size(), 0, "所有等待能力均按顺序收敛")

	garden_ui.free()
	main_menu.free()
	SaveManager.reset_save()


func test_garden_loop() -> void:
	SaveManager.reset_save()
	SaveManager.add_garden_inventory_item(Constants.TileType.BLUE_FORGET_ME_NOT, 1, 1)
	SaveManager.add_garden_inventory_item(Constants.TileType.RED_ROSE, 1, 1)

	var garden_ui = GardenUI.new()
	add_child(garden_ui)
	garden_ui._load_garden_data()
	var slot_click = InputEventMouseButton.new()
	slot_click.button_index = MOUSE_BUTTON_LEFT
	slot_click.pressed = true
	garden_ui.flower_slots[0].gui_input.emit(slot_click)

	var garden = SaveManager.get_garden_data()
	assert_equal(garden.get("inventory", []).size(), 2, "打开花种选择时不会自动消费第一项库存")
	assert_equal(garden.get("slots", []).size(), 0, "未选择花种前不会写入花盆")
	assert_true(garden_ui.seed_picker_overlay.visible, "点击空花盆后显示花种选择面板")
	garden_ui._confirm_seed_selection(0, Constants.TileType.BLUE_FORGET_ME_NOT, 1)

	garden = SaveManager.get_garden_data()
	assert_equal(garden.get("inventory", []).size(), 1, "确认花种后只扣减选中的库存")
	assert_equal(garden.get("slots", []).size(), 1, "种植后花园槽位已有花朵")
	assert_equal(garden.get("slots", [])[0].get("type"), Constants.TileType.BLUE_FORGET_ME_NOT, "花盆种下玩家选中的花种")
	assert_true(not garden_ui.seed_picker_overlay.visible, "确认种植后关闭花种选择面板")
	var plant_visual = garden_ui.flower_slots[0].get_child(0).get_node("PlantVisual")
	assert_true(plant_visual.visible, "种植后显示花园专用植株视觉")
	assert_true(plant_visual.get_root_point().y > plant_visual.get_bloom_center().y, "花茎从花盆口连接到花头")
	assert_true(plant_visual.uses_pot_rim(), "花盆位使用前景盆沿遮挡花根")
	var planted_style = garden_ui.flower_slots[0].get_theme_stylebox("panel") as StyleBoxFlat
	assert_equal(planted_style.border_width_left, 0, "已种植花盆不再显示悬浮卡片边框")

	var slots = garden.get("slots", [])
	slots[0]["planted_at"] = Time.get_unix_time_from_system() - int(Constants.FLOWER_GROWTH_DURATION + 1.0)
	slots[0]["growth"] = 0.0
	garden["slots"] = slots
	SaveManager.update_garden_data(garden)

	garden_ui._load_garden_data()
	garden = SaveManager.get_garden_data()
	assert_true(garden["slots"][0].get("growth", 0.0) >= 1.0, "花朵会按时间成长完成")

	garden_ui._harvest_flower(0)
	var player_data = SaveManager.get_player_data()
	assert_equal(player_data.get("stars", 0), 10, "收获花朵后获得星光")
	garden = SaveManager.get_garden_data()
	assert_true(garden["slots"][0].is_empty(), "收获后花盆被清空")

	garden_ui.free()
	SaveManager.reset_save()


func test_garden_synthesis() -> void:
	SaveManager.reset_save()
	SaveManager.add_garden_inventory_item(Constants.TileType.RED_ROSE, 1, 2)
	_unlock_meta_feature_for_test(MetaUnlockService.FEATURE_SYNTHESIS)

	assert_true(GardenSynthesisService.can_synthesize(Constants.TileType.RED_ROSE, 1, 2), "两个同等级花种可以合成")
	var garden_ui = GardenUI.new()
	add_child(garden_ui)
	garden_ui._on_synthesize_pressed(Constants.TileType.RED_ROSE, 1)
	assert_true(PopupManager.active_popups.has("confirm"), "合成操作先显示确认预览")
	assert_equal(garden_ui.last_synthesis_preview.get("cost_count", 0), 2, "合成预览说明消耗两个同级花种")
	assert_equal(garden_ui.last_synthesis_preview.get("from_reward", 0), 10, "合成预览显示原等级收获收益")
	assert_equal(garden_ui.last_synthesis_preview.get("to_reward", 0), 25, "合成预览显示新等级收获收益")
	assert_equal(SaveManager.get_garden_data().get("inventory", [])[0].get("amount", 0), 2, "合成预览阶段不消耗材料")
	PopupManager.close_popup("confirm")
	garden_ui._perform_synthesis(Constants.TileType.RED_ROSE, 1)

	var garden = SaveManager.get_garden_data()
	var inventory = garden.get("inventory", [])
	var lv1_amount = 0
	var lv2_amount = 0
	for item in inventory:
		if item.get("type") == Constants.TileType.RED_ROSE and item.get("level", 1) == 1:
			lv1_amount = item.get("amount", 0)
		if item.get("type") == Constants.TileType.RED_ROSE and item.get("level", 1) == 2:
			lv2_amount = item.get("amount", 0)

	assert_equal(lv1_amount, 0, "合成后旧等级材料被扣除")
	assert_equal(lv2_amount, 1, "合成后获得高一级花种")

	var fail_result = GardenSynthesisService.synthesize_once(Constants.TileType.RED_ROSE, 2)
	assert_true(not fail_result.get("success", true), "材料不足时无法继续合成")

	garden_ui.free()
	SaveManager.reset_save()
