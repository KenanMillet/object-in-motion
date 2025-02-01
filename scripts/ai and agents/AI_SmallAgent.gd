extends Node

@export var idleTime: Vector2
@export var idleTransitionTime: float = 1
@export var idleDistance: Vector2
@export var attackDistance: float
@export var personalSpace: float
@export var agent: Agent
@export var pidController: PID
@export var thrustModifier: float
@export var maxThrustTowardPlayer: float
@export var maxThrustAwayFromPlayer: float
@export var minThrust: float
@export var speedSoftCap: float = 0

@onready var _debugCanvas = DebugCanvas.locate(agent)
@onready var aimAssist = AimAssist.new(agent)


var idling: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#aimAssist.debug_aim.connect(AimAssist.DebugPrint(agent.name))
	aimAssist.debug_aim.connect(AimAssist.DebugDraw(_debugCanvas, 20, Color.from_hsv(randf(), 1, 1, 0.75), false, 2))

func _go_idle() -> void:
	idling = true
	pidController.target_value = null
	await get_tree().create_timer(idleTransitionTime).timeout
	if agent.target != null:
		pidController.target_value = Vector2(randf_range(idleDistance.x, idleDistance.y), 0).rotated(agent.target.global_position.angle_to(agent.global_position) + randf_range(-PI/8, PI/8))
	var idle_time = randf_range(idleTime.x, idleTime.y)
	if agent.gun != null:
		idle_time = max(idle_time, 60.0/agent.gun.enemyRpm)
	await get_tree().create_timer(idle_time).timeout
	idling = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	if agent.controllingPlayer == null && agent.target != null:
		if agent.gun == null:
			agent.aimPosition = agent.target.global_position
		else:
			var target_vector = agent.target.global_position - agent.global_position
			var gun_direction = aimAssist.leadShot(agent.target, agent.gun.bulletSpeed)
			var target_distance = target_vector.length()
			var aim_vector = agent.global_position + (gun_direction * target_distance)
			if gun_direction != Vector2.INF && target_vector.dot(aim_vector) > 0:
				agent.aimPosition = aim_vector
			elif target_distance > attackDistance && !agent.prefiring:
				agent.aimPosition = agent.target.global_position
			if target_distance < attackDistance && !agent.prefiring:
				if agent.gun.can_fire():
					pidController.target_value = null
					agent.fire_gun()
					_go_idle()
		if !idling && !agent.reloading && agent.target != null:
			pidController.target_value = agent.target.global_position + (agent.global_position - agent.target.global_position).normalized() * personalSpace
		var thrust = thrustModifier * pidController.value_or(Vector2.ZERO)
		var maxThrust = maxThrustAwayFromPlayer
		if agent.linear_velocity.dot(agent.target.global_position - agent.global_position) >= 0 && thrust.dot(agent.target.global_position - agent.global_position) >= 0:
			maxThrust = maxThrustTowardPlayer
		if thrust.length() < minThrust:
			thrust = Vector2.ZERO
		elif thrust.length() > maxThrust:
			thrust = thrust.normalized() * maxThrust
		if speedSoftCap > 0 && agent.linear_velocity.length() > speedSoftCap:
			for i in 2:
				if signf(thrust[i]) == signf(agent.linear_velocity[i]):
					thrust[i] = 0
		#print(agent.name, " | Target pos (absolute): ", pidController.target_value, "  (relative): ", pidController.target_value - agent.global_position, "  PID: ", pidController.value_or(Vector2.ZERO), "  Thrust: ", thrust, " (magnitude:", thrust.length(), ")  Speed: ", agent.linear_velocity.length())
		agent.apply_force(thrust)
