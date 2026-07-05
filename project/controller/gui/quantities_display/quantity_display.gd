extends HBoxContainer

var quantity : QuantityInterface

func init(_q : QuantityInterface) -> void:
	quantity = _q
	quantity.geom.chars_calced.connect( _on_geom_chars_calced )
	$QuantityLabel.text = "Quantity " + str(quantity.get_id())
	$DescriptionLabel.text = quantity.description
	$CurValLabel.text = "Current value: " + str(quantity.calc_energy())
	
	if not quantity.constrained:
		quantity_not_constrained_setup()
	else:
		quantity_constrained_setup()

func quantity_not_constrained_setup() -> void:
	$TargetLabel.hide()
	$ToggleTargetButton.text = "Add target"
	$ChangeTargetButton.hide()

func quantity_constrained_setup() -> void:
	$TargetLabel.show()
	$TargetLabel.text = "Target: " + str(quantity.target)
	$ToggleTargetButton.text = "Remove target"
	$ChangeTargetButton.show()

func _on_geom_chars_calced() -> void:
	$CurValLabel.text = "Current value: " + str(quantity.calc_energy())

func _on_change_target_button_pressed() -> void:
	change_target()

func _on_toggle_target_button_pressed() -> void:
	if not quantity.constrained:
		# Add volume constraint
		if change_target():
			quantity.constrained = true
			quantity_constrained_setup()
	else:
		# Eliminate volume constraint
		quantity.constrained = false
		quantity_not_constrained_setup()

## Changes target volume.
## Returns true if successful, false otherwise.
func change_target() -> bool:
	var new_target = $TargetInput.text.strip_edges()
	if not new_target.is_valid_float():
		push_error("Invalid target %s" % new_target )
		globals.print_prompt()
		return false
	else:
		quantity.target = new_target
		$TargetLabel.text = "Target: " + str(quantity.target)
		return true

func _on_remove_button_pressed() -> void:
	quantity.remove()
