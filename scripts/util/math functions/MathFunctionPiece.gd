class_name MathFunctionPiece
extends MathFunction
## A function piece to be used in a [PiecewiseMathFunction].

## Input values in calls to [method MathFunction.compute] that are
## less than or equal to this value will use the [member function] in this instance.
@export var x: float

## The [MathFunction] to be used for input values that are less than or equal to [member x].
@export var function: MathFunction

func _compute(input: float) -> float:
	return function.compute(input) if input <= x else NAN
