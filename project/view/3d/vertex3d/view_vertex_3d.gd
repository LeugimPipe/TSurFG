extends MeshInstance3D

func _ready() -> void:
	get_node("/root/Controller/Body").cam_info_calculated.connect(change_radius)

func init(_vertex) -> void:
	position.x = _vertex.coords[0]
	position.y = _vertex.coords[1]
	if _vertex.coords.size() > 2:
		position.z = _vertex.coords[2]
	_vertex.coords_changed.connect(self.on_coords_changed)

func on_coords_changed(coords: Array) -> void:
	position.x = coords[0]
	position.y = coords[1]
	if coords.size() > 2:
		position.z = coords[2]

func change_radius(_center : Array, radius : float) -> void:
	mesh.radius = min( pow(radius, 3./2.) * 0.05, 0.05)
	mesh.height = min( pow(radius, 3./2.) * 0.1, 0.1)
