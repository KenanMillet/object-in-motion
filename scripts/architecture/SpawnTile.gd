@tool
class_name SpawnTile
extends Area2D

signal blocker_entered(blocker: Node2D)
signal blocker_exited(blocker: Node2D)
signal test_blocker_entered(blocker: Node2D)
signal test_blocker_exited(blocker: Node2D)

var _collider: CollisionShape2D = CollisionShape2D.new()
var _visible_checker: VisibleOnScreenNotifier2D = VisibleOnScreenNotifier2D.new()

var _shape: RectangleShape2D:
	get:
		if _collider.shape == null:
			_collider.shape = RectangleShape2D.new()
		return _collider.shape

@export var size: Vector2 = Vector2(100, 100):
	get:
		return _shape.size
	set(value):
		_shape.size = value
		_collider.position = value/2
		visor_padding = visor_padding

enum VisCheckPaddingType
{
	PIXELS,
	SIZE_RATIO
}

@export var spawn_on_screen: bool = true:
	get:
		return _visible_checker.process_mode == Node.PROCESS_MODE_DISABLED
	set(value):
		_visible_checker.process_mode = Node.PROCESS_MODE_DISABLED if value else Node.PROCESS_MODE_INHERIT

@export var visor_padding_type: VisCheckPaddingType = VisCheckPaddingType.SIZE_RATIO:
	get:
		return visor_padding_type
	set(value):
		visor_padding_type = value
		visor_padding = visor_padding * (Vector2.ONE if !Engine.is_editor_hint() else (Vector2.ONE/size if value == VisCheckPaddingType.SIZE_RATIO else size))
		

@export var visor_padding: Vector2 = Vector2(0.5, 0.5):
	get:
		return visor_padding
	set(value):
		visor_padding = value
		var padding_px: Vector2 = value
		if visor_padding_type == VisCheckPaddingType.SIZE_RATIO:
			padding_px *= size
		_visible_checker.rect = Rect2(-padding_px, size + 2*padding_px)
		if Engine.is_editor_hint():
			queue_redraw()
		if _visible_checker.rect.size.x * _visible_checker.rect.size.y == 0:
			spawn_on_screen = true

func _queue_redraw_on_can_spawn_change(body: Node2D=null) -> void:
	if body is CollisionObject2D && body.collision_layer & CollisionUtil.Layer.spawn_testing == CollisionUtil.Layer.spawn_testing:
		return
	queue_redraw()

func _update_debug_draw() -> void:
	if Engine.is_editor_hint():
		queue_redraw()
	else:
		if debug_can_spawn || debug_cannot_spawn:
			if !_visible_checker.screen_entered.is_connected(_queue_redraw_on_can_spawn_change):
				_visible_checker.screen_entered.connect(_queue_redraw_on_can_spawn_change)
			if !_visible_checker.screen_exited.is_connected(_queue_redraw_on_can_spawn_change):
				_visible_checker.screen_exited.connect(_queue_redraw_on_can_spawn_change)
			if !body_entered.is_connected(_queue_redraw_on_can_spawn_change):
				body_entered.connect(_queue_redraw_on_can_spawn_change)
			if !body_exited.is_connected(_queue_redraw_on_can_spawn_change):
				body_exited.connect(_queue_redraw_on_can_spawn_change)
		else:
			if _visible_checker.screen_entered.is_connected(_queue_redraw_on_can_spawn_change):
				_visible_checker.screen_entered.disconnect(_queue_redraw_on_can_spawn_change)
			if _visible_checker.screen_exited.is_connected(_queue_redraw_on_can_spawn_change):
				_visible_checker.screen_exited.disconnect(_queue_redraw_on_can_spawn_change)
			if body_entered.is_connected(_queue_redraw_on_can_spawn_change):
				body_entered.disconnect(_queue_redraw_on_can_spawn_change)
			if body_exited.is_connected(_queue_redraw_on_can_spawn_change):
				body_exited.disconnect(_queue_redraw_on_can_spawn_change)

@export var debug_can_spawn: bool = false:
	get:
		return debug_can_spawn
	set(value):
		debug_can_spawn = value
		_update_debug_draw()

@export var debug_cannot_spawn: bool = false:
	get:
		return debug_cannot_spawn
	set(value):
		debug_cannot_spawn = value
		_update_debug_draw()

@export var tile_debug_color: Color = Color(Color.AQUA, 0.5):
	get:
		return tile_debug_color
	set(value):
		tile_debug_color = value
		if Engine.is_editor_hint():
			queue_redraw()
@export var visor_debug_color: Color = Color(Color.VIOLET, 0.5):
	get:
		return visor_debug_color
	set(value):
		visor_debug_color = value
		if Engine.is_editor_hint():
			queue_redraw()

func spawn(object: Node2D) -> void:
	object.global_position = center
	body_entered.emit(object)

var _spawn_blockers = {}

var can_spawn: bool:
	get:
		return _spawn_blockers.is_empty() && (spawn_on_screen || !_visible_checker.is_on_screen())

var spawn_blocker_count: int:
	get:
		return _spawn_blockers.size()

var spawn_blockers: Array:
	get:
		return _spawn_blockers.keys()

var center: Vector2:
	get:
		return global_position + size/2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_collider.visible = !Engine.is_editor_hint()
	_visible_checker.visible = !Engine.is_editor_hint()
	add_child(_collider)
	add_child(_visible_checker)
	collision_layer = CollisionUtil.Layer.spawn_tile
	collision_mask = CollisionUtil.Layer.spawn_blocking | CollisionUtil.Layer.spawn_testing
	monitoring = true
	monitorable = false
	body_entered.connect(func(body: Node2D):
		if body is CollisionObject2D && body.collision_layer & CollisionUtil.Layer.spawn_testing == CollisionUtil.Layer.spawn_testing:
			test_blocker_entered.emit(body)
		else:
			_spawn_blockers[body] = body
			blocker_entered.emit(body))
	body_exited.connect(func(body: Node2D):
		if body is CollisionObject2D && body.collision_layer & CollisionUtil.Layer.spawn_testing == CollisionUtil.Layer.spawn_testing:
			test_blocker_exited.emit(body)
		else:
			_spawn_blockers.erase(body)
			blocker_exited.emit(body))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _draw() -> void:
	if Engine.is_editor_hint():
		if visor_debug_color != null:
			if !debug_can_spawn || debug_cannot_spawn:
				draw_rect(_visible_checker.rect, visor_debug_color, true)
			draw_rect(_visible_checker.rect, Color(visor_debug_color, 1), false)
		if tile_debug_color != null:
			if !debug_can_spawn || debug_cannot_spawn:
				draw_rect(Rect2(Vector2.ZERO, size), tile_debug_color, true)
			draw_rect(Rect2(Vector2.ZERO, size), Color(tile_debug_color, 1), false)
	else:
		if debug_can_spawn && can_spawn:
			if !spawn_on_screen:
				draw_rect(_visible_checker.rect, Color(visor_debug_color, 1), false)
			draw_rect(Rect2(Vector2.ZERO, size), Color(tile_debug_color, 1), false)
		elif debug_cannot_spawn:
			if !spawn_on_screen && _visible_checker.is_on_screen():
				draw_rect(_visible_checker.rect, visor_debug_color)
			if !_spawn_blockers.is_empty():
				draw_rect(Rect2(Vector2.ZERO, size), tile_debug_color)
