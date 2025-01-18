class_name InstanceManager
extends Node

@export var defaultSpawnLoc: Marker2D = null

func _default_spawn_pos() -> Vector2:
	if defaultSpawnLoc != null:
		return defaultSpawnLoc.global_position
	else:
		return Vector2.ZERO

func spawnAgent(agent: Agent, pos: Vector2 = _default_spawn_pos(), gun: Gun = null) -> void:
	agent.global_position = pos
	add_child(agent)
	if gun != null:
		spawnGun(gun)
	agent.holdGun(gun, self)

func spawnGun(gun: Gun, pos: Vector2 = _default_spawn_pos()) -> void:
	gun.global_position = pos
	if !gun.bullet_fired.is_connected(_fire_bullet):
		gun.bullet_fired.connect(_fire_bullet)
	add_child(gun)


func _fire_bullet(bullet: Bullet, pos: Vector2, muzzle_velocity: Vector2, gun_velocity: Vector2) -> void:
	bullet.global_position = pos
	bullet.rotation = muzzle_velocity.angle()
	bullet.linear_velocity = muzzle_velocity + gun_velocity
	add_child(bullet)
