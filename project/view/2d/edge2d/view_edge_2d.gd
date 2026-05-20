extends Node2D

var tail : Vector2 = Vector2.ZERO
var head : Vector2 = Vector2.ZERO

func _draw() -> void:
	draw_line(tail, head, Color.WHITE, globals.VIS_SCALE_2D*0.02, true)

func init(_tail, _head) -> void:
	tail = globals.VIS_TRANSFORM_2D*Vector2(_tail.coords[0], _tail.coords[1])
	head = globals.VIS_TRANSFORM_2D*Vector2(_head.coords[0], _head.coords[1])
	
	_tail.coords_changed.connect(self.on_tail_changed)
	_head.coords_changed.connect(self.on_head_changed)

func on_tail_changed(coords : Array) -> void:
	tail = globals.VIS_TRANSFORM_2D*Vector2(coords[0], coords[1])
	queue_redraw()
	
func on_head_changed(coords : Array) -> void:
	head = globals.VIS_TRANSFORM_2D*Vector2(coords[0], coords[1])
	queue_redraw()
