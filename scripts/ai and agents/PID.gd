@tool
class_name PID
extends Node

## Use this to set the Ref Node and Ref Property via scripts.
## Ref Node and Ref Property should only be assigned directly via the Inspector.
func set_control_input(ref_node: Node, ref_property: NodePath):
	_ref_node = ref_node
	_ref_property = ref_property

## The target_value that the PID should provide feedback for.
## Set this to the same type as your Ref Property, or set to null to reset the PID with no target_value.
var target_value = null:
	get:
		return target_value
	set(value):
		if target_value == null && value != null:
			_last_value = _get_ref_value()
			_cumulative_integral = _get_scalar_value(0)
			_derivative = _get_scalar_value(0)
		target_value = value

## The value that the PID provides as an output given your target_value, Ref Property, and other control values.
## This will be null if the target_value is null
var value:
	get:
		if target_value != null:
			var proportional = target_value - _get_ref_value()
			var val = (_proportional_wt * proportional)
			if _cumulative_integral != null:
				val += (_integral_wt * _cumulative_integral)
			if _derivative != null:
				val += (_derivative_wt * _derivative)
			return val
		else:
			return null

## Like the value property, but will return the provided default value if the target_value is null.
func value_or(default):
	var val = value
	return val if val != null else default


## The Node that the PID Controller will use as a reference.
## Outside of the Inspector, should be set using set_control_input.
@export var _ref_node: Node = null:
	get:
		return _ref_node
	set(value):
		_ref_node = value
		if !Engine.is_editor_hint() || _ref_set_at_runtime:
			return
		if value == null:
			_property_values.clear()
		_infer_ref_property_type()

## The Property of the Ref Node that the PID Controller will use to get its input value from.
## Outside of the Inspector, should be set using set_control_input.
@export var _ref_property: String = "global_position":
	get:
		return _ref_property
	set(value):
		_ref_property = value
		if !Engine.is_editor_hint() || _ref_set_at_runtime:
			return
		_infer_ref_property_type()

## Set this to true if either the Ref Node or Ref Property are set at runtime.
## This will allow you to manually set the control values.
@export var _ref_set_at_runtime: bool = false:
	get:
		return _ref_set_at_runtime
	set(value):
		if Engine.is_editor_hint():
			_ref_set_at_runtime = value
			notify_property_list_changed()

## If Ref Set at Runtime is set to true, this will allow you to specify what type
## the control values (as well as the control input) should be.
@export var _ref_property_type: supported_types:
	get:
		return _internal_ref_property_type
	set(value):
		if value != _internal_ref_property_type:
			_internal_ref_property_type = value
			if Engine.is_editor_hint():
				_refresh_inspector()

## The weight to apply to the Proportional part of the PID Controller.
## This affects the speed at which the input will approach the target_value.
@export var _proportional_wt = null
## The weight to apply to the Integral part of the PID Controller.
## This affects how "impatient" the PID Controller is
## (how much it accounts for outside forces that keep it from reaching the target_value).
## This should usually be a small number that is greater than or equal to zero.
@export var _integral_wt = null
## The weight to apply to the Derivative part of the PID Controller.
## This affects how much the PID Controller will slow down as it approaches the target_value.
## This should usually be negative, as it works against the Proportional part.
@export var _derivative_wt = null
## The minimum value that the Integral part of the PID Controller can reach.
## Use this when it can take a while to reach the target_value.
## Typically, this would be a negative number. If both this and the Integral Max Value are zero,
## then the Integral part of the PID controller will be unclamped.
@export var _integral_min_value = null
## The minimum value that the Integral part of the PID Controller can reach.
## Use this when it can take a while to reach the target_value.
## Typically, this would be a positive number. If both this and the Integral Min Value are zero,
## then the Integral part of the PID controller will be unclamped.
@export var _integral_max_value = null



var _property_values = {}

const _dynamic_property_defaults: Dictionary = {
	"_proportional_wt": 1,
	"_integral_wt": 0,
	"_derivative_wt": -1,
	"_integral_min_value": 0,
	"_integral_max_value": 0,
}

enum supported_types
{
	NULL = TYPE_NIL,
	INT = TYPE_INT,
	FLOAT = TYPE_FLOAT,
	VECTOR2 = TYPE_VECTOR2,
	VECTOR2I = TYPE_VECTOR2I,
	VECTOR3 = TYPE_VECTOR3,
	VECTOR3I = TYPE_VECTOR3I,
	VECTOR4 = TYPE_VECTOR4,
	VECTOR4I = TYPE_VECTOR4I,
}

func _get_supported_type(type: Variant.Type) -> supported_types:
	return (type as supported_types) if type in _one_values_by_type else supported_types.NULL

const _one_values_by_type: Dictionary = {
	supported_types.NULL: null,
	supported_types.INT: 1 as int,
	supported_types.FLOAT: 1.0 as float,
	supported_types.VECTOR2: Vector2.ONE,
	supported_types.VECTOR2I: Vector2i.ONE,
	supported_types.VECTOR3: Vector3.ONE,
	supported_types.VECTOR3I: Vector3i.ONE,
	supported_types.VECTOR4: Vector4.ONE,
	supported_types.VECTOR4I: Vector4i.ONE,
}

func _property_can_revert(property: StringName) -> bool:
	return property in _dynamic_property_defaults

func _property_get_revert(property: StringName) -> Variant:
	return _get_scalar_value(_dynamic_property_defaults[property])
	
func _validate_property(property: Dictionary) -> void:
	if property.name == "_ref_property_type" && !_ref_set_at_runtime:
		property.usage |= PROPERTY_USAGE_READ_ONLY
	elif property.name in _dynamic_property_defaults:
		property.type = _ref_property_type
		property.hint = PROPERTY_HINT_LINK

func _refresh_inspector():
	for _name in _dynamic_property_defaults.keys():
		var prop = get(_name)
		var _value_by_type = _property_values.get_or_add(_name, {})
		_value_by_type[_get_supported_type(typeof(prop))] = prop
		set(_name, _value_by_type.get_or_add(_ref_property_type, _property_get_revert(_name)))
	notify_property_list_changed()
	_refresh_timer = null

func _get_ref_value():
	return _ref_node.get_indexed(_ref_property) if _ref_node != null else null

func _get_ref_type():
	return _get_supported_type(typeof(_get_ref_value()))

func _get_scalar_value(scalar):
	var one = _one_values_by_type[_ref_property_type]
	return one * scalar if one != null else null

const REFRESH_TIME_SECONDS: float = 2.0

var _refresh_timer: SceneTreeTimer = null
func _refresh_inspector_after(seconds: float):
	if _refresh_timer != null:
		_refresh_timer.timeout.disconnect(_refresh_inspector)
		_refresh_timer = null
	var tree = get_tree()
	if tree != null:
		_refresh_timer = tree.create_timer(seconds)
		_refresh_timer.timeout.connect(_refresh_inspector)

var _internal_ref_property_type: supported_types = supported_types.NULL
func _infer_ref_property_type():
	_internal_ref_property_type = _get_ref_type()
	_refresh_inspector_after(REFRESH_TIME_SECONDS)

var _cumulative_integral
var _derivative
var _last_value

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_last_value = _get_ref_value()
	_cumulative_integral = _get_scalar_value(0)
	_derivative = _get_scalar_value(0)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if target_value != null:
		var proportional = target_value - _get_ref_value()
		_derivative = (_get_ref_value() - _last_value)/delta
		_cumulative_integral = (_cumulative_integral + proportional*delta)
		if _integral_max_value != _get_scalar_value(0) || _integral_min_value != _get_scalar_value(0):
			match typeof(_cumulative_integral):
				TYPE_INT:
					_cumulative_integral = clampi(_cumulative_integral, _integral_min_value/_integral_wt, _integral_max_value/_integral_wt)
				TYPE_FLOAT:
					_cumulative_integral = clampf(_cumulative_integral, _integral_min_value/_integral_wt, _integral_max_value/_integral_wt)
				_:
					_cumulative_integral = _cumulative_integral.clamp(_integral_min_value/_integral_wt, _integral_max_value/_integral_wt)
		_last_value = _get_ref_value()
