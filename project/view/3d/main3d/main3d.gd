extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var body = get_node("../Geometry")
	body.cam_info_calculated.connect(_on_body_cam_info_calculated)
	body.cam_center_calculated.connect(_on_body_cam_center_calculated)

func _on_body_cam_info_calculated(center : VectorN, radius : float) -> void:
	if radius != 0.: $CameraGimbal.zoom_factor = radius
	var tw = create_tween().set_trans(Tween.TRANS_SINE)
	tw.tween_property($CameraGimbal, "position", Vector3(center.get_i(0), center.get_i(1), center.get_i(2)), 0.3)
	await tw.finished

func _on_body_cam_center_calculated(center : VectorN) -> void:
	var tw = create_tween().set_trans(Tween.TRANS_SINE)
	tw.tween_property($CameraGimbal, "position", Vector3(center.get_i(0), center.get_i(1), center.get_i(2)), 0.3)
	await tw.finished
