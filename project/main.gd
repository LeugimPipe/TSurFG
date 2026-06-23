extends Node

var terminal_input_thread : Thread
var terminal_input_thread_terminate : bool = false

@export var body_scene : PackedScene
var body

var view

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	terminal_input_thread = Thread.new()
	
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
	
	body = body_scene.instantiate()
	add_child(body)
	body.load_file(content)
	
	# Start thread for terminal input
	terminal_input_thread.start(terminal_input)
	
	if globals.AMBIENT_DIMENSION == 2:
		view = load("res://view/2d/main2d/main2d.tscn").instantiate()
		add_child(view)
	
	if globals.AMBIENT_DIMENSION == 3:
		view = load("res://view/3d/main3d/main3d.tscn").instantiate()
		add_child(view)

func _exit_tree():
	globals.semaphore.post()
	terminal_input_thread_terminate = true
	if terminal_input_thread.is_alive():
		print("To finnish quitting in this mode, type enter in the terminal")
		printraw("> ")
	
	terminal_input_thread.wait_to_finish()

func terminal_input() -> void:
	var n_enters : int = 0
	var input : String = "STRING"
	
	# Condicion de parada cutre
	# pero asi el hilo termina
	# cuando no hay terminal
	# ya que read_string_from_stdin
	# da string vacia cuando no hay terminal
	
	# Wait for body to be complete
	globals.semaphore.wait()
	while n_enters < 1000:
		
		globals.print_prompt()
		
		input = OS.read_string_from_stdin()
		if terminal_input_thread_terminate: return
		
		if input == "q":
			get_tree().quit()
			return
		
		if input == "": n_enters += 1
		else: n_enters = 0
	
		if input.length() == 1:
			match input:
				"g":
					body.call_deferred("iterate_n")
					# Wait for action to complete
					globals.semaphore.wait()
	
		elif input.length() > 1:
			match input[1]:
				" ":
					match input[0]:
						"g":
							input = input.right(-2)
							if !input.is_valid_int():
								push_error("Invalid number of iterations")
							else:
								var n = input.to_int()
								body.call_deferred("iterate_n", n)
								# Wait for action to complete
								globals.semaphore.wait()
				_: pass
	
	#if input == "m": print("Changing from optimizing time factor to constant time factor")
	#elif input.length() != 1 and input[0] == "m":
	#	if input[1] != " ": push_error("No ")
	
	#if input[0] == "m":
	#	print("Changing from optimizing time factor to constant time factor")
	
	#if input.length() == 1: print("Receive time step")
	#elif input[1] != " ": push_error("No ")
