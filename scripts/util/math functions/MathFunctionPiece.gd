class_name MathFunctionPiece
extends Resource
## A function piece to be used in a [PiecewiseMathFunction].

## Input values in calls to [method MathFunction.compute] that are
## less than or equal to this value should use the [member function] in this instance.
@export var x: float

## The [MathFunction] to be used for input values that are less than or equal to [member x].
@export var function: MathFunction
