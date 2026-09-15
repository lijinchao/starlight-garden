## UI and navigation suite
extends "res://tests/suites/test_suite.gd"


func test_navigation_and_guidance() -> void:
	SaveManager.reset_save()
	TutorialManager.mark_tutorial_completed()
	var isolated_settings = SettingsUI.new()
	add_child(isolated_settings)
	isolated_settings.visible = false
	isolated_settings.hide_settings()
	assert_true(isolated_settings.transition_tween == null, "隐藏的设置页不会创建延迟关闭补间")
	isolated_settings.show_settings()
	var entering_settings = isolated_settings.transition_tween
	isolated_settings.hide_settings()
	assert_true(not entering_settings.is_valid(), "关闭设置页会取消尚未完成的淡入")
	var leaving_settings = isolated_settings.transition_tween
	isolated_settings.show_settings()
	assert_true(not leaving_settings.is_valid(), "重新打开设置页会取消延迟隐藏")
	assert_true(isolated_settings.visible, "快速重新打开后设置页保持可见")
	isolated_settings.free()
	var player_data = SaveManager.get_player_data()
	player_data["total_runs"] = 4
	SaveManager.update_player_data(player_data)

	var scene_manager = SceneManager.new()
	add_child(scene_manager)
	scene_manager._show_settings()
	assert_equal(scene_manager.current_scene, SceneManager.SceneType.SETTINGS, "设置入口切换到设置场景")
	assert_true(scene_manager.settings_ui.visible, "设置页首次打开后保持可见")
	scene_manager._start_game(1)
	assert_equal(scene_manager.current_scene, SceneManager.SceneType.GAME, "开始关卡后进入游戏场景")
	assert_true(scene_manager.game_controller.home_btn.visible, "局内主页入口可见")
	assert_equal(scene_manager.game_controller.home_btn.tooltip_text, "返回主页", "局内主页入口含明确提示")
	assert_true(
		scene_manager.game_controller.hud_container.position.y + scene_manager.game_controller.hud_container.size.y
		<= scene_manager.game_controller.board_container.position.y,
		"局内目标说明不会遮挡棋盘"
	)
	scene_manager.game_controller.home_btn.pressed.emit()
	assert_true(PopupManager.active_popups.has("confirm"), "局内返回主页前说明未结算进度")
	PopupManager.close_popup("confirm")
	scene_manager._leave_game_to_menu()
	assert_equal(scene_manager.current_scene, SceneManager.SceneType.MENU, "确认退出后返回主页")
	assert_equal(GameManager.current_state, GameManager.GameState.MENU, "退出关卡后同步菜单状态")
	scene_manager.free()

	player_data = SaveManager.get_player_data()
	player_data["level"] = 5
	player_data["total_runs"] = 4
	SaveManager.update_player_data(player_data)
	SaveManager.update_garden_data({
		"slots": [{}, {}, {}, {}],
		"inventory": [{"type": Constants.TileType.BLUE_FORGET_ME_NOT, "level": 1, "amount": 1}],
		"decorations": [],
		"restoration_stage": 3
	})

	var menu = MainMenu.new()
	add_child(menu)
	var recommendation = menu.get_home_recommendation()
	assert_equal(recommendation.get("action", ""), "garden", "有花种和空花盆时首页推荐去花园")
	assert_true(menu.recommendation_label.text.contains("下一步："), "首页明确显示单一下一步")
	var recommended_buttons = int(menu.start_btn.text.contains("推荐")) + int(menu.garden_btn.text.contains("推荐"))
	assert_equal(recommended_buttons, 1, "首页同时只突出一个推荐动作")
	assert_true(menu.garden_btn.text.contains("推荐"), "首页推荐按钮与推荐内容一致")
	menu.free()

	SaveManager.reset_save()
	TutorialManager.reset_tutorial()
	scene_manager = SceneManager.new()
	add_child(scene_manager)
	scene_manager._start_game(1)
	var tutorial_generation = scene_manager.tutorial_start_generation
	scene_manager._show_daily_gift()
	assert_true(scene_manager.tutorial_start_generation > tutorial_generation, "离开关卡会取消待启动教程")
	assert_equal(scene_manager.current_scene, SceneManager.SceneType.DAILY_GIFT, "取消教程后保持目标页面")
	assert_true(not TutorialManager.is_tutorial_running(), "教程不会覆盖已切换的页面")
	scene_manager.free()
	TutorialManager.reset_tutorial()
	SaveManager.reset_save()


func test_home_return_paths() -> void:
	# 局内主页按钮必须可点：HUD 容器与标签不能拦截点击
	var controller = SimpleGameController.new()
	add_child(controller)
	controller._start_level(1)
	assert_equal(controller.hud_container.mouse_filter, Control.MOUSE_FILTER_IGNORE, "HUD 容器不拦截局内主页按钮")
	for hud_label in [controller.moves_label, controller.score_label, controller.target_label, controller.status_label]:
		assert_equal(hud_label.mouse_filter, Control.MOUSE_FILTER_IGNORE, "HUD 标签不拦截局内主页按钮")
	var home_signals: Array = []
	controller.home_requested.connect(func() -> void: home_signals.append(true))
	controller._on_home_pressed()
	assert_equal(home_signals.size(), 1, "局内主页按钮触发返回主页")
	controller.free()

	# 胜利弹窗必须提供回主页入口，不能只强迫继续过关
	var victory = {
		"outcome": "victory",
		"level_id": 1,
		"score": 100,
		"stars_earned": 3,
		"player_total_runs_after": 9,
		"rewards": {"seed_count": 1, "seed_type": Constants.TileType.RED_ROSE, "stars": 20},
		"restoration_progress": {"changed": true, "name": "发芽角", "focus_title": "第一簇新芽"}
	}
	var victory_popup = PopupManager._create_victory_popup(victory)
	assert_true(_find_button_texts(victory_popup).has("回主页"), "胜利弹窗提供回主页入口，不强迫继续过关")
	victory_popup.free()

	# 迭代 P / B-2：失败后必须能免费立刻重试
	var failure_popup = PopupManager._create_failure_popup({
		"outcome": "failure",
		"level_id": 6,
		"moves_used": 13,
		"continue_cost": 10,
		"player_total_runs_after": 9,
		"progress_ratio": 0.5,
		"rest_rewards": {"stars": 6, "seed_count": 0, "seed_type": Constants.TileType.RED_ROSE}
	}, true)
	assert_true(_find_button_texts(failure_popup).has("重试本关"), "失败弹窗提供免费重试入口")
	failure_popup.free()


func test_level_select_replay() -> void:
	SaveManager.reset_save()
	var player = SaveManager.get_player_data()
	player["level"] = 6
	player["cleared_levels"] = [1, 2, 3, 4, 5]
	SaveManager.update_player_data(player)

	var menu = MainMenu.new()
	add_child(menu)
	menu.show_menu()
	assert_true(menu.level_select_btn.visible, "有进度后主菜单出现选关入口")

	menu._open_level_select()
	var level_buttons = menu.get_level_select_buttons()
	assert_true(level_buttons.size() >= 6, "选关面板列出已到达的关卡")

	var captured: Array = []
	menu.start_specific_level.connect(func(level_id: int) -> void: captured.append(level_id))
	(level_buttons[5] as Button).pressed.emit()
	assert_equal(captured.size(), 1, "点击关卡按钮会请求开始该关")
	assert_equal(int(captured[0]), 6, "请求的是被点击的关卡")

	menu.free()
	SaveManager.reset_save()


func test_restoration_feedback() -> void:
	SaveManager.reset_save()

	assert_equal(SaveManager.get_garden_data().get("restoration_stage", -1), 0, "默认花园恢复阶段为0")
	assert_equal(SaveManager.get_restoration_state().get("name", ""), "沉睡角", "默认恢复阶段名称正确")
	assert_true(not str(SaveManager.get_restoration_state().get("preview", "")).is_empty(), "恢复阶段包含可见预览")
	assert_equal(SaveManager.get_restoration_state().get("focus_title", ""), "左侧空盆", "默认恢复阶段包含具象修复角落")

	var synced = SaveManager.sync_restoration_stage(1)
	assert_equal(int(synced.get("target_stage", -1)), 1, "第1局后同步到恢复阶段1")
	assert_true(bool(synced.get("changed", false)), "恢复阶段首次推进时标记为变化")
	assert_equal(str(synced.get("focus_title", "")), "第一簇新芽", "第1局后恢复角落变为第一簇新芽")

	synced = SaveManager.sync_restoration_stage(3)
	assert_equal(int(synced.get("target_stage", -1)), 3, "第3局后同步到恢复阶段3")
	synced = SaveManager.sync_restoration_stage(8)
	assert_equal(int(synced.get("target_stage", -1)), 3, "恢复阶段不会在第3局后继续增长")

	SaveManager.reset_save()
	synced = SaveManager.sync_restoration_stage(1)
	GameManager.change_state(GameManager.GameState.VICTORY)
	var scene_manager = SceneManager.new()
	add_child(scene_manager)
	scene_manager._sync_scene_sizes()
	GameManager.open_garden({"restoration_progress": synced})
	assert_equal(scene_manager.current_scene, SceneManager.SceneType.GARDEN, "GameManager 请求会切换到花园场景")
	assert_true(scene_manager.garden_ui.visible, "花园场景切换后保持可见")
	assert_equal(scene_manager.garden_ui.anchor_right, 1.0, "花园界面横向铺满父容器")
	assert_equal(scene_manager.garden_ui.anchor_bottom, 1.0, "花园界面纵向铺满父容器")
	assert_equal(scene_manager.garden_ui.size, scene_manager.get_viewport_rect().size, "花园背景拥有完整视口尺寸")
	assert_true(scene_manager.garden_ui.back_btn.visible, "花园返回按钮可见")
	assert_equal(scene_manager.garden_ui.back_btn.text, "←", "花园返回按钮使用独立图标入口")
	assert_true(
		scene_manager.garden_ui.top_bar_panel.offset_bottom < scene_manager.garden_ui.restoration_summary_panel.offset_top,
		"顶部导航与恢复摘要不重叠"
	)
	assert_true(
		scene_manager.garden_ui.restoration_summary_panel.offset_bottom < scene_manager.garden_ui.garden_grid.position.y,
		"恢复摘要与花盆操作区不重叠"
	)
	assert_equal(scene_manager.garden_ui.last_arrival_message, "花园恢复到「发芽角」", "打开花园时会带入恢复到达反馈")
	assert_equal(scene_manager.garden_ui.last_arrival_detail, "左侧空盆已经冒出第一簇新芽。", "花园到达反馈会说明具体修好的角落")
	scene_manager.garden_ui.back_btn.pressed.emit()
	assert_equal(scene_manager.current_scene, SceneManager.SceneType.MENU, "花园返回按钮可回到首页")
	assert_equal(GameManager.current_state, GameManager.GameState.MENU, "花园返回首页时同步全局游戏状态")
	scene_manager.free()

	var menu = MainMenu.new()
	add_child(menu)
	assert_equal(menu.start_btn.text, "✨ 开始修复", "前三局主按钮聚焦修复花园")
	assert_equal(menu.garden_btn.text, "🌿 看看花园", "前三局花园入口聚焦查看变化")
	assert_equal(menu.restoration_scene_strip.get_child_count(), 3, "主菜单展示三格恢复小景")
	assert_equal(menu.restoration_focus_label.text, "现在最明显的是：第一簇新芽", "主菜单展示当前修好的角落")
	menu.free()

	SaveManager.reset_save()
	var garden_ui = GardenUI.new()
	add_child(garden_ui)
	var slot_zero = garden_ui.flower_slots[0]
	var slot_zero_box = slot_zero.get_child(0)
	assert_equal(slot_zero_box.get_node("PotIcon").text, "🍂", "恢复阶段0时空花盆显示枯叶")
	assert_equal(slot_zero_box.get_node("StatusLabel").text, "静待唤醒", "恢复阶段0时花盆文案提示待修复")
	assert_true(not garden_ui.restoration_hint_label.visible, "花园首屏隐藏重复的长恢复描述")
	assert_true(not garden_ui.restoration_preview_label.visible, "花园首屏不重复展示落叶预览图标")
	assert_true(not garden_ui.restoration_goal_label.visible, "花园首屏隐藏重复的下一局说明")
	assert_true(not garden_ui.decoration_container.visible, "前三局花园不显示未解锁装饰说明")
	garden_ui.free()

	var player_data = SaveManager.get_player_data()
	player_data["total_runs"] = 3
	SaveManager.update_player_data(player_data)
	SaveManager.sync_restoration_stage(3)
	menu = MainMenu.new()
	add_child(menu)
	assert_true(menu.start_btn.text.contains("推荐"), "完成前三局后主页突出唯一推荐动作")
	assert_equal(menu.garden_btn.text, "🌿 我的花园", "完成前三局后花园入口恢复长期表达")
	menu.free()

	garden_ui = GardenUI.new()
	add_child(garden_ui)
	slot_zero = garden_ui.flower_slots[0]
	slot_zero_box = slot_zero.get_child(0)
	assert_equal(slot_zero_box.get_node("PotIcon").text, "+", "恢复阶段3时空花盆显示可操作入口")
	assert_equal(slot_zero_box.get_node("StatusLabel").text, "种在大花盆", "恢复阶段3时花盆文案说明空间落点")
	assert_equal(garden_ui.restoration_focus_label.text, "现在最明显的是：门前微灯", "花园页展示当前修好的角落")
	assert_equal(garden_ui.highlighted_restoration_slot, 3, "花园页高亮当前修复角落对应的花盆位")
	assert_true(not garden_ui.decoration_container.visible, "完成前三局但未发生收获时不显示装饰操作区")
	_unlock_meta_feature_for_test(MetaUnlockService.FEATURE_DECORATION)
	garden_ui._update_garden_display()
	assert_true(garden_ui.decoration_container.visible, "行为解锁装饰后花园显示操作区")
	garden_ui.free()

	var early_failure = {
		"outcome": "failure",
		"moves_used": 20,
		"continue_cost": 10,
		"progress_ratio": 0.5,
		"player_total_runs_after": 1,
		"rest_rewards": {
			"stars": 6,
			"seed_count": 0,
			"seed_type": Constants.TileType.RED_ROSE
		},
		"restoration_progress": {
			"changed": true,
			"name": "发芽角",
			"focus_title": "第一簇新芽"
		}
	}
	var failure_popup = PopupManager._create_failure_popup(early_failure)
	var failure_button_texts = _find_button_texts(failure_popup)
	var failure_label_texts = "\n".join(_find_label_texts(failure_popup))
	assert_true(not failure_button_texts.has("继续挑战"), "前三局失败弹窗不显示继续挑战入口")
	assert_true(failure_button_texts.has("回花园看看"), "前三局失败弹窗主按钮引导返回花园")
	assert_true(failure_label_texts.contains("这次修好了：第一簇新芽"), "前三局失败弹窗会指出修好的角落")
	failure_popup.free()

	var early_victory = {
		"outcome": "victory",
		"level_id": 1,
		"score": 100,
		"stars_earned": 3,
		"player_total_runs_after": 1,
		"rewards": {
			"seed_count": 1,
			"seed_type": Constants.TileType.RED_ROSE,
			"stars": 20
		},
		"restoration_progress": {
			"changed": true,
			"name": "发芽角",
			"focus_title": "第一簇新芽"
		}
	}
	var victory_popup = PopupManager._create_victory_popup(early_victory)
	var victory_button_texts = _find_button_texts(victory_popup)
	var victory_label_texts = "\n".join(_find_label_texts(victory_popup))
	assert_true(victory_button_texts.has("回花园看看"), "前三局胜利弹窗主按钮引导查看花园变化")
	assert_true(victory_label_texts.contains("这次修好了：第一簇新芽"), "前三局胜利弹窗会指出修好的角落")
	victory_popup.free()

	SaveManager.reset_save()
