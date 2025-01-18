class_name Player
extends Node

signal swapGuns(player: Player, newGun: Gun, oldGun: Gun)

@export var focusTimeScale = 0.2
@export var startingGun: PackedScene
var gun: Gun = null

func takeGun(newGun: Gun) -> void:
	swapGuns.emit(self, newGun, gun)
	gun = newGun

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	takeGun(startingGun.instantiate())
	gun.global_position = get_viewport().size/2


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	gun.look_at(get_viewport().get_mouse_position())
	if Input.is_action_pressed("Fire"):
		gun.fire()
	if Input.is_action_pressed("Focus"):
		Engine.time_scale = focusTimeScale
		print("Focusing!")
	else:
		Engine.time_scale = 1.0
