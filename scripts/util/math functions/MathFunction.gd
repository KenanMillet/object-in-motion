class_name MathFunction
extends Resource
## Base Class for Math Functions that can be selected from for use in the Godot Inspector

@export_group("Input Modifier")
## If not set to null, [method compute] will return [code]_compute(modify_input.compute(input))[/code].
@export var modify_input: MathFunction = null

## Call to compute the output of the function given an [param input].
func compute(input: float) -> float:
	return _compute(modify_input.compute(input) if modify_input != null else input)

## Derived classes should override this to perform their own custom
## computations when [method compute] is called.
func _compute(_x: float) -> float:
	return NAN
