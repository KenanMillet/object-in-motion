class_name Agent
extends RigidBody2D

signal died
signal health_changed(new_health: int)
signal target_changed(new_target: Node2D)

@export var hand: Marker2D
@export var shoulder: Marker2D
@export var throwChargeTime = 1.0
@export var minThrowImpulse = 50
@export var maxThrowImpulse = 250
@export var minThrowTorque = 10
@export var maxThrowTorque = 75
@export var enemyHitbox: CollisionShape2D = null
@export var playerHitbox: CollisionShape2D = null
@export var health: int = 12:
	get:
		return health
	set(value):
		health = value
		health_changed.emit(value)
@export var healthChunk: PackedScene
@export var maxFocusTime: float = 2.0
@export var focusTimeScale: float = 0.2
@export var focusBar: Texture = null

var reloading: bool = false

var gun: Gun = null
var prevGunParent: Node = null
var target: RigidBody2D = null:
	get:
		return target
	set(value):
		target = value
		target_changed.emit(value)
var aimPosition: Vector2 = Vector2.INF
var controllingPlayer: Player = null

var throwMode: bool = false:
	get:
		return throwMode
	set(value):
		throwMode = value
		queue_redraw()
		if !value:
			stopChargingThrow()
var _throwChargingStart = null

var _impulses = []

func propel(impulse: Vector2, from: Vector2, torque: float = 0) -> void:
	_impulses.append([impulse, from, torque])

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
	reloading = false

func releaseGun() -> void:
	var old_gun = gun
	controllingPlayer = null
	gun.detach()
	gun.reparent.call_deferred(prevGunParent)
	gun.needs_reload.disconnect(_reload_gun)
	gun.bullet_fired.disconnect(_on_bullet_fired)
	gun = null
	prevGunParent = null
	reloading = false
	await get_tree().create_timer(1).timeout 
	remove_collision_exception_with(old_gun)

func startChargingThrow() -> void:
	_throwChargingStart = Time.get_ticks_msec()

func stopChargingThrow() -> void:
	_throwChargingStart = null

func throwPower() -> float:
	return clamp((Time.get_ticks_msec() - _throwChargingStart)/(throwChargeTime*1000.0), 0.0, 1.0) if _throwChargingStart != null else 0.0

func throwGun() -> void:
	if (_throwChargingStart == null || !throwMode):
		return
	var power = throwPower()
	var impulse = lerpf(minThrowImpulse, maxThrowImpulse, power)
	var torque = lerpf(minThrowTorque, maxThrowTorque, power)
	gun.thrownBy = self
	gun.propel(Vector2(impulse, 0).rotated(gun.global_rotation), shoulder.global_position - gun.global_position, torque)
	releaseGun()
	throwMode = false

func damage(value: int) -> void:
	if controllingPlayer != null && controllingPlayer.godMode:
		return
	health = max(health - value, 0)
	queue_redraw()
	if health == 0:
		die()

func die() -> void:
	if gun != null:
		releaseGun()
	died.emit()
	enemyHitbox.set_deferred("disabled", true)
	playerHitbox.set_deferred("disabled", true)
	target = null

func _reload_gun(reload_time: float) -> void:
	if !reloading:
		reloading = true
		await get_tree().create_timer(reload_time).timeout
		reloading = false
		if gun != null:
			gun.reload()
	
func _on_bullet_fired(_bullet: Bullet, _pos: Vector2, muzzle_velocity: Vector2, _gun_velocity: Vector2) -> void:
	lock_rotation = true
	propel(Vector2.RIGHT.rotated(muzzle_velocity.angle() + PI) * gun.agentRecoil, shoulder.global_position - global_position)
	lock_rotation = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	collision_layer = CollisionUtil.Layer.agents | CollisionUtil.Layer.spawn_blocking_obj
	collision_mask |= CollisionUtil.Layer.objects
	enemyHitbox.set_deferred("disabled", false)
	playerHitbox.set_deferred("disabled", true)

func _on_player_control_target_changed(control_target: RigidBody2D, _player: Player) -> void:
	target = control_target if health > 0 else null

func _process(_delta: float) -> void:
	if throwMode:
		queue_redraw()

func _physics_process(_delta: float) -> void:
	if gun != null:
		if controllingPlayer != null:
			aimPosition = controllingPlayer.cursorPos.global_position
		if aimPosition != Vector2.INF:
			shoulder.look_at(aimPosition)
			gun.global_position = hand.global_position
			gun.look_at(aimPosition)
	for impulse in _impulses:
		apply_impulse(impulse[0], impulse[1])
		apply_torque_impulse(impulse[2])
	_impulses.clear()

func _draw() -> void:
	var tp = throwPower()
	var throwIndicatorLength = lerpf(minThrowImpulse, maxThrowImpulse, tp)
	if tp > 0 && gun != null:
		var endOfGun = gun.endOfGun.get_relative_transform_to_parent(self)
		draw_dashed_line(endOfGun.origin, endOfGun.origin + endOfGun.x * throwIndicatorLength, Color.ALICE_BLUE,  throwIndicatorLength / 100.0, maxThrowImpulse / 10.0)
