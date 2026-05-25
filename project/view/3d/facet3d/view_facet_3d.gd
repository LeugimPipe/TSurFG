extends Node3D

var v0 : Vector3 = Vector3.ZERO
var v1 : Vector3 = Vector3.ZERO
var v2 : Vector3 = Vector3.ZERO

func init(_edge1, _edge2, _edge3) -> void:
	v0.x = _edge1.tail.coords[0]
	v0.y = _edge1.tail.coords[1]
	if _edge1.tail.coords.size() > 2:
		v0.z = _edge1.tail.coords[2]
	
	v1.x = _edge2.tail.coords[0]
	v1.y = _edge2.tail.coords[1]
	if _edge2.tail.coords.size() > 2:
		v1.z = _edge2.tail.coords[2]
	
	v2.x = _edge3.tail.coords[0]
	v2.y = _edge3.tail.coords[1]
	if _edge3.tail.coords.size() > 2:
		v2.z = _edge3.tail.coords[2]
	
	draw()

func draw() -> void:
	position = v0

	$GimbalOuter/GimbalInner/FacetVis.mesh.size.x = e0().length()
	$GimbalOuter/GimbalInner/FacetVis.position.x = e0().length()/2
	
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
	
	# Height
	$GimbalOuter/GimbalInner/FacetVis.mesh.size.y = height()
	$GimbalOuter/GimbalInner/FacetVis.position.y = height()/2
	
	# Angle to triangle
	# Current height vector
	var cur_height = Vector3( cos(lat+PI/2)*cos(long), sin(lat+PI/2), cos(lat+PI/2)*sin(long))
	var angle = cur_height.signed_angle_to(height_vector(), $GimbalOuter/GimbalInner.basis.x)
	$GimbalOuter/GimbalInner.rotation.x = -angle
	
	# Shear transform
	var t = Transform3D()
	var shear_factor = e0().normalized().dot(-e2()) / e0().length() - .5
	t.basis.y = Vector3(shear_factor,1,0)
	$GimbalOuter/GimbalInner/FacetVis.transform = t*$GimbalOuter/GimbalInner/FacetVis.transform

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
