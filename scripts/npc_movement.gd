extends CharacterBody3D

@export var speed: float = 4.0
@export var detection_radius: float = 10.0
@export var move_duration: float = 2.0
# Add these gravity variables
@export var gravity: float = 9.8  # Earth gravity = 9.8 m/s², adjust as needed
@export var max_fall_speed: float = 20.0  # Terminal velocity
# Add this new export variable to control rotation speed
@export var rotation_speed: float = 5.0  # Higher = faster rotation

var original_speed: float
var players_in_range: Array = []
var is_movement_stopped: bool = false
var current_rotation: float = 0.0
var target_rotation: float = 0.0
var current_direction: Vector3 = Vector3.ZERO
var is_chasing: bool = false
var player: Node3D = null
var movement_timer: float = 0.0

@onready var timer: Timer = $Timer
@onready var model: Node3D = $Model
@onready var detection_area: Area3D = $DetectionArea
@onready var ground_check: RayCast3D = $GroundCheck
@onready var raycast: RayCast3D = $RayCast3D

func _ready() -> void:
	
	original_speed = speed
	timer.wait_time = 5
	timer.timeout.connect(_on_timer_timeout)
	timer.start()
	pick_random_direction()
	setup_detection_area()

func setup_detection_area() -> void:
	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = SphereShape3D.new()
	collision_shape.shape.radius = detection_radius
	detection_area.add_child(collision_shape)

func pick_random_direction() -> void:
	current_direction = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()

func stop_randomly() -> void:
	if randf() < 0.35:
		if is_movement_stopped:
			# Resume movement with original speed
			speed = original_speed
			is_movement_stopped = false
			#print("Movement resumed")
		else:
			# Stop movement but keep direction
			original_speed = speed
			speed = 0.0
			is_movement_stopped = true
			#print("Movement stopped")

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	update_chasing_state()
	update_movement()
	move_and_slide()
	
	# Collision handling
	var collision = get_last_slide_collision()
	if collision and not is_chasing:
		handle_collision(collision)
	
	# Movement timer logic
	if not is_chasing:
		movement_timer += delta
		if movement_timer >= move_duration:
			velocity = Vector3.ZERO
			movement_timer = 0.0

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		# Apply gravity while airborne
		velocity.y -= gravity * delta
		# Limit fall speed
		velocity.y = max(velocity.y, -max_fall_speed)
	else:
		# Reset vertical velocity when grounded
		velocity.y = 0


func handle_collision(collision: KinematicCollision3D) -> void:
	# Calculate new direction based on collision normal
	var normal = collision.get_normal()
	current_direction = current_direction.bounce(normal).normalized()
	movement_timer = 0.0  # Reset movement timer
	update_rotation()

func update_movement() -> void:
	var horizontal_velocity = Vector3.ZERO
	
	if is_chasing and player != null:
		print("CHASE")
		current_direction = (player.global_position - global_position).normalized()
	
	if not is_movement_stopped:
		horizontal_velocity = current_direction * speed
	
	# Only modify horizontal components (X and Z)
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z

func update_rotation() -> void:
	if velocity.length() > 0.1:
		# Calculate target rotation
		var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
		target_rotation = atan2(horizontal_velocity.x, horizontal_velocity.z) + PI + PI/2
		
		# Interpolate rotation
		current_rotation = lerp_angle(current_rotation, target_rotation, rotation_speed * get_process_delta_time())
		model.rotation.y = current_rotation
	# Keep updating rotation even when velocity is low to maintain smoothness
	else:
		current_rotation = model.rotation.y
		target_rotation = model.rotation.y

func _on_timer_timeout() -> void:
	stop_randomly()
	if not is_chasing and not is_movement_stopped:
		pick_random_direction()
		movement_timer = 0.0

func _on_body_entered(body: Node3D):
	print("Body entered: ", body.name)
	if body.is_in_group("player"):
		print("Player detected!")
		players_in_range.append(body)

func _on_body_exited(body: Node3D):
	print("Body exited: ", body.name)
	if body in players_in_range:
		players_in_range.erase(body)

func update_chasing_state() -> void:
	if players_in_range.is_empty():
		player = null
		is_chasing = false
		#print(players_in_range)
		return

	# Find nearest player in detection area
	var nearest_distance = INF
	var nearest_player: Node3D = null
	
	for p in players_in_range:
		var distance = global_position.distance_to(p.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_player = p
			#print(p)

	# Check line of sight
	if nearest_player:
		raycast.target_position = raycast.to_local(nearest_player.global_position)
		raycast.force_raycast_update()
		
		if raycast.is_colliding() and raycast.get_collider() == nearest_player:
			player = nearest_player
			is_chasing = true
		else:
			player = null
			is_chasing = false

# Rest of your existing body entered/exited functions
