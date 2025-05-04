extends RigidBody3D
class_name CarryableObject3D

@export var weight: float = 2.5
@export var money_value: int = 100
@export var torque_strength: float = 5.0  # Adjust rotation force
@export var damping: float = 0.8         # Rotation damping
@export var max_angular_velocity: float = 2.0  # Prevent overspinin

var _target_up: Vector3 = Vector3.UP
var is_carried: bool = false
var player: Node3D = null
var original_parent: Node  # Add this to track original parent

func _ready():
	add_to_group("items")

func _apply_gyro_stabilization(delta: float) -> void:
	# Get current orientation vectors
	var current_up = global_transform.basis.y.normalized()
	
	# Calculate rotation needed to align with target up
	var rotation_axis = current_up.cross(_target_up).normalized()
	var rotation_angle = current_up.angle_to(_target_up)
	
	# Only apply torque if significantly misaligned
	if rotation_angle > 0.01:
		# Calculate corrective torque
		var torque = rotation_axis * rotation_angle * torque_strength
		
		# Apply torque with damping
		apply_torque_impulse(torque - angular_velocity * damping)
	
	# Limit angular velocity
	if angular_velocity.length() > max_angular_velocity:
		angular_velocity = angular_velocity.normalized() * max_angular_velocity

func pick_up(player_node: Node3D) -> void:
	if not is_carried:
		original_parent = get_parent()  # Store original parent
		player = player_node
		is_carried = true
		freeze = true
		collision_layer = 0
		collision_mask = 0
		
		var carry_pos = player_node.carry_position
		# Store global transform before reparenting
		var prev_global_transform = global_transform
		
		# Reparent to carry position
		original_parent.remove_child(self)
		carry_pos.add_child(self)
		
		# Restore global position after reparenting
		global_transform = prev_global_transform

func drop() -> void:
	if is_carried:
		is_carried = false
		freeze = false
		collision_layer = 1
		collision_mask = 1
		
		# Store global transform before reparenting
		var drop_global_transform = global_transform
		
		# Rep# Reparent to original parent
		var parent = get_parent()
		parent.remove_child(self)
		original_parent.add_child(self)
		
		# Restore global position and physics properties
		global_transform = drop_global_transform
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO
		
		# Transfer player velocity if moving
		if player and player is CharacterBody3D:
			linear_velocity = player.velocity
		
		player = null
		
func _physics_process(delta: float) -> void:
	# Add gyro effect (wiP) remove if not needed
	if not is_carried:
		_apply_gyro_stabilization(delta)
