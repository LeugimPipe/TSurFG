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

## File content.
var file_content = ""

@export var geom_scene : PackedScene
var geom

var view

var volumes_display

## File selection GUI.
var file_select

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
	if view != null: view.queue_free()
	if !terminal: printraw("\n")
	globals.printer("Reading file " + filename)
	
	var file = FileAccess.open(filename, FileAccess.READ)
	if FileAccess.get_open_error() != OK:
		push_error("Couldn't open file ", filename)
		set_file_loaded( false )
	else:
		file_content = file.get_as_text()
		
		geom.set_file_read( set_file_read_strat() )
		set_file_loaded( geom.load_file(file_content) )
		
		if file_loaded:
		
			if globals.AMBIENT_DIMENSION == 2:
				view = load("res://view/2d/main2d/main2d.tscn").instantiate()
				add_child(view)
		
			if globals.AMBIENT_DIMENSION == 3:
				view = load("res://view/3d/main3d/main3d.tscn").instantiate()
				add_child(view)
	
	# Allow terminal thread to continue execution
	if terminal: globals.semaphore.post()

func set_up_user_file_load() -> void:
	$GUI/FileSelect.visible = true

func put_down_user_file_load(terminal : bool = false) -> void:
	$GUI/FileSelect.visible = false
	if not terminal: globals.print_prompt()

## Selects a file reading strategy to pass.
## Selection done according to file_content.
func set_file_read_strat() -> FileRead:
	# Eliminate initial white space
	while file_content[0] == " " or file_content == "\n" or file_content == "\t":
		file_content = file_content.right(-1)
	
	if file_content.left( "ply".length() ) == "ply":
		# File reading strategy for ply files
		return FileReadPly.new()
	
	else:
		# Will attempt to parse file
		# as a surface evolver (.fe) file
		# These don't start with a magic word
		# File reading strategy for fe files
		return FileReadFe.new()

func change_to_optimizing(terminal : bool = false) -> void:
	globals.optimizing_time_step = true
	globals.printer("Changing from constant to optimizing time step")
	$GUI/EvolutionControls/ChangeTimeStep.disabled = true
	$GUI/EvolutionControls/TimeStepIntro.editable = false
	$GUI/EvolutionControls/ChangeTimeStepMode.text = "Change to constant time step"
	if terminal: globals.semaphore.post()

func change_to_constant(new_time_step : float, terminal : bool = false) -> void:
	globals.optimizing_time_step = false
	
	globals.time_step = new_time_step
	
	globals.printer("Changing from optimizing to constant time step %s" % globals.time_step)
	$GUI/EvolutionControls/ChangeTimeStep.disabled = false
	$GUI/EvolutionControls/TimeStepIntro.editable = true
	$GUI/EvolutionControls/ChangeTimeStepMode.text = "Change to optimizing time step"
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
	
	var n = $GUI/EvolutionControls/NIterationIntro.text.strip_edges()
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
	
	var new_time_step = $GUI/EvolutionControls/TimeStepIntro.text.strip_edges()
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
		var new_time_step = $GUI/EvolutionControls/TimeStepIntro.text.strip_edges()
	
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

func _on_volumes_button_pressed() -> void:
	if not file_loaded: return
	
	if volumes_display == null:
		volumes_display = load("res://controller/gui/volumes_display/volumes_display.tscn").instantiate()
		geom.bodies_changed.connect(volumes_display._on_bodies_changed)
		volumes_display.add_body_whole.connect(geom._on_add_body_whole)
		volumes_display.init( geom.bodies )
		$GUI.add_child(volumes_display)
		$GUI/EvolutionControls/VolumesButton.text = "Hide volumes"
		
	else:
		hide_volumes_display()

func hide_volumes_display() -> void:
	volumes_display.queue_free()
	$GUI/EvolutionControls/VolumesButton.text = "Display volumes"

func _on_reload_button_pressed() -> void:
	if not file_loaded: return
	if volumes_display != null: hide_volumes_display()
	set_file_loaded(false)
	set_up_user_file_load()

func _on_save_button_pressed() -> void:
	if not file_loaded: return
	if volumes_display != null: hide_volumes_display()
	display_file_select()

func display_file_select() -> void:
	if file_select == null:
		file_select = load("res://controller/gui/file_select/file_select.tscn").instantiate()
		file_select.cancel.connect(self._on_file_select_cancel)
		file_select.file_selected.connect(self._on_file_select_file_selected)
		$GUI.add_child(file_select)

func _on_file_select_cancel() -> void:
	file_select.queue_free()

func _on_file_select_file_selected(file : String) -> void:
	file_select.queue_free()
	
	## Strategy for file writing
	var file_write
	
	# Process file type
	# Only one strategy for one, no need to process
	file_write = FileWriteFe.new()
	
	geom.set_file_write(file_write)
	geom.write_to_file(file)

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
						# Iterate
						"g":
							geom.call_deferred("iterate_n", 1, true)
							# Wait for action to complete
							globals.semaphore.wait()
						
						# Refine
						"r":
							geom.call_deferred("refine", true)
							# Wait for action to complete
							globals.semaphore.wait()
						
						# Display volume information
						#"v":
						#	geom.call_deferred("", true)
						
						# Change time step/time step mode
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
								# Iterate n
								"g":
									input = input.right(-2).strip_edges()
									if !input.is_valid_int():
										push_error("Invalid number of iterations %s" % input)
									else:
										var n = input.to_int()
										geom.call_deferred("iterate_n", n, true)
										# Wait for action to complete
										globals.semaphore.wait()
								
								# Change time step
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
## Disables all other input.
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
