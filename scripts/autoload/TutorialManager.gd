## TutorialManager - 新手引导管理器
extends Node

# ==================== 常量 ====================
const TUTORIAL_COMPLETED_KEY = "tutorial_completed"

# ==================== 变量 ====================
var tutorial_system: TutorialSystem

# ==================== 生命周期 ====================
func _ready() -> void:
	print("TutorialManager initialized")

# ==================== 公开方法 ====================
# 检查引导是否完成
func is_tutorial_completed() -> bool:
	var settings = SaveManager.get_settings()
	return settings.get(TUTORIAL_COMPLETED_KEY, false)

# 标记引导完成
func mark_tutorial_completed() -> void:
	var settings = SaveManager.get_settings()
	settings[TUTORIAL_COMPLETED_KEY] = true
	SaveManager.update_settings(settings)
	print("Tutorial marked as completed")

# 重置引导状态（用于测试）
func reset_tutorial() -> void:
	var settings = SaveManager.get_settings()
	settings[TUTORIAL_COMPLETED_KEY] = false
	SaveManager.update_settings(settings)
	clear_tutorial_system()
	print("Tutorial reset")

# 开始引导
func start_tutorial() -> void:
	if is_tutorial_completed():
		print("Tutorial already completed, skipping")
		return
	
	# 创建引导系统
	if not is_instance_valid(tutorial_system):
		tutorial_system = preload("res://scripts/systems/TutorialSystem.gd").new()
		add_child(tutorial_system)
	
	tutorial_system.start_tutorial()


func is_tutorial_running() -> bool:
	return tutorial_system != null and tutorial_system.is_running()


func notify_action_completed(action: String) -> void:
	if tutorial_system != null and tutorial_system.is_running():
		tutorial_system.notify_action_completed(action)

# 检查是否需要显示引导
func should_show_tutorial() -> bool:
	return not is_tutorial_completed()

# 获取引导状态文本
func get_tutorial_status() -> String:
	if is_tutorial_completed():
		return "已完成"
	else:
		return "未完成"


func clear_tutorial_system() -> void:
	if tutorial_system and is_instance_valid(tutorial_system):
		tutorial_system.shutdown()
		tutorial_system.queue_free()
	tutorial_system = null
