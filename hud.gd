class_name HUD
extends CanvasLayer

@export var focus: TextureProgressBar
@export var spaceFocusBar: Texture = null
@export var health: HBoxContainer
@export var plan: HBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_new_health_chunks(new_agent: Agent) -> void:
	for child in health.get_children():
		health.remove_child(child)
		child.queue_free()
	if new_agent == null || new_agent.healthChunk == null:
		return
	for _h in ceili(new_agent.health/4.0):
		health.add_child(new_agent.healthChunk.instantiate())

func _on_player_agent_changed(new_agent: Agent, old_agent: Agent) -> void:
	set_new_health_chunks(new_agent)
	focus.texture_progress = new_agent.focusBar if new_agent != null else spaceFocusBar

	var handle_signals = func(agent: Agent, signal_fn: StringName):
		var handle: Callable
		if signal_fn == "connect":
			handle = func(sig: Signal, slot: Callable, args: Array):
				Callable.create(sig, signal_fn).call(slot)
				slot.callv(args)
		else:
			handle = func(sig: Signal, slot: Callable, _args: Array):
				Callable.create(sig, signal_fn).call(slot)
		handle.call(agent.health_changed, _on_agent_health_changed, [agent.health])

	if old_agent != null:
		handle_signals.call(old_agent, "disconnect")
	if new_agent != null:
		handle_signals.call(new_agent, "connect")

func _on_player_gun_changed(new_gun: Gun, old_gun: Gun) -> void:
	pass # Replace with function body.


func _on_agent_health_changed(new_health: int) -> void:
	for chunk: CanvasItem in health.get_children():
		chunk.visible = false
		for piece: CanvasItem in chunk.get_children():
			piece.visible = false
	var max_health: int = health.get_child_count() * 4
	if max_health < new_health:
		print("new_health: ", new_health, " is above max_health: ", max_health, " so excess health will not be displayed")
	new_health = min(new_health, max_health)
	for h in range(0,new_health,4):
		var chunk: CanvasItem = health.get_child(h/4)
		var piece: CanvasItem = chunk.get_child(4 - min(new_health - h, 4))
		chunk.visible = true
		piece.visible = true


func _on_player_focus_changed(percent_remaining: float) -> void:
	print("Focus Remaining: ", percent_remaining * 100, "%")
	focus.value = percent_remaining
