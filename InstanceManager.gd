class_name InstanceManager
extends Node

@export var defaultSpawnLoc: Marker2D = null

@export_group("Spawn Zone Bounds")
@export var spawnZoneCornerA: Marker2D = null
@export var spawnZoneCornerB: Marker2D = null
@export_group("")

@export_group("Spawn Table")
@export var enemiesToSpawn: int = 3
@export var forceGunMatchesAgent: bool = true
@export var agentTable: Array[PackedScene] = []
@export var agentWeights: Array[int] = []
@export var gunTable: Array[PackedScene] = []
@export var gunWeights: Array[int] = []
@export var aesteroidTileSpacing: float = 300
@export_group("")

@export var players: Array[Player] = []
@export var playerSpawns: Array[Marker2D] = []

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
var _agentWeightedTable: Array[int] = []
var _gunWeightedTable: Array[int] = []

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
	var agent_idx = _agentWeightedTable.pick_random()
	var gun_idx = agent_idx if forceGunMatchesAgent else _gunWeightedTable.pick_random()
	return [
		agentTable[agent_idx].instantiate(),
		gunTable[gun_idx].instantiate()
	]

func spawnAgent(agent: Agent, pos: Vector2 = _default_spawn_pos(), gun: Gun = null, targetPlayer: Player = players.pick_random()) -> void:
	agent.global_position = pos
	targetPlayer.control_target_changed.connect(agent._on_player_control_target_changed)
	agent.add_collision_exception_with(levelBounds)
	add_child(agent)
	if gun != null:
		spawnGun(gun)
	agent.holdGun(gun, self)

func spawnGun(gun: Gun, pos: Vector2 = _default_spawn_pos()) -> void:
	gun.global_position = pos
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

func _spawn_player(player: Player, position: Vector2) -> void:
	var newAgent = player.startingAgent.instantiate()
	var newGun = player.startingGun.instantiate()
	spawnAgent(newAgent, position, newGun, player)
	player.controlAgent(newAgent, newGun)

func _ready() -> void:
	var tbls = [[agentTable, agentWeights, _agentWeightedTable]]
	if !forceGunMatchesAgent:
		tbls.append([gunTable, gunWeights, _gunWeightedTable])
	for tbl_trio in tbls:
		var in_tbl = tbl_trio[0]
		var wt_tbl = tbl_trio[1]
		var out_tbl = tbl_trio[2]
		for i in in_tbl.size():
			var weight: int = wt_tbl[i] if wt_tbl.size() > i else 0
			for _j in weight:
				out_tbl.append(i)
		if out_tbl.is_empty():
			for i in in_tbl.size():
				out_tbl.append(i)
			
	for i in enemiesToSpawn:
		var agent_and_gun = _randomAgentAndGun()
		spawnAgent(agent_and_gun[0], _randomSpawnLocation(), agent_and_gun[1])

	assert(playerSpawns.size() >= players.size(), "There must be at least as many possible player spawns as there are players!")
	for player in players:
		player.levelBounds = levelBounds
	playerSpawns.shuffle()
	for i in players.size():
		var player: Player = players[i]
		_spawn_player(player, playerSpawns[i].global_position)

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
