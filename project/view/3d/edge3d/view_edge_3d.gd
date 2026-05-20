extends Node3D

var tail : Vector3 = Vector3.ZERO
var head : Vector3 = Vector3.ZERO

func init(_tail, _head) -> void:
	tail.x = _tail.coords[0]
	tail.y = _tail.coords[1]
	if _tail.coords.size() > 2:
		tail.z = _tail.coords[2]
	_tail.coords_changed.connect(self.on_tail_changed)
	
	head.x = _head.coords[0]
	head.y = _head.coords[1]
	if _head.coords.size() > 2:
		head.z = _head.coords[2]
	_head.coords_changed.connect(self.on_head_changed)
	
	draw()

func on_tail_changed(coords : Array) -> void:
	tail.x = coords[0]
	tail.y = coords[1]
	if coords.size() > 2:
		tail.z = coords[2]

	draw()
	
func on_head_changed(coords : Array) -> void:
	head.x = coords[0]
	head.y = coords[1]
	if coords.size() > 2:
		head.z = coords[2]

	draw()
	
func draw() -> void:
	var t = Transform3D()
	t.origin = tail
	t.basis.x = head - tail
	transform = t
