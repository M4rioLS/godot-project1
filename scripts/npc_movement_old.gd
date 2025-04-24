# RigidBody3D Script for a random walking NPC enemy

extends RigidBody3D

# --- Exported Variables ---

@export var speed: float = 3.0
@export var walk_duration_min: float = 2.0
@export var walk_duration_max: float = 5.0
@export var pause_duration_min: float = 1.0
@export var pause_duration_max: float = 3.0
@export var model_path: NodePath # Path to the visual model node (e.g., "MeshInstance3D")

# --- States ---

enum State { WALKING, PAUSING }

# --- Onready Variables ---

@onready var model_node: Node3D = get_node(model_path) if model_path else null

# --- Internal Variables ---

var current_state: State = State.PAUSING # Start paused to pick initial direction
var current_direction: Vector3 = Vector3.ZERO
var timer: float = 0.0

# --- Godot Lifecycle Methods ---

func _ready():
	# Ensure randomness is initialized for this script
	randomize()

	if model_node == null:
		printerr("Error: model_path is not set or node not found!")
		# Optionally disable script or handle error appropriately
		set_process(false) # Stop physics processing if model is missing
		return

	# Start by setting up the initial pause duration
	_set_new_timer(State.PAUSING)
	current_state = State.PAUSING # Explicitly set state


func _physics_process(delta):
	# RigidBody3D movement should be handled in _physics_process
	if model_node == null:
		return # Don't process if model node wasn't found

	timer -= delta

	match current_state:
		State.WALKING:
			# Apply velocity in the current direction
			# Note: RigidBody3D movement is best controlled by physics,
			# setting linear_velocity directly works but can sometimes
			# feel less "physical" than applying forces. For simple movement,
			# setting velocity is often sufficient.
			linear_velocity = current_direction * speed

			# Rotate the model node to face the direction of movement
			if current_direction.length_squared() > 0.0001: # Avoid rotating if direction is zero
				# Create a target point slightly ahead in the direction of movement
				var target_point = global_transform.origin + current_direction * 0.1
				# Rotate the model node using look_at
				# look_at points the node's local -Z axis towards the target by default
				# If your model faces a different direction (e.g., +Z), you might need
				# to adjust the model's rotation in the editor or add an offset rotation here.
				model_node.look_at(target_point, Vector3.UP)


			# Check if walk time is finished
			if timer <= 0:
				_change_state(State.PAUSING)

		State.PAUSING:
			# Stop movement
			linear_velocity = Vector3.ZERO

			# Check if pause time is finished
			if timer <= 0:
				_change_state(State.WALKING)

# --- State Change Method ---

func _change_state(new_state: State):
	current_state = new_state
	match current_state:
		State.WALKING:
			_set_new_direction()
			_set_new_timer(State.WALKING)
		State.PAUSING:
			_set_new_timer(State.PAUSING)

# --- Helper Methods ---

func _set_new_direction():
	# Generate a random point on the XZ plane within a unit circle range
	# This is generally more uniformly distributed than picking angles
	var x = randf_range(-1.0, 1.0)
	var z = randf_range(-1.0, 1.0)
	current_direction = Vector3(x, 0, z).normalized()

	# If the random point was exactly (0,0), normalization results in zero vector.
	# Although rare, handle it by trying again.
	if current_direction.length_squared() < 0.0001:
		_set_new_direction() # Recursive call to try again


func _set_new_timer(for_state: State):
	match for_state:
		State.WALKING:
			timer = randf_range(walk_duration_min, walk_duration_max)
		State.PAUSING:
			timer = randf_range(pause_duration_min, pause_duration_max)
