class_name Bullet
extends RigidBody2D

@export var playerDamage: int = 2
@export var enemyDamage: int = 4
@export var playerHurtBox: CollisionShape2D = null
@export var enemyHurtBox: CollisionShape2D = null
@export var ignoreEnemyBullets: bool = false
@export var friendlyFireTimeLimit: float = 5

var firedFromPlayer: Player = null

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 10
	#collision_layer = 0b0100 # bullets
	collision_layer = 0b0000 # bullets
	collision_mask = 0b1111 # guns, bullets, agents, walls
	body_entered.connect(_on_body_entered)
	if firedFromPlayer == null:
		await get_tree().create_timer(friendlyFireTimeLimit).timeout
		enemyDamage = 0

func _process(_delta: float) -> void:
	if global_position.distance_to(Vector2.ZERO) > 10000:
		queue_free()

func _on_body_entered(body:Node) -> void:
	if body is Agent:
		var agent: Agent = body as Agent
		agent.damage(playerDamage if agent.controllingPlayer != null else enemyDamage)
	if body is Gun && (body as Gun).agent == null:
		hide()
		await get_tree().create_timer(0.1).timeout
	if body is Bullet && firedFromPlayer != null && ignoreEnemyBullets:
		return
	queue_free()
