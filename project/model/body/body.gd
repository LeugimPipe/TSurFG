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
