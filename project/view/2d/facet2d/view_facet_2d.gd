extends Node2D

var v1 : Vector2 = Vector2.ZERO
var v2 : Vector2 = Vector2.ZERO
var v3 : Vector2 = Vector2.ZERO

func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([v1, v2, v3]), Color("#ddd"))

func init(_edge1, _edge2, _edge3) -> void:
	v1 = globals.VIS_TRANSFORM_2D*Vector2(_edge1.tail.coords[0],_edge1.tail.coords[1])
	v2 = globals.VIS_TRANSFORM_2D*Vector2(_edge2.tail.coords[0],_edge2.tail.coords[1])
	v3 = globals.VIS_TRANSFORM_2D*Vector2(_edge3.tail.coords[0],_edge3.tail.coords[1])

	_edge1.tail.coords_changed.connect(self.on_v1_changed)
	_edge2.tail.coords_changed.connect(self.on_v2_changed)
	_edge3.tail.coords_changed.connect(self.on_v3_changed)

func on_v1_changed(coords : Array) -> void:
	v1 = Vector2(coords[0], coords[1])
	queue_redraw()
	
func on_v2_changed(coords : Array) -> void:
	v2 = Vector2(coords[0], coords[1])
	queue_redraw()

func on_v3_changed(coords : Array) -> void:
	v3 = Vector2(coords[0], coords[1])
	queue_redraw()
