extends ScrollContainer

var quantities : Dictionary[int, QuantityInterface]

signal add_body_whole

## Inits display.
## Receives list of bodies to display and modify info for.
func init( _q : Dictionary ) -> void:
	quantities = _q
	$VBoxContainer/Label.show()
	if quantities.size() > 0:
		$VBoxContainer/Label.hide()
		
		for q_id in quantities:
			var q = quantities[q_id]
			var qd = load("res://controller/gui/quantities_display/quantity_display.tscn").instantiate()
			qd.init(q)
			$VBoxContainer.add_child(qd)

func _on_quantities_changed( _q : Dictionary ) -> void:
	for node in $VBoxContainer.get_children():
		if not (node.name == "Label" or node.name == "AddBodyButton"):
			node.queue_free()
	quantities = _q
	init(quantities)

func _on_add_quantity_button_pressed() -> void:
	add_body_whole.emit()
