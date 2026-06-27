extends "res://model/body/body.gd"

func init() -> void:
	for i in 6:
		vertices.append(vertex_scene.instantiate())
	
	vertices[0].init([0,0], true)
	vertices[1].init([2,0], true)
	vertices[2].init([0,1], true)
	vertices[3].init([2,1], true)
	vertices[4].init([0,1./2])
	vertices[5].init([2,1./2])
	
	for i in 6:
		add_child(vertices[i])
	
	for i in 5:
		edges.append(edge_scene.instantiate())
	
	edges[0].init(vertices[0], vertices[4])
	edges[1].init(vertices[1], vertices[5])
	edges[2].init(vertices[2], vertices[4])
	edges[3].init(vertices[3], vertices[5])
	edges[4].init(vertices[4], vertices[5])
	
	for i in 5:
		add_child(edges[i])
	
	print("Total length: %s" % get_total_length())
	var ang = Vector2(edges[0].head.coords[0] - edges[0].tail.coords[0], edges[0].head.coords[1] - edges[0].tail.coords[1]).angle_to(
		Vector2(edges[2].head.coords[0] - edges[2].tail.coords[0], edges[2].head.coords[1] - edges[2].tail.coords[1])
	)
	print("Angle: %s" % rad_to_deg(ang))

func get_total_length() -> float:
	var total_length = 0.
	
	for e in edges:
		total_length += get_length(e)
	
	return total_length

func get_length(edge) -> float:
	var norm : float = 0.
	for i in min(globals.AMBIENT_DIMENSION, edge.head.coords.size(), edge.tail.coords.size()):
		norm += (edge.head.coords[i] - edge.tail.coords[i])*(edge.head.coords[i] - edge.tail.coords[i])
	
	return sqrt(norm)

func calc_forces() -> void:
	super()
	
	# Force 1: Gradient of length
	for i in vertices.size():
		calc_force_vertex(i)

func calc_force_vertex(i: int) -> void:
	if i >= vertices.size():
		print("ERROR: attempted to access non existent vertex of index %s" % i)
		return
	
	var verti = vertices[i]
	
	# Force 1: Gradient of length
	var vedges = get_edges_of_vertex(i)
	for ee in vedges:
		var vl
		if verti == ee.tail:
			vl = ee.head
		if verti == ee.head:
			vl = ee.tail
		
		var force_link = force_scene.instantiate()
		if !verti.fixed:
			force_link.init([ (vl.coords[0] - verti.coords[0])/get_length(ee), (vl.coords[1] - verti.coords[1])/get_length(ee) ])
			forces[i][0].coords = [ forces[i][0].coords[0] + force_link.coords[0], forces[i][0].coords[1] + force_link.coords[1] ] 

func get_edges_of_vertex(i : int) -> Array:
	var ret : Array = []
	
	for ee in edges:
		if vertices[i] == ee.tail or vertices[i] == ee.head:
			ret.append(ee)
	
	return ret

func iterate() -> void:
	super()
	
	print("Total length: %s" % get_total_length())
	var ang = Vector2(edges[0].head.coords[0] - edges[0].tail.coords[0], edges[0].head.coords[1] - edges[0].tail.coords[1]).angle_to(
		Vector2(edges[2].head.coords[0] - edges[2].tail.coords[0], edges[2].head.coords[1] - edges[2].tail.coords[1])
	)
	print("Angle: %s" % rad_to_deg(ang))
