extends Node

@export var preferredDistance: Vector2
@export var agent: Agent
@export var pidController: PID
@export var attackDistance: float
@export var thrustModifier: float
@export var maxThrust: float
@export var minThrust: float
@export var speedSoftCap: float = 0

@onready var _debugCanvas = DebugCanvas.locate(agent)
@onready var aimAssist = AimAssist.new(agent)

var targetMovementAngle: float = NAN
var targetAcquireTime: float = NAN


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#aimAssist.debug_aim.connect(AimAssist.DebugPrint(agent.name))
	aimAssist.debug_aim.connect(AimAssist.DebugDraw(_debugCanvas, 10, Color.from_hsv(randf(), 1, 1, 0.75), false, 2))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if agent.controllingPlayer == null && agent.target != null && targetMovementAngle != NAN:
		if agent.gun != null:
			var target_vector = agent.target.global_position - agent.global_position
			var gun_direction = aimAssist.leadShot(agent.target, agent.gun.bulletSpeed)
			var target_distance = target_vector.length()
			var aim_vector = agent.global_position + (gun_direction * target_distance)
			if gun_direction != Vector2.INF:
				agent.aimPosition = aim_vector
			elif target_distance > attackDistance:
				agent.aimPosition = agent.target.global_position
			if target_distance < attackDistance:
				agent.fire_gun()
			
		targetMovementAngle += delta
		targetAcquireTime += delta
		pidController.target_value = agent.target.global_position + Vector2(lerp(preferredDistance.x, preferredDistance.y, (sin(targetAcquireTime * 2 * PI)+1)/2), 0).rotated(targetMovementAngle)
		var thrust = thrustModifier * pidController.value_or(Vector2.ZERO)
		if thrust.length() < minThrust:
			thrust = Vector2.ZERO
		elif thrust.length() > maxThrust:
			thrust = thrust.normalized() * maxThrust
		if speedSoftCap > 0 && agent.linear_velocity.length() > speedSoftCap:
			for i in 2:
				if signf(thrust[i]) == signf(agent.linear_velocity[i]):
					thrust[i] = 0
		#print(agent.name, " | Target pos (relative): ", pidController.target_value - agent.global_position, "  PID: ", pidController.value_or(Vector2.ZERO), "  Thrust: ", thrust, " (magnitude:", thrust.length(), ")  Speed: ", agent.linear_velocity.length())
		agent.apply_force(thrust)

func _on_medium_agent_target_changed(new_target: Node2D) -> void:
	if new_target != null:
		targetMovementAngle = new_target.global_position.angle_to_point(agent.global_position)
		targetAcquireTime = 0
	else:
		targetMovementAngle = NAN
		targetAcquireTime = NAN
