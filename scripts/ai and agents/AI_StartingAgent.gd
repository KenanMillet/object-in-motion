extends Node

@export var teleportDuration: float = 0.5
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
		agent.linear_velocity = Vector2.ZERO
		agent.angular_velocity = 0
		if agent.gun != null:
			agent.gun.visible = false
		agent.body.play("teleport_out")
		await agent.body.animation_finished
		var prev_collision_layer = agent.collision_layer
		agent.collision_layer = CollisionUtil.Layer.spawn_blocking_obj
		agent.visible = false
		await get_tree().create_timer(teleportDuration).timeout
		var tele_loc = agent.global_position
		if agent.target != null:
			tele_loc = agent.target.global_position + Vector2(randf_range(preferredDistance.x, preferredDistance.y), 0).rotated(randf_range(0, 2*PI))
		agent.global_position = tele_loc
		agent.visible = true
		agent.body.play("teleport_in")
		await agent.body.animation_finished
		if agent.gun != null:
			agent.gun.visible = true
		agent.collision_layer = prev_collision_layer
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
		var target_vector = agent.target.global_position - agent.global_position
		var gun_direction = aimAssist.leadShot(agent.target, agent.gun.bulletSpeed)
		var target_distance = target_vector.length()
		var aim_vector = agent.global_position + (gun_direction * target_distance)
		if gun_direction != Vector2.INF:
			agent.aimPosition = aim_vector
		else:
			agent.aimPosition = agent.target.global_position
		if !recoveringFromTeleport:
			await agent.fire_gun()
