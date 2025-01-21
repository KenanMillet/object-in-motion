extends Node

@export var idleTime: Vector2
@export var idleDistance: Vector2
@export var attackDistance: float
@export var agent: Agent
@export var pidController: PID
@export var thrustModifier: float

var idling: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_go_idle()

func _go_idle() -> void:
	idling = true
	pidController.target_position = Vector2(randf_range(idleDistance.x, idleDistance.y), 0).rotated(agent.target.global_position.angle_to(agent.global_position) + randf_range(-PI/8, PI/8))
	var idle_time = randf_range(idleTime.x, idleTime.y)
	if agent.gun != null:
		idle_time = max(idle_time, 60.0/agent.gun.enemyRpm)
	await get_tree().create_timer(idle_time).timeout
	idling = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if agent.target != null:
		if agent.global_position.distance_to(agent.target.global_position) < attackDistance && agent.gun != null:
			if agent.gun.fire():
				_go_idle()
		if !idling && !agent.reloading:
			pidController.target_position = agent.target.global_position

	agent.apply_force(thrustModifier * pidController.value)
