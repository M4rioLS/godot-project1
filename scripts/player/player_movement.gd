extends CharacterBody3D

# Movement variables
@export var SPEED = 5.0
@export var JUMP_VELOCITY = 5.0
@export var SENSITIVITY = 0.003 # Mouse sensitivity

# Get gravity from project settings
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Node references (assigned in _ready)
@onready var head = $Head
@onready var camera = $Head/Camera3D # Path relative to CharacterBody3D

func _ready():
	# Hide and capture the mouse cursor when the game starts
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	# Handle mouse look
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Rotate the CharacterBody3D left/right (Y-axis)
		rotate_y(-event.relative.x * SENSITIVITY)
		# Rotate the Head node up/down (X-axis)
		head.rotate_x(-event.relative.y * SENSITIVITY)

		# Clamp vertical rotation to prevent looking too far up or down
		# Use degrees for easier understanding with clampf
		var head_rotation_deg = rad_to_deg(head.rotation.x)
		head.rotation.x = deg_to_rad(clampf(head_rotation_deg, -85.0, 85.0))

	# Allow releasing the mouse cursor with Escape
	if event.is_action_pressed("ui_cancel"): # 'ui_cancel' is usually Escape
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta):
	# Apply gravity if not on the floor
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump (using the default "ui_accept" action, usually Spacebar)
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get input direction (WASD)
	# Note: Assumes default input map actions:
	# "move_forward", "move_backward", "move_left", "move_right"
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")

	# Calculate movement direction based on player's facing direction (transform.basis)
	# Z is forward/backward, X is left/right
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Apply movement
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		# Apply friction / stop moving if no input
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	# Apply the calculated velocity
	move_and_slide()
