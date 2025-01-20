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
@export_group("")

@export var players: Array[Player] = []

@onready var _spawnZoneTL = _min_bounds(spawnZoneCornerA.global_position, spawnZoneCornerB.global_position)
@onready var _spawnZoneBR = _max_bounds(spawnZoneCornerA.global_position, spawnZoneCornerB.global_position)
var _agentWeightedTable: Array[int] = []
var _gunWeightedTable: Array[int] = []

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
	var agent_idx = _agentWeightedTable[randi() % _agentWeightedTable.size()]
	var gun_idx = agent_idx if forceGunMatchesAgent else _gunWeightedTable[randi() % _gunWeightedTable.size()]
	return [
		agentTable[agent_idx].instantiate(),
		gunTable[gun_idx].instantiate()
	]

func spawnAgent(agent: Agent, pos: Vector2 = _default_spawn_pos(), gun: Gun = null, target: Node2D = players[randi() % players.size()].targetPos) -> void:
	agent.global_position = pos
	agent.target = target
	add_child(agent)
	if gun != null:
		spawnGun(gun)
	agent.holdGun(gun, self)

func spawnGun(gun: Gun, pos: Vector2 = _default_spawn_pos()) -> void:
	gun.global_position = pos
	if !gun.bullet_fired.is_connected(_fire_bullet):
		gun.bullet_fired.connect(_fire_bullet)
	add_child(gun)


func _fire_bullet(bullet: Bullet, pos: Vector2, muzzle_velocity: Vector2, gun_velocity: Vector2) -> void:
	bullet.global_position = pos
	bullet.rotation = muzzle_velocity.angle()
	bullet.linear_velocity = muzzle_velocity + gun_velocity
	add_child(bullet)

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
