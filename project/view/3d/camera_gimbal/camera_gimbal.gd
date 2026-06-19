extends Node3D

@export var orb_cam_speed = PI/2
@export var tras_cam_speed = 1.5
@export var zoom_speed = 0.05
var zoom = 1.0

var zoom_lower = 0.1
var zoom_upper = 2.0
var zoom_factor = 1.0 : set = set_zoom_factor

func set_zoom_factor(new_factor : float) -> void:
	zoom_factor = new_factor
	var tw = create_tween().set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "zoom", zoom_factor, 0.3)
	await tw.finished
	zoom_speed = 0.1 * zoom_factor
	zoom_lower = 0.1 * zoom_factor
	zoom_upper = 2.0 * zoom_factor

# Sceen movement
# Will be written by the keyboard
# And the mouse in certain cases
var long_mov = 0.0 # Longitude (horizontal)
var lat_mov = 0.0 # Latitude (vertical)

# Camera mode
enum {ORB, TRANS}
var mode = ORB

func _input(event):
	if event.is_action_pressed("cam_zoom_in"):
		zoom -= zoom_speed
	if event.is_action_pressed("cam_zoom_out"):
		zoom += zoom_speed
	
	if event.is_action_pressed("cam_reset"):
		var tw = create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
		tw.tween_property(self, "rotation", Vector3.ZERO, 0.3)
		tw.tween_property($GimbalInner, "rotation", Vector3.ZERO, 0.3)
		await tw.finished
	
	if event.is_action_pressed("cam_mode"):
		if mode == ORB: mode = TRANS
		elif mode == TRANS: mode = ORB
	
	if mode == ORB and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		if event is InputEventMouseMotion:
			long_mov = -event.relative.x * 0.25
			if abs(long_mov) <= 1.0: long_mov = 0.0
			lat_mov = -event.relative.y * 0.5
			if abs(lat_mov) <= 1.0: lat_mov = 0.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	zoom = clamp(zoom, zoom_lower, zoom_upper)
	scale = lerp( scale, Vector3.ONE * zoom, 0.1)
	
	# Get movements from keyboard
	if mode != ORB or !Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		long_mov = Input.get_axis("cam_west", "cam_east")
		lat_mov = Input.get_axis("cam_north", "cam_south")
	
	# Orbital mode
	if mode == ORB:
		rotate_y(long_mov * orb_cam_speed * delta)
		$GimbalInner.rotate_x(lat_mov * orb_cam_speed * delta)
		$GimbalInner.rotation.x = clamp($GimbalInner.rotation.x, -PI/2, PI/2)
	
	# Translation mode
	if mode == TRANS:
		translate_object_local(long_mov * tras_cam_speed * delta * $GimbalInner/Camera3D.transform.basis.x)
		translate_object_local(lat_mov * tras_cam_speed * delta * $GimbalInner.transform.basis.z)
		var vert_mov = Input.get_axis("cam_down", "cam_up")
		translate_object_local(vert_mov * tras_cam_speed * delta * ($GimbalInner.transform * $GimbalInner/Camera3D.transform.basis.y))
		
