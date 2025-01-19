class_name Player
extends Node

@export var focusTimeScale = 0.2
@export var maxFocusTime = 2.0
@export var startingGun: PackedScene
@export var startingAgent: PackedScene
@export var instanceManager: InstanceManager
@export var camera: Camera2D
@export var cameraMount: Node2D
@export var cursorPos: Node2D
@export var targetPos: Node2D
@export var controlCooldown = 0.5

var gun: Gun = null
var agent: Agent = null

var forceFocus = false
var controlDowntime = 0
@onready var focusTime = maxFocusTime

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
	newAgent.target = cursorPos
	if agent != null:
		agent.enemyHitbox.set_deferred("disabled", false)
		agent.playerHitbox.set_deferred("disabled", true)
		agent.target = targetPos
		agent.controllingPlayer = null
		agent.died.disconnect(_on_agent_death)
	newAgent.enemyHitbox.set_deferred("disabled", true)
	newAgent.playerHitbox.set_deferred("disabled", false)
	newAgent.died.connect(_on_agent_death)
	newAgent.controllingPlayer = self
	agent = newAgent
	if newGun != null:
		controlGun(newGun)
	controlDowntime = controlCooldown

func controlGun(newGun: Gun) -> void:
	if gun != null:
		gun.body_entered.disconnect(_on_gun_contact)
		gun.body_exited.disconnect(_on_gun_contact)
		gun.thrownBy = null
		if agent != null && agent.gun == gun:
			agent.releaseGun()
	newGun.body_entered.connect(_on_gun_contact)
	newGun.body_exited.connect(_on_gun_contact)
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
		Engine.time_scale = focusTimeScale
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
			agent.died.disconnect(_on_agent_death)
			agent.target = targetPos
			agent = null


func _on_agent_death() -> void:
	agent.died.disconnect(_on_agent_death)
	agent.target = null
	agent = null
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
