extends Node
class_name Geometry

@export var vertex_scene : PackedScene
@export var edge_scene : PackedScene
@export var facet_scene : PackedScene
@export var body_scene : PackedScene

var vertices : Array
var edges : Array
var facets : Array

var bodies : Dictionary
## Total number of bodies used in the history of this geometry
var n_hist_body : int = 0
## Emitted when bodies dictionary is altered
signal bodies_changed

## Body ids of bodies with volume constraints
var vol_constraint_bids : PackedInt32Array

signal cam_info_calculated
signal cam_center_calculated

# VectorN
var center : Array
var radius : float

# Force keys
var GRAD_AREA_KEY : String = "grad_area_key"
var REST_VECT_KEY : String = "rest_vect_key"

# FORCE PROJECTION UTILS

## Matrix needed to conserve magnitudes
var K : SquareMatrix

## Vector needed to conserve magnitudes
var F : VectorN

## Vector to store factors to project forces
var A : VectorN

# RESTORATION VECTORS UTILS

## Stores the differences between actual and target values
var DELTA : VectorN

## Vector to store factors to calculate the projection vectors
var C : VectorN

## Read file strategy.
var file_read_strat : FileRead

## Write file strategy.
var file_write_strat : FileWrite

# Functions after initialization
func init() -> void:
	calc_characteristics()
	
	var main = get_node("..")
	await main.child_entered_tree
	var main3d = get_node("../Main3D")
	await main3d.ready
	cam_info_calculated.emit(center, radius)
	
	print_info()

func print_info(i : int = -1) -> void:
	var s : String = ""
	if i != -1: s += str(i+1) + ": "
	s += ("Total area: %s\t" % get_total_area() +
		"Total energy: %s\t" % get_energy())
	if i != -1: s += "Time step: %s\t" % globals.time_step
	globals.printer(s)

func get_total_area() -> float:
	var ret = 0.
	for f in facets:
		ret += f.area()
	return ret

func get_energy() -> float:
	var energy = 0.
	
	# Energy 1: area
	energy += get_total_area()
	
	return energy

func print_volume() -> void:
	for b_id in bodies:
		var b = bodies[b_id]
		print("Volume of body ", b_id, ": ", b.get_volume())

func get_volume() -> float:
	var ret = 0.
	for f in facets:
		ret += f.volume_contribution()
	return ret

func calc_characteristics() -> void:
	calc_center()
	calc_radius()
	calc_all_ev_vectors()
	
	for b_id in bodies:
		calc_volume(bodies[b_id])

func calc_center() -> void:
	var ret : Array
	ret.resize(globals.AMBIENT_DIMENSION)
	ret.fill(0.)
	
	var max_v : Array
	max_v.resize(globals.AMBIENT_DIMENSION)
	max_v.fill(0.)
	
	var min_v : Array
	min_v.resize(globals.AMBIENT_DIMENSION)
	min_v.fill(0.)
	
	for v in vertices:
		for i in globals.AMBIENT_DIMENSION:
			if i < v.coords.size():
				if max_v[i] < v.coords[i]:
					max_v[i] = v.coords[i]
				if min_v[i] > v.coords[i]:
					min_v[i] = v.coords[i]
	
	for i in globals.AMBIENT_DIMENSION:
		ret[i] = (max_v[i] + min_v[i])/2.
	
	center = ret

func calc_radius() -> void:
	var ret = 0.
	
	if center.is_empty():
		push_error("Cannot calculate radius: center not calculated")
		return
	
	for v in vertices:
		var dist_center : float = 0.
		for i in globals.AMBIENT_DIMENSION:
			if i < v.coords.size(): dist_center += (v.coords[i] - center[i]) * (v.coords[i] - center[i])
			else: dist_center += center[i] * center[i]
		dist_center = sqrt(dist_center)
		
		if ret < dist_center:
			ret = dist_center
	
	radius = ret

func calc_volume(body) -> void:
	var vol = 0.
	for i in body.facets.size():
		var f = body.facets[i]
		var vol_contr : float = f.volume_contribution()
		# If the id is negative the volume contribution should be the opposite
		# as the actual volume contribution is the one that would result from a
		# facet with the opposite orientation.
		if body.facet_ids[i] < 0 : vol_contr = -vol_contr
		vol += vol_contr
	body.set_volume(vol)

func reset_cam() -> void:
	cam_info_calculated.emit(center, radius)

func focus_cam() -> void:
	cam_center_calculated.emit(center)

# ADD ELEMENTS

## Adds vertex with given characteristics
func add_vertex(_coords : Array = [], _oid : int = -1, _fixed : bool = false, _id : int = -1) -> void:
	vertices.append(vertex_scene.instantiate())
	var id : int = _id
	if id == -1 : id = vertices.size()-1
	vertices[-1].init(id, _coords, _oid, _fixed)
	add_child(vertices[-1])

## Adds edge with given characteristics
func add_edge(_tail = null, _head = null, _oid : int = -1, _id : int = -1) -> void:
	edges.append(edge_scene.instantiate())
	var id : int = _id
	if id == -1 : id = edges.size()-1
	edges[-1].init(id, _tail, _head, _oid)
	add_child(edges[-1])

## Adds facet with given characteristics
func add_facet(_edge0, _edge1, _edge2, _inversee0 : bool = false, _inversee1 : bool = false, _inversee2 : bool = false, _oid : int = -1, _id: int = -1) -> void:
	facets.append(facet_scene.instantiate())
	var id : int = _id
	if id == -1 : id = facets.size()-1
	facets[-1].init(id, _edge0, _edge1, _edge2, _inversee0, _inversee1, _inversee2, _oid)
	add_child(facets[-1])

## Adds body with given id
func add_body(b_oid : int = -1, _id : int = -1) -> void:
	var b_id : int = _id
	if b_id == -1 : b_id = n_hist_body
	
	bodies[b_id] = body_scene.instantiate()
	bodies[b_id].init(b_id, b_oid)
	bodies[b_id].constrain_changed.connect(_on_volume_constraints_changed)
	bodies[b_id].body_removed.connect(_on_body_removed)
	add_child(bodies[b_id])
	n_hist_body += 1

func _on_add_body_whole() -> void:
	add_body()
	for f in facets:
		bodies[n_hist_body-1].add_facet(f)
	calc_characteristics()
	bodies_changed.emit(bodies)

# FORCE CALC

func set_forces_zero() -> void:
	for v in vertices:
		v.set_forces_zero()

func calc_all_ev_vectors() -> void:
	calc_forces()

func calc_forces() -> void:
	# Force 1: Gradient of area
	for v in vertices:
		calc_grad_area_vertex(v)
	
	# Project forces
	if has_volume_constraint():
		calc_volume_gradient()
		calc_magnitude_constraint_matrix()
		calc_magnitude_constraint_force_product_vector()
		calc_force_projection_factor_vector()
		
		for i in vol_constraint_bids.size():
			for v in vertices:
				v.add_force( GRAD_AREA_KEY, [
					-A.get_i(i) * v.forces[ bodies[ vol_constraint_bids[i] ].GRAD_VOLUME_BODY_KEY ].coords[0],
					-A.get_i(i) * v.forces[ bodies[ vol_constraint_bids[i] ].GRAD_VOLUME_BODY_KEY ].coords[1],
					-A.get_i(i) * v.forces[ bodies[ vol_constraint_bids[i] ].GRAD_VOLUME_BODY_KEY ].coords[2]
					] )

func calc_grad_area_vertex(vertex) -> void:
	vertex.set_force_zero( GRAD_AREA_KEY )
	for f_id in vertex.con_facets:
		var vector = facets[ f_id ].get_oposite_side_rotated(vertex)
		
		vertex.add_force(GRAD_AREA_KEY, [.5*vector.x, .5*vector.y, .5*vector.z] )

# MAGNITUDE RESTORATION

func _on_volume_constraints_changed(b_id : int, constr : bool) -> void:
	if constr:
		if not vol_constraint_bids.has(b_id):
			vol_constraint_bids.append(b_id)
	else:
		vol_constraint_bids.erase(b_id)
	
	calc_characteristics()

func _on_body_removed(b_id : int) -> void:
	bodies.erase(b_id)
	vol_constraint_bids.erase(b_id)
	bodies_changed.emit(bodies)
	
	calc_characteristics()

func has_volume_constraint() -> bool:
	return vol_constraint_bids.size() > 0

## Calculate magnitude restoration vectors
func calc_magnitude_restoration_vectors() -> void:
	# Volume constraints
	calc_volume_gradient()
	calc_magnitude_constraint_matrix()
	calc_magnitude_differences_vector()
	calc_magnitude_restoration_vectors_factors()
	
	for vertex in vertices:
		vertex.set_force_zero( REST_VECT_KEY )
		
		for i in vol_constraint_bids.size():
			vertex.add_force( REST_VECT_KEY,
				[ C.get_i(i) * vertex.forces[ bodies[ vol_constraint_bids[i] ].GRAD_VOLUME_BODY_KEY ].coords[0],
				C.get_i(i) * vertex.forces[ bodies[ vol_constraint_bids[i] ].GRAD_VOLUME_BODY_KEY ].coords[1],
				C.get_i(i) * vertex.forces[ bodies[ vol_constraint_bids[i] ].GRAD_VOLUME_BODY_KEY ].coords[2],
				] )

## Calculates all volume gradients for each constrained body
func calc_volume_gradient() -> void:
	for b_id in vol_constraint_bids:
		calc_volume_gradient_body( bodies[b_id] )

## For given body, calculates volume gradient for all vertices.
## Note: gradient is zero if the vertex is not part of the body.
func calc_volume_gradient_body(body) -> void:
	for vertex in vertices:
		vertex.set_force_zero( body.GRAD_VOLUME_BODY_KEY )
		
		for fid in vertex.con_facets:
			var f = facets[fid]
			if f.is_body_connected(body):
				var q = f.get_next_vertex(vertex).get_as_vector()
				var r = f.get_prev_vertex(vertex).get_as_vector()
				var prod = q.cross(r)
				
				# If the id is negative the volume contribution should be the opposite
				# as the actual volume contribution is the one that would result from a
				# facet with the opposite orientation.
				if f.is_body_inverse(body): prod = -prod
				
				vertex.add_force( body.GRAD_VOLUME_BODY_KEY, [ 1/6. * prod.x, 1/6. * prod.y, 1/6. * prod.z] )

func calc_magnitude_constraint_matrix() -> void:
	K = SquareMatrix.new()
	K.init( vol_constraint_bids.size() )
	
	for i in vol_constraint_bids.size():
		for j in i+1:
			var dot_product : float = 0.
			for vertex in vertices:
				for d in globals.AMBIENT_DIMENSION:
					dot_product += vertex.forces[ bodies[ vol_constraint_bids[j] ].GRAD_VOLUME_BODY_KEY ].coords[d] * vertex.forces[ bodies[ vol_constraint_bids[i] ].GRAD_VOLUME_BODY_KEY ].coords[d]
			
			K.set_ij(i, j, dot_product)
			K.set_ij(j, i, dot_product)

func calc_magnitude_constraint_force_product_vector() -> void:
	F = VectorN.new()
	F.init(vol_constraint_bids.size())
	
	for i in vol_constraint_bids.size():
		var dot_product : float = 0.
		for vertex in vertices:
			for d in globals.AMBIENT_DIMENSION:
				# Should sum every force before
				dot_product += vertex.forces[ GRAD_AREA_KEY ].coords[d] * vertex.forces[ bodies[ vol_constraint_bids[i] ].GRAD_VOLUME_BODY_KEY ].coords[d]
		
		F.set_i(i, dot_product)

func calc_force_projection_factor_vector() -> void:
	A = VectorN.new()
	A.init(vol_constraint_bids.size())
	
	A = K.get_inverse().product_by_vector(F)

func calc_magnitude_differences_vector() -> void:
	DELTA = VectorN.new()
	DELTA.init(vol_constraint_bids.size())
	
	for i in DELTA.dimension:
		calc_volume(bodies[ vol_constraint_bids[i] ])
		DELTA.set_i(i, bodies[ vol_constraint_bids[i] ].volume_constraint - bodies[ vol_constraint_bids[i] ].get_volume())

func calc_magnitude_restoration_vectors_factors() -> void:
	C = VectorN.new()
	C.init(vol_constraint_bids.size())
	
	C = K.get_inverse().product_by_vector(DELTA)

# ITERATION

func save_coords() -> void:
	for v in vertices:
		v.save_coords()

func restore_coords() -> void:
	for v in vertices:
		v.restore_coords()

func alter_coordinates() -> void:
	# Force 1
	# Gradient of area
	for v in vertices:
		v.apply_forces(GRAD_AREA_KEY)
	
	if has_volume_constraint():
		calc_magnitude_restoration_vectors()
		
		for v in vertices:
			v.apply_vector(REST_VECT_KEY)

# TODO: hacer mejor con clase buena, todas las fuerzas, etc
func iterate( i: int = -1 ) -> void:
	if globals.optimizing_time_step:
		
		globals.CALCULATING_STEP = true
		save_coords()
		
		# Set up the three steps
		var s1 = globals.time_step
		var s0 = s1 / 2
		var s2 = s1 * 2
		
		# Calculate values for the 3 steps
		restore_coords()
		globals.time_step = s1
		alter_coordinates()
		var s1_energy = get_energy()
		# print("Total area %s: %s" % [s1, s1_area])
	
		restore_coords()
		globals.time_step = s0
		alter_coordinates()
		var s0_energy = get_energy()
		# print("Total area %s: %s" % [s0, s0_area])
	
		restore_coords()
		globals.time_step = s2
		alter_coordinates()
		var s2_energy = get_energy()
		# print("Total area %s: %s" % [s2, s2_area])
		
		while (s1_energy > s2_energy):
			s0 = s1
			s0_energy = s1_energy
			s1 = s2
			s1_energy = s2_energy
			s2 = s1*2
			globals.time_step = s2
			restore_coords()
			alter_coordinates()
			s2_energy = get_energy()
			# print("Total area %s: %s" % [s2, s2_area])
	
		while (s1_energy > s0_energy):
			s2 = s1
			s2_energy = s1_energy
			s1 = s0
			s1_energy = s0_energy
			s0 = s1/2
			globals.time_step = s0
			restore_coords()
			alter_coordinates()
			s0_energy = get_total_area()
			# print("Total area %s: %s" % [s0, s0_area])
		
		restore_coords()
		
		if (2*s0_energy - 3*s1_energy + s2_energy == 0.0): globals.time_step = 1.0
		else: globals.time_step = 0.75 * s1 * (4*s0_energy - 5*s1_energy + s2_energy) / (2*s0_energy - 3*s1_energy + s2_energy)
		globals.time_step = min(globals.time_step, 1.0)
		
		globals.CALCULATING_STEP = false
	
	alter_coordinates()
	
	calc_characteristics()
	print_info(i)

func iterate_n(n : int = 1, terminal : bool = false) -> void:
	for i in n:
		iterate(i)
	
	# Allow terminal thread to continue
	if terminal: globals.semaphore.post()

# REFINE

func refine(terminal : bool = false) -> void:
	var new_edges = []
	var old_n_edges = edges.size()
	var old_n_vertices = vertices.size()
	var new_facets = []
	var old_n_facets = facets.size()
	
	for v in vertices:
		v.disconnect_everything()
	
	for e in edges:
		e.disconnect_everything()
	
	for e in edges:
		# Add new vertices
		# One for each edge
		# New vertices have ids ranging
		# from old_n_vertices
		# to old_n_vertices + old_n_edges
		# Central vertex of edge i has id
		# old_n_vertices + i
		vertices.append(vertex_scene.instantiate())
		vertices[-1].init( vertices.size()-1, e.midpoint() )
		add_child( vertices[-1] )
		
		# Add new edges, one for each old edge
		# New edges have ids ranging from old_n_edges
		# to 2*old_n_edges-1
		# Edge descendant of edge i has id old_n_edges+i
		new_edges.append( edge_scene.instantiate() )
		new_edges[-1].init( old_n_edges+new_edges.size()-1, vertices[-1], e.head)
		add_child( new_edges[-1] )
		
		# Reinit old edge
		e.init( e.get_id(), e.tail, vertices[-1] )
	
	# Add new edges to edges array
	for e in new_edges:
		edges.append(e)
	
	for f in facets:
		# Add new edges uniting the midpoints of the old edges
		edges.append( edge_scene.instantiate() )
		edges[-1].init( edges.size()-1, vertices[ old_n_vertices + f.edge0_id ], vertices[ old_n_vertices + f.edge1_id ] )
		add_child(edges[-1])
		
		edges.append( edge_scene.instantiate() )
		edges[-1].init( edges.size()-1, vertices[ old_n_vertices + f.edge1_id ], vertices[ old_n_vertices + f.edge2_id ] )
		add_child(edges[-1])
		
		edges.append( edge_scene.instantiate() )
		edges[-1].init( edges.size()-1, vertices[ old_n_vertices + f.edge2_id ], vertices[ old_n_vertices + f.edge0_id ] )
		add_child(edges[-1])
		
		# New facets
		new_facets.append( facet_scene.instantiate() )
		new_facets[-1].init( old_n_facets + new_facets.size()-1, edges[ f.edge0_id + int(f.inversee0)*old_n_edges ], edges[-1], edges[ f.edge2_id + int(not f.inversee2)*old_n_edges ], f.inversee0, true, f.inversee2)
		add_child(new_facets[-1])
		
		new_facets.append( facet_scene.instantiate() )
		new_facets[-1].init( old_n_facets + new_facets.size()-1, edges[ f.edge0_id + int(not f.inversee0)*old_n_edges ], edges[ f.edge1_id + int(f.inversee1)*old_n_edges ], edges[-3], f.inversee0, f.inversee1, true)
		add_child(new_facets[-1])
		
		new_facets.append( facet_scene.instantiate() )
		new_facets[-1].init( old_n_facets + new_facets.size()-1, edges[-2], edges[ f.edge1_id + int(not f.inversee1)*old_n_edges ], edges[ f.edge2_id + int(f.inversee2)*old_n_edges ], true, f.inversee1, f.inversee2)
		add_child(new_facets[-1])
		
		# Reinit the facet to be the central facet now
		f.init( f.get_id(), edges[-3], edges[-2], edges[-1])
		
		# Add new facets to bodies
		for b_id in bodies:
			var b = bodies[b_id]
			if f.is_body_connected(b):
				var inverse : bool = f.is_body_inverse(b)
				b.add_facet(new_facets[-3], inverse)
				b.add_facet(new_facets[-2], inverse)
				b.add_facet(new_facets[-1], inverse)
	
	# Add new facets to facet array
	for f in new_facets:
		facets.append(f)
	
	# Allow terminal thread to continue
	if terminal: globals.semaphore.post()
	
	calc_characteristics()

# GET ID FROM ORIGINAL ID

func v_get_id_from_oid(_oid: int) -> int:
	for v in vertices:
		if v.oid == _oid: return v.get_id()
	return -1

func e_get_id_from_oid(_oid : int) -> int:
	for e in edges:
		if e.oid == _oid: return e.get_id()
	return -1

## Returns all ids of facets with given oid
func f_get_ids_from_oid(_oid : int) -> PackedInt32Array:
	var ret : PackedInt32Array = []
	for f in facets:
		if f.oid == _oid: ret.append(f.get_id())
	return ret

# GEOMETRY UNLOAD

func unload() -> void:
	for v in vertices:
		v.queue_free()
	
	for e in edges:
		e.queue_free()
	
	for f in facets:
		f.queue_free()
	
	for b_id in bodies:
		var b = bodies[b_id]
		b.queue_free()
	
	vertices.clear()
	edges.clear()
	facets.clear()
	
	bodies.clear()
	vol_constraint_bids.clear()
	n_hist_body = 0

# FILE LOAD

func set_file_read(_file_read : FileRead) -> void:
	file_read_strat = _file_read

func load_file(file_content: String) -> bool:
	unload()
	if not file_read_strat.load_file(file_content, self):
		return false
	
	# TODO: check face orientation compatibility
	
	init()
	return true

# FILE WRITE

func set_file_write(_file_write : FileWrite) -> void:
	file_write_strat = _file_write

func write_to_file(file : String) -> void:
	file_write_strat.write_to_file(file, self)
