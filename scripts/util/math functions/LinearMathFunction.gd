class_name LinearMathFunction
extends MathFunction
## Math function of the form: f(x) = a*x + b

@export_group("Constants")
## f(x) = [b]a[/b]*x + b
@export_custom(PROPERTY_HINT_NONE, "suffix:*x") var a: float = 1
## f(x) = a*x + [b]b[/b]
@export var b: float = 0

func _compute(x: float) -> float:
	return a*x + b
