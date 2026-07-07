extends Node3D

var tail : Vector3 = Vector3.ZERO
var head : Vector3 = Vector3.ZERO

func _ready() -> void:
	get_node("/root/Controller/Geometry").cam_info_calculated.connect(change_radius)

func init(_tail : Vertex, _head : Vertex) -> void:
	tail.x = _tail.coords.get_i(0)
	tail.y = _tail.coords.get_i(1)
	if _tail.coords.dimension > 2:
		tail.z = _tail.coords.get_i(2)
	_tail.coords_changed.connect(self.on_tail_changed)
	
	head.x = _head.coords.get_i(0)
	head.y = _head.coords.get_i(1)
	if _head.coords.dimension > 2:
		head.z = _head.coords.get_i(2)
	_head.coords_changed.connect(self.on_head_changed)
	
	draw()

func on_tail_changed(coords : VectorN) -> void:
	tail.x = coords.get_i(0)
	tail.y = coords.get_i(1)
	if coords.dimension > 2:
		tail.z = coords.get_i(2)
	
	draw()

func on_head_changed(coords : VectorN) -> void:
	head.x = coords.get_i(0)
	head.y = coords.get_i(1)
	if coords.dimension > 2:
		head.z = coords.get_i(2)
	
	draw()

func draw() -> void:
	position = tail
	
	var segment = head - tail
	$Gimbal/EdgeVis.mesh.height = segment.length()
	$Gimbal/EdgeVis.position.x = segment.length()/2
	
	# Longitude
	var long = Vector2(segment.x, segment.z).angle()
	rotation.y = -long
	
	# Latitude
	var lat
	if segment.x == 0 and segment.z == 0:
		lat = PI/2
	else:
		lat = segment.angle_to(Vector3(segment.x, 0 , segment.z))
	if segment.y < 0: lat = -lat
	$Gimbal.rotation.z = lat

func change_radius(_center : VectorN, radius : float) -> void:
	$Gimbal/EdgeVis.mesh.top_radius = min(  pow(radius, 3./2.) * 0.025, 0.025)
	$Gimbal/EdgeVis.mesh.bottom_radius = min(  pow(radius, 3./2.) * 0.025, 0.025)
