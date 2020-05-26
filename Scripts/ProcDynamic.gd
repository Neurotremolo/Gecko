extends Object
# Class to manage the movement of bones related to soft body physics,
# like tails, using a soft body mesh and imitating its behaviour
# with the corresponding bones
# We set the rotation of the bones to be the same as the group
# of vertices that forms the soft body mesh, where each 'extension'
# is each group of vertices

var proc_animator
var skel: Skeleton
var dynamic_bone: SoftBody
var extensions: Array
var ordered_vertices: Array
var armature: Spatial

var mesh: Mesh
var mdt: MeshDataTool
var vertices: Array = []
var default_extensions_transforms: Dictionary = {}
var parent_rotation: Quat
var lift_up: float = 12.0

func _init(my_proc_animator, my_dynamic_bone: SoftBody, my_extensions: Array, my_ordered_vertices: Array) -> void:
	proc_animator = my_proc_animator
	skel = proc_animator.skel
	dynamic_bone = my_dynamic_bone
	extensions = my_extensions
	ordered_vertices = my_ordered_vertices
	mesh = dynamic_bone.mesh
	armature = skel.get_parent()
	lift_up = deg2rad(lift_up)
	update_vertices()
	load_default_extensions_transforms()

func load_default_extensions_transforms() -> void:
	for idx in range(extensions.size()):
		var extension_transform: Transform = get_extension_transform(idx)
		default_extensions_transforms[extensions[idx]] = extension_transform

func update_vertices() -> void:
	mdt = MeshDataTool.new()
	vertices.clear()
	if (mdt.create_from_surface(mesh,0) == OK):
		for i in range(mdt.get_vertex_count()):
			var global_pos: Vector3 = (
				armature.global_transform.xform_inv(mdt.get_vertex(i))
				)
			vertices.append(global_pos)

func get_extension_transform(idx: int) -> Transform:
	var extension_transform: Transform
	var root_vertices_idx: Array = ordered_vertices[idx]
	var tip_vertices_idx: Array = ordered_vertices[idx+1]
	var root_vertices_positions: Array = []
	for root_vertex_idx in root_vertices_idx:
		root_vertices_positions.append(vertices[root_vertex_idx])
	var tip_vertices_positions: Array = []
	for tip_vertex_idx in tip_vertices_idx:
		tip_vertices_positions.append(vertices[tip_vertex_idx])
	var root_position: Vector3 = get_centroid(root_vertices_positions)
	var tip_position: Vector3 = get_centroid(tip_vertices_positions)
	var direction: Vector3 = tip_position - root_position
	var rotation: Quat = Quat(direction)
	extension_transform = Transform(Basis(rotation),root_position)
	return extension_transform

func move_extension(_delta: float) -> void:
	update_vertices()
	parent_rotation = Quat(Vector3())
	for idx in range(extensions.size()):
		rotate_individual_extension(idx)

func rotate_individual_extension(idx: int) -> void:
	var extension_transform: Transform = get_extension_transform(idx)
	# Calculate local extension rotation
	var local_extension: Quat = proc_animator.subtract_rotation(
		extension_transform.basis.get_rotation_quat(),
		default_extensions_transforms[extensions[idx]].basis.get_rotation_quat()
		)
	# Add parent rotation
	local_extension = proc_animator.add_rotation(
		local_extension,
		parent_rotation
		)
	# Update parent rotation
	parent_rotation = local_extension
	# Fix angles
	var local_euler: Vector3 = local_extension.get_euler()
	var tmp_euler: Vector3 = local_euler
	local_euler.z = tmp_euler.x
	local_euler.x = tmp_euler.y
	local_euler.y = tmp_euler.z
	local_euler.z = -local_euler.z
	local_euler.x += lift_up
	local_extension = Quat(local_euler)
	# Calculate final bone rotation
	var bone_rotation: Quat = proc_animator.add_rotation(
		proc_animator.default_bones_transforms[extensions[idx]].basis.get_rotation_quat(),
		local_extension
		)
	var pose: Transform = skel.get_bone_global_pose(skel.find_bone(extensions[idx]))
	pose.basis = Basis(bone_rotation)
	skel.set_bone_global_pose_override(skel.find_bone(extensions[idx]),pose,1.0,true)
	# Fix origin
	var pose_fixed: Transform = skel.get_bone_global_pose(skel.find_bone(extensions[idx]))
	pose_fixed.origin = proc_animator.get_fixed_origin(extensions[idx])
	skel.set_bone_global_pose_override(skel.find_bone(extensions[idx]),pose_fixed,1.0,true)

func get_centroid(positions: Array) -> Vector3:
	var result: Vector3 = Vector3()
	var amount: int = positions.size()
	for position in positions:
		result += position
	result = result/amount
	return result
