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

@export var geom_scene : PackedScene
var geom

var view

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	file_loaded_mutex = Mutex.new()
	geom = geom_scene.instantiate()
	add_child(geom)
	
	var args = OS.get_cmdline_user_args()
	
	if !args.is_empty():
		filename = args[0]
		
		if not filename.is_empty():
			load_file()
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
func load_file(terminal : bool = false) :
	if !terminal: printraw("\n")
	print("Reading file ", filename)
	
	var file = FileAccess.open(filename, FileAccess.READ)
	if FileAccess.get_open_error() != OK:
		push_error("Couldn't open file ", filename)
		set_file_loaded( false )
	else:
		content = file.get_as_text()
	
		set_file_loaded( geom.load_file(content) )
	
		if file_loaded:
	
			if globals.AMBIENT_DIMENSION == 2:
				view = load("res://view/2d/main2d/main2d.tscn").instantiate()
				add_child(view)
	
			if globals.AMBIENT_DIMENSION == 3:
				view = load("res://view/3d/main3d/main3d.tscn").instantiate()
				add_child(view)
	
	if terminal: globals.semaphore.post()

func set_up_user_file_load() -> void:
	$GUI/FileSelect.visible = true

func put_down_user_file_load(terminal : bool = false) -> void:
	$GUI/FileSelect.visible = false
	if not terminal: globals.print_prompt()

func change_to_optimizing(terminal : bool = false) -> void:
	globals.optimizing_time_step = true
	globals.printer("Changing from constant to optimizing time step")
	$GUI/HBoxContainer/ChangeTimeStep.disabled = true
	$GUI/HBoxContainer/TimeStepIntro.editable = false
	$GUI/HBoxContainer/ChangeTimeStepMode.text = "Change to constant time step"
	if terminal: globals.semaphore.post()

func change_to_constant(new_time_step : float, terminal : bool = false) -> void:
	globals.optimizing_time_step = false
	
	globals.time_step = new_time_step
	
	globals.printer("Changing from optimizing to constant time step %s" % globals.time_step)
	$GUI/HBoxContainer/ChangeTimeStep.disabled = false
	$GUI/HBoxContainer/TimeStepIntro.editable = true
	$GUI/HBoxContainer/ChangeTimeStepMode.text = "Change to optimizing time step"
	if terminal: globals.semaphore.post()

func change_time_step(new_time_step : float, terminal : bool = false) -> void:
	print("Changing time step from ", globals.time_step , " to ", new_time_step)
	globals.time_step = new_time_step
	if terminal: globals.semaphore.post()

# KEYBOARD INPUT
func _input(_event: InputEvent) -> void:
	if not file_loaded: return
	if Input.is_action_just_pressed("iterate"):
		printraw("\n")
		geom.iterate_n()
		globals.print_prompt()
		
	if Input.is_action_just_pressed("refine"):
		printraw("\n")
		geom.refine()
		globals.print_prompt()
		
	if Input.is_action_just_pressed("cam_reset"):
		geom.reset_cam()
		
	if Input.is_action_just_pressed("cam_focus"):
		geom.focus_cam()

# GUI INPUT
func _on_iterate_button_pressed() -> void:
	if not file_loaded: return
	printraw("\n")
	geom.iterate_n()
	globals.print_prompt()

func _on_iterate_button_n_pressed() -> void:
	if not file_loaded: return
	printraw("\n")
	
	var n = $GUI/HBoxContainer/NIterationIntro.text.strip_edges()
	if not n.is_valid_int():
		push_error("Invalid number of iterations")
	else:
		n = n.to_int()
		geom.iterate_n(n)
	
	globals.print_prompt()

func _on_line_edit_text_submitted(new_text: String) -> void:
	new_text = new_text.strip_edges()
	if new_text != "":
		filename = new_text
		load_file()
		
		if file_loaded: put_down_user_file_load()
		else: globals.print_file_select_prompt()

func _on_change_time_step_pressed() -> void:
	if not file_loaded: return
	printraw("\n")
	
	var new_time_step = $GUI/HBoxContainer/TimeStepIntro.text.strip_edges()
	if not new_time_step.is_valid_float():
		push_error("Invalid time step %s" % new_time_step )
	else:
		change_time_step(new_time_step.to_float())
	
	globals.print_prompt()

func _on_change_time_step_mode_pressed() -> void:
	if not file_loaded: return
	printraw("\n")
	
	if not globals.optimizing_time_step:
		change_to_optimizing()
	else:
		var new_time_step = $GUI/HBoxContainer/TimeStepIntro.text.strip_edges()
	
		if new_time_step.is_valid_float():
			new_time_step = new_time_step.to_float()
		else:
			new_time_step = 0.1
		
		change_to_constant(new_time_step)
	
	globals.print_prompt()

func _on_refine_button_pressed() -> void:
	if not file_loaded: return
	printraw("\n")
	geom.refine()
	globals.print_prompt()

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
							geom.call_deferred("iterate_n", 1, true)
							# Wait for action to complete
							globals.semaphore.wait()
						
						"r":
							geom.call_deferred("refine", true)
							# Wait for action to complete
							globals.semaphore.wait()
						
						"m":
							if not globals.optimizing_time_step:
								call_deferred("change_to_optimizing", true)
								# Wait for action to complete
								globals.semaphore.wait()
							
							else:
								print("Changing from optimizing to constant time step")
								
								call_deferred( "start_sub_prompt" )
								# Wait for action to complete
								globals.semaphore.wait()
								
								printraw("Introduce new time step: ")
								var new_time_step = OS.read_string_from_stdin().strip_edges()
								if terminal_input_thread_terminate: return
								
								while not new_time_step.is_valid_float():
									print("Invalid time step")
									printraw("Introduce new time step: ")
									new_time_step = OS.read_string_from_stdin().strip_edges()
									if terminal_input_thread_terminate: return
								
								call_deferred( "end_sub_prompt" )
								# Wait for action to complete
								globals.semaphore.wait()
								
								call_deferred("change_to_constant", new_time_step.to_float(), true)
								
								# Wait for action to complete
								globals.semaphore.wait()
	
				elif input.length() > 1:
					match input[1]:
						" ":
							match input[0]:
								"g":
									input = input.right(-2).strip_edges()
									if !input.is_valid_int():
										push_error("Invalid number of iterations %s" % input)
									else:
										var n = input.to_int()
										geom.call_deferred("iterate_n", n, true)
										# Wait for action to complete
										globals.semaphore.wait()
								
								"m":
									input = input.right(-2).strip_edges()
									if not input.is_valid_float():
										push_error("Invalid time step %s" % input)
									else:
										var new_time_step = input.to_float()
										if globals.optimizing_time_step:
											call_deferred("change_to_constant", new_time_step, true)
										
										else:
											call_deferred("change_time_step", new_time_step, true)
										
										# Wait for action to complete
										globals.semaphore.wait()
						
						_: pass

## Called when the terminal input thread starts a subprompt.
## Disables all other input
func start_sub_prompt() -> void:
	get_tree().paused = true
	globals.semaphore.post()

func end_sub_prompt() -> void:
	get_tree().paused = false
	globals.semaphore.post()

func _exit_tree():
	terminal_input_thread_terminate = true
	if terminal_input_thread.is_alive(): printraw("\n")
	printraw("To confirm quitting, type enter in the terminal\n")
	if not terminal_input_thread.is_alive():
		OS.read_string_from_stdin()
	
	terminal_input_thread.wait_to_finish()
