extends Node

@export var vertex_scene : PackedScene
@export var edge_scene : PackedScene
@export var facet_scene : PackedScene
@export var force_scene : PackedScene

var vertices : Array
var edges : Array
var facets : Array

# List of forces
# Array of array of Force nodes
# Each element is the set of forces applied to a vertex
# The vertex is the one with the same number in the list of vertices
var forces : Array

# Content of the file being processed
var file_content : String

# File type
enum {NONE, PLY}
var file_type = NONE

signal cam_info_calculated
signal cam_center_calculated

# VectorN
var center : Array
var radius : float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("iterate"):
		iterate()
	if Input.is_action_just_pressed("refine"):
		refine()
	if Input.is_action_just_pressed("cam_reset"):
		cam_info_calculated.emit(center, radius)
	if Input.is_action_just_pressed("cam_focus"):
		cam_center_calculated.emit(center)

# Functions after initialization
func init() -> void:
	calc_characteristics()
	
	var main = get_node("..")
	await main.child_entered_tree
	var main3d = get_node("../Main3D")
	await main3d.ready
	cam_info_calculated.emit(center, radius)

func calc_characteristics() -> void:
	calc_center()
	calc_radius()
	calc_all_ev_vectors()

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

func calc_all_ev_vectors() -> void:
	calc_forces()
	restore_constants()

func restore_constants() -> void:
	pass

func set_forces_zero() -> void:
	forces.resize(vertices.size())
	for i in forces.size():
		var zeroforce = force_scene.instantiate()
		zeroforce.init([0,0])
		forces[i] = [zeroforce]
		add_child(zeroforce)

func calc_forces() -> void:
	set_forces_zero()

# TODO: hacer mejor con clase buena, todas las fuerzas, etc
func iterate() -> void:
	for i in vertices.size():
		vertices[i].coords = [ vertices[i].coords[0] + 0.2*forces[i][0].coords[0], vertices[i].coords[1] + 0.2*forces[i][0].coords[1] ]
	
	restore_constants()
	calc_forces()

func refine() -> void:
	pass

func load_file(content: String) -> void:
	file_content = content
	
	consume_white_or_end_line()
	
	# Check file type
	if check_and_consume_head("ply"):
		file_type = PLY
		load_ply()
	else:
		push_error("Unrecognized file type")
		return
	
	# TODO: check face orientation compatibility
	
	init()

# FILE PROCESS UTILS

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
	
	return false

func check_head(check: String) -> bool:
	return file_content.left(check.length()) == check

# Consume file_content until nth character
func consume_until(s : String, n : int = 1) -> void:
	for i in n:
		consume( file_content.find(s)+1 )

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

# Consumes next word
# (consumes white space,
# consumes whatever is next until it hits whitespace again,
# and then consumes white space again)
func consume_word(n: int = 1) -> void:
	for i in n:
		consume_white_or_end_line()
		while file_content.length() > 0 and file_content[0] != "\n" and file_content[0] != " ":
			consume(1)
		consume_white_or_end_line()

# LOAD PLY

func load_ply() -> void:
	var n_vertices
	var n_prop_verts
	var x_pos
	var y_pos
	var z_pos
	var n_faces
	
	# Check next comes the format indicator
	if !check_and_consume_head("format"):
		push_error("Missing format")
		return
	
	# Check next is the ascii formar indicator
	if !check_and_consume_head("ascii"):
		push_error("Only ascii .ply files are allowed")
		return
	
	# Consume version
	consume_word()
	
	# Consume next comments
	consume_ply_comments()
	
	# VERTICES section
	
	# Check next line stores number of vertices
	if !check_and_consume_head("element"):
		push_error("Vertex definition not found")
		return
	
	# Check next line stores number of vertices
	if !check_and_consume_head("vertex"):
		push_error("Vertex definition not found")
		return
	
	# Check, store and consume number of vertices
	n_vertices = get_and_consume_head()
	if !n_vertices.is_valid_int():
		error_ply()
		push_error("Number of vertices not found")
		return
	n_vertices = n_vertices.to_int()
	
	# Consume next comments
	consume_ply_comments()
	
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
		
		# Consume next comments
		consume_ply_comments()
		
		n_prop_verts += 1
	
	if x_pos == -1:
		error_ply()
		push_error("Definition of x coordinate not found")
		return
	
	if y_pos == -1:
		error_ply()
		push_error("Definition of y coordinate not found")
		return
	
	if z_pos == -1:
		error_ply()
		push_error("Definition of z coordinate not found")
		return
	
	# Consume next comments
	consume_ply_comments()
	
	# FACES section
	
	# Check next is a definition
	if !check_and_consume_head("element"):
		push_error("Expected definition of element")
		return
	
	# Check it is for faces
	if !check_and_consume_head("face"):
		push_error("Invalid definition of faces")
		return
	
	# Check, store and consume number of vertices
	n_faces = get_and_consume_head()
	if !n_faces.is_valid_int():
		error_ply()
		push_error("Invalid number of faces")
		return
	n_faces = n_faces.to_int()
	
	# Consume next comments
	consume_ply_comments()
	
	# Check, process and consume property list
	if !check_and_consume_head("property"):
		push_error("Expected property of faces")
		return
	
	if !check_and_consume_head("list"):
		push_error("Property vertex list of faces not found")
		return
	
	# Consume type of elements
	# Will check later if they are ints
	consume_word(2)
	
	# Check, process and consume vertex_indices or vertex_index
	if !check_head("vertex_indices") and !check_head("vertex_index"):
		error_ply()
		push_error("Property of faces does not contain vertex indices or vertex index")
		return
	consume_word()
	
	# Consume next comments
	consume_ply_comments()
	
	# TODO: allow edges
	
	# Allow more element definitions
	# Will ignore them
	while check_head("element"):
		# Consume "element", element name and number of elements
		consume_word(3)
		
		# Consume any comments after element definition
		consume_ply_comments()
		
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
			
			# Consume any comments after property definition
			consume_ply_comments()
	
	# Check and consume end_header
	if !check_and_consume_head("end_header"):
		push_error("end_header not found")
		return
	
	# VERTEX LIST
	
	# n_vertices
	# n_prop_verts
	# x_pos
	# y_pos
	# z_pos
	# n_faces
	# n_prop_verts
	
	for i in n_vertices:
		vertices.append(vertex_scene.instantiate())
		
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
					return
				
				if j == x_pos: x = cur.to_float()
				if j == y_pos: y = cur.to_float()
				if j == z_pos: z = cur.to_float()
		
		vertices[-1].init(i, [x,y,z])
		add_child(vertices[-1])
	
	# FACET LIST
	for i in n_faces:
		# Get number of vertices
		var n_vertices_face = get_and_consume_head()
		if !n_vertices_face.is_valid_int():
			error_ply()
			push_error("Invalid number of vertices %s for facet %s" % [n_vertices_face, i])
			return
		n_vertices_face = n_vertices_face.to_int()
		
		if n_vertices_face != 3 and n_vertices_face != 4:
			error_ply()
			push_error("Invalid number of vertices %s for facet %s" % [n_vertices_face, i])
			push_error("Only 3 or 4 vertices per face are allowed")
			return
		
		var v_indices : Array
		v_indices.resize(n_vertices_face)
		v_indices.fill(-1)
		
		# Get indices of vertices
		for j in n_vertices_face:
			v_indices[j] = get_and_consume_head()
			if !v_indices[j].is_valid_int():
				error_ply()
				push_error("Invalid vertex %s for facet %s" % [v_indices[j], i])
				return
			v_indices[j] = v_indices[j].to_int()
		
		for j in n_vertices_face:
			if v_indices[j] == -1:
				error_ply()
				push_error("Invalid %sth index for facet %s" % [j, i])
				return
		
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
		
		# Add facet
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

func consume_ply_comments() -> void:
	consume_white_or_end_line()
	
	while check_head("comment"):
		consume("comment".length())
		consume_white_or_end_line()
		consume_line()
		consume_white_or_end_line()
	
	consume_white_or_end_line()

func error_ply() -> void:
	push_error("Cannot open .ply file")
