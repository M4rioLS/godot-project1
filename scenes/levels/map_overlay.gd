extends TextureRect
var vec2: Vector2

func _draw():
	# Draw player indicator
	
	vec2 = Vector2(125,125)#Vector2(player.global_position.x, player.global_position.y)
	draw_circle(vec2, 6, Color.LIME_GREEN)
	
	# Draw enemy indicators from texture
	if texture:
		draw_texture(texture, Vector2.ZERO)
