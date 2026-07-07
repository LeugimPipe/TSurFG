extends Node2D

var tail : Vector2 = Vector2.ZERO
var head : Vector2 = Vector2.ZERO

func _draw() -> void:
	draw_line(tail, head, Color.WHITE, globals.VIS_SCALE_2D*0.02, true)

func init(_tail : Vertex, _head : Vertex) -> void:
	tail = globals.VIS_TRANSFORM_2D*Vector2(_tail.coords.get_i(0), _tail.coords.get_i(1))
	head = globals.VIS_TRANSFORM_2D*Vector2(_head.coords.get_i(0), _head.coords.get_i(1))
	
	_tail.coords_changed.connect(self.on_tail_changed)
	_head.coords_changed.connect(self.on_head_changed)

func on_tail_changed(coords : VectorN) -> void:
	tail = globals.VIS_TRANSFORM_2D*Vector2(coords.get_i(0), coords.get_i(1))
	queue_redraw()
	
func on_head_changed(coords : VectorN) -> void:
	head = globals.VIS_TRANSFORM_2D*Vector2(coords.get_i(0), coords.get_i(1))
	queue_redraw()
