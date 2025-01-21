extends Node

@export var preferredDistance: Vector2
@export var agent: Agent
@export var pidController: PID
@export var thrustModifier: float

var targetMovementAngle: float = NAN
var targetAcquireTime: float = NAN


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if agent.controllingPlayer == null && agent.target != null && targetMovementAngle != NAN:
		if agent.gun != null:
			agent.gun.fire()
		targetMovementAngle += delta
		targetAcquireTime += delta
		pidController.target_position = agent.target.global_position + Vector2(lerp(preferredDistance.x, preferredDistance.y, (sin(targetAcquireTime * 2 * PI)+1)/2), 0).rotated(targetMovementAngle)
		agent.apply_force(thrustModifier * pidController.value)


func _on_medium_agent_target_changed(new_target: Node2D) -> void:
	if new_target != null:
		targetMovementAngle = new_target.global_position.angle_to_point(agent.global_position)
		targetAcquireTime = 0
	else:
		targetMovementAngle = NAN
		targetAcquireTime = NAN
