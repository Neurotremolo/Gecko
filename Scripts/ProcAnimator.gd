extends Node
# Class that manges all the procedural animations

# Misc variables
var up_vector: Vector3
var target: Spatial
var max_possible_angle: float = 360
var ProcIk = load("res://Scripts/ProcIk.gd")
var ProcDynamic = load("res://Scripts/ProcDynamic.gd")

# Skeleton variables
var armature: Spatial
var skel: Skeleton
var default_bones_transforms: Dictionary = {}
var rot_compensation: float = -90.0

# Root motion variables
var move_speed: float = 3.0
var turn_speed: float = 2.0
var move_acceleration: float = 1.25
var turn_acceleration: float = 1.25
var min_dist_to_target: float = 2.5
var max_dist_to_target: float = 4.5
var max_ang_to_target: float = 30
var current_velocity: Vector3
var current_angular_velocity: float = 0.0
var max_angle_to_move: float = 90.0

# Head variables
var head_id: String = "neck"
var head_speed: float = 4.5
var head_max_angle: float = 40

# Eyes variables
var left_eye_id: String = "eye_l"
var right_eye_id: String = "eye_r"
var eye_tracking_speed: float = 10.0
var left_eye_max_rotation: float = 70.0
var left_eye_min_rotation: float = -45.0
var right_eye_max_rotation: float = 45.0
var right_eye_min_rotation: float = -70.0

# Legs variables
var step_distance: float = 0.55
var step_duration: float = 0.15
var step_overshoot_fraction: float = 1.25
var right_hand_id: String = "hand_r"
var left_hand_id: String = "hand_l"
var right_foot_id: String = "foot_r"
var left_foot_id: String = "foot_l"
var right_hand
var left_hand
var right_foot
var left_foot

# Idle animation variables
var time: float = 0.0
var root_id: String = "root"
var root_right_arm_id: String = "arm_1_r"
var root_left_arm_id: String = "arm_1_l"
var root_right_leg_id: String = "leg_1_r"
var root_left_leg_id: String = "leg_1_l"

# Dynamic tail variables
var tail
var tail_dynamic_bone: SoftBody
var tail_extensions: Array = []
var tail_extension_1: String = "tail_1"
var tail_extension_2: String = "tail_2"
var tail_extension_3: String = "tail_3"
var tail_extension_4: String = "tail_4"
var tail_vertices: Array = []
var tail_vertices_1: Array = [6,7,8,9]
var tail_vertices_2: Array = [4,5,12,15]
var tail_vertices_3: Array = [1,3,11,14]
var tail_vertices_4: Array = [0,2,10,13]
var tail_vertices_5: Array = [16,17,18,19]

func _ready() -> void:
	target = get_node("Targets/Target")
	armature = get_node("Armature")
	skel = get_node("Armature/Skeleton")
	up_vector = Vector3.UP
	max_ang_to_target = deg2rad(max_ang_to_target)
	max_angle_to_move = deg2rad(max_angle_to_move)
	max_possible_angle = deg2rad(max_possible_angle)
	rot_compensation = deg2rad(rot_compensation)
	head_max_angle = deg2rad(head_max_angle)
	left_eye_max_rotation = deg2rad(left_eye_max_rotation)
	left_eye_min_rotation = deg2rad(left_eye_min_rotation)
	right_eye_max_rotation = deg2rad(right_eye_max_rotation)
	right_eye_min_rotation = deg2rad(right_eye_min_rotation)
	right_hand = ProcIk.new(
		step_distance,
		step_duration,
		step_overshoot_fraction,
		skel,
		right_hand_id,
		get_node("Targets/TargetRightHand"),
		get_node("Armature/Skeleton/HomePoints/HomeRightHand")
		)
	left_hand = ProcIk.new(
		step_distance,
		step_duration,
		step_overshoot_fraction,
		skel,
		left_hand_id,
		get_node("Targets/TargetLeftHand"),
		get_node("Armature/Skeleton/HomePoints/HomeLeftHand")
		)
	right_foot = ProcIk.new(
		step_distance,
		step_duration,
		step_overshoot_fraction,
		skel,
		right_foot_id,
		get_node("Targets/TargetRightFoot"),
		get_node("Armature/Skeleton/HomePoints/HomeRightFoot")
		)
	left_foot = ProcIk.new(
		step_distance,
		step_duration,
		step_overshoot_fraction,
		skel,
		left_foot_id,
		get_node("Targets/TargetLeftFoot"),
		get_node("Armature/Skeleton/HomePoints/HomeLeftFoot")
		)
	tail_dynamic_bone = get_node("Armature/Skeleton/TailAttachment/DynamicBone")
	tail_extensions.append(tail_extension_1)
	tail_extensions.append(tail_extension_2)
	tail_extensions.append(tail_extension_3)
	tail_extensions.append(tail_extension_4)
	tail_vertices.append(tail_vertices_1)
	tail_vertices.append(tail_vertices_2)
	tail_vertices.append(tail_vertices_3)
	tail_vertices.append(tail_vertices_4)
	tail_vertices.append(tail_vertices_5)
	tail = ProcDynamic.new(self,tail_dynamic_bone,tail_extensions,tail_vertices)
	load_default_bones_transforms()

func load_default_bones_transforms() -> void:
	# Save default bones transforms
	var bone_count: int = skel.get_bone_count()
	for n in range(bone_count):
		var current_bone_name: String = skel.get_bone_name(n)
		default_bones_transforms[current_bone_name] = skel.get_bone_global_pose(n)

func _physics_process(_delta: float) -> void:
	blend_idle_animation(_delta)
	move_body(_delta)
	move_head(_delta)
	move_eyes(_delta)
	move_legs(_delta)
	move_tail(_delta)

func blend_idle_animation(_delta: float) -> void:
	# This idle animation just offsets some bones vertically
	# with the sin() function
	# Calculate time passed
	time += _delta
	# Calculate current offset
	var vertical_offset: float = sin(time*2)*0.04
	# Apply
	apply_vertical_offset(root_id,vertical_offset)
	apply_vertical_offset(root_right_arm_id,vertical_offset)
	apply_vertical_offset(root_left_arm_id,vertical_offset)
	apply_vertical_offset(root_right_leg_id,vertical_offset)
	apply_vertical_offset(root_left_leg_id,vertical_offset)
	apply_vertical_offset(tail_extension_1,vertical_offset)
	apply_vertical_offset(tail_extension_2,vertical_offset)
	apply_vertical_offset(tail_extension_3,vertical_offset)
	apply_vertical_offset(tail_extension_4,vertical_offset)

func apply_vertical_offset(bone_id: String, vertical_offset: float) -> void:
	# Get root pose
	var pose: Transform = skel.get_bone_global_pose(skel.find_bone(bone_id))
	# Set root pose
	pose.origin.y = default_bones_transforms[bone_id].origin.y + vertical_offset
	# Apply
	skel.set_bone_global_pose_override(skel.find_bone(bone_id),pose,1.0,true)

func move_body(_delta: float) -> void:
	# Rotation of the body
	var toward_target: Vector3 = target.global_transform.origin - armature.global_transform.origin
	var toward_target_projected: Vector3 = Plane(Vector3.UP,0).project(toward_target)
	var angle_to_target: float = (armature.global_transform.basis.z).angle_to(toward_target_projected)
	# Calculate 2d angle to get signed angle
	var angle_2d: float = (
		Vector2(
		armature.global_transform.basis.z.x,
		armature.global_transform.basis.z.z).angle_to(
		Vector2(
		toward_target_projected.x,
		toward_target_projected.z)
		))
	var target_angular_velocity: float = 0.0
	if (abs(angle_to_target) > max_ang_to_target):
		if (angle_2d < 0):
			target_angular_velocity = turn_speed
		else:
			target_angular_velocity = -turn_speed
	current_angular_velocity = lerp(
			current_angular_velocity,
			target_angular_velocity,
			1-exp(-turn_acceleration*_delta)
			)
	var tmp_rot: Vector3 = armature.global_transform.basis.get_euler()
	tmp_rot.y += current_angular_velocity * _delta
	armature.global_transform.basis = Quat(tmp_rot)
	# Movement of the body
	var target_velocity: Vector3 = Vector3.ZERO
	if (abs(angle_to_target) < max_angle_to_move):
		var dist_to_target: float = armature.global_transform.origin.distance_to(target.global_transform.origin)
		if (dist_to_target > max_dist_to_target):
			target_velocity = move_speed * toward_target_projected.normalized()
		elif (dist_to_target < min_dist_to_target):
			target_velocity = move_speed * -toward_target_projected.normalized()
	current_velocity = lerp(
			current_velocity,
			target_velocity,
			1-exp(-move_acceleration*_delta)
			)
	armature.global_transform.origin += current_velocity * _delta

func move_head(_delta: float) -> void:
	var pose: Transform = skel.get_bone_global_pose(skel.find_bone(head_id))
	var initial_rotation: Quat = pose.basis.get_rotation_quat()
	var target_pos: Vector3 = armature.global_transform.xform_inv(target.global_transform.origin)
	pose = pose.looking_at(target_pos,up_vector)
	# Compensate
	pose.basis = pose.basis.rotated(pose.basis.x,rot_compensation)
	# Limit target position to max angle
	var final_rot: Quat = limit_rotation_by_angle(
		get_min_bone_rotation(head_id),
		pose.basis.get_rotation_quat(),
		head_max_angle
		)
	pose.basis = Basis(final_rot)
	# Smooth rotation
	var target_rotation: Quat = pose.basis.get_rotation_quat()
	var final_rotation: Quat = initial_rotation.slerp(target_rotation,1-exp(-head_speed*_delta))
	pose.basis = Basis(final_rotation)
	# Fix origin
	pose.origin = get_fixed_origin(head_id)
	# Apply
	skel.set_bone_global_pose_override(skel.find_bone(head_id),pose,1.0,true)

func move_eyes(_delta: float) -> void:
	move_eye(right_eye_id,eye_tracking_speed,right_eye_min_rotation,right_eye_max_rotation,_delta)
	move_eye(left_eye_id,eye_tracking_speed,left_eye_min_rotation,left_eye_max_rotation,_delta)

func move_eye(bone_id: String, speed: float, min_angle: float, max_angle: float, _delta: float) -> void:
	var eye_idx: int = skel.find_bone(bone_id)
	var pose: Transform = skel.get_bone_global_pose(eye_idx)
	var initial_rotation: Quat = pose.basis.get_rotation_quat()
	var target_pos: Vector3 = skel.global_transform.xform_inv(target.global_transform.origin)
	pose = pose.looking_at(target_pos,up_vector)
	pose.basis = pose.basis.rotated(pose.basis.x,rot_compensation)
	var target_rotation: Quat = pose.basis.get_rotation_quat()
	var final_rotation: Quat = initial_rotation.slerp(target_rotation,1-exp(-speed*_delta))
	pose.basis = Basis(final_rotation)
	# Contrain angle
	var min_constrain: Vector3 = Vector3(-max_possible_angle,min_angle,-max_possible_angle)
	var max_contrain: Vector3 = Vector3(max_possible_angle,max_angle,max_possible_angle)
	var corrected_rotation: Quat = constrain_rotation(
		bone_id,
		pose.basis.get_rotation_quat(),
		min_constrain,
		max_contrain
		)
	pose.basis = Basis(corrected_rotation)
	# Fix origin
	pose.origin = get_fixed_origin(bone_id)
	# Apply
	skel.set_bone_global_pose_override(eye_idx,pose,1.0,true)

func move_legs(_delta: float) -> void:
	# Move Ik targets
	if (!left_hand.is_moving && !right_foot.is_moving):
		right_hand.move_limb(_delta)
		left_foot.move_limb(_delta)
	if (!right_hand.is_moving && !left_foot.is_moving):
		left_hand.move_limb(_delta)
		right_foot.move_limb(_delta)

func move_tail(_delta: float) -> void:
	# Move dynamic bone
	tail.move_extension(_delta)

func add_rotation(from: Quat, addition: Quat) -> Quat:
	var result: Quat
	result = from * addition
	return result

func subtract_rotation(from: Quat, subtraction: Quat) -> Quat:
	var result: Quat
	result = from * subtraction.inverse()
	return result

func get_direction(rotation: Quat) -> Vector3:
	# Get direction vector normalized from a transform
	var temp = rotation
	temp = temp * Vector3.UP
	temp = temp.normalized()
	var result: Vector3 = temp
	return result

func get_min_bone_rotation(bone_id: String) -> Quat:
	# Get the current possible rotation of the bone if it would have
	# its default rotation within the current skeleton transform
	var result: Quat
	var parent_bone_idx: int = skel.get_bone_parent(skel.find_bone(bone_id))
	var parent_bone_id: String = skel.get_bone_name(parent_bone_idx)
	var default_local_rot: Quat = subtract_rotation(
		default_bones_transforms[bone_id].basis.get_rotation_quat(),
		default_bones_transforms[parent_bone_id].basis.get_rotation_quat()
		)
	result = add_rotation(
		skel.get_bone_global_pose(parent_bone_idx).basis.get_rotation_quat(),
		default_local_rot
		)
	return result

func limit_rotation_by_angle(min_rotation: Quat, proposed_rotation: Quat, max_angle: float) -> Quat:
	# Limit a rotation by a given angle
	var result: Quat
	var min_direction: Vector3 = get_direction(min_rotation)
	var proposed_direction: Vector3 = get_direction(proposed_rotation)
	var va_n = min_direction.normalized()
	var vb_n = proposed_direction.normalized()
	var cross = va_n.cross(vb_n).normalized()
	var dot = va_n.dot(vb_n)
	var angle = clamp(acos(dot), -max_angle, max_angle)
	result = Basis(min_rotation).rotated(cross, angle).get_rotation_quat()
	return result

func get_fixed_origin(bone_id: String) -> Vector3:
	# Fix origin according to parent bone
	var result: Vector3
	var bone_idx: int = skel.find_bone(bone_id)
	var parent_bone_idx: int = skel.get_bone_parent(bone_idx)
	var parent_origin: Vector3 = skel.get_bone_global_pose(parent_bone_idx).origin
	var parent_direction: Vector3 = get_direction(skel.get_bone_global_pose(parent_bone_idx).basis.get_rotation_quat())
	var parent_magnitude: float = (
			default_bones_transforms[bone_id].origin -
			default_bones_transforms[skel.get_bone_name(parent_bone_idx)].origin
		).length()
	result = parent_origin + (
			parent_magnitude * parent_direction
		)
	return result

func constrain_rotation(bone_id: String, rot: Quat, min_constrain: Vector3, max_constrain: Vector3) -> Quat:
	# Constrain rotation
	var parent_rot: Quat = skel.get_bone_global_pose(
		skel.get_bone_parent(skel.find_bone(bone_id))
		).basis.get_rotation_quat()
	var local_rot: Quat = subtract_rotation(
		rot,
		parent_rot
		)
	var local_euler: Vector3 = local_rot.get_euler()
	for i in range(0,3):
		local_euler[i] = clamp(local_euler[i],min_constrain[i],max_constrain[i])
	local_rot = Quat(local_euler)
	var global_rot: Quat = add_rotation(
		local_rot,
		parent_rot
		)
	return global_rot
