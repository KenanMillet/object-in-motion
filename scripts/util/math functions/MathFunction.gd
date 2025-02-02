class_name MathFunction
extends Resource
## Base Class for Math Functions that can be selected from for use in the Godot Inspector

@export_group("Modifiers")
## Upon calling [method compute], this number will be subtracted from the [param input] before calculation.
## Positive numbers are equivalent of shifting the graph to the right.
## Negative numbers are equivalent of shifting the graph to the left.
@export var shift_input: float = 0

## Inverts the function (calling [method compute] will return 1.0 divided by the result of the computation).
@export var invert: bool = false

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
