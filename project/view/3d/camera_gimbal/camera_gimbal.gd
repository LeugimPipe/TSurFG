extends Node3D

@export var cam_speed = PI/2
@export var zoom_speed = 0.05
var zoom_factor = 1.0 : set = set_zoom_factor

func set_zoom_factor(new_factor : float) -> void:
	zoom_factor = new_factor
	var tw = create_tween().set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "zoom", zoom_factor, 0.3)
	await tw.finished
	zoom_speed = 0.05 * zoom_factor
	zoom_lower = 0.1 * zoom_factor
	zoom_upper = 2.0 * zoom_factor

var zoom = 1.0
var zoom_lower = 0.1
var zoom_upper = 2.0

func _input(event):
	if event.is_action_pressed("cam_zoom_in"):
		var tw = create_tween().set_trans(Tween.TRANS_LINEAR)
		tw.tween_property(self, "zoom", zoom-zoom_speed, 0.1)
		await tw.finished
	if event.is_action_pressed("cam_zoom_out"):
		var tw = create_tween().set_trans(Tween.TRANS_LINEAR)
		tw.tween_property(self, "zoom", zoom+zoom_speed, 0.1)
		await tw.finished
	
	if event.is_action_pressed("cam_reset"):
		var tw = create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
		tw.tween_property($GimbalInner/Camera3D, "rotation", Vector3.ZERO, 0.3)
		tw.tween_property(self, "rotation", Vector3.ZERO, 0.3)
		tw.tween_property($GimbalInner, "rotation", Vector3.ZERO, 0.3)
		await tw.finished

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	zoom = clamp(zoom, zoom_lower, zoom_upper)
	scale = Vector3.ONE * zoom
	
	var roll = Input.get_axis("cam_roll_left", "cam_roll_right")
	$GimbalInner/Camera3D.rotate_z(roll * cam_speed * delta)
	$GimbalInner/Camera3D.rotation.z = clamp($GimbalInner/Camera3D.rotation.z, -PI/2, PI/2)
	
	var y = Input.get_axis("cam_orb_left", "cam_orb_right")
	rotate_y(y * cam_speed * delta)
	
	var x = Input.get_axis("cam_orb_up", "cam_orb_down")
	$GimbalInner.rotate_x(x * cam_speed * delta)
	$GimbalInner.rotation.x = clamp($GimbalInner.rotation.x, -PI/2, PI/2)
