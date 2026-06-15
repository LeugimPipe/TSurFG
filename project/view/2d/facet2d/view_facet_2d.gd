extends Node2D

var v0 : Vector2 = Vector2.ZERO
var v1 : Vector2 = Vector2.ZERO
var v2 : Vector2 = Vector2.ZERO

func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([v0, v1, v2]), Color("#ddd"))

func init(_v0, _v1, _v2) -> void:
	v0 = globals.VIS_TRANSFORM_2D*Vector2(_v0.coords[0], _v0.coords[1])
	v1 = globals.VIS_TRANSFORM_2D*Vector2(_v1.coords[0], _v1.coords[1])
	v2 = globals.VIS_TRANSFORM_2D*Vector2(_v2.coords[0], _v2.coords[1])

	_v0.coords_changed.connect(self.on_v0_changed)
	_v1.coords_changed.connect(self.on_v1_changed)
	_v2.coords_changed.connect(self.on_v2_changed)

func on_v0_changed(coords : Array) -> void:
	v0 = Vector2(coords[0], coords[1])
	queue_redraw()
	
func on_v1_changed(coords : Array) -> void:
	v1 = Vector2(coords[0], coords[1])
	queue_redraw()

func on_v2_changed(coords : Array) -> void:
	v2 = Vector2(coords[0], coords[1])
	queue_redraw()
