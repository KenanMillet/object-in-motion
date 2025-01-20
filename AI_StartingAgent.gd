extends Node

@export var teleportCooldown: float = 6
@export var teleportRecoveryTime: Vector2
@export var preferredDistance: Vector2
@export var agent: Agent

var recoveringFromTeleport: bool = false

func teleport() -> void:
	if agent.controllingPlayer == null && agent.target != null:
		recoveringFromTeleport = true
		var tele_loc = agent.target.global_position + Vector2(randf_range(preferredDistance.x, preferredDistance.y), 0).rotated(randf_range(0, 2*PI))
		agent.linear_velocity = Vector2.ZERO
		agent.angular_velocity = 0
		agent.global_position = tele_loc
		agent.rotation = randf_range(0, 2*PI)
		var recovery_time = randf_range(teleportRecoveryTime.x, teleportRecoveryTime.y)
		await get_tree().create_timer(recovery_time).timeout
		recoveringFromTeleport = false
		await get_tree().create_timer(teleportCooldown-recovery_time).timeout
		call_deferred("teleport")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	teleport()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if agent.controllingPlayer == null && agent.target != null && agent.gun != null && !recoveringFromTeleport:
		agent.gun.fire()
