class_name Agent
extends RigidBody2D

@export var hand: Marker2D
@export var shoulder: Marker2D

@onready var _collider: = $CollisionShape2D

var gun: Gun = null
var prevGunParent: Node = null
var target: Node2D = null

func holdGun(newgun: Gun, parent: Node) -> void:
	gun = newgun
	prevGunParent = parent
	gun.global_position = hand.global_position
	gun.global_rotation = hand.global_rotation
	gun.reparent(hand)
	gun.attach(self)
	gun.needs_reload.connect(_reload_gun)
	gun.bullet_fired.connect(_on_bullet_fired)

func releaseGun() -> void:
	gun.reparent(prevGunParent)
	gun.detach()
	gun.needs_reload.disconnect(_reload_gun)
	gun.bullet_fired.disconnect(_on_bullet_fired)
	gun = null
	prevGunParent = null

func die() -> void:
	releaseGun()
	_collider.disabled = true

func _reload_gun() -> void:
	gun.reload()
	
func _on_bullet_fired(bullet: Bullet, pos: Vector2, muzzle_velocity: Vector2, gun_velocity: Vector2) -> void:
	lock_rotation = true
	apply_impulse(Vector2.RIGHT.rotated(muzzle_velocity.angle() + PI) * gun.recoil, pos)
	lock_rotation = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _physics_process(delta: float) -> void:
	if gun != null:
		if target != null:
			shoulder.look_at(target.global_position)
		gun.global_position = hand.global_position
