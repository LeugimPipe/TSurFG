extends Node

@export var body_scene : PackedScene

var view

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	var args = OS.get_cmdline_user_args()
	var filename = ""
	if !args.is_empty(): filename = args[0]
	else:
		push_error("No file selected")
		return
	# TODO: seleccion de archivos manual
	
	print("Reading file ", filename)
	
	var content = ""
	if !filename.is_empty():
		var file = FileAccess.open(filename, FileAccess.READ)
		if FileAccess.get_open_error() != OK:
			push_error("Couldn't open file ", filename)
			return
		else:
			content = file.get_as_text()
	
	var body = body_scene.instantiate()
	add_child(body)
	body.load_file(content)
	
	if globals.AMBIENT_DIMENSION == 2:
		view = load("res://view/2d/main2d/main2d.tscn").instantiate()
		add_child(view)
	
	if globals.AMBIENT_DIMENSION == 3:
		view = load("res://view/3d/main3d/main3d.tscn").instantiate()
		add_child(view)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
