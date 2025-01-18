class_name Gun
extends RigidBody2D

signal bullet_fired(bullet: Bullet, position: Vector2, muzzle_velocity: Vector2, gun_velocity: Vector2)

@export var recoil = 1
@export var rpm = 60
@export var bullet: PackedScene
@export var bulletSpeed = 100
@export var magSize = 10

@onready var _rounds = magSize
@onready var _endOfGun = $EndOfGun

var _cooldown = 0

func fire() -> void:
	if _cooldown != 0:
		return
	if _rounds > 0 || magSize == 0:
		var b: Bullet = bullet.instantiate()
		_rounds-=1
		_cooldown = 60.0/rpm
		bullet_fired.emit(b,_endOfGun.global_position, Vector2(bulletSpeed, 0).rotated(global_rotation), linear_velocity)
	else:
		print("click...")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_cooldown = max(0.0, _cooldown - delta)
