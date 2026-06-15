extends Node

# TODO
# Las coordenadas deberian ser un tipo especial de Array a semejanza de Vector2 y Vector3
# Una cosa como VectorN
var coords : Array = []: set = set_coords
var saved_coords : Array = []
var fixed : bool = false

signal coords_changed

func set_coords(value : Array):
	coords = value.duplicate()
	if !globals.CALCULATING_STEP:
		coords_changed.emit(coords)

var view

func save_coords() -> void:
	saved_coords = coords.duplicate()

func restore_coords() -> void:
	coords = saved_coords.duplicate()

# Initialize the vertex
func init(_coords : Array = [], _fixed : bool = false) -> void:
	coords = _coords
	fixed = _fixed
	
	if globals.AMBIENT_DIMENSION == 2:
		view = load("res://view/2d/vertex2d/view_vertex_2d.tscn").instantiate()
	
	if globals.AMBIENT_DIMENSION == 3:
		view = load("res://view/3d/vertex3d/view_vertex_3d.tscn").instantiate()
	
	view.init(self)
	add_child(view)

func get_as_vector():
	if globals.AMBIENT_DIMENSION == 2:
		return Vector2(coords[0], coords[1])
	if globals.AMBIENT_DIMENSION == 3:
		if coords.size() == 2:
			return Vector3(coords[0], coords[1], 0)
		if coords.size() == 3:
			return Vector3(coords[0], coords[1], coords[2])
