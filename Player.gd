class_name Player
extends Node

signal agent_changed(new_agent: Agent, old_agent: Agent)
signal gun_changed(new_gun: Gun, old_gun: Gun)
signal focus_changed(percent_remaining: float)

@export var startingGun: PackedScene
@export var startingAgent: PackedScene
@export var instanceManager: InstanceManager
@export var camera: Camera2D
@export var cameraMount: Node2D
@export var cursorPos: Node2D
@export var targetPos: Node2D
@export var controlCooldown: float = 0.5
@export var spaceMaxFocusTime: float = INF
@export var spaceFocusTimeScale: float = 0.1

var gun: Gun = null:
	get:
		return gun
	set(value):
		var old_gun = gun
		gun = value
		gun_changed.emit(value, old_gun)
var agent: Agent = null:
	get:
		return agent
	set(value):
		var old_agent = agent
		agent = value
		agent_changed.emit(value, old_agent)

var forceFocus = false
var controlDowntime = 0
var maxFocusTime: float:
	get:
		return agent.maxFocusTime if agent != null else spaceMaxFocusTime
var focusTimeScale: float:
	get:
		return agent.focusTimeScale if agent != null else spaceFocusTimeScale
var focusTime: float = 0:
	get:
		return focusTime
	set(value):
		focusTime = value
		focus_changed.emit(focusTime/maxFocusTime if !is_inf(maxFocusTime) else 1.0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var newAgent = startingAgent.instantiate()
	var newGun = startingGun.instantiate()
	instanceManager.spawnAgent(newAgent, get_viewport().size/2, newGun, cursorPos)
	controlAgent(newAgent, newGun)
	camera.reparent(cameraMount)
	
	var secondGun = startingGun.instantiate()
	instanceManager.spawnGun(secondGun, get_viewport().size/2 + Vector2i(100, 0))

func controlAgent(newAgent: Agent, newGun: Gun) -> void:
	if agent != null:
		agent.enemyHitbox.set_deferred("disabled", false)
		agent.playerHitbox.set_deferred("disabled", true)
		if agent.target != null:
			agent.target = targetPos
		agent.controllingPlayer = null
		agent.died.disconnect(_on_agent_death)
	if newAgent != null:
		newAgent.target = cursorPos
		newAgent.enemyHitbox.set_deferred("disabled", true)
		newAgent.playerHitbox.set_deferred("disabled", false)
		newAgent.died.connect(_on_agent_death)
		newAgent.controllingPlayer = self
	agent = newAgent
	focusTime = maxFocusTime
	controlDowntime = controlCooldown
	if newGun != null:
		controlGun(newGun)

func controlGun(newGun: Gun) -> void:
	if gun != null:
		gun.body_entered.disconnect(_on_gun_contact)
		gun.body_exited.disconnect(_on_gun_break_contact)
		gun.thrownBy = null
		if agent != null && agent.gun == gun:
			agent.releaseGun()
	newGun.body_entered.connect(_on_gun_contact)
	newGun.body_exited.connect(_on_gun_break_contact)
	if agent != null && agent.gun != newGun:
		gun.global_position = newGun.global_position
		agent.holdGun(newGun, newGun.get_parent())
	gun = newGun
	controlDowntime = controlCooldown

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	cursorPos.global_position = camera.get_global_mouse_position()
	if Input.is_action_just_released("Focus"):
		forceFocus = false

	controlDowntime = max(controlDowntime - delta, 0)
	if Input.is_action_pressed("Focus") || forceFocus:
		Engine.time_scale = focusTimeScale if focusTime > 0 else 1.0
		if !Input.is_action_just_pressed("Focus"):
			focusTime = max(focusTime - delta, 0)
	else:
		Engine.time_scale = 1.0

	if gun != null:
		targetPos.global_position = gun.global_position
		cameraMount.global_position = gun.global_position
		if Input.is_action_pressed("Fire") && (agent == null || !agent.throwMode):
			gun.fire()

	if agent != null:
		targetPos.global_position = agent.global_position
		if Input.is_action_just_pressed("ToggleThrow"):
			agent.throwMode = !agent.throwMode
		if Input.is_action_just_pressed("Fire") && agent.throwMode:
			agent.startChargingThrow()
		if Input.is_action_just_released("Fire") && agent.throwMode:
			agent.throwGun()
			controlAgent(null, gun)

func _on_agent_death() -> void:
	agent.died.disconnect(_on_agent_death)
	agent.target = null
	controlAgent(null, gun)
	forceFocus = true

func _on_gun_contact(body: Node) -> void:
	if controlDowntime == 0:
		if body is Agent && body != gun.thrownBy:
			var a: Agent = body as Agent
			controlAgent(a, a.gun)
		elif body is Gun:
			var g: Gun = body as Gun
			if !g.is_empty():
				if g.agent != null:
					controlAgent(g.agent, g)
				else:
					controlGun(g)

func _on_gun_break_contact(body: Node) -> void:
	if body is Agent && body == gun.thrownBy:
		await get_tree().create_timer(0.5).timeout
		if gun.thrownBy == body:
			gun.thrownBy = null
