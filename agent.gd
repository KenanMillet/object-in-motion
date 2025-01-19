class_name Agent
extends RigidBody2D

signal died

@export var hand: Marker2D
@export var shoulder: Marker2D

var gun: Gun = null
var prevGunParent: Node = null
var target: Node2D = null
var controllingPlayer: Player = null

var _impulses = []

func holdGun(newgun: Gun, parent: Node) -> void:
	gun = newgun
	prevGunParent = parent
	add_collision_exception_with(gun)
	gun.attach(self)
	gun.global_position = hand.global_position
	gun.global_rotation = hand.global_rotation
	gun.reparent(hand)
	gun.needs_reload.connect(_reload_gun)
	gun.bullet_fired.connect(_on_bullet_fired)

func releaseGun() -> void:
	remove_collision_exception_with(gun)
	gun.detach()
	gun.reparent(prevGunParent)
	gun.needs_reload.disconnect(_reload_gun)
	gun.bullet_fired.disconnect(_on_bullet_fired)
	gun = null
	prevGunParent = null

func die() -> void:
	releaseGun()
	died.emit()
	$CollisionShape2D.set_deferred("disabled", true)

func _reload_gun() -> void:
	gun.reload()
	
func _on_bullet_fired(_bullet: Bullet, pos: Vector2, muzzle_velocity: Vector2, _gun_velocity: Vector2) -> void:
	lock_rotation = true
	_impulses.append([Vector2.RIGHT.rotated(muzzle_velocity.angle() + PI) * gun.recoil, pos])
	lock_rotation = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	collision_layer = 0b0010 # agents
	collision_mask |= 0b1111 # walls, agents, bullets, guns

func _physics_process(_delta: float) -> void:
	if gun != null:
		if target != null:
			shoulder.look_at(target.global_position)
			gun.look_at(target.global_position)
		gun.global_position = hand.global_position
	for impulse in _impulses:
		apply_impulse(impulse[0], impulse[1])
	_impulses.clear()
