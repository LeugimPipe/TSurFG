extends FileReadInterface
class_name FileReadFe

func error() -> void:
	push_error("Cannot open .fe file")

func erase_comments() -> void:
	var compos = file_content.find("//")
	while compos != -1:
		while compos < file_content.length() and file_content[compos] != "\n":
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

func load_file(_file_content : String, _geom : Geometry) -> bool:
	super(_file_content, _geom)
	
	erase_comments()
	
	# Case insensitivity
	file_content = file_content.to_lower()
	
	# TODO: rest of fe specification
	
	# Definitions and options section
	if not process_defs_section():
		return false
	
	# Vertices section
	if not process_vertices_section():
		return false
	
	# TODO: comprobar unicidad de los oid
	
	# Edges section
	if not process_edges_section():
		return false
	
	# Faces section
	if not geom.string_model:
		if not process_faces_section():
			return false
	
	# Optional Bodies section
	if not process_bodies_section():
		return false
	
	# Commands section
	
	return true

func process_defs_section() -> bool:
	while !check_head("vertices"):
		
		# Check for information
		if check_head("string"):
			geom.string_model = true
		
		consume_word()
		if file_content.is_empty():
			error()
			push_error("Vertices section not found")
			return false
	
	return true

func process_vertices_section() -> bool:
	# Consume vertices
	consume_word()
	
	while (check_head_is_int()):
		# Consume vertex number
		var vert_id = get_and_consume_head_respect_eol()
		if !vert_id.is_valid_int():
			error()
			push_error("Invalid vertex number %s" % vert_id)
			return false
		vert_id = vert_id.to_int()
		
		# Get vertex coordinates
		var coords : PackedFloat32Array
		coords.resize(globals.AMBIENT_DIMENSION)
		for i in globals.AMBIENT_DIMENSION:
			
			#Get coord string
			var cur = get_and_consume_head_respect_eol()
			if !cur.is_valid_float():
				error()
				push_error("Invalid x%s coordinate %s for vertex %s" % [i+1, cur, vert_id])
				return false
			
			coords[i] = cur.to_float()
		
		# Extra attributes
		var rest_of_line = get_and_consume_rest_of_line()
		
		var fixed : bool = false
		
		if rest_of_line.contains("fixed"):
			fixed = true
		
		geom.add_vertex(coords, vert_id, fixed)
	
	return true

func process_edges_section() -> bool:
	# Consume edges
	if !check_and_consume_head("edges"):
		push_error("Edges section not found")
		return false
	
	while (check_head_is_int()):
		# Consume edge number
		var edge_id = get_and_consume_head_respect_eol()
		if !edge_id.is_valid_int():
			error()
			push_error("Invalid edge number %s" % edge_id)
			return false
		edge_id = edge_id.to_int()
		
		# Get vertex numbers
		var v_oids : PackedInt32Array
		v_oids.resize(2)
		v_oids.fill(-1)
		for i in 2:
			var cur = get_and_consume_head_respect_eol()
			if !cur.is_valid_int():
				error()
				push_error("Invalid vertex number %s for edge %s" % [cur, edge_id])
				return false
			
			v_oids[i] = cur.to_int()
			consume_white_space()
		
		var v_id : PackedInt32Array
		v_id.resize(2)
		for i in 2:
			v_id[i] = geom.v_get_id_from_oid( v_oids[i] )
			if v_id[i] == -1:
				error()
				push_error("Invalid vertex number %s for edge %s" % [v_oids[i], edge_id])
				return false
		
		geom.add_edge( geom.vertices[ v_id[0] ], geom.vertices[ v_id[1] ], edge_id)
		
		# Extra attributes
		get_and_consume_rest_of_line()
		#var rest_of_line = get_and_consume_rest_of_line()
		
		#var no_refine : bool = false
		#if rest_of_line.contains("no_refine"):
		#	no_refine = true
	
	return true

func process_faces_section() -> bool:
	# Consume faces
	if !check_and_consume_head("faces"):
		push_error("Faces section not found")
		return false
	
	while check_head_is_int():
		
		# Consume facet number
		var facet_id = get_and_consume_head_respect_eol()
		if !facet_id.is_valid_int():
			error()
			push_error("Invalid facet number %s", facet_id)
			return false
		facet_id = facet_id.to_int()
		
		# Get edge numbers
		var e : PackedInt32Array
		while not is_new_line(file_content[0]) and check_head_is_int():
			var cur = get_and_consume_head_respect_eol()
			
			if !cur.is_valid_int():
				error()
				push_error("Invalid edge number %s for facet %s" % [cur, facet_id])
				return false
				
			e.append(cur.to_int())
				
		# Extra attributes
		get_and_consume_rest_of_line()
		#var rest_of_line = get_and_consume_rest_of_line()
		
		if e.size() == 3:
			var e0 = geom.edges[ geom.e_get_id_from_oid( abs(e[0])) ]
			var e1 = geom.edges[ geom.e_get_id_from_oid( abs(e[1])) ]
			var e2 = geom.edges[ geom.e_get_id_from_oid( abs(e[2])) ]
			
			geom.add_facet( e0, e1, e2, e[0] < 0, e[1] < 0, e[2] < 0, facet_id )
		
		# TODO: n-edge faces
		
		if e.size() == 4:
			# Add new vertex in center
			var coords : PackedFloat32Array
			coords.resize(3)
			coords.fill(0)
			
			for i in 4:
				var edge = geom.edges[ geom.e_get_id_from_oid( abs(e[i]) ) ]
				var vertex
				if e[i] < 0:
					vertex = edge.head
				else:
					vertex = edge.tail
				
				for j in 3:
					coords[j] += vertex.coords[j]
			
			for i in 3: coords[i] /= 4
			
			geom.add_vertex(coords)
			
			# Add diagonal edges
			for i in 4:
				if e[i] < 0: geom.add_edge( geom.edges[ geom.e_get_id_from_oid( abs(e[i]) ) ].tail, geom.vertices[-1] )
				else: geom.add_edge( geom.edges[ geom.e_get_id_from_oid( abs(e[i]) ) ].head, geom.vertices[-1] )
			
			for i in 4:
				geom.add_facet( geom.edges[ geom.e_get_id_from_oid( abs(e[i]) ) ], geom.edges[ geom.edges.size() + i-4 ], geom.edges[ geom.edges.size() + posmod(i-1, 4) - 4 ], e[i] < 0, false, true, facet_id )
	
	return true

func process_bodies_section() -> bool:
	# Bodies section is optional
	if not check_head("bodies"):
		return true
	
	# Consume "bodies"
	consume_word()
	
	while (check_head_is_int()):
		
		# Consume body number
		var body_oid = get_and_consume_head_respect_eol()
		if !body_oid.is_valid_int():
			error()
			push_error("Invalid body number %s", body_oid)
			return false
		
		body_oid = body_oid.to_int()
		var body_volume = VolumeBody.new(geom, body_oid)
		geom.add_quantity(body_volume)
		
		# Get body facet list
		while not is_new_line(file_content[0]) and check_head_is_int():
			var cur = get_and_consume_head_respect_eol()
			
			if !cur.is_valid_int():
				error()
				push_error("Invalid facet number %s for body %s" % [cur, body_oid])
				return false
			
			cur = cur.to_int()
			var f_ids : PackedInt32Array
			f_ids = geom.f_get_ids_from_oid( abs(cur) ) 
			for f_id in f_ids:
				body_volume.add_facet(geom.facets[f_id], cur < 0)
		
		# Extra attributes
		var rest_of_line = get_and_consume_rest_of_line()
		
		if rest_of_line.contains("volume"):
			var vol_str = rest_of_line.right( -rest_of_line.find("volume")-"volume".length() )
			
			while is_white_space(vol_str[0]):
				vol_str = vol_str.right(-1)
			
			var vol_val : String = ""
			while vol_str.length() > 0 and not is_white_space(vol_str[0]):
				vol_val += vol_str[0]
				vol_str = vol_str.right(-1)
			
			if not vol_val.is_valid_float():
				error()
				push_error("Invalid volume constraint %s for body %s" % [vol_val, body_oid])
				return false
				
			body_volume.set_magnitude_constraint(vol_val.to_float())
	
	return true
