extends ScrollContainer

var bodies : Dictionary

signal add_body_whole

## Inits display.
## Receives list of bodies to display and modify info for.
func init( _bodies : Dictionary ) -> void:
	bodies = _bodies
	$VBoxContainer/Label.show()
	if bodies.size() > 0:
		$VBoxContainer/Label.hide()
		
		for b_id in bodies:
			var b = bodies[b_id]
			var vd = load("res://controller/gui/volumes_display/volume_display.tscn").instantiate()
			vd.init(b)
			$VBoxContainer.add_child(vd)

func _on_bodies_changed( _bodies : Dictionary ) -> void:
	for node in $VBoxContainer.get_children():
		if not (node.name == "Label" or node.name == "AddBodyButton"):
			node.queue_free()
	bodies = _bodies
	init(bodies)


func _on_add_body_button_pressed() -> void:
	add_body_whole.emit()
