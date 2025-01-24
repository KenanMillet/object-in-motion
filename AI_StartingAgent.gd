extends Node

@export var teleportCooldown: float = 6
@export var teleportRecoveryTime: Vector2
@export var preferredDistance: Vector2
@export var agent: Agent

@onready var recoveringFromTeleport: bool = false

@onready var _debugCanvas = DebugCanvas.locate(agent)
@onready var aimAssist = AimAssist.new(agent)

func teleport() -> void:
	if agent.controllingPlayer == null && agent.target != null:
		recoveringFromTeleport = true
		var tele_loc = agent.target.global_position + Vector2(randf_range(preferredDistance.x, preferredDistance.y), 0).rotated(randf_range(0, 2*PI))
		agent.linear_velocity = Vector2.ZERO
		agent.angular_velocity = 0
		agent.global_position = tele_loc
		var recovery_time = randf_range(teleportRecoveryTime.x, teleportRecoveryTime.y)
		await get_tree().create_timer(recovery_time).timeout
		recoveringFromTeleport = false
		await get_tree().create_timer(teleportCooldown-recovery_time).timeout
		call_deferred("teleport")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#aimAssist.debug_aim.connect(AimAssist.DebugPrint(agent.name))
	aimAssist.debug_aim.connect(AimAssist.DebugDraw(_debugCanvas, 5, Color.from_hsv(randf(), 1, 1, 0.75), true, 2))
	call_deferred("teleport")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	if agent.controllingPlayer == null && agent.target != null && agent.gun != null:
		var gun_dist_sq = agent.global_position.distance_squared_to(agent.gun.global_position)
		var gun_direction = aimAssist.leadShot(agent.target, agent.gun.bulletSpeed)
		if gun_direction != Vector2.INF:
			agent.aimPosition = agent.global_position + (gun_direction * gun_dist_sq)
		agent.look_at(agent.target.global_position)
		if !recoveringFromTeleport:
			agent.gun.fire()
