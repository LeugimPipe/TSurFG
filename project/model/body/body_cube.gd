extends "res://model/body/body.gd"

func init() -> void:
	# Vertices
	for i in 8:
		vertices.append(vertex_scene.instantiate())
	
	for i in 8:
		vertices[i].init([ (((i/2)/2)%2) * 2 -1, ((i/2)%2) * 2 -1, (i%2) * 2 -1 ])
	
	for i in 8:
		add_child(vertices[i])
	
	# Edges
	for i in 18:
		edges.append(edge_scene.instantiate())
	
	edges[0].init(vertices[0], vertices[1])
	edges[1].init(vertices[1], vertices[5])
	edges[2].init(vertices[5], vertices[4])
	edges[3].init(vertices[4], vertices[0])
	
	edges[4].init(vertices[2], vertices[3])
	edges[5].init(vertices[3], vertices[7])
	edges[6].init(vertices[7], vertices[6])
	edges[7].init(vertices[6], vertices[2])
	
	edges[8].init(vertices[0], vertices[2])
	edges[9].init(vertices[1], vertices[3])
	edges[10].init(vertices[5], vertices[7])
	edges[11].init(vertices[4], vertices[6])
	
	edges[12].init(vertices[0], vertices[3])
	edges[13].init(vertices[1], vertices[7])
	edges[14].init(vertices[5], vertices[6])
	edges[15].init(vertices[4], vertices[2])
	
	edges[16].init(vertices[0], vertices[5])
	edges[17].init(vertices[3], vertices[6])
	
	for i in 18:
		add_child(edges[i])
	
	# Factes
	var nfacets = 6
	for i in nfacets:
		facets.append(facet_scene.instantiate())
	
	facets[0].init(edges[0], edges[1], edges[16].inverse())
	facets[1].init(edges[2], edges[3], edges[16])
	
	facets[2].init(edges[0], edges[9], edges[12].inverse())
	facets[3].init(edges[4], edges[12].inverse(), edges[8])
	
	facets[4].init(edges[1], edges[10], edges[13].inverse())
	facets[5].init(edges[13].inverse(), edges[9], edges[5])
	
	# TODO: check compatible orientations
	
	for i in nfacets:
		add_child(facets[i])
