extends CharacterBody3D

# --- Movement & Physics ---
@export var speed: float = 1.5
@export var rotation_speed: float = 5.0  # Higher = faster rotation
@export var gravity: float = 9.8         # Earth gravity = 9.8 m/s², adjust as needed
@export var max_fall_speed: float = 20.0 # Terminal velocity

# --- Detection & Vision ---
@export var detection_radius: float = 20.0 # Range for Area3D initial detection
@export var vision_angle: float = 90.0    # Total angle of the vision cone in degrees
@export var vision_range: float = 12.0     # Max distance for vision cone check (can be same or less than detection_radius)
@export var player_group: String = "player" # Group the player node belongs to (Used by Area3D signals implicitly)

# --- Patrolling ---
@export var move_duration: float = 2.0 # How long to move in one direction when patrolling
@onready var patrol_timer: Timer = $Timer # Renamed for clarity

# --- State & Internal ---
var original_speed: float
var players_in_range: Array[Node3D] = [] # Store players detected by Area3D
var is_movement_stopped: bool = false
var current_rotation: float = 0.0
var target_rotation: float = 0.0
var chasing_timer_max: float = 3.0 # Seconds to chase after losing sight/angle (adjust as needed)
var chasing_timer: float = 0.0     # Current chase countdown timer
var current_direction: Vector3 = Vector3.ZERO
var is_chasing: bool = false
var sees_player: bool = false
var player: Node3D = null         # The specific player being chased
var movement_timer: float = 0.0   # Timer for patrol movement duration

# --- Vision Cone Calculation ---
var vision_angle_rad: float = 0.0 # Vision angle converted to radians
var vision_dot_product_threshold: float = 0.0 # Pre-calculated dot product threshold

# --- Node References ---
@onready var model: Node3D = $Model
@onready var detection_area: Area3D = $DetectionArea
#@onready var ground_check: RayCast3D = $GroundCheck # Assumed for ground checks if needed, not used in provided funcs
@onready var line_of_sight_raycast: RayCast3D = $RayCast3D # Renamed for clarity

#-----------------------------------------------------------------------------
# Initialization
#-----------------------------------------------------------------------------
func _ready() -> void:
	original_speed = speed

	# Setup Patrol Timer
	patrol_timer.wait_time = 5 # Use a separate variable if needed
	patrol_timer.timeout.connect(_on_patrol_timer_timeout)
	patrol_timer.start()

	# Initial patrol direction
	pick_random_direction()

	# Setup Area3D for initial detection
	setup_detection_area()

	# Connect Area3D signals (make sure these are connected in the editor too!)
	#detection_area.body_entered.connect(_on_detection_area_body_entered)
	#detection_area.body_exited.connect(_on_detection_area_body_exited)

	# Calculate vision cone values
	vision_angle_rad = deg_to_rad(vision_angle)
	vision_dot_product_threshold = cos(vision_angle_rad / 2.0)

	# Ensure RayCast doesn't hit self
	line_of_sight_raycast.add_exception(self)

#-----------------------------------------------------------------------------
# Setup Functions
#-----------------------------------------------------------------------------
func setup_detection_area() -> void:
	# Find existing shape or create one if needed
	var collision_shape: CollisionShape3D = detection_area.get_node_or_null("CollisionShape3D")
	if not collision_shape:
		collision_shape = CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D" # Good practice to name it
		detection_area.add_child(collision_shape)

	if not collision_shape.shape or not collision_shape.shape is SphereShape3D:
		collision_shape.shape = SphereShape3D.new()

	# Explicitly cast to SphereShape3D to access radius
	(collision_shape.shape as SphereShape3D).radius = detection_radius

#-----------------------------------------------------------------------------
# Physics & Movement Loop
#-----------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	update_chasing_state(delta) # Pass delta for timer updates
	update_movement(delta)      # Pass delta for rotation lerp
	move_and_slide()

	# Handle collisions (primarily for patrol bouncing)
	var collision = get_last_slide_collision()
	if collision and not is_chasing:
		handle_patrol_collision(collision)

	# Patrol movement timer logic
	#if not is_chasing:
		#movement_timer += delta
		#if movement_timer >= move_duration:
			## Stop moving after duration, wait for timer timeout to pick new direction
			#velocity = Vector3.ZERO
			## Optionally stop immediately:
			## is_movement_stopped = true
			## speed = 0.0
			## movement_timer = 0.0 # Reset timer


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
		velocity.y = max(velocity.y, -max_fall_speed)
	# Removed the velocity.y = 0 on floor, move_and_slide handles this better generally.
	# If you specifically need sharp stops on landing, you might add it back conditionally.

#-----------------------------------------------------------------------------
# State Updates (Chasing, Patrolling)
#-----------------------------------------------------------------------------
func update_chasing_state(delta: float) -> void:
	# Countdown the chase timer if it's active
	if sees_player:
		chasing_timer = chasing_timer_max
	else:
		if chasing_timer > 0:
			chasing_timer -= delta
		else:
			if is_chasing:
			# Timer ran out, stop chasing
				print("Lost target, stopping chase.")
				is_chasing = false
				player = null
				speed = original_speed # Revert speed if changed for chasing
				pick_random_direction() # Go back to patrol
	print(chasing_timer)

	# --- Vision Cone and Line of Sight Check ---
	# Only try to *start* chasing if not already chasing (or if timer just ran out)
	#if not is_chasing:
	var potential_target = find_player_in_vision()
	if is_instance_valid(potential_target):
		print("Player spotted! Starting chase.")
		player = potential_target
		is_chasing = true
		is_movement_stopped = false # Ensure movement isn't stopped
		# Optional: Increase speed when chasing
		# speed = original_speed * 1.5
		chasing_timer = chasing_timer_max # Reset timer on new detection
		# If no potential target found, do nothing (patrol logic continues)

func find_player_in_vision() -> Node3D:
	# Iterate through players currently within the large detection_radius
	for p in players_in_range:
		if not is_instance_valid(p): continue # Skip if player node became invalid

		var direction_to_player = p.global_position - global_position
		var distance_to_player = direction_to_player.length()

		# 1. Check Vision Range: Is player close enough for the detailed check?
		if distance_to_player <= vision_range:

			# 2. Check Vision Angle: Is player within the cone's angle?

			# --- MODIFIED FOR CUSTOM MODEL ROTATION ---
			# First, get the model's standard forward direction (-Z axis in global space)
			var model_standard_forward = -model.global_transform.basis.z
			# Then, apply the required rotation offset around the Y-axis (Vector3.UP)
			# because the model's visual 'forward' is not aligned with its local -Z.
			# Rotation is PI + PI/2 = 1.5 * PI radians (270 degrees).
			var forward_vector = model_standard_forward.rotated(Vector3.UP, PI + (PI / 2.0)).normalized()
			# --- END OF MODIFICATION ---

			# Normalize the direction *to* the player ONCE here
			var direction_to_player_normalized = direction_to_player.normalized()

			# Calculate the dot product using the *adjusted* forward vector
			var dot_product = forward_vector.dot(direction_to_player_normalized)

			if dot_product >= vision_dot_product_threshold:

				# 3. Check Line of Sight: Can the enemy see the player?
				line_of_sight_raycast.target_position = line_of_sight_raycast.to_local(p.global_position)
				line_of_sight_raycast.force_raycast_update()

				if line_of_sight_raycast.is_colliding() and line_of_sight_raycast.get_collider() == p:
					# All checks passed for this player!
					sees_player = true
					return p # Return the valid target
	sees_player = false
	# No player found satisfying all conditions
	print(sees_player)
	return null


func update_movement(delta: float) -> void:
	var horizontal_velocity = Vector3.ZERO

	if is_chasing and is_instance_valid(player):
		# Aim towards the player's current position
		current_direction = (player.global_position - global_position).normalized()
		# Keep Y component zero for direction calculation if needed, but velocity handles gravity
		current_direction.y = 0
		current_direction = current_direction.normalized() # Re-normalize after zeroing Y
		update_rotation(delta) # Rotate towards player

	elif is_movement_stopped:
		# No horizontal movement if stopped
		velocity.x = 0
		velocity.z = 0
		return # Skip setting velocity based on current_direction

	# If patrolling and not stopped, use current patrol direction
	horizontal_velocity = current_direction * speed

	# Apply horizontal velocity (keep existing vertical velocity from gravity)
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z

#-----------------------------------------------------------------------------
# Rotation
#-----------------------------------------------------------------------------
func update_rotation(delta: float) -> void:
	# Only rotate if there's a meaningful horizontal direction
	var horizontal_dir = Vector3(current_direction.x, 0, current_direction.z)
	if horizontal_dir.length() > 0.01:
		# Calculate target angle based on the current direction vector
		# atan2(x, z) gives angle relative to negative Z axis
		target_rotation = atan2(horizontal_dir.x, horizontal_dir.z) + PI + PI/2 

		# Smoothly interpolate towards the target angle using delta
		# Use lerp_angle for correct wrapping around PI radians
		model.rotation.y = lerp_angle(model.rotation.y, target_rotation, rotation_speed * delta)
	# No need for 'else' block, just keep current rotation if not moving horizontally

#-----------------------------------------------------------------------------
# Collision Handling (Patrol)
#-----------------------------------------------------------------------------
func handle_patrol_collision(collision: KinematicCollision3D) -> void:
	# Bounce off walls when patrolling
	var normal = collision.get_normal()
	current_direction = current_direction.bounce(normal).normalized()
	current_direction.y = 0 # Keep patrol direction horizontal
	current_direction = current_direction.normalized()
	movement_timer = 0.0 # Reset movement timer to move full duration in new direction
	# Immediately update rotation to face new direction
	update_rotation(get_physics_process_delta_time()) # Use last frame delta

#-----------------------------------------------------------------------------
# Patrol Logic
#-----------------------------------------------------------------------------
func pick_random_direction() -> void:
	current_direction = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	movement_timer = 0.0 # Reset timer for new direction
	is_movement_stopped = false # Ensure movement is active
	speed = original_speed

func stop_or_resume_patrol_movement() -> void:
	# Only affects patrol state
	if is_chasing: return

	if is_movement_stopped:
		# Resume movement
		speed = original_speed
		is_movement_stopped = false
		pick_random_direction() # Pick a new direction on resume
		print("Patrol movement resumed")
	elif randf() < 0.35: # Chance to stop
		# Stop movement
		speed = 0.0
		is_movement_stopped = true
		print("Patrol movement stopped")
	# If not stopped and random check fails, keep moving

#-----------------------------------------------------------------------------
# Signal Callbacks
#-----------------------------------------------------------------------------
func _on_patrol_timer_timeout() -> void:
	# Decide whether to stop/resume or pick a new direction
	stop_or_resume_patrol_movement()

func _on_detection_area_body_entered(body: Node3D):
	# Add player to list if it enters the outer detection radius
	if body.is_in_group(player_group):
		if not body in players_in_range: # Avoid duplicates
			players_in_range.append(body)
			print("Player entered detection radius: ", body.name)

func _on_detection_area_body_exited(body: Node3D):
	# Remove player from list if it leaves the outer detection radius
	if body in players_in_range:
		players_in_range.erase(body)
		print("Player exited detection radius: ", body.name)
		# Note: Chasing might continue due to chasing_timer even if player exits Area3D
