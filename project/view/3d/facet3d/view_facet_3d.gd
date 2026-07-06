extends Node3D

var v0 : Vector3 = Vector3.ZERO
var v1 : Vector3 = Vector3.ZERO
var v2 : Vector3 = Vector3.ZERO

func init(_v0 : Vertex, _v1 : Vertex, _v2 : Vertex) -> void:
	v0.x = _v0.coords.get_i(0)
	v0.y = _v0.coords.get_i(1)
	if _v0.coords.dimension > 2:
		v0.z = _v0.coords.get_i(2)
	_v0.coords_changed.connect(self.on_v0_changed)
	
	v1.x = _v1.coords.get_i(0)
	v1.y = _v1.coords.get_i(1)
	if _v1.coords.dimension > 2:
		v1.z = _v1.coords.get_i(2)
	_v1.coords_changed.connect(self.on_v1_changed)
	
	v2.x = _v2.coords.get_i(0)
	v2.y = _v2.coords.get_i(1)
	if _v2.coords.dimension > 2:
		v2.z = _v2.coords.get_i(2)
	_v2.coords_changed.connect(self.on_v2_changed)
	
	draw()

func on_v0_changed(coords : VectorN) -> void:
	v0.x = coords.get_i(0)
	v0.y = coords.get_i(1)
	if coords.dimension > 2:
		v0.z = coords.get_i(2)
	draw()

func on_v1_changed(coords : VectorN) -> void:
	v1.x = coords.get_i(0)
	v1.y = coords.get_i(1)
	if coords.dimension > 2:
		v1.z = coords.get_i(2)
	draw()

func on_v2_changed(coords : VectorN) -> void:
	v2.x = coords.get_i(0)
	v2.y = coords.get_i(1)
	if coords.dimension > 2:
		v2.z = coords.get_i(2)
	draw()

func draw() -> void:
	$GimbalOuter/GimbalInner/FacetVis.transform = Transform3D.IDENTITY
	position = v0

	# Base
	$GimbalOuter/GimbalInner/FacetVis.mesh.size.x = e0().length()
	$GimbalOuter/GimbalInner/FacetVis.position.x = e0().length()/2
	
	# Height
	$GimbalOuter/GimbalInner/FacetVis.mesh.size.y = height()
	$GimbalOuter/GimbalInner/FacetVis.position.y = height()/2
	
	
	# Shear transform
	# Transform height vector (0, height(), 0)
	# Tail in (e0.length(), 0, 0)
	# Head in (e0.length(), height(), 0)
	# Into (shear_factor, height(), 0)
	# Tail in (e0.length(), 0, 0)
	# Head in (e0.length()+shear_factor, height(), 0)
	# Such that it ends, when the other transformations are done, in v2
	var t = Transform3D()
	# Median vector of the triangle
	# (Image of the current height vector)
	var median_vector = v2 - (v0+v1)/2
	var shear_factor = e0().normalized().dot(median_vector) / height()
	t.basis.y = Vector3(shear_factor,1,0)
	$GimbalOuter/GimbalInner/FacetVis.transform = t*$GimbalOuter/GimbalInner/FacetVis.transform
	
	$GimbalOuter/GimbalInner/Normal.position.x = (1.5+shear_factor)/3 * (e0().length())
	$GimbalOuter/GimbalInner/Normal.position.y = height()/3
	
	# Longitude
	var long = Vector2(e0().x, e0().z).angle()
	rotation.y = -long
	
	# Latitude
	var lat
	if e0().x == 0 and e0().z == 0:
		lat = PI/2
	else:
		lat = e0().angle_to(Vector3(e0().x, 0 , e0().z))
	if e0().y < 0: lat = -lat
	$GimbalOuter.rotation.z = lat
	
	# Angle to triangle
	# Current height vector
	var cur_height = Vector3( cos(lat+PI/2)*cos(long), sin(lat+PI/2), cos(lat+PI/2)*sin(long))
	var angle = cur_height.signed_angle_to(height_vector(), e0())
	$GimbalOuter/GimbalInner.rotation.x = angle

func e0() -> Vector3:
	return v1 - v0

func e1() -> Vector3:
	return v2 - v1

func e2() -> Vector3:
	return v0 - v2

func normal() -> Vector3:
	return e0().cross(e1())

func height_vector() -> Vector3:
	var dir = normal().cross(e0())
	return height()*(dir.normalized())

func area() -> float:
	return normal().length()/2

func height() -> float:
	return normal().length() / e0().length()
