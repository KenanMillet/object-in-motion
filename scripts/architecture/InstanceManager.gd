class_name InstanceManager
extends Node

@export var defaultSpawnLoc: Marker2D = null

@export_group("Spawn Zone Bounds")
@export var spawnZoneCornerA: Marker2D = null
@export var spawnZoneCornerB: Marker2D = null
@export var spawnTile: PackedScene
@export var spawnTilePadding: Vector2
@export_range(0, 100, 1, "suffix:Spawn Tiles") var spawnAreaWidth: int = 32
@export_range(0, 100, 1, "suffix:Spawn Tiles") var spawnAreaHeight: int = 18
@export_group("")

@export_group("Spawn Table")
@export var enemiesToSpawn: int = 3
@export var forceGunMatchesAgent: bool = true
@export var agentTable: Array[PackedScene] = []
@export var agentWeights: Array[int] = []
@export var gunTable: Array[PackedScene] = []
@export var gunWeights: Array[int] = []
@export var asteroidTable: Array[PackedScene] = []
@export var asteroidWeights: Array[int] = []
@export var asteroidWaveRows: int = 3
@export var asteroidsPerRow: int = 5
@export var asterWaveSpawnDist: float = 8000
@export_range(0, 15, 0.01, "radians_as_degrees") var asterAngleVariance: float
@export_group("")

@export var players: Array[Player] = []
@export var playerSpawns: Array[SpawnTile] = []

@export var debugAimForSmall: bool = false:
	get:
		return debugAimForSmall
	set(value):
		debugAimForSmall = _debug_aim_for_group("small_agents", value)
@export var debugAimForMedium: bool = false:
	get:
		return debugAimForMedium
	set(value):
		debugAimForMedium = _debug_aim_for_group("medium_agents", value)
@export var debugAimForStarting: bool = false:
	get:
		return debugAimForStarting
	set(value):
		debugAimForStarting = _debug_aim_for_group("starting_agents", value)

@export var levelBounds: CollisionObject2D

@onready var _spawnZoneTL = _min_bounds(spawnZoneCornerA.global_position, spawnZoneCornerB.global_position)
@onready var _spawnZoneBR = _max_bounds(spawnZoneCornerA.global_position, spawnZoneCornerB.global_position)
var _spawnTiles: Array[Array] = []
var _agentWeightedTable: Array[PackedScene] = []
var _gunWeightedTable: Array[PackedScene] = []
var _asteroidWeightedDeck: Array[PackedScene] = []

@onready var debugCanvas: Node2D = DebugCanvas.locate(self)

func _debug_aim_for_group(group_name: String, value: bool) -> bool:
	if get_tree() != null:
		for agent in get_tree().get_nodes_in_group(group_name):
				agent.aimAssist.debug = value
	return value

func _min_bounds(a: Vector2, b: Vector2) -> Vector2:
	return Vector2(min(a.x, b.x), min(a.y, b.y))

func _max_bounds(a: Vector2, b: Vector2) -> Vector2:
	return Vector2(max(a.x, b.x), max(a.y, b.y))

func _rand_in_bounds(a: Vector2, b: Vector2) -> Vector2:
	return Vector2(randf_range(a.x, b.x), randf_range(a.y, b.y))

func _default_spawn_pos() -> Vector2:
	if defaultSpawnLoc != null:
		return defaultSpawnLoc.global_position
	else:
		return Vector2.ZERO

func _randomSpawnLocation() -> Vector2:
	return _rand_in_bounds(_spawnZoneTL, _spawnZoneBR)

func _randomAgentAndGun():
	if forceGunMatchesAgent:
		var i = randi_range(0, _agentWeightedTable.size()-1)
		return [
			_agentWeightedTable[i].instantiate(),
			_gunWeightedTable[i].instantiate()
		]
	else:
		return [
			_agentWeightedTable.pick_random().instantiate(),
			_gunWeightedTable.pick_random().instantiate()
		]

func spawnAgent(agent: Agent, spawn_tile: SpawnTile, gun: Gun, targetPlayer: Player = players.pick_random()) -> void:
	spawn_tile.spawn(agent)
	targetPlayer.control_target_changed.connect(agent._on_player_control_target_changed)
	agent.add_collision_exception_with(levelBounds)
	add_child(agent)
	if gun != null:
		spawnGun(gun, spawn_tile)
	agent.holdGun(gun, self)

func spawnGun(gun: Gun, spawn_tile: SpawnTile) -> void:
	spawn_tile.spawn(gun)
	gun.add_collision_exception_with(levelBounds)
	if !gun.bullet_fired.is_connected(_fire_bullet):
		gun.bullet_fired.connect(_fire_bullet)
	add_child(gun)


func _fire_bullet(bullet: Bullet, pos: Vector2, muzzle_velocity: Vector2, gun_velocity: Vector2) -> void:
	bullet.global_position = pos
	bullet.rotation = muzzle_velocity.angle()
	bullet.linear_velocity = muzzle_velocity + gun_velocity
	bullet.add_collision_exception_with(levelBounds)
	add_child(bullet)

func _spawn_player(player: Player, spawn_tile: SpawnTile) -> void:
	var newAgent = player.startingAgent.instantiate()
	var newGun = player.startingGun.instantiate()
	spawnAgent(newAgent, spawn_tile, newGun, player)
	player.controlAgent(newAgent, newGun)

func _makeAsteroidWave(direction: Vector2) -> Array[Array]:
	var wave: Array[Array]
	wave.resize(asteroidWaveRows)
	var wt_idx = 0
	for row_idx in asteroidWaveRows:
		var row: Array[Asteroid]
		row.resize(asteroidsPerRow)
		for ast_idx in asteroidsPerRow:
			if wt_idx == 0:
				_asteroidWeightedDeck.shuffle()
			row[ast_idx] = _asteroidWeightedDeck[wt_idx].instantiate()
			wt_idx = (wt_idx + 1) % _asteroidWeightedDeck.size()
			var asteroid: Asteroid = row[ast_idx]
			asteroid.setup(
				direction if asterAngleVariance == 0 else direction.rotated(randf_range(-asterAngleVariance, asterAngleVariance)),
				minf(_spawnTiles[0][0].size.x, _spawnTiles[0][0].size.y))
			asteroid.add_collision_exception_with(levelBounds)
		wave[row_idx] = row
	return wave

func spawnAsteroidWave(direction: Vector2, distance_from_center: float = asterWaveSpawnDist) -> Array[Asteroid]:
	if asteroidWaveRows * asteroidsPerRow == 0:
		return []

	direction = direction.normalized()
	var wave: Array[Array] = _makeAsteroidWave(direction)

	var row_origin: Vector2 = direction * -distance_from_center
	var wave_line: Vector2 = direction.rotated(PI/2)
	for row_idx in wave.size():
		var row: Array[Asteroid] = wave[row_idx] as Array[Asteroid]
		if row_idx != 0:
			var prev_row: Array[Asteroid] = wave[row_idx-1]
			row_origin += direction * -Asteroid.minRowOffset(row, prev_row)
		for col_idx in row.size():
			var asteroid: Asteroid = row[col_idx]
			if col_idx == 0:
				asteroid.global_position = row_origin
			else:
				var prev_asteroid: Asteroid = row[col_idx-1]
				asteroid.global_position = prev_asteroid.global_position + wave_line * Asteroid.minSpawnDist(asteroid, prev_asteroid)

	for row: Array[Asteroid] in wave:
		var row_width = row[0].global_position.distance_to(row[-1].global_position)
		for asteroid: Asteroid in row:
			asteroid.global_position -= wave_line * row_width

	for row: Array[Asteroid] in wave:
		for asteroid: Asteroid in row:
			add_child(asteroid)
	return wave.reduce(func(a, b): return a + b)

func _makeWeightedTable(table: Array[PackedScene], weights: Array[int]) -> Array[PackedScene]:
	var weighted: Array[PackedScene]
	if weights.size() == 0:
		weights.resize(table.size())
		weights.fill(1)
	weighted.resize(weights.reduce(func(a,b): return a+b))
	var wi = 0
	for i in table.size():
		var weight = weights[i] if weights.size() > i else 0
		for _j in weight:
			weighted[wi] = table[i]
			wi += 1
	return weighted

func _setupSpawnTiles() -> void:
	_spawnTiles.resize(spawnAreaHeight)
	var spawn_tile_size: Vector2
	for h in spawnAreaHeight:
		var spawn_tile_row: Array[SpawnTile]
		spawn_tile_row.resize(spawnAreaWidth)
		for w in spawnAreaWidth:
			var spawn_tile: SpawnTile = spawnTile.instantiate()
			spawn_tile_size = spawn_tile.size
			spawn_tile_row[w] = spawn_tile
		_spawnTiles[h] = spawn_tile_row

	var spawn_area_size = (spawn_tile_size * Vector2(spawnAreaWidth, spawnAreaHeight)) + (spawnTilePadding * Vector2(spawnAreaWidth-1, spawnAreaHeight-1))
	for h in spawnAreaHeight:
		for w in spawnAreaWidth:
			var spawn_tile: SpawnTile = _spawnTiles[h][w]
			spawn_tile.global_position = ((spawn_tile_size + spawnTilePadding) * Vector2(w, h)) - spawn_area_size/2
			add_child(spawn_tile)

func _findTilesToSpawnObject(bounding_box: Rect2 = Rect2(0, 0, 0, 0)) -> Array[SpawnTile]:
	if bounding_box.size < _spawnTiles[0][0].size:
		return _spawnTiles.reduce(func(a, b): return a + b).filter(func(spawn_tile: SpawnTile): return spawn_tile.can_spawn)
	return []

func _ready() -> void:
	_setupSpawnTiles()

	_agentWeightedTable = _makeWeightedTable(agentTable, agentWeights)
	_gunWeightedTable = _makeWeightedTable(gunTable, agentWeights if forceGunMatchesAgent else gunWeights)
	_asteroidWeightedDeck = _makeWeightedTable(asteroidTable, asteroidWeights)

	var is_asteroid_covering_agent = func(asteroid: Asteroid, agent: Agent) -> bool:
		return asteroid.global_position.distance_to(agent.global_position) < asteroid.boundingCircle.radius * asteroid.spawnScaleFactor

	var tiles: Array[SpawnTile] = _findTilesToSpawnObject()
	tiles.shuffle()

	var aster_wave: Array[Asteroid] = spawnAsteroidWave(Vector2.RIGHT.rotated(randf_range(0, 2*PI)), 0)
	var aster_mid_point: Vector2 = (aster_wave[0].global_position + aster_wave[-1].global_position)/2
	for asteroid: Asteroid in aster_wave:
		asteroid.global_position -= aster_mid_point

	for i in min(tiles.size(), aster_wave.size()):
		tiles[i].spawn(aster_wave[i])

	var asteroids_covering_agents = {}

	for i in min(max(tiles.size()-aster_wave.size(), 0), enemiesToSpawn):
		var agent_and_gun = _randomAgentAndGun()
		spawnAgent(agent_and_gun[0], tiles[i], agent_and_gun[1])
		for asteroid: Asteroid in aster_wave:
			if is_asteroid_covering_agent.call(asteroid, agent_and_gun[0]):
				asteroids_covering_agents[asteroid] = asteroid


	assert(playerSpawns.size() >= players.size(), "There must be at least as many possible player spawns as there are players!")
	for player in players:
		player.levelBounds = levelBounds
	playerSpawns.shuffle()
	for i in players.size():
		var player: Player = players[i]
		_spawn_player(player, playerSpawns[i])
		for asteroid: Asteroid in aster_wave:
			if is_asteroid_covering_agent.call(asteroid, player.agent):
				asteroids_covering_agents[asteroid] = asteroid

	for asteroid: Asteroid in asteroids_covering_agents.keys():
		asteroid.queue_free()
	asteroids_covering_agents = {}

	debugAimForSmall = debugAimForSmall
	debugAimForMedium = debugAimForMedium
	debugAimForStarting = debugAimForStarting

	var boundsMin = Vector2.ZERO
	var boundsMax = Vector2.ZERO
	for boundary: Node2D in levelBounds.get_children():
		boundsMin.x = minf(boundsMin.x, boundary.global_position.x)
		boundsMin.y = minf(boundsMin.y, boundary.global_position.y)
		boundsMax.x = maxf(boundsMax.x, boundary.global_position.x)
		boundsMax.y = maxf(boundsMax.y, boundary.global_position.y)
	debugCanvas.draw.connect(_draw_borders.bind(boundsMin.x, boundsMin.y, boundsMax.x, boundsMax.y))

func _draw_borders(x1: float, y1: float, x2: float, y2: float) -> void:
	debugCanvas.draw_dashed_line(Vector2(x1,y1), Vector2(x2,y1), Color.RED)
	debugCanvas.draw_dashed_line(Vector2(x2,y1), Vector2(x2,y2), Color.RED)
	debugCanvas.draw_dashed_line(Vector2(x2,y2), Vector2(x1,y2), Color.RED)
	debugCanvas.draw_dashed_line(Vector2(x1,y2), Vector2(x1,y1), Color.RED)
