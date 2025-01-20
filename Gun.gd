class_name Gun
extends RigidBody2D

signal bullet_fired(bullet: Bullet, pos: Vector2, muzzle_velocity: Vector2, gun_velocity: Vector2)
signal needs_reload

@export var bullet: PackedScene
@export var bulletSpeed = 500
@export var recoil = 100
@export var agentRecoil = 5000
@export var rpm = 120
@export var enemyRpm = 90
@export var reloadTime = 1.5
@export var enemyReloadTime = 3.0
@export var magSize = 10
@export var endOfGun: Marker2D = null
@export var customCenterOfMass: Marker2D = null

@onready var _rounds = magSize

var agent: Agent = null

var thrownBy: Agent = null

var _cooldown = 0

var _impulses = []

func is_empty():
	return _rounds == 0 && magSize != 0

func propel(impulse: Vector2, from: Vector2, torque: float = 0) -> void:
	_impulses.append([impulse, from, torque])

func attach(newAgent: Agent) -> void:
	agent = newAgent

func detach() -> void:
	linear_velocity = agent.linear_velocity
	agent = null

func fire() -> void:
	if _cooldown != 0:
		return
	if !is_empty():
		var b: Bullet = bullet.instantiate()
		var is_player = (agent == null || agent.controllingPlayer != null)
		b.enemyHurtBox.set_deferred("disabled", !is_player)
		b.playerHurtBox.set_deferred("disabled", is_player)
		_rounds-=1
		if !is_empty():
			_cooldown = 60.0/rpm
		var vel = linear_velocity if agent == null else agent.linear_velocity
		bullet_fired.emit(b,endOfGun.global_position, Vector2(bulletSpeed, 0).rotated(endOfGun.global_rotation), vel)
		add_collision_exception_with(b)
		if agent == null:
			propel(Vector2(recoil, 0).rotated(global_rotation + PI), endOfGun.global_position - global_position)
		else:
			b.add_collision_exception_with(agent)
	else:
		needs_reload.emit()
		
func reload() -> void:
	_cooldown = reloadTime
	_rounds = magSize

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 10
	collision_layer = 0b1000 # guns
	collision_mask |= 0b1111 # walls, agents, bullets, guns
	if customCenterOfMass != null:
		center_of_mass_mode = CENTER_OF_MASS_MODE_CUSTOM
		center_of_mass = customCenterOfMass.position
	else:
		center_of_mass_mode = CENTER_OF_MASS_MODE_AUTO

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_cooldown = max(0.0, _cooldown - delta)

func _physics_process(_delta: float) -> void:
	for impulse in _impulses:
		apply_impulse(impulse[0], impulse[1])
		apply_torque_impulse(impulse[2])
	_impulses.clear()
