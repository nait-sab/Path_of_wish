extends Camera2D

@export var tilemap: TileMap

func _ready():
	if tilemap:
		var map_rect = tilemap.get_used_rect()
		var tile_size = tilemap.rendering_quadrant_size
		var world_size_in_pixels = map_rect.size * tile_size
		
		limit_left = 0
		limit_right = world_size_in_pixels.x
		limit_top = 0
		limit_bottom = world_size_in_pixels.y
