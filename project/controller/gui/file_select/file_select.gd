extends VBoxContainer

signal cancel
signal file_selected

func _on_file_input_text_changed(_new_text: String) -> void:
	$HBoxContainer/SubmitButton.disabled = false

func _on_submit_button_pressed() -> void:
	file_selected.emit($FileInput.text.strip_edges())

func _on_cancel_button_pressed() -> void:
	cancel.emit()
