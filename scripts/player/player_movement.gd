extends CharacterBody3D

# Movement variables
@export var SPEED = 5.0
@export var JUMP_VELOCITY = 5.0
@export var SENSITIVITY = 0.003 # Mouse sensitivity

# Get gravity from project settings
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var carried_object: CarryableObject3D = null
var carryable_object_max_weight_jump: float = 5.0
var nearby_objects: Array = []

@onready var pickup_area: Area3D = $PickupArea
@onready var carry_position: Marker3D = $CarryPosition

# Node references (assigned in _ready)
@onready var head = $Head
@onready var camera = $Head/Camera3D # Path relative to CharacterBody3D

func _ready():
	# Hide and capture the mouse cursor when the game starts
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	pickup_area.body_entered.connect(_on_pickup_area_body_entered)
	pickup_area.body_exited.connect(_on_pickup_area_body_exited)

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
			
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if carried_object:
			carried_object.drop()
			carried_object = null
		else:
			# Find the closest object in range
			var closest_obj: CarryableObject3D = null
			var closest_dist = INF
			for obj in nearby_objects:
				if obj.is_carried:
					continue
				var dist = global_transform.origin.distance_to(obj.global_transform.origin)
				if dist < closest_dist:
					closest_dist = dist
					closest_obj = obj
			
			if closest_obj:
				carried_object = closest_obj
				closest_obj.pick_up(self)
				nearby_objects.erase(closest_obj)


func _physics_process(delta):
	# Apply gravity if not on the floor
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump (using the default "ui_accept" action, usually Spacebar)
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		if carried_object:
			if carried_object.weight < carryable_object_max_weight_jump:
				velocity.y = JUMP_VELOCITY
		else:
			velocity.y = JUMP_VELOCITY
		
	if carried_object:
		# Smoothly follow carry position while respecting physics
		var target_transform = carry_position.global_transform
		carried_object.global_transform = target_transform
		carried_object.linear_velocity = Vector3.ZERO
		carried_object.angular_velocity = Vector3.ZERO

	# Get input direction (WASD)
	# Note: Assumes default input map actions:
	# "move_forward", "move_backward", "move_left", "move_right"
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")

	# Calculate movement direction based on player's facing direction (transform.basis)
	# Z is forward/backward, X is left/right
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var speed_multiplier = 1.0
	if carried_object:
		speed_multiplier = clamp(1.0 - (carried_object.weight * 0.1), 0.5, 1.0)
	
	# Apply movement
	if direction:
		velocity.x = direction.x * SPEED * speed_multiplier
		velocity.z = direction.z * SPEED * speed_multiplier
	else:
		# Apply friction / stop moving if no input
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	# Apply the calculated velocity
	move_and_slide()
	
func _on_pickup_area_body_entered(body: Node3D) -> void:
	if body is CarryableObject3D and not body.is_carried:
		if not nearby_objects.has(body):
			nearby_objects.append(body)

func _on_pickup_area_body_exited(body: Node3D) -> void:
	if body is CarryableObject3D and nearby_objects.has(body):
		nearby_objects.erase(body)
