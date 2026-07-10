extends FileWriteInterface
class_name FileWriteFe

## Concrete file writing strategy object for .fe files

## Writes to given file.
func write_to_file(_file_name : String, _geom : Geometry) -> bool:
	if not super(_file_name, _geom): return false
	
	file.store_line("// " + _file_name)
	file.store_line("// Produced by TSurFG by Miguel Piñar Pérez")
	file.store_line("// .fe file compatible with Surface Evolver by Kenneth A. Brakke")
	
	file.store_line("")
	
	# DEFINITIONS SECTION
	
	if globals.AMBIENT_DIMENSION != 3:
		file.store_line("space_dimension " + str(globals.AMBIENT_DIMENSION))
	
	if geom.string_model:
		file.store_line("string")
	
	file.store_line("")
	
	# VERTICES SECTION
	if not geom.vertices.is_empty():
		file.store_line("vertices")
		for i in geom.vertices.size():
			var v = geom.vertices[i]
			var line : String = str(i+1) + " "
			
			for j in globals.AMBIENT_DIMENSION:
				line += " " + str(v.coords.get_i(j))
			
			if v.fixed: line += " fixed"
			
			file.store_line(line)
	
	file.store_line("")
	
	# EDGES SECTION
	if not geom.edges.is_empty():
		file.store_line("edges")
		for i in geom.edges.size():
			var e = geom.edges[i]
			var line : String = str(i+1) + "  "
			
			line += str(e.tail_id+1) + " " + str(e.head_id+1)
			
			file.store_line(line)
	
	file.store_line("")
	
	# FACES SECTION
	if not geom.facets.is_empty():
		file.store_line("faces")
		for i in geom.facets.size():
			var f = geom.facets[i]
			var line : String = str(i+1) + "  "
			
			if f.inversee0: line += "-"
			line += str(f.edge0_id+1) + " "
			if f.inversee1: line += "-"
			line += str(f.edge1_id+1) + " "
			if f.inversee2: line += "-"
			line += str(f.edge2_id+1)
			
			file.store_line(line)
	
	file.store_line("")
	
	var bodies_written : bool = false
	for q_id in geom.quantities:
		var q = geom.quantities[q_id]
		# If it's a body
		if q.description == VolumeBody.new(geom).description:
			
			if not bodies_written:
				file.store_line("bodies")
				bodies_written = true
			
			var line : String = str(q_id+1) + " "
			
			for f_id in q.facet_ids:
				var f_idstr : String = ""
				if f_id == -0.1 : f_idstr = str(-1)
				else:
					if f_id < 0: f_idstr = "-"
					f_idstr += str( abs(int(f_id))+1 )
				
				line += " " + f_idstr
				
			if q.constrained:
				line += " volume " + str(q.target)
			
			file.store_line(line)
	
	file.close()
	return true
