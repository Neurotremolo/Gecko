extends Spatial

var ray_length = 1000
var camera: Camera
var offset_y: float = 0.0

func _ready() -> void:
	camera = get_node("../../../CameraPivot/Camera")
	offset_y = self.global_transform.origin.y

func _physics_process(_delta: float):
	cursor_point(_delta)

func cursor_point(_delta: float) -> void:
	# Move target with cursor
	if (Input.is_mouse_button_pressed(BUTTON_LEFT)):
		var ray_length = 10000
		var mouse_pos = get_viewport().get_mouse_position()
		var from = camera.project_ray_origin(mouse_pos)
		var to = from + camera.project_ray_normal(mouse_pos) * ray_length
		var space_state = get_world().get_direct_space_state()
		var result = space_state.intersect_ray(from, to, [], 0x7FFFFFFF, false, true)
		if (len(result) > 0 && result["collider"].name=="CursorArea"):
			var cursor_pos = result["position"]
			self.global_transform.origin = cursor_pos + Vector3(0.0,offset_y,0.0)
