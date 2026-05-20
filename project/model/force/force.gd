extends Node

# TODO
# Las coordenadas deberian ser un tipo especial de Array a semejanza de Vector2 y Vector3
# Una cosa como VectorN
@export var coords : Array = []: set = set_coords

signal coords_changed

func set_coords(value : Array):
	coords = value.duplicate()
	coords_changed.emit(coords)

#var view

# Initialize the force
func init(_coords : Array = []) -> void:
	coords = _coords
	
	#if globals.AMBIENT_DIMENSION == 2:
	#	view = load("res://view/2d/vertex2d/view_vertex_2d.tscn").instantiate()
	
	#if globals.AMBIENT_DIMENSION == 3:
	#	view = load("res://view/3d/vertex3d/view_vertex_3d.tscn").instantiate()
	
	#view.init(self)
	#add_child(view)
