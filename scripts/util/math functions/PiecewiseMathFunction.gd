class_name PiecewiseMathFunction
extends MathFunction
## Math function that uses different functions depending on the value of the input

## Array of [MathFunctionPiece]s to use for calculation. Ensure that pieces are in ascending order, by
## [code]x[/code] value as the implementation of [method MathFunction.compute] will assume as much.
@export var pieces: Array[MathFunctionPiece]
## If the input value is greater than all of the [code]x[/code] values in [member pieces],
## this function will be used to compute the resulting value. If set to [code]null[/code] (as by default),
## the last element in [member pieces] will be used on its own [code]x[/code] value to compute the result.
## If set to [code]null[/code] and [member pieces] is empty, the result of [method MathFunction.compute] will instead be [code]NAN[/code]. 
@export var upper_bounds: MathFunction = null

func _compute(x: float) -> float:
	for piece in pieces:
		if x <= piece.x:
			return piece.compute(x)
	if upper_bounds != null:
		return upper_bounds.compute(x)
	elif !pieces.is_empty():
		var piece: MathFunctionPiece = pieces[-1]
		return piece.compute(piece.x)
	else:
		return NAN
