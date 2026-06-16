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
	
	# Check file type
	if content.left("ply".length()) == "ply":
		load_ply(content)
	else:
		print("ERROR: unrecognized file type")
		return

func load_ply(content: String) -> void:
	# Consume "ply" header
	content = content.right(-3)
	
	# Check next character is a new line
	if !check_next_is_newline(content):
		return
	content = content.right(-1)
	
	# Check next line is the ascii formar indicator
	if content.left("format ascii".length()) != "format ascii":
		error_ply()
		print("Only ascii .ply files are allowed")
		return
	
	# Consume rest of the line
	content = content.right( -content.find("\n")-1 )
	
	# Consume next comments
	while content.left("comment".length()) == "comment":
		content = content.right( -content.find("\n") )
		# Check next character is a new line
		if !check_next_is_newline(content):
			return
		content = content.right(-1)
	
	# Check next line stores number of vertices
	if content.left("element vertex ".length()) != "element vertex ":
		error_ply()
		return
	content = content.right(-"element vertex ".length())
	
	# Check, store and consume number of vertices
	var n_vertices = content.left(content.find("\n"))
	if !n_vertices.is_valid_int():
		error_ply()
		return
	n_vertices = n_vertices.to_int()
	content = content.right( -content.find("\n")-1 )
	
	# Consume next comments
	while content.left("comment".length()) == "comment":
		content = content.right( -content.find("\n") )
		# Check next character is a new line
		if !check_next_is_newline(content):
			return
		content = content.right(-1)
	
	# Process properties
	# Make note of where in the file the x, y, z are located
	var x_pos = -1
	var y_pos = -1
	var z_pos = -1
	
	var cur_pos = 0
	while content.left("property ".length()) == "property ":
		content = content.right(-"property ".length())
		content = content.right( -content.find(" ")-1 )
		
		var next_nl = content.find("\n")
		if content.left( next_nl ) == "x": x_pos = cur_pos
		elif content.left( next_nl ) == "y": y_pos = cur_pos
		elif content.left( next_nl ) == "z": z_pos = cur_pos
		
		content = content.right( -next_nl-1 )
		
		# Consume next comments
		while content.left("comment".length()) == "comment":
			content = content.right( -content.find("\n") )
			# Check next character is a new line
			if !check_next_is_newline(content):
				return
			content = content.right(-1)
		
		cur_pos += 1
	
	# Consume next comments
	while content.left("comment".length()) == "comment":
		content = content.right( -content.find("\n") )
		# Check next character is a new line
		if !check_next_is_newline(content):
			return
		content = content.right(-1)
	
	# Check next line stores number of faces
	if content.left("element face ".length()) != "element face ":
		error_ply()
		return
	content = content.right(-"element face ".length())
	
	# Check, store and consume number of vertices
	var n_faces = content.left(content.find("\n"))
	if !n_faces.is_valid_int():
		error_ply()
		return
	n_faces = n_faces.to_int()
	content = content.right( -content.find("\n")-1 )
	
	# Consume next comments
	while content.left("comment".length()) == "comment":
		content = content.right( -content.find("\n") )
		# Check next character is a new line
		if !check_next_is_newline(content):
			return
		content = content.right(-1)
	
	print(content)

func check_next_is_newline(content) -> bool:
	if content.left(1) != "\n":
		error_ply()
		return false
	return true

func error_ply() -> void:
	print("ERROR: cannot open .ply file")
