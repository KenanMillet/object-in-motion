class_name LogarithmicMathFunction
extends MathFunction
## Math function of the form: f(x) = a*log(x) + b

@export_group("Constants")
## f(x) = [b]a[/b]*log(x) + b
@export_custom(PROPERTY_HINT_NONE, "suffix:*log(x)") var a: float = 1
## f(x) = a*log(x) + [b]b[/b]
@export var b: float = 0

func _init() -> void:
	super(null)

func _compute(x: float) -> float:
	return a*log(x) + b
