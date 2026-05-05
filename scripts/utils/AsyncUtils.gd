## AsyncUtils - 统一异步等待工具
class_name AsyncUtils
extends RefCounted

static func create_delay_tween(owner: Node, duration: float) -> Tween:
	var tween = owner.create_tween()
	tween.tween_interval(max(duration, 0.0))
	return tween
