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
	
	# TODO: file format is case insensitive
	
	erase_comments()
	
	# Definitions and options sections
	# Will ignore it
	
	# TODO: rest of fe specification
	# TODO: there may be more information per line than the basics
	
	# Vertices section
	while !check_head("vertices"):
		consume_word()
		if file_content.is_empty():
			error()
			push_error("Vertices section not found")
			return false
	
	# Consume vertices
	consume_word()
	
	while (check_head_is_int()):
		# Consume vertex number
		var vert_id = get_and_consume_head(" ")
		if !vert_id.is_valid_int():
			error()
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
				error()
				push_error("Invalid x%s coordinate %s for vertex %s" % [i+1, cur, vert_id])
				return false
			
			coords[i] = cur.to_float()
		
		geom.add_vertex(coords, vert_id)
	
	# TODO: comprobar unicidad de los oid
	
	# Consume edges
	if !check_and_consume_head("edges"):
		push_error("Edges section not found")
		return false
	
	while (check_head_is_int()):
		# Consume edge number
		var edge_id = get_and_consume_head(" ")
		if !edge_id.is_valid_int():
			error()
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
				error()
				push_error("Invalid vertex number %s for edge %s" % [cur, edge_id])
				return false
			
			v_oids[i] = cur.to_int()
		
		var v_id : PackedInt32Array
		v_id.resize(2)
		for i in 2:
			v_id[i] = geom.v_get_id_from_oid( v_oids[i] )
			if v_id[i] == -1:
				error()
				push_error("Invalid vertex number %s for edge %s" % [v_oids[i], edge_id])
				return false
		
		geom.add_edge( geom.vertices[ v_id[0] ], geom.vertices[ v_id[1] ], edge_id)
	
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
			error()
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
				error()
				push_error("Invalid edge number %s for facet %s" % [cur, facet_id])
				return false
			
			e.append(cur.to_int())
		
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
		var body_oid = get_and_consume_head(" ")
		if !body_oid.is_valid_int():
			error()
			push_error("Invalid body number %s", body_oid)
			return false
		
		body_oid = body_oid.to_int()
		var body_volume = VolumeBody.new(geom, body_oid)
		geom.add_quantity(body_volume)
		
		# Get body facet list
		while file_content[0] != "\n" and  check_head_is_int():
			var cur = ""
			while !is_new_line_or_white(file_content[0]):
				cur += file_content[0]
				consume(1)
			consume_white_space()
			
			if !cur.is_valid_int():
				error()
				push_error("Invalid facet number %s for body %s" % [cur, body_oid])
				return false
			
			cur = cur.to_int()
			var f_ids : PackedInt32Array
			f_ids = geom.f_get_ids_from_oid( abs(cur) ) 
			for f_id in f_ids:
				body_volume.add_facet(geom.facets[f_id], cur < 0)
			
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
					error()
					push_error("Invalid volume constraint %s for body %s" % [cur, body_oid])
					return false
				
				body_volume.set_magnitude_constraint(cur.to_float())
			
			else: consume(1)
		# Consume rest of line
		consume_line()
	
	# Commands section
	
	return true
