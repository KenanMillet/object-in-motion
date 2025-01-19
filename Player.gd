class_name Player
extends Node

@export var focusTimeScale = 0.2
@export var startingGun: PackedScene
@export var startingAgent: PackedScene
@export var instanceManager: InstanceManager
@export var camera: Camera2D
@export var cameraMount: Node2D
@export var cursorPos: Node2D

var gun: Gun = null
var agent: Agent = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var newAgent = startingAgent.instantiate()
	var newGun = startingGun.instantiate()
	instanceManager.spawnAgent(newAgent, get_viewport().size/2, newGun)
	controlAgent(newAgent, newGun)
	camera.reparent(cameraMount)

func controlAgent(newAgent: Agent, newGun: Gun) -> void:
	newAgent.target = cursorPos
	if agent != null:
		agent.target = newAgent
	agent = newAgent
	gun = newGun
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	cursorPos.global_position = camera.get_global_mouse_position()
	if agent != null:
		if Input.is_action_just_pressed("Plan"):
			agent.die()
	if gun != null:
		cameraMount.global_position = gun.global_position
		if Input.is_action_pressed("Fire"):
			gun.fire()
	if Input.is_action_pressed("Focus"):
		Engine.time_scale = focusTimeScale
	else:
		Engine.time_scale = 1.0
