class_name ExponentialMathFunction
extends MathFunction
## Math function of the form: f(x) = a*b^x + c

@export_group("Constants")
## f(x) = f(x) = [b]a[/b]*b^x + c
@export_custom(PROPERTY_HINT_NONE, "suffix:*b^x") var a: float = 1
## f(x) = f(x) = a*[b]b[/b]^x + c
@export_custom(PROPERTY_HINT_NONE, "suffix:^x") var b: float = exp(1)
## f(x) = f(x) = a*b^x + [b]c[/b]
@export var c: float = 0

func _compute(x: float) -> float:
	return a*pow(b,x) + c
