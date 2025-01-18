class_name Player
extends Node

@export var focusTimeScale = 0.2
@export var startingGun: PackedScene
@export var startingAgent: PackedScene
@export var instanceManager: InstanceManager
@export var camera: Camera2D
@export var cameraMount: Node2D
var gun: Gun = null
var agent: Agent = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	agent = startingAgent.instantiate() as Agent
	gun = startingGun.instantiate() as Gun
	instanceManager.spawnAgent(agent, get_viewport().size/2, gun)
	camera.reparent(cameraMount)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if agent != null:
		agent.target = camera.get_global_mouse_position()
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
