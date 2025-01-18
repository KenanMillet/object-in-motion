class_name Gun
extends RigidBody2D

signal bullet_fired(bullet: Bullet, pos: Vector2, muzzle_velocity: Vector2, gun_velocity: Vector2)
signal needs_reload

@export var bullet: PackedScene
@export var bulletSpeed = 500
@export var recoil = 10
@export var rpm = 60
@export var magSize = 10
@export var reloadTime = 1.5

@onready var _rounds = magSize
@onready var _endOfGun: Marker2D = $EndOfGun
@onready var _collider: = $CollisionPolygon2D

var agent: Agent = null

var _cooldown = 0

func attach(newAgent: Agent) -> void:
	agent = newAgent
	_collider.disabled = true

func detach() -> void:
	linear_velocity = agent.linear_velocity
	agent = null
	_collider.disabled = false

func fire() -> void:
	if _cooldown != 0:
		return
	if _rounds > 0 || magSize == 0:
		var b: Bullet = bullet.instantiate()
		_rounds-=1
		if _rounds != 0:
			_cooldown = 60.0/rpm
		var vel = linear_velocity if agent == null else agent.linear_velocity
		bullet_fired.emit(b,_endOfGun.global_position, Vector2(bulletSpeed, 0).rotated(_endOfGun.global_rotation), vel)
		if agent == null:
			apply_impulse(Vector2.RIGHT.rotated(global_rotation + PI) * recoil, _endOfGun.global_position)
	else:
		needs_reload.emit()
		
func reload() -> void:
	_cooldown = reloadTime
	_rounds = magSize

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	center_of_mass_mode = CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = $CenterOfMass.position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_cooldown = max(0.0, _cooldown - delta)
