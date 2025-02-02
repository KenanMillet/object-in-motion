class_name Player
extends Node

signal agent_changed(new_agent: Agent, old_agent: Agent)
signal gun_changed(new_gun: Gun, old_gun: Gun)
signal focus_changed(percent_remaining: float)
signal gun_max_focus_changed(percent_remaining: float)
signal control_target_changed(target: RigidBody2D, player: Player)
signal game_over()

@export var startingAgent: PackedScene
@export var startingGun: PackedScene
@export var camera: Camera2D
@export var refSpeed: float = 1000
@export var stationaryZoom: float = 1.5
@export var refSpeedZoom: float = 1
@export var zoomSpeed: float = 0.01
@export var cameraMount: Node2D
@export var cursorPos: Node2D
@export var controlCooldown: float = 3
@export var spaceGunRpmMult: float = 1.5
@export var throwGracePeriod: float = 1
@export var gunStartingFocusTime: float = 6
@export var gunFocusTimeScale: float = 0.1
@export var gunTetherTimeScale: float = 0.6
@export var gunTetherAnglePID: PID
@export var gunTetherMovePID: PID
@export var gunTetherArea: Area2D
@export var focusPrecisionMult: float = 1.5
@export var godMode: bool = false

var levelBounds: CollisionObject2D

var target_zoom: Vector2

var agent_on_prev_frame: Agent = null
var agent: Agent = null:
	get:
		return agent
	set(value):
		var prev_agent = agent
		agent = value
		if prev_agent != value:
			agent_changed.emit(value, prev_agent)
			control_target_changed.emit((value as RigidBody2D) if value != null else (gun as RigidBody2D), self)
var gun: Gun = null:
	get:
		return gun
	set(value):
		var prev_gun = gun
		gun = value
		if prev_gun != value:
			gun_changed.emit(value, prev_gun)
			if agent == null:
				control_target_changed.emit((value as RigidBody2D), self)

var gun_rpm_mult: float:
	get:
		return spaceGunRpmMult if agent == null else 1.0

var gun_angle_to_mouse: float:
	get:
		return 0.0 if Engine.is_editor_hint() || gun == null || camera == null else gun.get_angle_to(cursorPos.global_position)

@export_storage var gun_abs_angle_to_mouse: float:
	get:
		return absf(gun_angle_to_mouse)

@export_storage var gun_center_of_mass: Vector2:
	get:
		return gun.to_global(gun.center_of_mass) if gun != null else Vector2.ZERO

var controlDowntime = 0
var throwGraceTime = 0
var maxFocusTime: float:
	get:
		return agent.maxFocusTime if agent != null else gunMaxFocusTime
var maxFocusTimeForBar: float:
	get:
		return agent.maxFocusTime if agent != null else gunStartingFocusTime
var focusTimeScale: float:
	get:
		return agent.focusTimeScale if agent != null else gunFocusTimeScale
var focusTime: float = 0:
	get:
		return focusTime
	set(value):
		if focusTime == value:
			return
		focusTime = value
		focus_changed.emit(focusTime/maxFocusTimeForBar if !is_inf(maxFocusTimeForBar) else 1.0)
@onready var gunMaxFocusTime: float = gunStartingFocusTime:
	get:
		return gunMaxFocusTime
	set(value):
		if gunMaxFocusTime == value:
			return
		gunMaxFocusTime = value
		gun_max_focus_changed.emit(gunMaxFocusTime/gunStartingFocusTime if !is_inf(gunStartingFocusTime) else 1.0)

@onready var _debugCanvas = DebugCanvas.locate(self)

var focusing: bool = false

var cameraTarget: RigidBody2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camera.reparent.call_deferred(cameraMount)
	_debugCanvas.draw.connect(_draw_on_canvas.bind(_debugCanvas))

func controlAgent(newAgent: Agent, newGun: Gun) -> Agent:
	if agent == newAgent:
		if newGun != null:
			controlGun(newGun)
		return agent
	var old_agent = agent
	if agent != null:
		agent.enemyHitbox.set_deferred("disabled", false)
		agent.playerHitbox.set_deferred("disabled", true)
		agent.controllingPlayer = null
		if agent.gun != null:
			agent.gun.self_modulate.a = 0
		agent.add_collision_exception_with(levelBounds)
		if agent.died.is_connected(_on_agent_death):
			agent.died.disconnect(_on_agent_death)
	if newAgent != null:
		newAgent.enemyHitbox.set_deferred("disabled", true)
		newAgent.playerHitbox.set_deferred("disabled", false)
		newAgent.died.connect(_on_agent_death)
		newAgent.controllingPlayer = self
		if newAgent.gun != null:
			newAgent.gun.self_modulate.a = 1
		newAgent.remove_collision_exception_with(levelBounds)
	agent = newAgent
	focusTime = agent.maxFocusTime if agent != null else gunMaxFocusTime
	if newAgent != null && old_agent != null:
		controlDowntime = controlCooldown
	if newGun != null:
		controlGun(newGun)
	return old_agent

func controlGun(newGun: Gun) -> void:
	if newGun == gun:
		return
	var old_gun = gun
	if gun != null:
		gun.body_entered.disconnect(_on_gun_contact)
		gun.body_exited.disconnect(_on_gun_break_contact)
		gun.thrownBy = null
		gun.controllingPlayer = null
		gun.self_modulate.a = 1
		gun.add_collision_exception_with(levelBounds)
		if agent != null && agent.gun == gun:
			agent.releaseGun()
			agent.controllingPlayer = self
	if newGun != null:
		newGun.body_entered.connect(_on_gun_contact)
		newGun.body_exited.connect(_on_gun_break_contact)
		newGun.controllingPlayer = self
		newGun.remove_collision_exception_with(levelBounds)
	if agent != null && agent.gun != newGun:
		if newGun != null:
			if gun != null:
				gun.global_position = newGun.global_position
			agent.holdGun(newGun, newGun.get_parent())
		else:
			agent.holdGun(null, null)
	gun = newGun
	if newGun != null && old_gun != null:
		controlDowntime = controlCooldown

func _is_closer(ref_pos: Vector2, closest: Node2D, next: Node2D) -> Node2D:
	var closest_dist = closest.global_position.distance_squared_to(ref_pos)
	var next_dist = next.global_position.distance_squared_to(ref_pos)
	return closest if closest_dist < next_dist else next

func _closest_if(options: Array[Node2D], ref_pos: Vector2, predicate: Callable) -> Node2D:
	return options.filter(predicate).reduce(_is_closer.bind(ref_pos))

func _closest_living_agent(options: Array[Node2D], ref_pos: Vector2) -> Agent:
	return _closest_if(options, ref_pos, func(opt): return opt is Agent && opt.health > 0 && opt != gun.thrownBy) as Agent

func _closest_loaded_gun(options: Array[Node2D], ref_pos: Vector2) -> Gun:
	return _closest_if(options, ref_pos, func(opt): return opt is Gun && !opt.is_empty()) as Gun

var _closest_tether: Node2D = null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	cursorPos.global_position = camera.get_global_mouse_position()
	
	var bullet_fired = false

	if gun != null:
		cameraTarget = gun
		if Input.is_action_pressed("Fire"):
			bullet_fired = gun.fire()

	if agent != null:
		cameraTarget = agent
		if Input.is_action_just_pressed("Throw"):
			agent.throwGun()
			controlAgent(null, gun)
			throwGraceTime = throwGracePeriod + delta

	var tethering = (agent == null && focusing && gun != null)
	
	if tethering || bullet_fired || agent != null:
		throwGraceTime = 0

	cameraMount.global_position = cameraTarget.to_global(cameraTarget.center_of_mass)
	
	target_zoom = Vector2.ONE * lerpf(stationaryZoom, refSpeedZoom, cameraTarget.linear_velocity.length()/ refSpeed)
	
	var zoom_dir = Vector2(signf(target_zoom.x - camera.zoom.x), signf(target_zoom.y - camera.zoom.y))
	camera.zoom += zoom_dir * zoomSpeed * delta

	controlDowntime = max(controlDowntime - delta, 0)
	throwGraceTime = max(throwGraceTime - delta, 0)
	focusing = Input.is_action_pressed("Focus")
	Engine.time_scale = 1.0
	if focusTime > 0:
		if tethering:
			Engine.time_scale = gunTetherTimeScale
		elif agent == null:
			Engine.time_scale = gunFocusTimeScale
		elif focusing:
			Engine.time_scale = agent.focusTimeScale

	var focusDrainRate = gunFocusTimeScale / gunTetherTimeScale if tethering else (0.0 if throwGraceTime else 1.0)
	var newGunMaxFocusTime = gunMaxFocusTime
	var newFocusTime = focusTime

	_debugCanvas.queue_redraw()

	if tethering:
		gunTetherArea.process_mode = Node.PROCESS_MODE_INHERIT
		gunTetherArea.global_position = gun.global_position
		gunTetherAnglePID.target_value = 0
		
		if controlDowntime == 0:
			var tetherables: Array[Node2D] = gunTetherArea.get_overlapping_bodies()
			var ref_pos: Vector2 = gun_center_of_mass
			_closest_tether = _closest_living_agent(tetherables, ref_pos)
			if _closest_tether == null:
				_closest_tether = _closest_loaded_gun(tetherables, ref_pos)
			if _closest_tether != null:
				gunTetherMovePID.target_value = _closest_tether.global_position
			else:
				gunTetherMovePID.target_value = null
		else:
			gunTetherMovePID.target_value = null

		var torque = gunTetherAnglePID.value_or(0.0)
		var force = gunTetherMovePID.value_or(Vector2.ZERO)
		gun.impart(force * gun.mass, Vector2.ZERO, torque * gun.inertia * -signf(gun_angle_to_mouse))
		if !Input.is_action_just_pressed("Focus"):
			newGunMaxFocusTime = max(gunMaxFocusTime - delta, 0)
	else:
		gunTetherAnglePID.target_value = null
		gunTetherMovePID.target_value = null
		gunTetherArea.process_mode = Node.PROCESS_MODE_DISABLED

	if (agent == null && agent_on_prev_frame == null) || (focusing && !Input.is_action_just_pressed("Focus")):
		newFocusTime = max(focusTime - (delta*focusDrainRate), 0)

	if bullet_fired && agent == null:
		newGunMaxFocusTime -= gun.focusDecayPerShot * gunStartingFocusTime

	gunMaxFocusTime = min(gunStartingFocusTime, newGunMaxFocusTime)
	focusTime = min(maxFocusTime, newFocusTime)
	
	if agent == null && focusTime == 0:
		controlGun(null)
		print("Game Over!")
		game_over.emit()
	
	agent_on_prev_frame = agent

func _on_agent_death() -> void:
	agent.died.disconnect(_on_agent_death)
	var old_agent = controlAgent(null, gun)
	old_agent.target = null

func _on_gun_contact(body: Node) -> void:
	if controlDowntime == 0:
		if body is Agent && body != gun.thrownBy:
			var a: Agent = body as Agent
			controlAgent(a, a.gun)
			if a.gun == null:
				a.holdGun(gun, gun.get_parent())
		elif body is Gun:
			var g: Gun = body as Gun
			if g.agent != null:
				controlAgent(g.agent, g)
			elif !g.is_empty():
				controlGun(g)

func _on_gun_break_contact(body: Node) -> void:
	if body is Agent && body == gun.thrownBy:
		await get_tree().create_timer(0.5).timeout
		if gun.thrownBy == body:
			gun.thrownBy = null

func _draw_on_canvas(canvas: DebugCanvas):
	if agent == null && focusing && gun != null && controlDowntime == 0:
		var color := Color(Color.WHITE, 0.25) if _closest_tether != null else Color(Color.RED, 0.1)
		canvas.draw_circle(gunTetherArea.global_position, gunTetherArea.get_child(0).shape.radius, color)
