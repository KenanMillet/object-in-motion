class_name Bullet
extends RigidBody2D

@export var damage = 1

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 10
	collision_layer = 0b0100 # bullets
	collision_mask = 0b0100 # bullets
