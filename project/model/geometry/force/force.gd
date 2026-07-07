extends Node
class_name Force

var coords : VectorN = VectorN.new(): set = set_coords

signal coords_changed

func set_coords(value : VectorN):
	coords.init(value.dimension)
	for i in coords.dimension:
		coords.set_i(i, value.get_i(i))
	
	coords_changed.emit(coords)

#var view

# Initialize the force
func init(_coords : VectorN = VectorN.new()) -> void:
	coords = _coords
	
	#if globals.AMBIENT_DIMENSION == 2:
	#	view = load("res://view/2d/vertex2d/view_vertex_2d.tscn").instantiate()
	
	#if globals.AMBIENT_DIMENSION == 3:
	#	view = load("res://view/3d/vertex3d/view_vertex_3d.tscn").instantiate()
	
	#view.init(self)
	#add_child(view)

func sum_vector(with : VectorN) -> void:
	coords = coords.sum(with)
