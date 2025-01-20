extends Node

@export var preferredDistance: Vector2
@export var agent: Agent
@export var enemyThrustModifier: float = 1000
@export var enemyPropWeight: Vector2 = 1.1 * Vector2.ONE
@export var enemyIntegWeight: Vector2 = 0.15 * Vector2.ONE
@export var enemyDerivWeight: Vector2 = -2 * Vector2.ONE

func pid(target_pos: Vector2, last_pos: Vector2, pos: Vector2, deltaTime: float, cumulative_integral: Vector2, p_weight: Vector2, i_weight: Vector2, d_weight: Vector2) -> Array[Vector2]:
	var proportional = target_pos - agent.global_position
	var derivative = (pos - last_pos)/deltaTime
	cumulative_integral += proportional*deltaTime
	var output = (p_weight * proportional) + (i_weight * cumulative_integral) + (d_weight * derivative)
	return [output, cumulative_integral]

var last_position = null
var integral = Vector2.ZERO

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
		var movementTarget = agent.target.global_position + Vector2(lerp(preferredDistance.x, preferredDistance.y, (sin(targetAcquireTime * 2 * PI)+1)/2), 0).rotated(targetMovementAngle)
		if last_position == null:
			last_position = agent.global_position
		var pid_result = pid(movementTarget, last_position, agent.global_position, delta, integral, enemyPropWeight, enemyIntegWeight, enemyDerivWeight)
		last_position = agent.global_position
		integral = pid_result[1]
		agent.apply_force(enemyThrustModifier*pid_result[0])
	else:
		last_position = null


func _on_medium_agent_target_changed(new_target: Node2D) -> void:
	if new_target != null:
		targetMovementAngle = new_target.global_position.angle_to_point(agent.global_position)
		targetAcquireTime = 0
		integral = Vector2.ZERO
	else:
		targetMovementAngle = NAN
		targetAcquireTime = NAN
