extends Node
class_name Geometry

@export var vertex_scene : PackedScene
@export var edge_scene : PackedScene
@export var facet_scene : PackedScene

var vertices : Array
var edges : Array
var facets : Array

var area_energy : Area
## Stores quantity computation strategies to be used for force computation.
var energies : Dictionary[int, QuantityInterface]
## Stores quantity computation strategies to be used for information reporting.
## Some of them may be constrained.
var quantities : Dictionary[int, QuantityInterface]
var constr_quantities_ids : PackedInt32Array
var n_hist_quantity : int = 0

signal cam_info_calculated
signal cam_center_calculated

# VectorN
var center : Array
var radius : float

# Force keys
var FORCE_PROJ_KEY : String = "force_proj_key"
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

# Functions after initialization
func init() -> void:
	area_energy = Area.new(self)
	calc_characteristics()
	
	var main = get_node("../..")
	await main.child_entered_tree
	var main3d = get_node("../../Main3D")
	await main3d.ready
	cam_info_calculated.emit(center, radius)
	
	print_info()

func print_info(i : int = -1) -> void:
	var s : String = ""
	if i != -1: s += str(i+1) + ": "
	s += ("Total area: %s\t" % area_energy.calc_energy() +
		"Total energy: %s\t" % get_energy())
	if i != -1: s += "Time step: %s\t" % globals.time_step
	globals.printer(s)

func get_energy() -> float:
	var energy = 0.
	
	for e_id in energies:
		var e = energies[e_id]
		energy += e.calc_energy()
	
	return energy

func calc_characteristics() -> void:
	calc_center()
	calc_radius()
	calc_forces()

func calc_center() -> void:
	var ret : Array
	ret.resize(globals.AMBIENT_DIMENSION)
	ret.fill(0.)
	
	var max_v : Array
	max_v.resize(globals.AMBIENT_DIMENSION)
	max_v.fill(-INF)
	
	var min_v : Array
	min_v.resize(globals.AMBIENT_DIMENSION)
	min_v.fill(INF)
	
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

## Adds given energy to energy computation
func add_energy(en : QuantityInterface, _id : int = -1) -> void:
	var id : int = _id
	if id == -1 : id = energies.size()-1
	en.id = id
	energies[id] = en

## Adds given quantity to magnitude constraints
func add_quantity(q : QuantityInterface, _id : int = -1) -> void:
	var id : int = _id
	if id == -1 : id = n_hist_quantity
	q.id = id
	quantities[id] = q
	if q.constrained: constr_quantities_ids.append(id)
	n_hist_quantity += 1

# FORCE CALC

func set_forces_zero() -> void:
	for v in vertices:
		v.set_forces_zero()

func calc_forces() -> void:
	for e_id in energies:
		var e = energies[e_id]
		e.calc_forces()
	
	# Project forces
	if has_constraints():
		calc_constraints_gradient()
		calc_magnitude_constraint_matrix()
		calc_magnitude_constraint_force_product_vector()
		calc_force_projection_factor_vector()
		
		for v in vertices:
			v.set_force_zero( FORCE_PROJ_KEY )
			for i in constr_quantities_ids.size():
				v.add_force( FORCE_PROJ_KEY, [
					-A.get_i(i) * v.forces[ quantities[ constr_quantities_ids[i] ].GRAD_KEY ].coords[0],
					-A.get_i(i) * v.forces[ quantities[ constr_quantities_ids[i] ].GRAD_KEY ].coords[1],
					-A.get_i(i) * v.forces[ quantities[ constr_quantities_ids[i] ].GRAD_KEY ].coords[2]
					] )

# MAGNITUDE RESTORATION

func calc_constraints_gradient() -> void:
	for q_id in quantities:
		var q = quantities[q_id]
		if q.constrained:
			q.calc_forces()

func _on_volume_constraints_changed(b_id : int, constr : bool) -> void:
	#if constr:
	#	if not vol_constraint_bids.has(b_id):
	#		vol_constraint_bids.append(b_id)
	#else:
	#	vol_constraint_bids.erase(b_id)
	
	calc_characteristics()

func _on_body_removed(b_id : int) -> void:
	#bodies.erase(b_id)
	#vol_constraint_bids.erase(b_id)
	#bodies_changed.emit(bodies)
	
	calc_characteristics()

func has_constraints() -> bool:
	for q_id in quantities:
		var q = quantities[q_id]
		if q.constrained: return true
	return false

## Calculate magnitude restoration vectors
func calc_magnitude_restoration_vectors() -> void:
	# Volume constraints
	calc_constraints_gradient()
	calc_magnitude_constraint_matrix()
	calc_magnitude_differences_vector()
	calc_magnitude_restoration_vectors_factors()
	
	for vertex in vertices:
		vertex.set_force_zero( REST_VECT_KEY )
		
		for i in constr_quantities_ids.size():
			vertex.add_force( REST_VECT_KEY,
				[ C.get_i(i) * vertex.forces[ quantities[ constr_quantities_ids[i] ].GRAD_KEY ].coords[0],
				C.get_i(i) * vertex.forces[ quantities[ constr_quantities_ids[i] ].GRAD_KEY ].coords[1],
				C.get_i(i) * vertex.forces[ quantities[ constr_quantities_ids[i] ].GRAD_KEY ].coords[2],
				] )

func calc_magnitude_constraint_matrix() -> void:
	K = SquareMatrix.new()
	K.init( constr_quantities_ids.size() )
	
	for i in constr_quantities_ids.size():
		for j in i+1:
			var dot_product : float = 0.
			for vertex in vertices:
				for d in globals.AMBIENT_DIMENSION:
					dot_product += vertex.forces[ quantities[ constr_quantities_ids[j] ].GRAD_KEY ].coords[d] * vertex.forces[ quantities[ constr_quantities_ids[i] ].GRAD_KEY ].coords[d]
			
			K.set_ij(i, j, dot_product)
			K.set_ij(j, i, dot_product)
	print(K.content)

func calc_magnitude_constraint_force_product_vector() -> void:
	F = VectorN.new()
	F.init(constr_quantities_ids.size())
	
	for i in constr_quantities_ids.size():
		var dot_product : float = 0.
		for vertex in vertices:
			for d in globals.AMBIENT_DIMENSION:
				for e_id in energies:
					var e = energies[e_id]
					dot_product += vertex.forces[ e.GRAD_KEY ].coords[d] * vertex.forces[ quantities[ constr_quantities_ids[i] ].GRAD_KEY ].coords[d]
		
		F.set_i(i, dot_product)

func calc_force_projection_factor_vector() -> void:
	A = VectorN.new()
	
	A = K.get_inverse().product_by_vector(F)

func calc_magnitude_differences_vector() -> void:
	DELTA = VectorN.new()
	DELTA.init(constr_quantities_ids.size())
	
	for i in constr_quantities_ids.size():
		DELTA.set_i(i, quantities[ constr_quantities_ids[i] ].target -  quantities[ constr_quantities_ids[i] ].calc_energy())

func calc_magnitude_restoration_vectors_factors() -> void:
	C = VectorN.new()
	C.init(constr_quantities_ids.size())
	
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
	for e_id in energies:
		var e = energies[e_id]
		for v in vertices:
			v.apply_forces(e.GRAD_KEY)
	
	if has_constraints():
		for v in vertices:
			v.apply_forces(FORCE_PROJ_KEY)
			
		#calc_magnitude_restoration_vectors()
		
		#for v in vertices:
		#	v.apply_vector(REST_VECT_KEY)

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
			s0_energy = get_energy()
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
		
		if f.body_id != -1:
			var b = quantities[f.body_id]
			var inverse : bool = f.is_body_inverse(b)
			b.add_facet(new_facets[-3], inverse)
			b.add_facet(new_facets[-2], inverse)
			b.add_facet(new_facets[-1], inverse)
		
		if f.bodyinverse_id != -1:
			var b = quantities[f.body_id]
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
	
	vertices.clear()
	edges.clear()
	facets.clear()
	
	energies.clear()
	quantities.clear()
	constr_quantities_ids.clear()
	n_hist_quantity = 0
