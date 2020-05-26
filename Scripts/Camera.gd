extends Camera

var pivot: Spatial
var movement: float = 0.0

func _ready() -> void:
	pivot = get_parent()

func _physics_process(_delta: float) -> void:
	# Orbit camera
	movement = 0.0
	if (Input.is_key_pressed(KEY_A)):
		movement -= 1.0
	if (Input.is_key_pressed(KEY_D)):
		movement += 1.0
	pivot.rotate_y(deg2rad(movement))
