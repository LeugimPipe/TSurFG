extends Node

var tail
var head

var view

func init(_tail = null, _head = null) -> void:
	if view != null: view.queue_free()
	tail = _tail
	head = _head
	
	if globals.AMBIENT_DIMENSION == 2:
		view = load("res://view/2d/edge2d/view_edge_2d.tscn").instantiate()
	
	if globals.AMBIENT_DIMENSION == 3:
		view = load("res://view/3d/edge3d/view_edge_3d.tscn").instantiate()

	view.init(tail, head)
	add_child(view)

func midpoint() -> Array:
	var ret = [0, 0, 0]
	
	for i in 3:
		ret[i] = 0.5 * (tail.coords[i] + head.coords[i])
	
	return ret
