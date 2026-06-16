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
	
	# Check file type
	if check_and_consume_head("ply\n"):
		file_type = PLY
		load_ply()
	else:
		print("ERROR: unrecognized file type")
		return

# FILE PROCESS UTILS

# Checks first characters of file_content match check
# And if so consumes them
# Else displays error message
func check_and_consume_head(check: String) -> bool:
	if check_head(check):
		file_content = file_content.right( -check.length() )
		return true
	if file_type == PLY: error_ply()
	return false

func check_head(check: String) -> bool:
	return file_content.left(check.length()) == check

# Consume file_content until nth character
func consume_until(s : String, n : int = 1) -> void:
	for i in n:
		file_content = file_content.right( -file_content.find(s)-1 )

func consume_line(n: int = 1) -> void:
	consume_until("\n", n)

# Returns and consumes first part of file_content
# (default separator \n)
func get_and_consume_head(separator: String = "\n") -> String:
	var ret : String
	
	var pos_sep = file_content.find(separator)
	ret = file_content.left( pos_sep )
	file_content = file_content.right( -pos_sep-1 )
	
	return ret

# LOAD PLY

func load_ply() -> void:
	
	# Check next line is the ascii formar indicator
	if !check_and_consume_head("format ascii"):
		print("Only ascii .ply files are allowed")
		return
	
	# Consume rest of the line
	consume_line()
	
	# Consume next comments
	consume_ply_comments()
	
	# VERTICES section
	
	# Check next line stores number of vertices
	if !check_and_consume_head("element vertex "):
		print("Vertex definition not found")
		return
	
	# Check, store and consume number of vertices
	var n_vertices = get_and_consume_head()
	if !n_vertices.is_valid_int():
		error_ply()
		print("Number of vertices not found")
		return
	n_vertices = n_vertices.to_int()
	
	# Consume next comments
	consume_ply_comments()
	
	# Process properties
	# Make note of where in the file the x, y, z are located
	var x_pos = -1
	var y_pos = -1
	var z_pos = -1
	
	var cur_pos = 0
	while check_head("property "):
		consume_until(" ", 2)
		
		if check_head("x"): x_pos = cur_pos
		elif check_head("y"): y_pos = cur_pos
		elif check_head("z"): z_pos = cur_pos
		
		consume_line()
		
		# Consume next comments
		consume_ply_comments()
		
		cur_pos += 1
	
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
	
	# Check next line stores number of faces
	if !check_and_consume_head("element face "):
		print("Definition of faces not found")
		return
	
	# Check, store and consume number of vertices
	var n_faces = get_and_consume_head()
	if !n_faces.is_valid_int():
		error_ply()
		print("Number of faces not found")
		return
	n_faces = n_faces.to_int()
	
	# Consume next comments
	consume_ply_comments()
	
	# Check, process and consume property list
	if !check_and_consume_head("property list "):
		print("Property of faces not found")
		return
	
	# Consume type of elements
	# Will check later if they are ints
	consume_until(" ", 2)
	
	# Check, process and consume vertex_indices or vertex_index
	if !check_head("vertex_indices\n") and !check_head("vertex_index\n"):
		error_ply()
		print("Property of faces does not contain vertex indices or vertex index")
		return
	consume_line()
	
	consume_ply_comments()
	
	if !check_and_consume_head("end_header\n"):
		print("end_header not found")
		return
	
	print(file_content)

func consume_ply_comments() -> void:
	while check_head("comment"):
		consume_line()

func error_ply() -> void:
	print("ERROR: cannot open .ply file")
