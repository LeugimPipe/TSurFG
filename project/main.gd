extends Node

@export var body_scene : PackedScene

var view

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if globals.AMBIENT_DIMENSION == 2:
		view = load("res://view/2d/main2d/main2d.tscn").instantiate()
		add_child(view)
	
	if globals.AMBIENT_DIMENSION == 3:
		view = load("res://view/3d/main3d/main3d.tscn").instantiate()
		add_child(view)
	
	var file = FileAccess.open("../../ant.ply", FileAccess.READ)
	var content = file.get_as_text()
	
	var body = body_scene.instantiate()
	add_child(body)
	body.load_file(content)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
