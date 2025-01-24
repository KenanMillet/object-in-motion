extends Node

@export var preferredDistance: Vector2
@export var agent: Agent
@export var pidController: PID
@export var aimAssist: AimAssist
@export var attackDistance: float
@export var thrustModifier: float
@export var maxThrust: float
@export var minThrust: float
@export var speedSoftCap: float = 0

var targetMovementAngle: float = NAN
var targetAcquireTime: float = NAN


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if agent.controllingPlayer == null && agent.target != null && targetMovementAngle != NAN:
		if agent.gun != null:
			var gun_dist_sq = agent.global_position.distance_squared_to(agent.gun.global_position)
			var gun_direction = aimAssist.shotLead(agent.global_position, agent.target.global_position, agent.linear_velocity, agent.target.linear_velocity, agent.gun.bulletSpeed)
			agent.aimPosition = agent.target.global_position
			if gun_direction != Vector2.INF:
				agent.aimPosition = agent.global_position + (gun_direction * gun_dist_sq)
			#print(agent.name, " | Target pos (relative): ", agent.target.global_position-agent.global_position, "  Target vel (relative): ", agent.target.linear_velocity-agent.linear_velocity, "  Bullet speed: ", agent.gun.bulletSpeed, "  Gun Direction: ", gun_direction)
			if agent.global_position.distance_to(agent.target.global_position) < attackDistance:
				agent.gun.fire()
		targetMovementAngle += delta
		targetAcquireTime += delta
		pidController.target_position = agent.target.global_position + Vector2(lerp(preferredDistance.x, preferredDistance.y, (sin(targetAcquireTime * 2 * PI)+1)/2), 0).rotated(targetMovementAngle)
		var thrust = thrustModifier * pidController.value
		if thrust.length() < minThrust:
			thrust = Vector2.ZERO
		elif thrust.length() > maxThrust:
			thrust = thrust.normalized() * maxThrust
		if speedSoftCap > 0 && agent.linear_velocity.length() > speedSoftCap:
			for i in 2:
				if signf(thrust[i]) == signf(agent.linear_velocity[i]):
					thrust[i] = 0
		#print(agent.name, " | Target pos (relative): ", pidController.target_position - agent.global_position, "  PID: ", pidController.value, "  Thrust: ", thrust, " (magnitude:", thrust.length(), ")  Speed: ", agent.linear_velocity.length())
		agent.apply_force(thrust)

func _on_medium_agent_target_changed(new_target: Node2D) -> void:
	if new_target != null:
		targetMovementAngle = new_target.global_position.angle_to_point(agent.global_position)
		targetAcquireTime = 0
	else:
		targetMovementAngle = NAN
		targetAcquireTime = NAN
