extends Node

var mutex : Mutex
var semaphore : Semaphore

var AMBIENT_DIMENSION = 3

# 2D Transforms
var VIS_SCALE_2D = 100
var VIS_TRANSFORM_2D = Transform2D(VIS_SCALE_2D*Vector2.RIGHT,-VIS_SCALE_2D*Vector2.DOWN, Vector2.ZERO)

# Calculating time step
var CALCULATING_STEP = false

func _ready() -> void:
	mutex = Mutex.new()
	semaphore = Semaphore.new()

func printer(s : String) -> void:
	mutex.lock()
	print(s)
	mutex.unlock()

func print_prompt() -> void:
	mutex.lock()
	printraw("> ")
	mutex.unlock()

func print_file_select_prompt() -> void:
	mutex.lock()
	printraw("Select file, or type q to quit: ")
	mutex.unlock()
