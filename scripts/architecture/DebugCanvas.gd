class_name DebugCanvas
extends Node2D

static func locate(node: Node) -> Node2D:
	return node.get_tree().get_first_node_in_group("debug_canvas") as Node2D

func _ready() -> void:
	add_to_group("debug_canvas")
	queue_redraw()

func _draw() -> void:
	pass
