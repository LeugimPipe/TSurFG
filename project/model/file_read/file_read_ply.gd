extends FileRead
class_name FileReadPly

func error() -> void:
	push_error("Cannot open .ply file")

func erase_comments() -> void:
	var compos = file_content.find("comment")
	while compos != -1:
		while file_content[compos] != "\n":
			file_content = file_content.erase(compos)
		compos = file_content.find("comment")

func load_file(_file_content : String, _geom : Geometry) -> bool:
	super(_file_content, _geom)
	
	# Consume ply
	consume_word()
	
	var n_vertices
	var n_prop_verts
	var x_pos
	var y_pos
	var z_pos
	var n_faces
	
	# Check next comes the format indicator
	if !check_and_consume_head("format"):
		error()
		push_error("Missing format")
		return false
	
	# Check next is the ascii formar indicator
	if !check_and_consume_head("ascii"):
		error()
		push_error("Only ascii .ply files are allowed")
		return false
	
	# Consume version
	consume_word()
	
	# Erases comments
	erase_comments()
	
	# VERTICES section
	
	# Check next line stores number of vertices
	if !check_and_consume_head("element"):
		error()
		push_error("Vertex definition not found")
		return false
	
	# Check next line stores number of vertices
	if !check_and_consume_head("vertex"):
		error()
		push_error("Vertex definition not found")
		return false
	
	# Check, store and consume number of vertices
	n_vertices = get_and_consume_head()
	if !n_vertices.is_valid_int():
		error()
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
		error()
		push_error("Definition of x coordinate not found")
		return false
	
	if y_pos == -1:
		error()
		push_error("Definition of y coordinate not found")
		return false
	
	if z_pos == -1:
		error()
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
		error()
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
		error()
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
					error()
					if j == x_pos: push_error("Invalid x coordinate %s for vertex %s" % [cur, i])
					if j == y_pos: push_error("Invalid y coordinate %s for vertex %s" % [cur, i])
					if j == z_pos: push_error("Invalid z coordinate %s for vertex %s" % [cur, i])
					return false
				
				if j == x_pos: x = cur.to_float()
				if j == y_pos: y = cur.to_float()
				if j == z_pos: z = cur.to_float()
		
		geom.add_vertex([x,y,z], i)
	
	# FACET LIST
	for i in n_faces:
		# Get number of vertices
		var n_vertices_face = get_and_consume_head()
		if !n_vertices_face.is_valid_int():
			error()
			push_error("Invalid number of vertices %s for facet %s" % [n_vertices_face, i])
			return false
		n_vertices_face = n_vertices_face.to_int()
		
		if n_vertices_face != 3 and n_vertices_face != 4:
			error()
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
				error()
				push_error("Invalid vertex %s for facet %s" % [v_indices[j], i])
				return false
			v_indices[j] = v_indices[j].to_int()
		
		for j in n_vertices_face:
			if v_indices[j] == -1:
				error()
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
			if j == 4: edge_id = geom.vertices[ v_indices[0] ].get_edge_index_from_v_id( v_indices[2] )
			else: edge_id = geom.vertices[ v_indices[j] ].get_edge_index_from_v_id( v_indices[ (j+1) % n_vertices_face ] )
			
			# If it doesn't exist, we create it
			# In both cases we make note of the edge id
			if edge_id == INF:
				if j == 4: geom.add_edge( geom.vertices[ v_indices[ 0 ] ], geom.vertices[ v_indices[ 2 ] ] )
				else: geom.add_edge( geom.vertices[ v_indices[ j ] ], geom.vertices[ v_indices[ (j+1) % n_vertices_face ] ] )
				
				e_indices[j] = geom.edges.size()-1
			else:
				e_indices[j] = edge_id
		
		# Add facet(s)
		if n_vertices_face == 3:
			geom.add_facet( geom.edges[ abs(e_indices[0]) ], geom.edges[ abs(e_indices[1]) ], geom.edges[ abs(e_indices[2]) ], e_indices[0] < 0, e_indices[1] < 0, e_indices[2] < 0 )
			
		elif n_vertices_face == 4:
			geom.add_facet( geom.edges[ abs(e_indices[0]) ], geom.edges[ abs(e_indices[1]) ], geom.edges[ abs(e_indices[4]) ], e_indices[0] < 0, e_indices[1] < 0, e_indices[4] > 0 )
			geom.add_facet( geom.edges[ abs(e_indices[2]) ], geom.edges[ abs(e_indices[3]) ], geom.edges[ abs(e_indices[4]) ], e_indices[2] < 0, e_indices[3] < 0, e_indices[4] < 0 )
	
	return true
	
