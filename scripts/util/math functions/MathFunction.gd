class_name MathFunction
extends Resource

@export_group("Modifiers")
## Upon calling [method compute], this number will be subtracted from the [param input] before calculation.
## Positive numbers are equivalent of shifting the graph to the right.
## Negative numbers are equivalent of shifting the graph to the left.
@export var shift_input: float = 0

## Inverts the function (calling [method compute] will return 1.0 divided by the result of the computation).
@export var invert: bool = false

## Whether or not to apply [member lower_bounds] to the function.
@export var apply_lower_bounds: bool = false
## If [member apply_lower_bounds] is [code]true[/code], calling [method compute] with [param input] values
## less than or equal to [code]lower_bounds.x[/code] will return [code]lower_bounds.y[/code].
@export var lower_bounds: Vector2
## Whether or not to apply upper bounds to the function.
@export var apply_upper_bounds: bool = false
## If [member apply_upper_bounds] is [code]true[/code], calling [method compute] with [param input] values
## greater than or equal to [code]upper_bounds.x[/code] will return [code]upper_bounds.y[/code].
@export var upper_bounds: Vector2

func _init(_ignore):
	pass

## Call to compute the output of the function given an [param input].
func compute(input: float) -> float:
	var result: float = _compute(input-shift_input)
	return (1.0/result) if invert else result

## Derived classes should override this to perform their own custom
## computations when [method compute] is called.
func _compute(_x: float) -> float:
	return NAN
