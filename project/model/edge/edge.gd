extends Node

var id

var tail
var head

var tail_id
var head_id

var view

func init(_id = -1, _tail = null, _head = null) -> void:
	if view != null: view.queue_free()
	id = _id
	tail = _tail
	head = _head
	
	tail_id = tail.get_id()
	head_id = head.get_id()
	
	tail.connect_edge(self)
	head.connect_edge(self, false)
	
	if globals.AMBIENT_DIMENSION == 2:
		view = load("res://view/2d/edge2d/view_edge_2d.tscn").instantiate()
	
	if globals.AMBIENT_DIMENSION == 3:
		view = load("res://view/3d/edge3d/view_edge_3d.tscn").instantiate()

	view.init(tail, head)
	add_child(view)

func get_id() -> int:
	return id

func midpoint() -> Array:
	var ret = [0, 0, 0]
	
	for i in 3:
		ret[i] = 0.5 * (tail.coords[i] + head.coords[i])
	
	return ret
