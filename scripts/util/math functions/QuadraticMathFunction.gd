class_name QuadraticMathFunction
extends MathFunction
## Math function of the form: f(x) = a*x^2 + b*x + c

@export_group("Constants")
## f(x) = [b]a[/b]*x^2 + b*x + c
@export_custom(PROPERTY_HINT_NONE, "suffix:*x^2") var a: float = 1
## f(x) = a*x^2 + [b]b[/b]*x + c
@export_custom(PROPERTY_HINT_NONE, "suffix:*x") var b: float = 0
## f(x) = a*x^2 + b*x + [b]c[/b]
@export var c: float = 0

func _init() -> void:
	super(null)

func _compute(x: float) -> float:
	return a*x*x + b*x + c
