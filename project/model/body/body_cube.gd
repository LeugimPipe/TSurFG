extends "res://model/body/body.gd"

func init() -> void:
	# Vertices
	for i in 14:
		vertices.append(vertex_scene.instantiate())
	
	for i in 8:
		vertices[i].init([ (((i/2)/2)%2) * 2 -1, ((i/2)%2) * 2 -1, (i%2) * 2 -1 ])
	
	vertices[8].init( [ 0, 0, -1] )
	vertices[9].init( [ 0, 0, 1] )
	vertices[10].init( [ 0, -1, 0] )
	vertices[11].init( [ 0, 1, 0] )
	vertices[12].init( [ -1, 0, 0] )
	vertices[13].init( [ 1, 0, 0] )
	
	for i in 14:
		add_child(vertices[i])
	
	# Edges
	var nedges = 12+4*6
	for i in nedges:
		edges.append(edge_scene.instantiate())
	
	# -Y face border
	edges[0].init(vertices[0], vertices[1])
	edges[1].init(vertices[1], vertices[5])
	edges[2].init(vertices[5], vertices[4])
	edges[3].init(vertices[4], vertices[0])
	
	# +Y face border
	edges[4].init(vertices[2], vertices[3])
	edges[5].init(vertices[3], vertices[7])
	edges[6].init(vertices[7], vertices[6])
	edges[7].init(vertices[6], vertices[2])
	
	# Edges connecting both faces
	edges[8].init(vertices[0], vertices[2])
	edges[9].init(vertices[1], vertices[3])
	edges[10].init(vertices[5], vertices[7])
	edges[11].init(vertices[4], vertices[6])
	
	# -Y face diagonals
	edges[12].init(vertices[0], vertices[10])
	edges[13].init(vertices[1], vertices[10])
	edges[14].init(vertices[5], vertices[10])
	edges[15].init(vertices[4], vertices[10])
	
	# +Y face diagonals
	edges[16].init(vertices[2], vertices[11])
	edges[17].init(vertices[3], vertices[11])
	edges[18].init(vertices[7], vertices[11])
	edges[19].init(vertices[6], vertices[11])
	
	# -X face diagonals
	edges[20].init(vertices[0], vertices[12])
	edges[21].init(vertices[1], vertices[12])
	edges[22].init(vertices[2], vertices[12])
	edges[23].init(vertices[3], vertices[12])
	
	# +X face diagonals
	edges[24].init(vertices[4], vertices[13])
	edges[25].init(vertices[5], vertices[13])
	edges[26].init(vertices[6], vertices[13])
	edges[27].init(vertices[7], vertices[13])
	
	# -Z face diagonals
	edges[28].init(vertices[0], vertices[8])
	edges[29].init(vertices[2], vertices[8])
	edges[30].init(vertices[4], vertices[8])
	edges[31].init(vertices[6], vertices[8])
	
	# +Z face diagonals
	edges[32].init(vertices[1], vertices[9])
	edges[33].init(vertices[3], vertices[9])
	edges[34].init(vertices[5], vertices[9])
	edges[35].init(vertices[7], vertices[9])
	
	for i in nedges:
		add_child(edges[i])
	
	# Factes
	var nfacets = 6*4
	for i in nfacets:
		facets.append(facet_scene.instantiate())

	# -Y face
	facets[0].init(edges[0].inverse(), edges[12], edges[13].inverse())
	facets[1].init(edges[1].inverse(), edges[13], edges[14].inverse())
	facets[2].init(edges[2].inverse(), edges[14], edges[15].inverse())
	facets[3].init(edges[3].inverse(), edges[15], edges[12].inverse())
	
	# -Z face
	facets[4].init(edges[3], edges[28], edges[30].inverse())
	facets[5].init(edges[8], edges[29], edges[28].inverse())
	facets[6].init(edges[7].inverse(), edges[31], edges[29].inverse())
	facets[7].init(edges[11].inverse(), edges[30], edges[31].inverse())
	
	# -X face
	facets[8].init(edges[0], edges[21], edges[20].inverse())
	facets[9].init(edges[9], edges[23], edges[21].inverse())
	facets[10].init(edges[4].inverse(), edges[22], edges[23].inverse())
	facets[11].init(edges[8].inverse(), edges[20], edges[22].inverse())
	
	# +X face
	facets[12].init(edges[2], edges[24], edges[25].inverse())
	facets[13].init(edges[11], edges[26], edges[24].inverse())
	facets[14].init(edges[6].inverse(), edges[27], edges[26].inverse())
	facets[15].init(edges[10].inverse(), edges[25], edges[27].inverse())
	
	# +Z face
	facets[16].init(edges[1], edges[34], edges[32].inverse())
	facets[17].init(edges[10], edges[35], edges[34].inverse())
	facets[18].init(edges[5].inverse(), edges[33], edges[35].inverse())
	facets[19].init(edges[9].inverse(), edges[32], edges[33].inverse())
	
	# +Y face
	facets[20].init(edges[5], edges[18], edges[17].inverse())
	facets[21].init(edges[6], edges[19], edges[18].inverse())
	facets[22].init(edges[7], edges[16], edges[19].inverse())
	facets[23].init(edges[4], edges[17], edges[16].inverse())
	
	# TODO: check compatible orientations
	
	for i in nfacets:
		add_child(facets[i])
	
	print("Total area: %s" % get_total_area())

func get_total_area() -> float:
	var ret = 0.
	
	for f in facets:
		ret += f.area()

	return ret

func set_forces_zero() -> void:
	forces.resize(vertices.size())
	for i in forces.size():
		var zeroforce = force_scene.instantiate()
		zeroforce.init([0,0,0])
		forces[i] = [zeroforce]

func calc_forces() -> void:
	super()
	
	# Force 1: Gradient of area
	for i in vertices.size():
		calc_force_vertex(i)

func calc_force_vertex(i: int) -> void:
	if i >= vertices.size():
		print("ERROR: attempted to access non existent vertex of index %s" % i)
		return
	
	var verti = vertices[i]
	
	# Force 1: Gradient of area
	var vfacets = get_facets_of_vertex(i)
	for f in vfacets:
		var vector = f.get_oposite_side_rotated(verti)
		
		var force_link = force_scene.instantiate()
		force_link.init( [.5 * vector.x , .5 * vector.y, .5 * vector.z] )
		forces[i][0].coords = [ forces[i][0].coords[0] + force_link.coords[0], forces[i][0].coords[1] + force_link.coords[1], forces[i][0].coords[2] + force_link.coords[2] ]

func iterate() -> void:
	for i in vertices.size():
		vertices[i].coords = [ vertices[i].coords[0] + 0.2*forces[i][0].coords[0], vertices[i].coords[1] + 0.2*forces[i][0].coords[1], vertices[i].coords[2] + 0.2*forces[i][0].coords[2] ]

	calc_forces()
	
	print("Total area: %s" % get_total_area())

func get_facets_of_vertex(i : int) -> Array:
	var ret : Array = []
	
	for ff in facets:
		if ff.is_vertex_in_facet(vertices[i]):
			ret.append(ff)

	return ret
