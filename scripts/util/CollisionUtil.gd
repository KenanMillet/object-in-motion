class_name CollisionUtil

enum Layer
{
	none = 0,
	walls = 1 << 0,
	agents = 1 << 1,
	bullets = 1 << 2,
	guns = 1 << 3,
	
	objects = 0xFFFF,
	spawn_tile = 1 << 16,
	spawn_testing = 1 << 17,
	spawn_blocking_obj = 1 << 18,
	spawn_blocking_bg1 = 1 << 19,
	spawn_blocking_bg2 = 1 << 20,
	spawn_blocking_bg3 = 1 << 21,
}

static func testForSpawning(object: CollisionObject2D):
	var old_collision_layer = object.collision_layer
	var old_collision_mask = object.collision_mask
	object.collision_layer = CollisionUtil.Layer.spawn_testing
	object.collision_mask = CollisionUtil.Layer.spawn_tile
	return [old_collision_layer, old_collision_mask]
