extends Node

var edge1
var edge2
var edge3

var view

func init( _edge1 = null, _edge2 = null, _edge3 = null) -> void:
	edge1 = _edge1
	edge2 = _edge2
	edge3 = _edge3
	
	# check edges form a closed loop
	if (edge1.head != edge2.tail):
		print("ERROR: head of edge 1 of facet is different from tail of edge 2")
		return
	
	if (edge2.head != edge3.tail):
		print("ERROR: head of edge 2 of facet is different from tail of edge 3")
		return
	
	if (edge3.head != edge1.tail):
		print("ERROR: head of edge 3 of facet is different from tail of edge 1")
		return
	
	if globals.AMBIENT_DIMENSION == 2:
		view = load("res://view/2d/facet2d/view_facet_2d.tscn").instantiate()
	
	if globals.AMBIENT_DIMENSION == 3:
		view = load("res://view/3d/facet3d/view_facet_3d.tscn").instantiate()

	view.init(edge1, edge2, edge3)
	add_child(view)
