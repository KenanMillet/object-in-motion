class_name CubicMathFunction
extends MathFunction
## Math function of the form: f(x) = a*x^3 + b*x^2 + c*x + d

@export_group("Constants")
## f(x) = [b]a[/b]*x^3 + b*x^2 + c*x + d
@export_custom(PROPERTY_HINT_NONE, "suffix:*x^3") var a: float = 1
## f(x) = a*x^3 + [b]b[/b]*x^2 + c*x + d
@export_custom(PROPERTY_HINT_NONE, "suffix:*x^2") var b: float = 0
## f(x) = a*x^3 + b*x^2 + [b]c[/b]*x + d
@export_custom(PROPERTY_HINT_NONE, "suffix:*x") var c: float = 0
## f(x) = a*x^3 + b*x^2 + c*x + [b]d[/b]
@export var d: float = 0

func _compute(x: float) -> float:
	return a*x*x*x + b*x*x + c*x + d
