extends HBoxContainer

var body

func init(_body) -> void:
	body = _body
	body.volume_changed.connect(self._on_body_volume_changed)
	$BodyLabel.text = "Body " + str(body.get_id())
	$CurVolumeLabel.text = "Current volume: " + str(body.volume)
	
	if not body.volume_constrained:
		volume_not_constrained_setup()
	else:
		volume_constrained_setup()

func volume_not_constrained_setup() -> void:
	$TargetVolumeLabel.hide()
	$ToggleTargetVolumeButton.text = "Add target volume"
	$ChangeTargetVolumeButton.hide()

func volume_constrained_setup() -> void:
	$TargetVolumeLabel.show()
	$TargetVolumeLabel.text = "Target volume: " + str(body.volume_constraint)
	$ToggleTargetVolumeButton.text = "Remove target volume"
	$ChangeTargetVolumeButton.show()

func _on_body_volume_changed() -> void:
	$CurVolumeLabel.text = "Current volume: " + str(body.volume)

func _on_change_target_volume_button_pressed() -> void:
	change_target_volume()

func _on_toggle_target_volume_button_pressed() -> void:
	if not body.volume_constrained:
		# Add volume constraint
		if change_target_volume():
			body.volume_constrained = true
			volume_constrained_setup()
	else:
		# Eliminate volume constraint
		body.volume_constrained = false
		volume_not_constrained_setup()

## Changes target volume.
## Returns true if successful, false otherwise
func change_target_volume() -> bool:
	var new_target = $TargetVolumeInput.text.strip_edges()
	if not new_target.is_valid_float():
		push_error("Invalid target volume %s" % new_target )
		globals.print_prompt()
		return false
	else:
		body.volume_constraint = new_target
		$TargetVolumeLabel.text = "Target volume: " + str(body.volume_constraint)
		return true

func _on_remove_body_button_pressed() -> void:
	body.remove()
