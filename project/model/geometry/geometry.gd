extends Node

@export var vertex_scene : PackedScene
@export var edge_scene : PackedScene
@export var facet_scene : PackedScene
@export var body_scene : PackedScene

var vertices : Array
var edges : Array
var facets : Array
var bodies : Array

# Content of the file being processed
var file_content : String

# File type
enum {NONE, PLY, FE}
var file_type = NONE

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
	
	print_volume()

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
	for b in bodies:
		print("Volume of body ", b.id, ": ", b.get_volume())

func get_volume() -> float:
	var ret = 0.
	for f in facets:
		ret += f.volume_contribution()
	return ret

func calc_characteristics() -> void:
	calc_center()
	calc_radius()
	calc_all_ev_vectors()
	
	for b in bodies:
		calc_volume(b)

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
	for f in body.facets:
		vol += f.volume_contribution()
	body.set_volume(vol)

func reset_cam() -> void:
	cam_info_calculated.emit(center, radius)

func focus_cam() -> void:
	cam_center_calculated.emit(center)

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
		
		for i in bodies.size():
			for v in vertices:
				v.add_force( GRAD_AREA_KEY, [
					-A.get_i(i) * v.forces[ bodies[i].GRAD_VOLUME_BODY_KEY ].coords[0],
					-A.get_i(i) * v.forces[ bodies[i].GRAD_VOLUME_BODY_KEY ].coords[1],
					-A.get_i(i) * v.forces[ bodies[i].GRAD_VOLUME_BODY_KEY ].coords[2]
					] )

func calc_grad_area_vertex(vertex) -> void:
	vertex.set_force_zero( GRAD_AREA_KEY )
	for f_id in vertex.con_facets:
		var vector = facets[ f_id ].get_oposite_side_rotated(vertex)
		
		vertex.add_force(GRAD_AREA_KEY, [.5*vector.x, .5*vector.y, .5*vector.z] )

# MAGNITUDE RESTORATION

func has_volume_constraint() -> bool:
	for b in bodies:
		if b.volume_constraint >= 0.0: return true
	return false

## Calculate magnitude restoration vectors
func calc_magnitude_restoration_vectors() -> void:
	# Volume constraints
	calc_volume_gradient()
	calc_magnitude_constraint_matrix()
	calc_magnitude_differences_vector()
	calc_magnitude_restoration_vectors_factors()
	
	for vertex in vertices:
		vertex.set_force_zero( REST_VECT_KEY )
		
		for i in bodies.size():
			vertex.add_force(REST_VECT_KEY,
				[ C.get_i(i) * vertex.forces[ bodies[i].GRAD_VOLUME_BODY_KEY ].coords[0],
				C.get_i(i) * vertex.forces[ bodies[i].GRAD_VOLUME_BODY_KEY ].coords[1],
				C.get_i(i) * vertex.forces[ bodies[i].GRAD_VOLUME_BODY_KEY ].coords[2],
				] )

## Calculates all volume gradients for each body
func calc_volume_gradient() -> void:
	for b in bodies:
		calc_volume_gradient_body(b)

## For given body, calculates volume gradient for all vertices.
## Note: gradient is zero if the vertex is not part of the body.
func calc_volume_gradient_body(body) -> void:
	for vertex in vertices:
		vertex.set_force_zero( body.GRAD_VOLUME_BODY_KEY )
		
		for fid in vertex.con_facets:
			var f = facets[fid]
			if body.has_facet( facets[fid] ):
				var q = f.get_next_vertex(vertex).get_as_vector()
				var r = f.get_prev_vertex(vertex).get_as_vector()
				var prod = q.cross(r)
				
				vertex.add_force( body.GRAD_VOLUME_BODY_KEY, [ 1/6. * prod.x, 1/6. * prod.y, 1/6. * prod.z] )

func calc_magnitude_constraint_matrix() -> void:
	K = SquareMatrix.new()
	K.init(bodies.size())
	
	for i in bodies.size():
		for j in i+1:
			var dot_product : float = 0.
			for vertex in vertices:
				for d in globals.AMBIENT_DIMENSION:
					dot_product += vertex.forces[ bodies[j].GRAD_VOLUME_BODY_KEY ].coords[d] * vertex.forces[ bodies[i].GRAD_VOLUME_BODY_KEY ].coords[d]
			
			K.set_ij(i, j, dot_product)
			K.set_ij(j, i, dot_product)

func calc_magnitude_constraint_force_product_vector() -> void:
	F = VectorN.new()
	F.init(bodies.size())
	
	for i in bodies.size():
		var dot_product : float = 0.
		for vertex in vertices:
			for d in globals.AMBIENT_DIMENSION:
				## Should sum every force before
				dot_product += vertex.forces[ GRAD_AREA_KEY ].coords[d] * vertex.forces[ bodies[i].GRAD_VOLUME_BODY_KEY ].coords[d]
		
		F.set_i(i, dot_product)

func calc_force_projection_factor_vector() -> void:
	A = VectorN.new()
	A.init(bodies.size())
	
	A = K.get_inverse().product_by_vector(F)

func calc_magnitude_differences_vector() -> void:
	DELTA = VectorN.new()
	DELTA.init(bodies.size())
	
	for i in DELTA.dimension:
		calc_volume(bodies[i])
		DELTA.set_i(i, bodies[i].volume_constraint - bodies[i].get_volume())

func calc_magnitude_restoration_vectors_factors() -> void:
	C = VectorN.new()
	C.init(bodies.size())
	
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
		for b in bodies:
			if b.has_facet(f):
				b.add_facet(new_facets[-3])
				b.add_facet(new_facets[-2])
				b.add_facet(new_facets[-1])
	
	# Add new facets to facet array
	for f in new_facets:
		facets.append(f)
	
	# Allow terminal thread to continue
	if terminal: globals.semaphore.post()

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
	
	for b in bodies:
		b.queue_free()
	
	vertices.clear()
	edges.clear()
	facets.clear()
	bodies.clear()

# FILE LOAD

func load_file(content: String) -> bool:
	unload()
	file_content = content
	
	consume_white_or_end_line()
	
	# Check file type
	if check_head("ply"):
		# Consume ply
		consume_word()
		file_type = PLY
		var file_loaded = load_ply()
		if not file_loaded: return false
		
	else:
		# Will attempt to parse file
		# as a surface evolver (.fe) file
		# These don't start with a magic word
		file_type = FE
		var file_loaded = load_fe()
		if not file_loaded: return false
	
	# TODO: check face orientation compatibility
	
	init()
	return true

# FILE PROCESSING UTILS

func is_white_space(s : String) -> bool:
	return s == " " or s == "\t"

func is_new_line(s : String) -> bool:
	return s == "\n"

func is_new_line_or_white(s : String) -> bool:
	return is_white_space(s) or is_new_line(s)

# Consumes first n characters
func consume(n: int) -> void:
	file_content = file_content.right( -n )

# Checks first characters of file_content match check
# And if so consumes them
# Else displays error message
# Consumes white spaces and endlines before and after check
func check_and_consume_head(check: String) -> bool:
	consume_white_or_end_line()
	
	if check_head(check):
		consume( check.length() )
		consume_white_or_end_line()
		return true
	
	match file_type:
		PLY:
			error_ply()
		FE:
			error_fe()
	
	return false

func check_head(check: String) -> bool:
	consume_white_or_end_line()
	return file_content.left(check.length()) == check

## Consume file_content until nth character
func consume_until(s : String, n : int = 1) -> void:
	for i in n:
		var pos = file_content.find(s)
		if pos != -1:
			consume( pos+s.length() )

func consume_line(n: int = 1) -> void:
	consume_until("\n", n)

# Returns and consumes first part of file_content
# (default separator \n)
func get_and_consume_head(separator: String = "") -> String:
	var ret : String
	
	consume_white_or_end_line()
	
	if separator != "":
		var pos_sep = file_content.find(separator)
		ret = file_content.left( pos_sep )
		consume( pos_sep+1 )
	else:
		while file_content.length() > 0 and !is_new_line_or_white(file_content[0]):
			ret += file_content[0]
			consume(1)
	
	consume_white_or_end_line()
	
	return ret

func consume_white_space() -> void:
	while file_content.length() > 0 and is_white_space(file_content[0]):
		consume(1)

func consume_end_line() -> void:
	while file_content.length() > 0 and is_new_line(file_content[0]):
		consume(1)

func consume_white_or_end_line() -> void:
	while file_content.length() > 0 and is_new_line_or_white(file_content[0]):
		consume(1)

## Consumes next word
## (consumes white space,
## consumes whatever is next until it hits whitespace again,
## and then consumes white space again)
func consume_word(n: int = 1) -> void:
	for i in n:
		consume_white_or_end_line()
		while file_content.length() > 0 and !is_new_line_or_white(file_content[0]):
			consume(1)
		consume_white_or_end_line()

func check_head_is_int() -> bool:
	for i in 10:
		if check_head( str(i) ): return true
	return false

# LOAD PLY

func load_ply() -> bool:
	var n_vertices
	var n_prop_verts
	var x_pos
	var y_pos
	var z_pos
	var n_faces
	
	# Check next comes the format indicator
	if !check_and_consume_head("format"):
		push_error("Missing format")
		return false
	
	# Check next is the ascii formar indicator
	if !check_and_consume_head("ascii"):
		push_error("Only ascii .ply files are allowed")
		return false
	
	# Consume version
	consume_word()
	
	# Erases comments
	erase_ply_comments()
	
	# VERTICES section
	
	# Check next line stores number of vertices
	if !check_and_consume_head("element"):
		push_error("Vertex definition not found")
		return false
	
	# Check next line stores number of vertices
	if !check_and_consume_head("vertex"):
		push_error("Vertex definition not found")
		return false
	
	# Check, store and consume number of vertices
	n_vertices = get_and_consume_head()
	if !n_vertices.is_valid_int():
		error_ply()
		push_error("Number of vertices not found")
		return false
	n_vertices = n_vertices.to_int()
	
	# Process properties
	# Make note of where in the file the x, y, z are located
	x_pos = -1
	y_pos = -1
	z_pos = -1
	
	n_prop_verts = 0
	while check_head("property"):
		consume("property".length())
		consume_word()
		
		if file_content[0] == "x" : x_pos = n_prop_verts
		elif file_content[0] == "y" : y_pos = n_prop_verts
		elif file_content[0] == "z" : z_pos = n_prop_verts
		
		consume_word()
		
		n_prop_verts += 1
	
	if x_pos == -1:
		error_ply()
		push_error("Definition of x coordinate not found")
		return false
	
	if y_pos == -1:
		error_ply()
		push_error("Definition of y coordinate not found")
		return false
	
	if z_pos == -1:
		error_ply()
		push_error("Definition of z coordinate not found")
		return false
	
	# FACES section
	
	# Check next is a definition
	if !check_and_consume_head("element"):
		push_error("Expected definition of element")
		return false
	
	# Check it is for faces
	if !check_and_consume_head("face"):
		push_error("Invalid definition of faces")
		return false
	
	# Check, store and consume number of vertices
	n_faces = get_and_consume_head()
	if !n_faces.is_valid_int():
		error_ply()
		push_error("Invalid number of faces")
		return false
	n_faces = n_faces.to_int()
	
	# Check, process and consume property list
	if !check_and_consume_head("property"):
		push_error("Expected property of faces")
		return false
	
	if !check_and_consume_head("list"):
		push_error("Property vertex list of faces not found")
		return false
	
	# Consume type of elements
	# Will check later if they are ints
	consume_word(2)
	
	# Check, process and consume vertex_indices or vertex_index
	if !check_head("vertex_indices") and !check_head("vertex_index"):
		error_ply()
		push_error("Property of faces does not contain vertex indices or vertex index")
		return false
	consume_word()
	
	# Allow more element definitions
	# Will ignore them
	while check_head("element"):
		# Consume "element", element name and number of elements
		consume_word(3)
		
		# Consume any property definitions
		while check_head("property"):
			# Consume "property"
			consume_word()
			
			# Different processing if it's a list or not
			if check_head("list"):
				# Consume "list", the two types and the index name
				consume_word(4)
			else:
				# Consume type and name
				consume_word(2)
			
	
	# Check and consume end_header
	if !check_and_consume_head("end_header"):
		push_error("end_header not found")
		return false
	
	# VERTEX LIST
	
	# n_vertices
	# n_prop_verts
	# x_pos
	# y_pos
	# z_pos
	# n_faces
	# n_prop_verts
	
	for i in n_vertices:
		
		# Get vertex coordinates
		var x
		var y
		var z
		
		for j in n_prop_verts:
			var cur = get_and_consume_head()
			
			if j == x_pos or j == y_pos or j == z_pos:
				if !cur.is_valid_float():
					error_ply()
					if j == x_pos: push_error("Invalid x coordinate %s for vertex %s" % [cur, i])
					if j == y_pos: push_error("Invalid y coordinate %s for vertex %s" % [cur, i])
					if j == z_pos: push_error("Invalid z coordinate %s for vertex %s" % [cur, i])
					return false
				
				if j == x_pos: x = cur.to_float()
				if j == y_pos: y = cur.to_float()
				if j == z_pos: z = cur.to_float()
		
		vertices.append(vertex_scene.instantiate())
		vertices[-1].init(i, [x,y,z])
		add_child(vertices[-1])
	
	# FACET LIST
	for i in n_faces:
		# Get number of vertices
		var n_vertices_face = get_and_consume_head()
		if !n_vertices_face.is_valid_int():
			error_ply()
			push_error("Invalid number of vertices %s for facet %s" % [n_vertices_face, i])
			return false
		n_vertices_face = n_vertices_face.to_int()
		
		if n_vertices_face != 3 and n_vertices_face != 4:
			error_ply()
			push_error("Invalid number of vertices %s for facet %s" % [n_vertices_face, i])
			push_error("Only 3 or 4 vertices per face are allowed")
			return false
		
		var v_indices : Array
		v_indices.resize(n_vertices_face)
		v_indices.fill(-1)
		
		# Get indices of vertices
		for j in n_vertices_face:
			v_indices[j] = get_and_consume_head()
			if !v_indices[j].is_valid_int():
				error_ply()
				push_error("Invalid vertex %s for facet %s" % [v_indices[j], i])
				return false
			v_indices[j] = v_indices[j].to_int()
		
		for j in n_vertices_face:
			if v_indices[j] == -1:
				error_ply()
				push_error("Invalid %sth index for facet %s" % [j, i])
				return false
		
		# Add edges
		# Store indices of edges of facet
		var e_indices : Array
		var n_edges
		n_edges = 3
		if n_vertices_face == 4: n_edges = 5
		e_indices.resize(n_edges)
		e_indices.fill(-1)
		
		for j in n_edges:
			# If it exists, get the id of the edge connecting these two vertices
			var edge_id
			if j == 4: edge_id = vertices[ v_indices[0] ].get_edge_index_from_v_id( v_indices[2] )
			else: edge_id = vertices[ v_indices[j] ].get_edge_index_from_v_id( v_indices[ (j+1) % n_vertices_face ] )
			
			# If it doesn't exist, we create it
			# In both cases we make note of the edge id
			if edge_id == INF:
				edges.append(edge_scene.instantiate())
				if j == 4: edges[-1].init( edges.size()-1, vertices[ v_indices[ 0 ] ], vertices[ v_indices[ 2 ] ] )
				else: edges[-1].init( edges.size()-1, vertices[ v_indices[ j ] ], vertices[ v_indices[ (j+1) % n_vertices_face ] ] )
				add_child(edges[-1])
				e_indices[j] = edges.size()-1
			else:
				e_indices[j] = edge_id
		
		# Add facet(s)
		if n_vertices_face == 3:
			facets.append(facet_scene.instantiate())
			facets[-1].init( i, edges[ abs(e_indices[0]) ], edges[ abs(e_indices[1]) ], edges[ abs(e_indices[2]) ], e_indices[0] < 0, e_indices[1] < 0, e_indices[2] < 0 )
			add_child(facets[-1])
			
		elif n_vertices_face == 4:
			facets.append(facet_scene.instantiate())
			facets[-1].init( i*2, edges[ abs(e_indices[0]) ], edges[ abs(e_indices[1]) ], edges[ abs(e_indices[4]) ], e_indices[0] < 0, e_indices[1] < 0, e_indices[4] > 0 )
			add_child(facets[-1])
			
			facets.append(facet_scene.instantiate())
			facets[-1].init( i*2+1, edges[ abs(e_indices[2]) ], edges[ abs(e_indices[3]) ], edges[ abs(e_indices[4]) ], e_indices[2] < 0, e_indices[3] < 0, e_indices[4] < 0 )
			add_child(facets[-1])
	
	return true

func error_ply() -> void:
	push_error("Cannot open .ply file")

func erase_ply_comments() -> void:
	var compos = file_content.find("comment")
	while compos != -1:
		while file_content[compos] != "\n":
			file_content = file_content.erase(compos)
		compos = file_content.find("comment")

# LOAD FE

func load_fe() -> bool:
	# TODO: file format is case insensitive
	
	erase_fe_comments()
	
	# Definitions and options sections
	# Will ignore it
	
	# TODO: rest of fe specification
	# TODO: there may be more information per line than the basics
	
	# Vertices section
	while !check_head("vertices"):
		consume_word()
		if file_content.is_empty():
			error_fe()
			push_error("Vertices section not found")
			return false
	
	# Consume vertices
	consume_word()
	
	while (check_head_is_int()):
		# Consume vertex number
		var vert_id = get_and_consume_head(" ")
		if !vert_id.is_valid_int():
			error_fe()
			push_error("Invalid vertex number %s", vert_id)
			return false
		vert_id = vert_id.to_int()
		
		# Get vertex coordinates
		var coords : PackedFloat32Array
		coords.resize(3)
		for i in 3:
			var cur
			if i == 2: cur = get_and_consume_head()
			else: cur = get_and_consume_head(" ")
			
			if !cur.is_valid_float():
				error_fe()
				push_error("Invalid x%s coordinate %s for vertex %s" % [i+1, cur, vert_id])
				return false
			
			coords[i] = cur.to_float()
		
		vertices.append(vertex_scene.instantiate())
		vertices[-1].init( vertices.size()-1, coords, vert_id )
		add_child(vertices[-1])
	
	# TODO: comprobar unicidad de los oid
	
	# Consume edges
	if !check_and_consume_head("edges"):
		push_error("Edges section not found")
		return false
	
	while (check_head_is_int()):
		# Consume edge number
		var edge_id = get_and_consume_head(" ")
		if !edge_id.is_valid_int():
			error_fe()
			push_error("Invalid edge number %s", edge_id)
			return false
		edge_id = edge_id.to_int()
		
		# Get vertex numbers
		var v_oids : PackedInt32Array
		v_oids.resize(2)
		v_oids.fill(-1)
		for i in 2:
			var cur
			if i == 1: cur = get_and_consume_head()
			else: cur = get_and_consume_head(" ")
			
			if !cur.is_valid_int():
				error_fe()
				push_error("Invalid vertex number %s for edge %s" % [cur, edge_id])
				return false
			
			v_oids[i] = cur.to_int()
		
		var v_id : PackedInt32Array
		v_id.resize(2)
		for i in 2:
			v_id[i] = v_get_id_from_oid( v_oids[i] )
			if v_id[i] == -1:
				error_fe()
				push_error("Invalid vertex number %s for edge %s" % [v_oids[i], edge_id])
				return false
		
		edges.append(edge_scene.instantiate())
		edges[-1].init( edges.size()-1, vertices[ v_id[0] ], vertices[ v_id[1] ], edge_id )
		add_child(edges[-1])
	
	# Faces section
	# TODO: optional in string model
	
	# Consume faces
	if !check_and_consume_head("faces"):
		push_error("Faces section not found")
		return false
	
	while (check_head_is_int()):
		
		# Consume facet number
		var facet_id = get_and_consume_head(" ")
		if !facet_id.is_valid_int():
			error_fe()
			push_error("Invalid facet number %s", facet_id)
			return false
		facet_id = facet_id.to_int()
		
		# Get edge numbers
		var e : PackedInt32Array
		while !is_new_line(file_content[0]):
			var cur = ""
			while !is_new_line_or_white(file_content[0]):
				cur += file_content[0]
				consume(1)
			consume_white_space()
			
			if !cur.is_valid_int():
				error_fe()
				push_error("Invalid edge number %s for facet %s" % [cur, facet_id])
				return false
			
			e.append(cur.to_int())
		
		# TODO: 3-edge faces
		
		if e.size() == 4:
			# Add new vertex in center
			var coords : PackedFloat32Array
			coords.resize(3)
			coords.fill(0)
			
			for i in 4:
				var edge = edges[ e_get_id_from_oid( abs(e[i]) ) ]
				var vertex
				if e[i] < 0:
					vertex = edge.head
				else:
					vertex = edge.tail
				
				for j in 3:
					coords[j] += vertex.coords[j]
			
			for i in 3: coords[i] /= 4
			
			vertices.append(vertex_scene.instantiate())
			vertices[-1].init( vertices.size()-1, coords )
			add_child(vertices[-1])
			
			# Add diagonal edges
			for i in 4:
				edges.append(edge_scene.instantiate())
				if e[i] < 0: edges[-1].init( edges.size()-1, edges[ e_get_id_from_oid( abs(e[i]) ) ].tail, vertices[-1] )
				else: edges[-1].init( edges.size()-1, edges[ e_get_id_from_oid( abs(e[i]) ) ].head, vertices[-1] )
				add_child(edges[-1])
			
			for i in 4:
				facets.append(facet_scene.instantiate())
				facets[-1].init( facets.size()-1, edges[ e_get_id_from_oid( abs(e[i]) ) ], edges[ edges.size() + i-4 ], edges[ edges.size() + posmod(i-1, 4) - 4 ], e[i] < 0, false, true, facet_id )
				add_child(facets[-1])
			
	# Optional Bodies section
	# Note: if it doesn't detect a bodies section
	# it won't process commands either
	while !check_head("bodies"):
		consume_word()
		if file_content.is_empty():
			return true
	
	# Consume "bodies"
	consume_word()
	
	while (check_head_is_int()):
		
		# Consume body number
		var body_id = get_and_consume_head(" ")
		if !body_id.is_valid_int():
			error_fe()
			push_error("Invalid body number %s", body_id)
			return false
		body_id = body_id.to_int()
		
		bodies.append(body_scene.instantiate())
		bodies[-1].init( bodies.size()-1, body_id)
		add_child(bodies[-1])
		
		# Get body facet list
		while check_head_is_int():
			var cur = ""
			while !is_new_line_or_white(file_content[0]):
				cur += file_content[0]
				consume(1)
			consume_white_space()
			
			if !cur.is_valid_int():
				error_fe()
				push_error("Invalid facet number %s for body %s" % [cur, body_id])
				return false
			
			var f_ids : PackedInt32Array
			f_ids = f_get_ids_from_oid(cur.to_int())
			for f_id in f_ids:
				bodies[-1].add_facet( facets[f_id] )
		
		if not check_head("read"):
		
			while file_content[0] != "\n":
				if check_head("volume"):
					# Consume "volume"
					consume_word()
					
					# Get volume constraint value
					var cur = ""
					while !is_new_line_or_white(file_content[0]):
						cur += file_content[0]
						consume(1)
					consume_white_space()
				
					if not cur.is_valid_float():
						error_fe()
						push_error("Invalid volume constraint %s for body %s" % [cur, body_id])
						return false
				
					bodies[-1].add_vol_constraint(cur.to_float())
			
				else: consume(1)
			
			# Consume rest of line
			consume_line()
	
	# Commands section
	
	return true

func erase_fe_comments() -> void:
	var compos = file_content.find("//")
	while compos != -1:
		while file_content[compos] != "\n":
			file_content = file_content.erase(compos)
		compos = file_content.find("//")
	
	compos = file_content.find("/*")
	while compos != -1:
		file_content = file_content.erase(compos)
		file_content = file_content.erase(compos)
		while compos < file_content.length() and !(file_content[compos] == "*" and file_content[compos+1] == "/"):
			file_content = file_content.erase(compos)
		if compos < file_content.length():
			file_content = file_content.erase(compos)
			file_content = file_content.erase(compos)
		compos = file_content.find("/*")

func error_fe() -> void:
	push_error("Cannot open .fe file")
