## TestSuite - 拆分后各测试套件的共享基类
## 测试用例按领域放在 tests/suites/ 下，断言结果统一记到 TestRunner。
extends Node

const Fragment = preload("res://scripts/ui/Fragment.gd")
const VisualAssetCatalogScript = preload("res://scripts/utils/VisualAssetCatalog.gd")
const PlaytestRecorderScript = preload("res://scripts/utils/PlaytestRecorder.gd")
const PlaytestReportScript = preload("res://scripts/tools/playtest_report.gd")

var runner


func assert_true(condition: bool, message: String = "") -> bool:
	return runner.assert_true(condition, message)


func assert_equal(actual, expected, message: String = "") -> bool:
	return runner.assert_equal(actual, expected, message)


func assert_not_equal(actual, expected, message: String = "") -> bool:
	return runner.assert_not_equal(actual, expected, message)


func assert_greater(actual: float, threshold: float, message: String = "") -> bool:
	return runner.assert_greater(actual, threshold, message)


func _find_button_texts(node: Node) -> Array[String]:
	var texts: Array[String] = []
	if node is Button:
		texts.append((node as Button).text)
	for child in node.get_children():
		texts.append_array(_find_button_texts(child))
	return texts


func _find_label_texts(node: Node) -> Array[String]:
	var texts: Array[String] = []
	if node is Label:
		texts.append((node as Label).text)
	for child in node.get_children():
		texts.append_array(_find_label_texts(child))
	return texts


func _unlock_meta_feature_for_test(feature_id: String) -> void:
	var state = SaveManager.get_meta_progression_data()
	var unlocked = state.get("unlocked", [])
	if not unlocked.has(feature_id):
		unlocked.append(feature_id)
	state["unlocked"] = unlocked
	SaveManager.update_meta_progression_data(state)
