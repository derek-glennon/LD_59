extends MarginContainer

@export var right_offset_ratio := 0.0
@export var top_offset_ratio := 0.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var viewport_width = get_viewport().get_visible_rect().size.x
	var viewport_height = get_viewport().get_visible_rect().size.y
	var right_offset = viewport_width * right_offset_ratio
	var top_offset = viewport_height * top_offset_ratio
	add_theme_constant_override("margin_right", right_offset)
	add_theme_constant_override("margin_top", top_offset)
