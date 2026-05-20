extends Node2D

var pos = Vector2.ZERO

func init(_vertex) -> void:
	pos.x = _vertex.coords[0]
	pos.y = _vertex.coords[1]
	pos *= globals.VIS_TRANSFORM_2D
	_vertex.coords_changed.connect(self.on_coords_changed)

func on_coords_changed(coords: Array) -> void:
	pos.x = coords[0]
	pos.y = coords[1]
	pos *= globals.VIS_TRANSFORM_2D
	queue_redraw()
	
func _draw() -> void:
	draw_circle(pos, globals.VIS_SCALE_2D*0.1, Color.WHITE, true, -1.0, true)
