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

# TODO: list of vertex
# TODO: list of edges
# TODO: list of facets

# Called when the node enters the scene tree for the first time.
func init() -> void:
	for i in 6:
		vertices.append(vertex_scene.instantiate())
	
	vertices[0].init([0,0], true)
	vertices[1].init([2,0], true)
	vertices[2].init([0,1], true)
	vertices[3].init([2,1], true)
	vertices[4].init([0,1./2])
	vertices[5].init([2,1./2])
	
	for i in 6:
		add_child(vertices[i])
	
	for i in 5:
		edges.append(edge_scene.instantiate())
	
	edges[0].init(vertices[0], vertices[4])
	edges[1].init(vertices[1], vertices[5])
	edges[2].init(vertices[2], vertices[4])
	edges[3].init(vertices[3], vertices[5])
	edges[4].init(vertices[4], vertices[5])
	
	for i in 5:
		add_child(edges[i])
	
	set_forces_zero()

func _ready() -> void:
	init()
	calc_forces()

func set_forces_zero() -> void:
	forces.resize(vertices.size())
	for i in forces.size():
		var zeroforce = force_scene.instantiate()
		zeroforce.init([0,0])
		forces[i] = [zeroforce]

func get_total_length() -> float:
	var total_length = 0.
	
	for e in edges:
		total_length += get_length(e)
	
	return total_length

func get_length(edge) -> float:
	var norm : float = 0.
	for i in globals.AMBIENT_DIMENSION:
		norm += (edge.head.coords[i] - edge.tail.coords[i])*(edge.head.coords[i] - edge.tail.coords[i])
	
	return sqrt(norm)

func calc_forces() -> void:
	set_forces_zero()
	
	# Force 1: Gradient of length
	for i in vertices.size():
		calc_force_vertex(i)

func calc_force_vertex(i: int) -> void:
	if i >= vertices.size():
		print("ERROR: attempted to access non existent vertex of index %s" % i)
		return
	
	var verti = vertices[i]
	
	# Force 1: Gradient of length
	var link = get_link_vertex(i)
	var vedges = get_edges_of_vertex(i)
	for ee in vedges:
		var vl
		if verti == ee.tail:
			vl = ee.head
		if verti == ee.head:
			vl = ee.tail
		
		var force_link = force_scene.instantiate()
		if !verti.fixed:
			force_link.init([ (vl.coords[0] - verti.coords[0])/get_length(ee), (vl.coords[1] - verti.coords[1])/get_length(ee) ])
			forces[i][0].coords = [ forces[i][0].coords[0] + force_link.coords[0], forces[i][0].coords[1] + force_link.coords[1] ] 

func get_edges_of_vertex(i : int) -> Array:
	var ret : Array = []
	
	for ee in edges:
		if vertices[i] == ee.tail or vertices[i] == ee.head:
			ret.append(ee)
	
	return ret

func get_link_vertex(i : int) -> Array:
	var link : Array = [] 
	for j in edges.size():
		if vertices[i] == edges[j].tail:
			link.append(edges[j].head)
		if vertices[i] == edges[j].head:
			link.append(edges[j].tail)
			
	return link

func iterate() -> void:
	for i in vertices.size():
		vertices[i].coords = [ vertices[i].coords[0] + 0.2*forces[i][0].coords[0], vertices[i].coords[1] + 0.2*forces[i][0].coords[1] ]
	
	calc_forces()

	for i in forces.size():
		print("Force %s:" % i)
		print(forces[i][0].coords)
	print(get_total_length())	
	
	var ee = get_edges_of_vertex(4)
	var angle = Vector2( ee[0].head.coords[0] - ee[0].tail.coords[0] , ee[0].head.coords[1] - ee[0].tail.coords[1] ).angle_to( Vector2( ee[1].head.coords[0] - ee[1].tail.coords[0] , ee[1].head.coords[1] - ee[1].tail.coords[1] ) )
	print(rad_to_deg(angle))
	
	for v in vertices:
		print(v.coords)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("iterate"):
		iterate()
