class_name CircularMathFunction
extends MathFunction
## Math function of the form: f(x) = a*sqrt(x) + b

@export_group("Constants")
## f(x) = [b]a[/b]*sqrt(x) + b
@export_custom(PROPERTY_HINT_NONE, "suffix:*sqrt(x)") var a: float = 1
## f(x) = a*sqrt(x) + [b]b[/b]
@export var b: float = 0

func _init() -> void:
	super(null)

func _compute(x: float) -> float:
	return a*sqrt(x) + b
