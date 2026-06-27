extends "res://model/body/body.gd"

var VOLUME = 8.
var TIME_STEP = 0.1

var volume_dot_product : float = 0.

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
	facets[0].init(edges[0], edges[12], edges[13], true, false, true)
	facets[1].init(edges[1], edges[13], edges[14], true, false, true)
	facets[2].init(edges[2], edges[14], edges[15], true, false, true)
	facets[3].init(edges[3], edges[15], edges[12], true, false, true)
	
	# -Z face
	facets[4].init(edges[3], edges[28], edges[30], false, false, true)
	facets[5].init(edges[8], edges[29], edges[28], false, false, true)
	facets[6].init(edges[7], edges[31], edges[29], true, false, true)
	facets[7].init(edges[11], edges[30], edges[31], true, false, true)
	
	# -X face
	facets[8].init(edges[0], edges[21], edges[20], false, false, true)
	facets[9].init(edges[9], edges[23], edges[21], false, false, true)
	facets[10].init(edges[4], edges[22], edges[23], true, false, true)
	facets[11].init(edges[8], edges[20], edges[22], true, false, true)
	
	# +X face
	facets[12].init(edges[2], edges[24], edges[25], false, false, true)
	facets[13].init(edges[11], edges[26], edges[24], false, false, true)
	facets[14].init(edges[6], edges[27], edges[26], true, false, true)
	facets[15].init(edges[10], edges[25], edges[27], true, false, true)
	
	# +Z face
	facets[16].init(edges[1], edges[34], edges[32], false, false, true)
	facets[17].init(edges[10], edges[35], edges[34], false, false, true)
	facets[18].init(edges[5], edges[33], edges[35], true, false, true)
	facets[19].init(edges[9], edges[32], edges[33], true, false, true)
	
	# +Y face
	facets[20].init(edges[5], edges[18], edges[17], false, false, true)
	facets[21].init(edges[6], edges[19], edges[18], false, false, true)
	facets[22].init(edges[7], edges[16], edges[19], false, false, true)
	facets[23].init(edges[4], edges[17], edges[16], false, false, true)
	
	# TODO: check compatible orientations
	
	for i in nfacets:
		add_child(facets[i])
	
	# Force init
	forces.resize(vertices.size())
	for i in forces.size():
		var zeroforce = force_scene.instantiate()
		zeroforce.init([0,0,0])
		forces[i] = [zeroforce]
	
	print("Total area: %s" % get_total_area())
	print("Total volume: %s" % get_volume())

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
		forces[i][0] = zeroforce

func calc_forces() -> void:
	super()
	
	calc_volume_gradient()
	
	calc_volume_gradient_product()
	
	# Force 1: Gradient of area
	for i in vertices.size():
		calc_force_vertex(i)
	
	# Project forces to be perpendicular to volume gradients
	
	# Calculate dot product of forces and gradients
	var dot_product = 0.0
	for i in vertices.size():
		dot_product += Vector3( forces[i][0].coords[0], forces[i][0].coords[1], forces[i][0].coords[2] ).dot(
			Vector3( forces[i][1].coords[0], forces[i][1].coords[1], forces[i][1].coords[2])
			)
	
	var factor = dot_product / volume_dot_product
	
	for i in vertices.size():
		forces[i][0].coords = [ forces[i][0].coords[0] - factor*forces[i][1].coords[0], forces[i][0].coords[1] - factor*forces[i][1].coords[1], forces[i][0].coords[2] - factor*forces[i][1].coords[2] ]
	

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

func alter_coordinates() -> void:
	for i in vertices.size():
		vertices[i].coords = [ vertices[i].coords[0] + TIME_STEP*forces[i][0].coords[0], vertices[i].coords[1] + TIME_STEP*forces[i][0].coords[1], vertices[i].coords[2] + TIME_STEP*forces[i][0].coords[2] ]

	for i in vertices.size():
		vertices[i].coords = [ vertices[i].coords[0] + forces[i][1].coords[0], vertices[i].coords[1] + forces[i][1].coords[1], vertices[i].coords[2] + forces[i][1].coords[2] ]

func save_coords() -> void:
	for v in vertices:
		v.save_coords()

func restore_coords() -> void:
	for v in vertices:
		v.restore_coords()

func iterate() -> void:
	save_coords()
	globals.CALCULATING_STEP = true
	
	# Set up the three steps
	var s1 = TIME_STEP
	var s0 = s1 / 2
	var s2 = s1 * 2
	
	# Calculate values for the 3 steps
	restore_coords()
	TIME_STEP = s1
	alter_coordinates()
	var s1_area = get_total_area()
	# print("Total area %s: %s" % [s1, s1_area])
	
	restore_coords()
	TIME_STEP = s0
	alter_coordinates()
	var s0_area = get_total_area()
	# print("Total area %s: %s" % [s0, s0_area])
	
	restore_coords()
	TIME_STEP = s2
	alter_coordinates()
	var s2_area = get_total_area()
	# print("Total area %s: %s" % [s2, s2_area])
	
	while (s1_area > s2_area):
		s0 = s1
		s0_area = s1_area
		s1 = s2
		s1_area = s2_area
		s2 = s1*2
		TIME_STEP = s2
		restore_coords()
		alter_coordinates()
		s2_area = get_total_area()
		# print("Total area %s: %s" % [s2, s2_area])
	
	while (s1_area > s0_area):
		s2 = s1
		s2_area = s1_area
		s1 = s0
		s1_area = s0_area
		s0 = s1/2
		TIME_STEP = s0
		restore_coords()
		alter_coordinates()
		s0_area = get_total_area()
		# print("Total area %s: %s" % [s0, s0_area])
	
	restore_coords()
	globals.CALCULATING_STEP = false

	if (2*s0_area - 3*s1_area + s2_area == 0.0): TIME_STEP = 1.0
	else: TIME_STEP = 0.75 * s1 * (4*s0_area - 5*s1_area + s2_area) / (2*s0_area - 3*s1_area + s2_area)
	TIME_STEP = min(TIME_STEP, 1.0)
	print("Time step: %s" % TIME_STEP)
	alter_coordinates()
	
	calc_all_ev_vectors()
	
	print("Total area: %s" % get_total_area())
	print("Total volume: %s" % get_volume())

func get_facets_of_vertex(i : int) -> Array:
	var ret : Array = []
	
	for ff in facets:
		if ff.is_vertex_in_facet(vertices[i]):
			ret.append(ff)

	return ret

func refine() -> void:
	var new_edges = []
	var old_n_edges = edges.size()
	var old_n_vertices = vertices.size()
	var new_facets = []
	
	for e in edges:
		# Index of new central vertex
		# of edge i
		# old_n_vertices + i
		vertices.append(vertex_scene.instantiate())
		vertices[-1].init(e.midpoint())
		add_child(vertices[-1])
		
		new_edges.append(edge_scene.instantiate())
		new_edges[-1].init( e.tail, vertices[-1] )
		add_child(new_edges[-1])
		
		new_edges.append(edge_scene.instantiate())
		new_edges[-1].init( vertices[-1], e.head )
		add_child(new_edges[-1])
	
	# Index of descendant edges
	# of edge i
	# old_n_edges+2*i
	# old_n_edges+2*i+1
	for e in new_edges:
		edges.append(e)
	new_edges.clear()
	
	for f in facets:
		var e0_index = -1
		var e1_index = -1
		var e2_index = -1
		
		for i in old_n_edges:
			if edges[i] == f.edge0:
				e0_index = i
			if edges[i] == f.edge1:
				e1_index = i
			if edges[i] == f.edge2:
				e2_index = i
		
		if e0_index == -1 or e1_index == -1 or e2_index == -1:
			print("ERROR: index not found")
		
		# Extra central edges
		new_edges.append(edge_scene.instantiate())
		new_edges[-1].init( vertices[old_n_vertices + e0_index], vertices[old_n_vertices + e1_index] )
		add_child(new_edges[-1])
		
		new_edges.append(edge_scene.instantiate())
		new_edges[-1].init( vertices[old_n_vertices + e1_index], vertices[old_n_vertices + e2_index] )
		add_child(new_edges[-1])
		
		new_edges.append(edge_scene.instantiate())
		new_edges[-1].init( vertices[old_n_vertices + e2_index], vertices[old_n_vertices + e0_index] )
		add_child(new_edges[-1])
		
		# New facets
		new_facets.append(facet_scene.instantiate())
		new_facets[-1].init( new_edges[-2], edges[old_n_edges + 2*e1_index + int(!f.inversee1)], edges[old_n_edges + 2*e2_index + int(f.inversee2)], true, f.inversee1, f.inversee2 )
		add_child(new_facets[-1])
		
		new_facets.append(facet_scene.instantiate())
		new_facets[-1].init( edges[old_n_edges + 2*e0_index + int(!f.inversee0)], edges[old_n_edges + 2*e1_index + int(f.inversee1)], new_edges[-3], f.inversee0, f.inversee1, true )
		add_child(new_facets[-1])
		
		new_facets.append(facet_scene.instantiate())
		new_facets[-1].init( edges[old_n_edges + 2*e0_index + int(f.inversee0)], new_edges[-1], edges[old_n_edges + 2*e2_index + int(!f.inversee2)], f.inversee0, true, f.inversee2 )
		add_child(new_facets[-1])
		
		# Turn original facet into central facet
		f.init( new_edges[-3], new_edges[-2], new_edges[-1] )
		
	for e in new_edges:
		edges.append(e)
	
	for f in new_facets:
		facets.append(f)
	
	for i in old_n_edges:
		edges.pop_front().queue_free()
	
	forces.resize(vertices.size())
	for i in forces.size():
		var zeroforce = force_scene.instantiate()
		zeroforce.init([0,0,0])
		forces[i] = [zeroforce]
	
	calc_all_ev_vectors()

func get_volume() -> float:
	var ret = 0.
	for f in facets:
		ret += f.volume_contribution()
	return ret

func calc_volume_gradient_vertex(i: int) -> void:
	if i >= vertices.size():
		print("ERROR: attempted to access non existent vertex of index %s" % i)
		return
	
	var verti = vertices[i]
	
	var vfacets = get_facets_of_vertex(i)
	for f in vfacets:
		var q = f.get_next_vertex(verti).get_as_vector()
		var r = f.get_prev_vertex(verti).get_as_vector()
		var prod = q.cross(r)
				
		var grad_facet = force_scene.instantiate()
		grad_facet.init( [1./6 * prod.x , 1./6 * prod.y, 1./6 * prod.z] )
		forces[i][1].coords = [ forces[i][1].coords[0] + grad_facet.coords[0], forces[i][1].coords[1] + grad_facet.coords[1], forces[i][1].coords[2] + grad_facet.coords[2] ]

# Calculates dot product of all volume gradient and stores it
func calc_volume_gradient_product() -> void:
	volume_dot_product = 0.
	for i in vertices.size():
		volume_dot_product += Vector3( forces[i][1].coords[0], forces[i][1].coords[1], forces[i][1].coords[2] ).dot( Vector3( forces[i][1].coords[0], forces[i][1].coords[1], forces[i][1].coords[2] ) )

# Calculates volume gradients and stores them in forces[i][1]
func calc_volume_gradient() -> void:
	forces.resize(vertices.size())
	for i in forces.size():
		var zeroforce = force_scene.instantiate()
		zeroforce.init([0,0,0])
		forces[i].resize(2)
		forces[i][1] = zeroforce
	
	for i in vertices.size():
		calc_volume_gradient_vertex(i)

# CONSTANT VOLUME 8
func restore_constants() -> void:
	
	var delta = get_volume() - VOLUME
	var scale = -delta/volume_dot_product
	
	for i in forces.size():
		forces[i][1].coords = [ scale*forces[i][1].coords[0], scale*forces[i][1].coords[1], scale*forces[i][1].coords[2] ]
	
	#for i in forces.size():
	#	print("Restoration vector in vertex %s" % i)
	#	print(forces[i][1].coords)
