extends MeshInstance3D

func _ready() -> void:
	get_node("/root/Controller/Geometry").cam_info_calculated.connect(change_radius)

func init(_vertex : Vertex) -> void:
	position.x = _vertex.coords.get_i(0)
	position.y = _vertex.coords.get_i(1)
	if _vertex.coords.dimension > 2:
		position.z = _vertex.coords.get_i(2)
	_vertex.coords_changed.connect(self.on_coords_changed)

func on_coords_changed(coords: VectorN) -> void:
	position.x = coords.get_i(0)
	position.y = coords.get_i(1)
	if coords.dimension > 2:
		position.z = coords.get_i(2)

func change_radius(_center : VectorN, radius : float) -> void:
	mesh.radius = min( pow(radius, 3./2.) * 0.05, 0.05)
	mesh.height = min( pow(radius, 3./2.) * 0.1, 0.1)
