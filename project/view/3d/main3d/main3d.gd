extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var body = get_node("../Geometry")
	body.cam_info_calculated.connect(_on_body_cam_info_calculated)
	body.cam_center_calculated.connect(_on_body_cam_center_calculated)

func _on_body_cam_info_calculated(center : Array, radius : float) -> void:
	if radius != 0.: $CameraGimbal.zoom_factor = radius
	var tw = create_tween().set_trans(Tween.TRANS_SINE)
	tw.tween_property($CameraGimbal, "position", Vector3(center[0], center[1], center[2]), 0.3)
	await tw.finished

func _on_body_cam_center_calculated(center : Array) -> void:
	var tw = create_tween().set_trans(Tween.TRANS_SINE)
	tw.tween_property($CameraGimbal, "position", Vector3(center[0], center[1], center[2]), 0.3)
	await tw.finished

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
