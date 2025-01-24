class_name Player
extends Node

signal agent_changed(new_agent: Agent, old_agent: Agent)
signal gun_changed(new_gun: Gun, old_gun: Gun)
signal focus_changed(percent_remaining: float)
signal control_target_changed(target: RigidBody2D, player: Player)

@export var startingAgent: PackedScene
@export var startingGun: PackedScene
@export var camera: Camera2D
@export var cameraMount: Node2D
@export var cursorPos: Node2D
@export var controlCooldown: float = 3
@export var gunMaxFocusTime: float = 6
@export var gunFocusTimeScale: float = 0.1
@export var godMode: bool = false

var levelBounds: CollisionObject2D

var agent: Agent = null:
	get:
		return agent
	set(value):
		var old_agent = agent
		agent = value
		agent_changed.emit(value, old_agent)
		if old_agent != value:
			control_target_changed.emit((value as RigidBody2D) if value != null else (gun as RigidBody2D), self)
var gun: Gun = null:
	get:
		return gun
	set(value):
		var old_gun = gun
		gun = value
		gun_changed.emit(value, old_gun)
		if old_gun != value && agent == null:
			control_target_changed.emit(value, self)

var focusIsForced: bool:
	get:
		return agent == null
var controlDowntime = 0
var maxFocusTime: float:
	get:
		return agent.maxFocusTime if agent != null else gunMaxFocusTime
var focusTimeScale: float:
	get:
		return agent.focusTimeScale if agent != null else gunFocusTimeScale
var focusTime: float = 0:
	get:
		return focusTime
	set(value):
		focusTime = value
		focus_changed.emit(focusTime/maxFocusTime if !is_inf(maxFocusTime) else 1.0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camera.reparent.call_deferred(cameraMount)

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
		agent.add_collision_exception_with(levelBounds)
		if agent.died.is_connected(_on_agent_death):
			agent.died.disconnect(_on_agent_death)
	if newAgent != null:
		newAgent.enemyHitbox.set_deferred("disabled", true)
		newAgent.playerHitbox.set_deferred("disabled", false)
		newAgent.died.connect(_on_agent_death)
		newAgent.controllingPlayer = self
		newAgent.remove_collision_exception_with(levelBounds)
	agent = newAgent
	focusTime = maxFocusTime
	controlDowntime = controlCooldown
	if newGun != null:
		controlGun(newGun)
	return old_agent

func controlGun(newGun: Gun) -> void:
	if newGun == gun:
		return
	if gun != null:
		gun.body_entered.disconnect(_on_gun_contact)
		gun.body_exited.disconnect(_on_gun_break_contact)
		gun.thrownBy = null
		gun.controllingPlayer = self
		gun.add_collision_exception_with(levelBounds)
		if agent != null && agent.gun == gun:
			agent.releaseGun()
	newGun.body_entered.connect(_on_gun_contact)
	newGun.body_exited.connect(_on_gun_break_contact)
	newGun.controllingPlayer = self
	newGun.remove_collision_exception_with(levelBounds)
	if agent != null && agent.gun != newGun:
		gun.global_position = newGun.global_position
		agent.holdGun(newGun, newGun.get_parent())
	gun = newGun
	controlDowntime = controlCooldown

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	cursorPos.global_position = camera.get_global_mouse_position()

	controlDowntime = max(controlDowntime - delta, 0)
	if Input.is_action_pressed("Focus") || focusIsForced:
		if Input.is_action_pressed("Focus") && focusIsForced:
			Engine.time_scale = 0.4
		else:
			Engine.time_scale = focusTimeScale if focusTime > 0 else 1.0
		if !Input.is_action_just_pressed("Focus"):
			focusTime = max(focusTime - delta, 0)
	else:
		Engine.time_scale = 1.0

	if gun != null:
		cameraMount.global_position = gun.customCenterOfMass.global_position if gun.customCenterOfMass != null else gun.global_position
		if Input.is_action_pressed("Fire") && (agent == null || !agent.throwMode):
			gun.fire()

	if agent != null:
		cameraMount.global_position = agent.global_position
		if Input.is_action_just_pressed("ToggleThrow"):
			agent.throwMode = !agent.throwMode
		if Input.is_action_just_pressed("Fire") && agent.throwMode:
			agent.startChargingThrow()
		if Input.is_action_just_released("Fire") && agent.throwMode:
			agent.throwGun()
			controlAgent(null, gun)

func _on_agent_death() -> void:
	agent.died.disconnect(_on_agent_death)
	var old_agent = controlAgent(null, gun)
	old_agent.target = null

func _on_gun_contact(body: Node) -> void:
	if controlDowntime == 0:
		if body is Agent && body != gun.thrownBy:
			var a: Agent = body as Agent
			controlAgent(a, a.gun)
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
