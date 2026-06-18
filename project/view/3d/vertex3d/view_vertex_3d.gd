extends MeshInstance3D

func _ready() -> void:
	await get_node("/root/Main").child_entered_tree
	var cam = get_node("/root/Main/Main3D/CameraGimbal")
	await cam.ready
	#cam.zoom_changed.connect(_on_cam_zoom_changed)

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

func _on_cam_zoom_changed(zoom : float) -> void:
	mesh.radius = min(zoom * 0.05, 0.05)
	mesh.height = min(zoom * 0.1, 0.1)
