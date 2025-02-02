class_name Gun
extends RigidBody2D

signal bullet_fired(bullet: Bullet, pos: Vector2, muzzle_velocity: Vector2, gun_velocity: Vector2)
signal needs_reload(reload_time: float)
signal ammo_changed(new_ammo: int, ammo_chunk: PackedScene)

@export var bullet: PackedScene
@export var playerBulletSpeed = 650
@export var enemyBulletSpeed = 500
@export var gunRecoil: float = 200
@export var playerAgentRecoil: float = 5000
@export var enemyAgentRecoil: float = 2000
@export var playerRpm: int = 120
@export var enemyRpm: int = 90
@export var bulletsPerShot: int = 1
@export var focusDecayPerShot: float = 0.01
@export var playerPrecision: float = 1
@export var enemyPrecision: float = 1
@export var playerReloadTime: float = 1.5
@export var enemyReloadTime: float = 3.0
@export var magSize = 10
@export var ammoChunk: PackedScene
@export var endOfGun: Marker2D = null
@export var customCenterOfMass: Marker2D = null
@export var laserGuide: Line2D
@export var readyToFireLight: Node2D
@export var invalidTetherMod: Color = Color.WHITE * 0.4

@onready var ammo = magSize:
	get:
		return ammo
	set(value):
		ammo = value
		ammo_changed.emit(value, ammoChunk)

var controllingPlayer: Player = null

var bulletSpeed: float:
	get:
		return playerBulletSpeed if controllingPlayer != null else enemyBulletSpeed

var recoil: float:
	get:
		return gunRecoil/float(bulletsPerShot)

var agentRecoil: float:
	get:
		return (playerAgentRecoil if controllingPlayer != null else enemyAgentRecoil)/float(bulletsPerShot)

var rpm: int:
	get:
		return int(playerRpm * controllingPlayer.gun_rpm_mult) if controllingPlayer != null else enemyRpm

var reloadTime: float:
	get:
		return playerReloadTime if controllingPlayer != null else enemyReloadTime

var playerFocusPrecisionModifier: float:
	get:
		return controllingPlayer.focusPrecisionMult if controllingPlayer != null && controllingPlayer.focusing else 1.0

var precision: float:
	get:
		return (playerPrecision * playerFocusPrecisionModifier) if controllingPlayer != null else enemyPrecision

const spread_outlier_deg: float = 15.0

var agent: Agent = null

var thrownBy: Agent = null

var _cooldown = 0

func can_fire() -> bool:
	return _cooldown == 0 && !is_empty()

var _impulses = []
var _forces = []

func is_empty() -> bool:
	return ammo == 0 && magSize != 0

func propel(impulse: Vector2, from: Vector2, torque: float = 0) -> void:
	_impulses.append([impulse, from, torque])

func impart(force: Vector2, from: Vector2, torque: float = 0) -> void:
	_forces.append([force, from, torque])

func attach(newAgent: Agent) -> void:
	agent = newAgent

func detach() -> void:
	linear_velocity = agent.linear_velocity
	agent = null
	
func bulletDeviation() -> float:
	return deg_to_rad((randfn(0, 1.0/precision)/PI) * spread_outlier_deg)

func fire() -> bool:
	if _cooldown != 0:
		return false
	var had_ammo = !is_empty()
	if had_ammo:
		ammo-=1
		if !is_empty():
			_cooldown = 60.0/rpm

		var vel = linear_velocity if agent == null else agent.linear_velocity
		var bullets: Array[Bullet] = []
		for _b in bulletsPerShot:
			bullets.append(InstanceManager.instance(bullet))
		for i in bullets.size():
			for j in bullets.size():
				if i != j:
					bullets[i].add_collision_exception_with(bullets[j])
			var b: Bullet = bullets[i]
			b.enemyHurtBox.set_deferred("disabled", controllingPlayer == null)
			b.playerHurtBox.set_deferred("disabled", controllingPlayer != null)
			b.firedFromPlayer = controllingPlayer
			var deviation: float = bulletDeviation()
			bullet_fired.emit(b,endOfGun.global_position, Vector2(bulletSpeed, 0).rotated(endOfGun.global_rotation + deviation), vel)
			add_collision_exception_with(b)
			if agent == null:
				propel(Vector2(recoil, 0).rotated(global_rotation + PI + deviation), endOfGun.global_position - global_position)
			else:
				b.add_collision_exception_with(agent)
		if is_empty():
			needs_reload.emit(reloadTime)
	else:
		needs_reload.emit(reloadTime)
	return had_ammo

func reload() -> void:
	ammo = magSize

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 10
	#collision_layer = CollisionUtil.Layer.guns | CollisionUtil.Layer.spawn_blocking_obj
	collision_layer = CollisionUtil.Layer.guns
	collision_mask |= CollisionUtil.Layer.objects
	if customCenterOfMass != null:
		center_of_mass_mode = CENTER_OF_MASS_MODE_CUSTOM
		center_of_mass = customCenterOfMass.position
	else:
		center_of_mass_mode = CENTER_OF_MASS_MODE_AUTO

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_cooldown = max(0.0, _cooldown - delta)
	laserGuide.points[1].x = minf(100, 50*precision/playerFocusPrecisionModifier) * pow(playerFocusPrecisionModifier, 3)
	laserGuide.visible = !is_empty()
	modulate = invalidTetherMod if agent == null && is_empty() && controllingPlayer == null else Color.WHITE
	readyToFireLight.visible = (!is_empty() && _cooldown == 0)

func _physics_process(_delta: float) -> void:
	for impulse in _impulses:
		apply_impulse(impulse[0], impulse[1])
		apply_torque_impulse(impulse[2])
	_impulses.clear()
	
	for force in _forces:
		apply_force(force[0], force[1])
		apply_torque(force[2])
	_forces.clear()
