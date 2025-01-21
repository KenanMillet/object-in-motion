class_name PID
extends Node

@export var proportionalWeight: Vector2 = 1.1 * Vector2.ONE
@export var integralWeight: Vector2 = 0.15 * Vector2.ONE
@export var derivativeWeight: Vector2 = -2 * Vector2.ONE
@export var refNode: Node2D

var target_position: Vector2 = Vector2.INF:
	get:
		return target_position
	set(value):
		if target_position == Vector2.INF && value != Vector2.INF:
			_last_position = refNode.global_position
			_cumulative_integral = Vector2.ZERO
			_derivative = Vector2.ZERO
		target_position = value

var value: Vector2:
	get:
		if target_position != Vector2.INF:
			var proportional = target_position - refNode.global_position
			return (proportionalWeight * proportional) + (integralWeight * _cumulative_integral) + (derivativeWeight * _derivative)
		else:
			return Vector2.ZERO

@onready var _last_position = refNode.global_position
@onready var _cumulative_integral = Vector2.ZERO
@onready var _derivative = Vector2.ZERO

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var proportional = target_position - refNode.global_position
	_derivative = (refNode.global_position - _last_position)/delta
	_cumulative_integral += proportional*delta
	_last_position = refNode.global_position
