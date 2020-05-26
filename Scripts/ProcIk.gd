extends Object
# Class to manage the movement of bones realted to inverse kinematics,
# like legs and arms

var step_distance: float
var step_duration: float
var step_overshoot_fraction: float

var target: Position3D
var home: Position3D
var is_moving: bool = false
var time: float = 0.0
var start_point: Vector3 = Vector3()
var start_rot: Quat = Quat()
var end_point: Vector3 = Vector3()
var end_rot: Quat = Quat()
var center_point: Vector3

var skel: Skeleton
var bone_id: String
var default_bones_transforms: Dictionary = {}
var parent_1_id: String
var parent_2_id: String

var x: int = 0
var y: int = 1
var z: int = 2

func _init(
		my_step_distance: float,
		my_step_duraion: float,
		my_step_overshoot_fraction: float,
		my_skel: Skeleton,
		my_bone_id: String,
		my_target: Position3D,
		my_home: Position3D
		) -> void:
	step_distance = my_step_distance
	step_duration = my_step_duraion
	step_overshoot_fraction = my_step_overshoot_fraction
	skel = my_skel
	bone_id = my_bone_id
	target = my_target
	home = my_home
	center_point = Vector3()
	load_default_transforms()

func load_default_transforms() -> void:
	parent_1_id = skel.get_bone_name(skel.get_bone_parent(skel.find_bone(bone_id)))
	parent_2_id = skel.get_bone_name(skel.get_bone_parent(skel.find_bone(parent_1_id)))
	default_bones_transforms[parent_1_id] = skel.get_bone_global_pose(skel.find_bone(parent_1_id))
	default_bones_transforms[parent_2_id] = skel.get_bone_global_pose(skel.find_bone(parent_2_id))

func move_limb(_delta: float) -> void:
	var distance: float = target.global_transform.origin.distance_to(home.global_transform.origin)
	if (distance > step_distance):
		if (!is_moving):
			is_moving = true
			start_point = target.global_transform.origin
			start_rot = target.global_transform.basis
			end_rot = home.global_transform.basis
			# Directional vector from the foot to the home position
			var toward_home: Vector3 = (home.global_transform.origin - target.global_transform.origin)
			# Total distnace to overshoot by   
			var overshoot_distance: float = step_distance * step_overshoot_fraction
			var overshoot_vector: Vector3 = toward_home * overshoot_distance
			# Since we don't ground the point in this simplified implementation,
			# we restrict the overshoot vector to be level with the ground
			# by projecting it on the world XZ plane.
			overshoot_vector = Plane(Vector3.UP,0).project(overshoot_vector)
			# Apply the overshoot
			end_point = home.global_transform.origin + overshoot_vector
			# We want to pass through the center point
			center_point = (start_point + end_point) / 2
			# But also lift off, so we move it up by half the step distance (arbitrarily)
			center_point += home.global_transform.basis.z.normalized() * start_point.distance_to(end_point) / 2.0
			
	if (is_moving):
		time += _delta
		var normalized_time: float
		normalized_time = time / step_duration
		# Quadratic bezier curve
		target.global_transform.origin = (
			start_point.linear_interpolate(center_point,normalized_time).linear_interpolate(
			center_point.linear_interpolate(end_point,normalized_time),
			normalized_time
			))
		
		target.global_transform.basis = start_rot.slerp(end_rot, normalized_time)
		if (time >= step_duration):
			is_moving = false
			time = 0.0
			target.global_transform.origin = home.global_transform.origin
			target.global_transform.basis = home.global_transform.basis
			fix_root_rotations()

func fix_root_rotations() -> void:
	fix_root_rotation(parent_2_id)
	fix_root_rotation(parent_1_id)

func fix_root_rotation(root_id) -> void:
	# Bones related to the Ik tend to set weird rotations that breaks the mesh,
	# even when setting a proper magnet
	# This is not perfect but will prevent it from happening most of the times
	var pose: Transform = skel.get_bone_global_pose(skel.find_bone(root_id))
	var idx0 = z
	var idx1 = y
	var up_vector: Vector3 = default_bones_transforms[root_id].basis.z.normalized()
	if (up_vector.x>0):
		idx0 = y
		idx1 = z
	var up_2dvector: Vector2 = Vector2(up_vector[idx0],up_vector[idx1]).normalized()
	var current_up_vector: Vector3 = pose.basis.z.normalized()
	var current_2dvector: Vector2 = Vector2(current_up_vector[idx0],current_up_vector[idx1]).normalized()
	var angle_3d: float = current_up_vector.angle_to(up_vector)
	var angle_2d: float = current_2dvector.angle_to(up_2dvector)
	if (angle_2d<0):
		angle_3d = -angle_3d
	if (abs(angle_3d)>deg2rad(45.0)):
		pose.basis = pose.basis.rotated(pose.basis.y.normalized(),angle_3d)
	skel.set_bone_global_pose_override(skel.find_bone(root_id),pose,1.0,true)
