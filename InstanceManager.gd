extends Node

func _handle_bullet(bullet: Bullet, position: Vector2, muzzle_velocity: Vector2, gun_velocity: Vector2) -> void:
	bullet.global_position = position
	bullet.rotation = muzzle_velocity.angle()
	bullet.linear_velocity = muzzle_velocity + gun_velocity
	add_child(bullet)

func _on_player_swap_guns(player: Player, newGun: Gun, oldGun: Gun) -> void:
	for gunAndNewParent in [[oldGun, self], [newGun, player]]:
		var gun = gunAndNewParent[0]
		var newParent = gunAndNewParent[1]
		if gun != null:
			var p = gun.get_parent()
			if p == null:
				newParent.add_child(gun)
			elif p != newParent:
				gun.reparent(newParent)
			if !gun.bullet_fired.is_connected(_handle_bullet):
				gun.bullet_fired.connect(_handle_bullet)
