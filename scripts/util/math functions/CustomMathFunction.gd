class_name CustomMathFunction
extends MathFunction
## Math function with a custom-defined f(x)

## The expression that is used to get the return value of the custom f(x).
@export_placeholder("f(x):") var _expression: String:
	get:
		return _expression
	set(value):
		_expression = value
		_expr = _compile(value)

var _expr: Expression

static func _compile(expression: String) -> Expression:
	var expr: Expression = Expression.new()
	if expr.parse(expression, PackedStringArray(["x"])) != OK:
		push_error(expr.get_error_text())
		return null
	return expr

func _compute(x: float) -> float:
	var result = _expr.execute([x])
	return NAN if _expr.has_execute_failed() else result
