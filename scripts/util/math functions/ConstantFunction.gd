class_name ConstantFunction
extends MathFunction
## Math function of the form: f(x) = constant

@export var constant: float = 0

func _init() -> void:
	super(null)

func _compute(_x: float) -> float:
	return constant
