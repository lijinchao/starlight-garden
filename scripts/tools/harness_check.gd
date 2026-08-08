## HarnessCheck - 产品目标与验证基线检查
extends SceneTree

const REQUIRED_DOCS: Array[String] = [
	"res://VERSION",
	"res://CHANGELOG.md",
	"res://README.md",
	"res://AGENTS.md",
	"res://docs/STATUS_AND_ITERATION_PLAN.md",
	"res://docs/CURRENT_PRODUCT_AND_ARCHITECTURE.md",
	"res://docs/PRODUCT_THEME_AND_GAMEPLAY_REVIEW.md",
	"res://docs/ITERATION_A_TASK_BREAKDOWN.md",
	"res://docs/ITERATION_B_TASK_BREAKDOWN.md",
	"res://docs/ITERATION_C_TASK_BREAKDOWN.md",
	"res://docs/ITERATION_D_TASK_BREAKDOWN.md",
	"res://docs/ITERATION_E_TASK_BREAKDOWN.md",
	"res://docs/ITERATION_F_TASK_BREAKDOWN.md",
	"res://docs/ITERATION_G_TASK_BREAKDOWN.md",
	"res://docs/ITERATION_H_TASK_BREAKDOWN.md",
	"res://docs/ITERATION_TEMPLATE.md",
	"res://docs/MANUAL_VERIFICATION_GUIDE.md",
	"res://docs/HARNESS_ENGINEERING.md",
	"res://tests/TEST_DOCUMENTATION.md"
]

const MANUAL_REQUIRED_TERMS: Array[String] = [
	"通关奖励",
	"关卡奖励",
	"花园种植",
	"花园合成",
	"星光祝福",
	"失败保底",
	"连续失败鼓励",
	"继续挑战",
	"花语碎片",
	"花语日记",
	"今日花礼",
	"每日任务",
	"花园装饰",
	"氛围值",
	"渐进解锁",
	"结算降噪",
	"花园恢复",
	"局内爽感",
	"清风唤醒"
]

const REQUIRED_AUTOLOADS: Array[String] = [
	"SaveManager",
	"SettlementService",
	"GardenSynthesisService",
	"EconomyService",
	"FlowerLanguageService",
	"DailyService",
	"DecorationService"
]

const LEVEL_COUNT: int = 20

var _failures: Array[String] = []
var _checks: int = 0


func _init() -> void:
	print("\n=====================================")
	print("   星光花园 - Harness 检查")
	print("=====================================\n")

	_check_required_docs()
	_check_version_contract()
	_check_doc_discoverability()
	_check_iteration_contract()
	_check_manual_verification_contract()
	_check_project_autoloads()
	_check_level_configs()

	print("\n=====================================")
	print("   Harness 检查结果")
	print("=====================================")
	print("检查项: %d" % _checks)
	print("失败: %d" % _failures.size())

	if not _failures.is_empty():
		print("\n失败详情:")
		for failure in _failures:
			print("  - %s" % failure)
		print("=====================================\n")
		quit(1)
		return

	print("状态: PASS")
	print("=====================================\n")
	quit(0)


func _check_required_docs() -> void:
	for path in REQUIRED_DOCS:
		_expect(FileAccess.file_exists(path), "必需文档存在: %s" % path)


func _check_version_contract() -> void:
	var version = _read_text("res://VERSION").strip_edges()
	var project_config = _read_text("res://project.godot")
	var changelog = _read_text("res://CHANGELOG.md")
	_expect(not version.is_empty(), "VERSION 包含版本号")
	_expect(project_config.contains('config/version="%s"' % version), "project.godot 版本与 VERSION 一致")
	_expect(changelog.contains("## %s" % version), "CHANGELOG 包含当前版本")


func _check_doc_discoverability() -> void:
	var readme = _read_text("res://README.md")
	var agents = _read_text("res://AGENTS.md")
	var test_docs = _read_text("res://tests/TEST_DOCUMENTATION.md")

	_expect(readme.contains("HARNESS_ENGINEERING.md"), "README 暴露 Harness 文档入口")
	_expect(readme.contains("CURRENT_PRODUCT_AND_ARCHITECTURE.md"), "README 暴露当前产品与架构基线")
	_expect(readme.contains("PRODUCT_THEME_AND_GAMEPLAY_REVIEW.md"), "README 暴露主题与玩法复盘")
	_expect(readme.contains("CHANGELOG.md"), "README 暴露版本历史")
	_expect(readme.contains("ITERATION_H_TASK_BREAKDOWN.md"), "README 暴露当前迭代 H 文档入口")
	_expect(agents.contains("HARNESS_ENGINEERING.md"), "AGENTS 暴露 Harness 文档入口")
	_expect(agents.contains("CURRENT_PRODUCT_AND_ARCHITECTURE.md"), "AGENTS 暴露当前产品与架构基线")
	_expect(agents.contains("PRODUCT_THEME_AND_GAMEPLAY_REVIEW.md"), "AGENTS 暴露主题与玩法复盘")
	_expect(agents.contains("ITERATION_H_TASK_BREAKDOWN.md"), "AGENTS 指向当前迭代 H")
	_expect(test_docs.contains("run_harness.sh"), "测试文档暴露统一 Harness 入口")


func _check_iteration_contract() -> void:
	var iteration = _read_text("res://docs/ITERATION_H_TASK_BREAKDOWN.md")
	_expect(_contains_any(iteration, ["迭代目标", "迭代 H 目标"]), "当前迭代文档包含迭代目标")
	_expect(iteration.contains("产品目标"), "当前迭代文档包含产品目标")
	_expect(iteration.contains("用户感知"), "当前迭代文档包含用户感知结果")
	_expect(iteration.contains("目标映射"), "当前迭代文档包含目标映射")
	_expect(iteration.contains("验证"), "当前迭代文档包含验证方式")
	_expect(iteration.contains("可评估"), "当前迭代文档包含可评估口径")
	_expect(iteration.contains("完成"), "当前迭代文档包含完成状态或完成定义")
	_expect(iteration.contains("试玩"), "当前迭代文档覆盖试玩验证")
	_expect(iteration.contains("不联网"), "当前迭代文档明确本地数据边界")


func _check_manual_verification_contract() -> void:
	var manual = _read_text("res://docs/MANUAL_VERIFICATION_GUIDE.md")
	for term in MANUAL_REQUIRED_TERMS:
		_expect(manual.contains(term), "手动验证覆盖: %s" % term)


func _check_project_autoloads() -> void:
	var project_config = _read_text("res://project.godot")
	for autoload_name in REQUIRED_AUTOLOADS:
		_expect(project_config.contains(autoload_name), "核心服务已注册 autoload: %s" % autoload_name)


func _check_level_configs() -> void:
	var seed_types: Dictionary = {}
	var reward_stages: Dictionary = {}

	for level_id in range(1, LEVEL_COUNT + 1):
		var level_path = "res://levels/level_%03d.json" % level_id
		_expect(FileAccess.file_exists(level_path), "关卡配置存在: %s" % level_path)
		if not FileAccess.file_exists(level_path):
			continue

		var parsed = _read_json(level_path)
		if parsed.is_empty():
			_fail("关卡配置 JSON 可解析: %s" % level_path)
			continue

		_expect(int(parsed.get("level_id", 0)) == level_id, "关卡 ID 与文件名一致: %s" % level_path)
		_expect(parsed.has("moves") and int(parsed.get("moves", 0)) > 0, "关卡包含有效步数: %s" % level_path)
		_expect(_has_collect_target(parsed), "关卡包含收集目标: %s" % level_path)
		_expect(_has_available_types(parsed), "关卡包含可用元素: %s" % level_path)
		_expect(_has_reward_contract(parsed), "关卡包含完整奖励契约: %s" % level_path)

		var rewards = parsed.get("rewards", {})
		seed_types[str(rewards.get("seed_type", ""))] = true
		reward_stages[str(rewards.get("stars", 0)) + ":" + str(rewards.get("seed_count", 0))] = true

	_expect(seed_types.size() >= 3, "20 关至少提供 3 种花种追求")
	_expect(reward_stages.size() >= 3, "20 关至少形成 3 个奖励阶段")


func _has_collect_target(config: Dictionary) -> bool:
	var target = config.get("target", {})
	if not target is Dictionary:
		return false
	if target.get("type", "") != "collect":
		return false
	var requirements = target.get("requirements", [])
	if not requirements is Array or requirements.is_empty():
		return false
	for req in requirements:
		if not req is Dictionary:
			return false
		if not req.has("tile_type") or int(req.get("count", 0)) <= 0:
			return false
	return true


func _has_available_types(config: Dictionary) -> bool:
	var available_types = config.get("available_types", [])
	if not available_types is Array or available_types.size() < 3:
		return false
	for tile_type in available_types:
		if int(tile_type) <= 0:
			return false
	return true


func _has_reward_contract(config: Dictionary) -> bool:
	var rewards = config.get("rewards", {})
	if not rewards is Dictionary:
		return false
	var first_clear_bonus = rewards.get("first_clear_bonus", {})
	if not first_clear_bonus is Dictionary:
		return false
	return rewards.has("seed_type") \
		and int(rewards.get("seed_count", 0)) > 0 \
		and int(rewards.get("stars", 0)) > 0 \
		and int(first_clear_bonus.get("stars", 0)) > 0 \
		and int(first_clear_bonus.get("seed_count", 0)) > 0


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text = file.get_as_text()
	file.close()
	return text


func _read_json(path: String) -> Dictionary:
	var text = _read_text(path)
	var json = JSON.new()
	if json.parse(text) != OK:
		return {}
	if not json.data is Dictionary:
		return {}
	return json.data


func _contains_any(text: String, terms: Array[String]) -> bool:
	for term in terms:
		if text.contains(term):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("  PASS: %s" % message)
	else:
		_fail(message)


func _fail(message: String) -> void:
	_failures.append(message)
	print("  FAIL: %s" % message)
