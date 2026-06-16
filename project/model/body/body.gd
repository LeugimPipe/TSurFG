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

func init() -> void:
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	init()
	calc_all_ev_vectors()

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

func calc_forces() -> void:
	set_forces_zero()

# TODO: hacer mejor con clase buena, todas las fuerzas, etc
func iterate() -> void:
	for i in vertices.size():
		vertices[i].coords = [ vertices[i].coords[0] + 0.2*forces[i][0].coords[0], vertices[i].coords[1] + 0.2*forces[i][0].coords[1] ]
	
	restore_constants()
	calc_forces()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("iterate"):
		iterate()
	if Input.is_action_just_pressed("refine"):
		refine()

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
		print("ERROR: unrecognized file type")
		return

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
		while !is_new_line_or_white(file_content[0]):
			ret += file_content[0]
			consume(1)
	
	consume_white_or_end_line()
	
	return ret

func consume_white_space() -> void:
	while is_white_space(file_content[0]):
		consume(1)

func consume_end_line() -> void:
	while is_new_line(file_content[0]):
		consume(1)

func consume_white_or_end_line() -> void:
	while is_new_line_or_white(file_content[0]):
		consume(1)

# Consumes next word
# (consumes white space,
# consumes whatever is next until it hits whitespace again,
# and then consumes white space again)
func consume_word() -> void:
	consume_white_or_end_line()
	while file_content[0] != "\n" and file_content[0] != " ":
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
		print("Missing format")
		return
	
	# Check next is the ascii formar indicator
	if !check_and_consume_head("ascii"):
		print("Only ascii .ply files are allowed")
		return
	
	# Consume version
	consume_word()
	
	# Consume next comments
	consume_ply_comments()
	
	# VERTICES section
	
	# Check next line stores number of vertices
	if !check_and_consume_head("element"):
		print("Vertex definition not found")
		return
	
	# Check next line stores number of vertices
	if !check_and_consume_head("vertex"):
		print("Vertex definition not found")
		return
	
	# Check, store and consume number of vertices
	n_vertices = get_and_consume_head()
	if !n_vertices.is_valid_int():
		error_ply()
		print("Number of vertices not found")
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
		print("Definition of x coordinate not found")
		return
	
	if y_pos == -1:
		error_ply()
		print("Definition of y coordinate not found")
		return
	
	if z_pos == -1:
		error_ply()
		print("Definition of z coordinate not found")
		return
	
	# Consume next comments
	consume_ply_comments()
	
	# FACES section
	
	# Check next is a definition
	if !check_and_consume_head("element"):
		print("Definition of faces not found")
		return
	
	# Check it is for faces
	if !check_and_consume_head("face"):
		print("Definition of faces not found")
		return
	
	# Check, store and consume number of vertices
	n_faces = get_and_consume_head()
	if !n_faces.is_valid_int():
		error_ply()
		print("Number of faces not found")
		return
	n_faces = n_faces.to_int()
	
	# Consume next comments
	consume_ply_comments()
	
	# Check, process and consume property list
	if !check_and_consume_head("property"):
		print("Property list of faces not found")
		return
	
	if !check_and_consume_head("list"):
		print("Property list of faces not found")
		return
	
	# Consume type of elements
	# Will check later if they are ints
	consume_word()
	consume_word()
	
	# Check, process and consume vertex_indices or vertex_index
	if !check_head("vertex_indices") and !check_head("vertex_index"):
		error_ply()
		print("Property of faces does not contain vertex indices or vertex index")
		return
	consume_word()
	
	# Consume next comments
	consume_ply_comments()
	
	# TODO: allow more element definitions
	# TODO: allow edges
	
	# Check and consume end_header
	if !check_and_consume_head("end_header"):
		print("end_header not found")
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
					if j == x_pos: print("Invalid x coordinate %s in vertex %s" % [cur, i])
					if j == y_pos: print("Invalid y coordinate %s in vertex %s" % [cur, i])
					if j == z_pos: print("Invalid z coordinate %s in vertex %s" % [cur, i])
					return
				
				if j == x_pos: x = cur.to_float()
				if j == y_pos: y = cur.to_float()
				if j == z_pos: z = cur.to_float()
		
		vertices[-1].init([x,y,z])
		add_child(vertices[-1])

func consume_ply_comments() -> void:
	consume_white_or_end_line()
	
	while check_head("comment"):
		consume("comment".length())
		consume_white_or_end_line()
		consume_line()
		consume_white_or_end_line()
	
	consume_white_or_end_line()

func error_ply() -> void:
	print("ERROR: cannot open .ply file")
