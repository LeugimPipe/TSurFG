extends "res://model/body/body.gd"

func init() -> void:
	# Vertices
	for i in 26:
		vertices.append(vertex_scene.instantiate())
	
	for i in 8:
		var x = cos(i*PI/4)
		var z = sin(i*PI/4)
		vertices[i].init([x,0,z])
	
	for i in 8:
		var x = cos(PI/4) * cos(i*PI/4)
		var y = sin(PI/4)
		var z = cos(PI/4) * sin(i*PI/4)
		vertices[8+i].init([x,y,z])
	
	for i in 8:
		var x = cos(PI/4) * cos(i*PI/4)
		var y = -sin(PI/4)
		var z = cos(PI/4) * sin(i*PI/4)
		vertices[16+i].init([x,y,z])
	
	vertices[24].init([0,1,0])
	vertices[25].init([0,-1,0])
	
	for i in 26:
		add_child(vertices[i])
	
	# Edges
	var nedges = 8*9
	for i in nedges:
		edges.append(edge_scene.instantiate())
	
	for i in 7:
		edges[i].init(vertices[i], vertices[i+1])
	edges[7].init(vertices[7], vertices[0])
	
	for i in 7:
		edges[i+8].init(vertices[i+8], vertices[i+9])
	edges[15].init(vertices[15], vertices[8])
	
	for i in 7:
		edges[i+16].init(vertices[i+16], vertices[i+17])
	edges[23].init(vertices[23], vertices[16])
	
	edges[24].init(vertices[0], vertices[8])
	edges[25].init(vertices[8], vertices[24])
	edges[26].init(vertices[24], vertices[12])
	edges[27].init(vertices[12], vertices[4])
	edges[28].init(vertices[4], vertices[20])
	edges[29].init(vertices[20], vertices[25])
	edges[30].init(vertices[25], vertices[16])
	edges[31].init(vertices[16], vertices[0])
	
	edges[32].init(vertices[1], vertices[9])
	edges[33].init(vertices[9], vertices[24])
	edges[34].init(vertices[24], vertices[13])
	edges[35].init(vertices[13], vertices[5])
	edges[36].init(vertices[5], vertices[21])
	edges[37].init(vertices[21], vertices[25])
	edges[38].init(vertices[25], vertices[17])
	edges[39].init(vertices[17], vertices[1])
	
	edges[40].init(vertices[2], vertices[10])
	edges[41].init(vertices[10], vertices[24])
	edges[42].init(vertices[24], vertices[14])
	edges[43].init(vertices[14], vertices[6])
	edges[44].init(vertices[6], vertices[22])
	edges[45].init(vertices[22], vertices[25])
	edges[46].init(vertices[25], vertices[18])
	edges[47].init(vertices[18], vertices[2])
	
	edges[48].init(vertices[3], vertices[11])
	edges[49].init(vertices[11], vertices[24])
	edges[50].init(vertices[24], vertices[15])
	edges[51].init(vertices[15], vertices[7])
	edges[52].init(vertices[7], vertices[23])
	edges[53].init(vertices[23], vertices[25])
	edges[54].init(vertices[25], vertices[19])
	edges[55].init(vertices[19], vertices[3])
	
	for i in 7:
		edges[i+56].init(vertices[i], vertices[i+9])
	edges[63].init(vertices[7], vertices[8])
	
	for i in 7:
		edges[i+64].init(vertices[i], vertices[i+17])
	edges[71].init(vertices[7], vertices[16])
	
	for i in nedges:
		add_child(edges[i])
	
	# Facets
	var nfacets = 8
	for i in nfacets:
		facets.append(facet_scene.instantiate())
	
	
	facets[0].init(edges[0], edges[32], edges[56].inverse())
	facets[1].init(edges[1], edges[40], edges[57].inverse())
	facets[2].init(edges[2], edges[48], edges[58].inverse())
	print("Vertices:")
	print(edges[2].tail.coords)
	print(edges[2].head.coords)
	print(edges[48].tail.coords)
	print(edges[48].head.coords)
	print(edges[58].tail.coords)
	print(edges[58].head.coords)
	facets[2].init(edges[2], edges[48], edges[58].inverse())
	
	for i in nfacets:
		add_child(facets[i])
