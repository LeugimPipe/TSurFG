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
	var t = Transform3D()
	t.origin = v0
	t.basis.x = v1 - v0
	t.basis.y = v2 - v0 - 0.5*t.basis.x
	
	transform = t
