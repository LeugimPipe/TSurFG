extends Node

var file_loaded_mutex : Mutex

var terminal_input_thread : Thread
var terminal_input_thread_terminate : bool = false

var filename = ""
var file_loaded : bool = false

func set_file_loaded(value: bool) -> void:
	file_loaded_mutex.lock()
	file_loaded = value
	file_loaded_mutex.unlock()

var content = ""

@export var body_scene : PackedScene
var body

var view

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	file_loaded_mutex = Mutex.new()
	body = body_scene.instantiate()
	add_child(body)
	
	var args = OS.get_cmdline_user_args()
	
	if !args.is_empty():
		filename = args[0]
		
		if not filename.is_empty():
			set_file_loaded(load_file())
			if not file_loaded:
				set_up_user_file_load()
		
		else:
			push_error("No file selected")
			set_up_user_file_load()
	
	else: set_up_user_file_load()
	
	terminal_input_thread = Thread.new()
	# Start thread for terminal input
	terminal_input_thread.start(terminal_input)

# There must be something in filename
func load_file(terminal : bool = false) -> bool:
	if !terminal: printraw("\n")
	print("Reading file ", filename)
	
	var file = FileAccess.open(filename, FileAccess.READ)
	if FileAccess.get_open_error() != OK:
		push_error("Couldn't open file ", filename)
		if terminal: globals.semaphore.post()
		return false
	else: content = file.get_as_text()
	
	set_file_loaded( body.load_file(content) )
	
	if not file_loaded:
		# Cutre repetirlo dos veces
		# pero si el load no falla
		# hay que continuar con el hilo
		# despues del inicio del main3d
		if terminal: globals.semaphore.post()
		return false
	
	if globals.AMBIENT_DIMENSION == 2:
		view = load("res://view/2d/main2d/main2d.tscn").instantiate()
		add_child(view)
	
	if globals.AMBIENT_DIMENSION == 3:
		view = load("res://view/3d/main3d/main3d.tscn").instantiate()
		add_child(view)
	
	if terminal: globals.semaphore.post()
	
	return true

func set_up_user_file_load() -> void:
	$GUI/FileSelect.visible = true

func put_down_user_file_load(terminal : bool = false) -> void:
	$GUI/FileSelect.visible = false
	if not terminal: globals.print_prompt()

# KEYBOARD INPUT
func _input(_event: InputEvent) -> void:
	if not file_loaded: return
	if Input.is_action_just_pressed("iterate"):
		printraw("\n")
		body.iterate_n()
		globals.print_prompt()
		
	if Input.is_action_just_pressed("refine"):
		printraw("\n")
		body.refine()
		globals.print_prompt()
		
	if Input.is_action_just_pressed("cam_reset"):
		body.reset_cam()
		
	if Input.is_action_just_pressed("cam_focus"):
		body.focus_cam()

# GUI INPUT
func _on_iterate_button_pressed() -> void:
	if not file_loaded: return
	printraw("\n")
	body.iterate_n()
	globals.print_prompt()

func _on_iterate_button_n_pressed() -> void:
	if not file_loaded: return
	printraw("\n")
	
	var n = $GUI/HBoxContainer/NIteration.text.strip_edges()
	if not n.is_valid_int():
		push_error("Invalid number of iterations")
	else:
		n = n.to_int()
		body.iterate_n(n)
	
	globals.print_prompt()

func _on_line_edit_text_submitted(new_text: String) -> void:
	new_text = new_text.strip_edges()
	if new_text != "":
		filename = new_text
		set_file_loaded( load_file() )
		
		if file_loaded: put_down_user_file_load()
		else: globals.print_file_select_prompt()

# TERMINAL INPUT
func terminal_input() -> void:
	var n_enters : int = 0
	var input : String = "STRING"
	
	while n_enters < 1000:
		if not file_loaded:
			globals.print_file_select_prompt()
		else:
			globals.print_prompt()
		
		input = OS.read_string_from_stdin().strip_edges()
		if terminal_input_thread_terminate: return
		
		if input == "": n_enters += 1
		else:
			if input == "q":
				get_tree().quit()
				return
			
			n_enters = 0
			
			if not file_loaded:
				filename = input
				call_deferred("load_file", true)
				
				# Wait for file to be processed
				globals.semaphore.wait()
				
				if file_loaded: call_deferred( "put_down_user_file_load", true )
		
			else:
			
				if input.length() == 1:
					match input:
						"g":
							body.call_deferred("iterate_n", 1, true)
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
										body.call_deferred("iterate_n", n, true)
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

func _exit_tree():
	terminal_input_thread_terminate = true
	if terminal_input_thread.is_alive(): printraw("\n")
	printraw("To confirm quitting, type enter in the terminal\n")
	if not terminal_input_thread.is_alive():
		OS.read_string_from_stdin()
	
	terminal_input_thread.wait_to_finish()
