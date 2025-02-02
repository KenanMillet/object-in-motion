@tool
class_name Asteroid
extends RigidBody2D

@export_group("Spawn Parameters")
@export_subgroup("Linear Speed", "linearSpeed")
## Minimum Linear Speed to give the asteroid when it spawns.
## Domain: [1,inf)
@export_range(1, 1000, 1, "or_greater", "suffix:px/s") var linearSpeedMin: float = 100
## Maximum Linear Speed to give the asteroid when it spawns.
## Domain: [1,inf)
@export_range(1, 1000, 1, "or_greater", "suffix:px/s") var linearSpeedMax: float = 300
@export_subgroup("Angular Speed", "angularSpeed")
## Minimum Angular Speed (in degrees) to give the asteroid when it spawns.
## Domain: [0,inf)
@export_range(0, 360, 1, "or_greater", "suffix:°/s") var angularSpeedMin: float = 2
## Maximum Angular Speed (in degrees) to give the asteroid when it spawns.
## Domain: [0,inf)
@export_range(0, 360, 1, "or_greater", "suffix:°/s") var angularSpeedMax: float = 10
## Chances of the Initial Angular Speed to be in a clockwise direction.
## Domain: [0,100]
@export_range(0, 100, 0.01, "suffix:%") var angularSpeedPolarity: float = 50.0
@export_subgroup("Scale Factor", "scaleFactor")
## Minimum factor that the asteroid's scale will be multiplied by when it spawns.
## Domain: [0.01,inf)
@export_range(0.01, 5, 0.01, "or_greater") var scaleFactorMin: float = 0.2
## Minimum factor that the asteroid's scale will be multiplied by when it spawns.
## Domain: [0.01,inf)
@export_range(0.01, 5, 0.01, "or_greater") var scaleFactorMax: float = 1.5
@export_group("Boundaries")
## Radius that encompasses the entire aesteroid; used to not spawn asteroids too close together.
@export var boundingCircle: CircleShape2D
## Radius that another asteroid's bounding circle should not spawn within.
@export var isolationCircle: CircleShape2D

static func _calcAngularSpeedPolarity(aspolarity) -> int:
	return -1 if randf() > remap(aspolarity, -1, 1, 0, 1) else 1

static func _calcInitialAngularVelocity(asmin, asmax, aspolarity) -> float:
	return randf_range(asmin, asmax) * _calcAngularSpeedPolarity(aspolarity)

@export_group("Spawn Values")
var spawnDirection: Vector2
var spawnLinearVelocity: Vector2
var spawnAngularVelocity: float
var spawnScaleFactor: float
var spawnMassScaleFactor: float
@export_group("")

func setup(direction: Vector2, maxSizeInPixels: float) -> void:
	spawnDirection = direction.normalized()
	spawnLinearVelocity = spawnDirection.normalized() * randf_range(linearSpeedMin, linearSpeedMax)
	spawnAngularVelocity = _calcInitialAngularVelocity(angularSpeedMin, angularSpeedMax, angularSpeedPolarity)
	var max_scale_factor = minf(scaleFactorMax, maxSizeInPixels/boundingCircle.radius)
	var min_scale_factor = minf(scaleFactorMin, max_scale_factor)
	spawnScaleFactor = randf_range(min_scale_factor, max_scale_factor)
	spawnMassScaleFactor = pow(spawnScaleFactor, 3)
	
static func minSpawnDist(a: Asteroid, b: Asteroid) -> float:
	return maxf(
		a.boundingCircle.radius * a.spawnScaleFactor + b.isolationCircle.radius * b.spawnScaleFactor,
		b.boundingCircle.radius * b.spawnScaleFactor + a.isolationCircle.radius * a.spawnScaleFactor)

static func minRowOffset(row_a: Array[Asteroid], row_b: Array[Asteroid]) -> float:
	var get_min_offset = func(min_off_for_a: float, a: Asteroid) -> float:
		var get_min_offset_for_row = func(min_off: float, b: Asteroid) -> float:
			return maxf(min_off, minSpawnDist(a, b))
		return row_b.reduce(get_min_offset_for_row, min_off_for_a)
	return row_a.reduce(get_min_offset, 0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	collision_layer = CollisionUtil.Layer.walls | CollisionUtil.Layer.spawn_blocking_obj
	global_rotation = randf_range(0, 2*PI)
	linear_velocity = spawnLinearVelocity
	angular_velocity = deg_to_rad(spawnAngularVelocity)
	$Sprite2D.apply_scale(Vector2.ONE * spawnScaleFactor)
	$CollisionPolygon2D.apply_scale(Vector2.ONE * spawnScaleFactor)
	mass *= spawnMassScaleFactor

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()

func _draw() -> void:
	if Engine.is_editor_hint():
		if isolationCircle != null:
			draw_circle(Vector2.ZERO, isolationCircle.radius, Color(Color.BLACK, 0.5))
		if boundingCircle != null:
			draw_circle(Vector2.ZERO, boundingCircle.radius, Color.BLUE, false)
