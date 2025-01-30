class_name Agent
extends RigidBody2D

signal died
signal health_changed(new_health: int)
signal target_changed(new_target: Node2D)

@export var hand: Marker2D
@export var shoulder: Marker2D
@export var throwImpulse = 250
@export var throwTorque = 75
@export_range(1, 360, 1, "or_greater", "suffix:°/s") var gunSpinOnDeath = 360
@export var enemyHitbox: CollisionShape2D = null
@export var playerHitbox: CollisionShape2D = null
@export var visionChecker: VisibleOnScreenNotifier2D
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

@onready var body: AnimatedSprite2D = $Body

var prefiring: bool = false
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

var _impulses = []

func propel(impulse: Vector2, from: Vector2, torque: float = 0) -> void:
	_impulses.append([impulse, from, torque])

func holdGun(newgun: Gun, parent: Node) -> void:
	gun = newgun
	gun.self_modulate.a = 1 if controllingPlayer != null else 0
	prevGunParent = parent
	add_collision_exception_with(gun)
	gun.attach(self)
	gun.global_position = hand.global_position
	gun.global_rotation = hand.global_rotation
	gun.reparent.call_deferred(hand)
	gun.needs_reload.connect(_reload_gun)
	gun.bullet_fired.connect(_on_bullet_fired)
	reloading = false

func releaseGun() -> void:
	var old_gun = gun
	gun.self_modulate.a = 1
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

func throwGun() -> void:
	if gun == null:
		return
	gun.thrownBy = self
	gun.propel(Vector2(throwImpulse, 0).rotated(gun.global_rotation), shoulder.global_position - gun.global_position, throwTorque)
	releaseGun()

func damage(value: int) -> void:
	if controllingPlayer != null && controllingPlayer.godMode:
		return
	health = max(health - value, 0)
	queue_redraw()
	if health == 0:
		die()

func die() -> void:
	if gun != null:
		gun.angular_velocity += deg_to_rad(gunSpinOnDeath)
		releaseGun()
	died.emit()
	enemyHitbox.set_deferred("disabled", true)
	playerHitbox.set_deferred("disabled", true)
	target = null
	body.play("death")

func fire_gun() -> bool:
	if gun != null && gun.can_fire():
		if body.sprite_frames.has_animation("pre_shoot"):
			prefiring = true
			body.play("pre_shoot")
			await body.animation_finished
			prefiring = false
	if gun != null && gun.fire():
		body.play("shoot")
		return true
	return false

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

func _on_animation_finished() -> void:
	if health > 0:
		body.play("default")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	collision_layer = CollisionUtil.Layer.agents | CollisionUtil.Layer.spawn_blocking_obj
	collision_mask |= CollisionUtil.Layer.objects
	enemyHitbox.set_deferred("disabled", false)
	playerHitbox.set_deferred("disabled", true)
	body.animation_finished.connect(_on_animation_finished)

func _on_player_control_target_changed(control_target: RigidBody2D, _player: Player) -> void:
	target = control_target if health > 0 else null

func _process(_delta: float) -> void:
	pass

func _physics_process(_delta: float) -> void:
	if gun != null:
		if controllingPlayer != null:
			aimPosition = controllingPlayer.cursorPos.global_position
			shoulder.look_at(aimPosition)
			gun.look_at(aimPosition)
		elif aimPosition != Vector2.INF:
			look_at(aimPosition)
			gun.look_at(aimPosition)
		gun.global_position = hand.global_position
	for impulse in _impulses:
		apply_impulse(impulse[0], impulse[1])
		apply_torque_impulse(impulse[2])
	_impulses.clear()
