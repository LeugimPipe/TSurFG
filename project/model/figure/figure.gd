extends Node
class_name Figure

## Client for the geometry in the framework of the Strategy pattern.
## Stores the geometry and selects the energy strategies.

@export var geom_scene : PackedScene
var geom : Geometry

## Read file strategy.
var file_read_strat : FileReadInterface

## Write file strategy.
var file_write_strat : FileWriteInterface

func _ready() -> void:
	geom = geom_scene.instantiate()
	add_child(geom)

# INIT
func init() -> void:
	# Set up energies in geometry according to characteristics
	# Only one energy for now
	geom.add_energy( Area.new(geom) )
	
	geom.init()

# UNLOAD

func unload() -> void:
	geom.unload()

# FILE LOAD

func set_file_read(_file_read : FileReadInterface) -> void:
	file_read_strat = _file_read

func load_file(file_content: String) -> bool:
	unload()
	if not file_read_strat.load_file(file_content, geom):
		return false
	
	# TODO: check face orientation compatibility
	
	init()
	return true

# FILE WRITE

func set_file_write(_file_write : FileWriteInterface) -> void:
	file_write_strat = _file_write

func write_to_file(file : String) -> void:
	file_write_strat.write_to_file(file, geom)
