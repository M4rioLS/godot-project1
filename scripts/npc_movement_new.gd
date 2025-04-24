extends CharacterBody3D

@export var speed: float = 4.0
@export var detection_radius: float = 10.0

var current_direction: Vector3 = Vector3.ZERO
var is_chasing: bool = false
var player: Node3D = null

@onready var timer: Timer = $Timer
@onready var model: Node3D = $Model
@onready var detection_area: Area3D = $DetectionArea
@onready var raycast: RayCast3D = $RayCast3D

func _ready() -> void:
	timer.timeout.connect(_on_timer_timeout)
	pick_random_direction()
	setup_detection_area()
	
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

func setup_detection_area() -> void:
	var collision_shape = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = detection_radius
	collision_shape.shape = shape
	detection_area.add_child(collision_shape)

func pick_random_direction() -> void:
	current_direction = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player = body

func _on_body_exited(body: Node3D) -> void:
	if body == player:
		player = null
		is_chasing = false

func _physics_process(delta: float) -> void:
	update_chasing_state()
	update_movement()
	update_rotation()

func update_chasing_state() -> void:
	if player == null:
		is_chasing = false
		return
	
	# Update raycast to check line of sight
	raycast.target_position = raycast.to_local(player.global_position)
	raycast.force_raycast_update()
	
	is_chasing = raycast.is_colliding() and raycast.get_collider() == player

func update_movement() -> void:
	if is_chasing:
		current_direction = (player.global_position - global_position).normalized()
	
	velocity = current_direction * speed
	move_and_slide()

func update_rotation() -> void:
	if velocity.length() > 0.1:
		var look_direction = Vector2(velocity.x, velocity.z).normalized()
		model.rotation.y = look_direction.angle() - PI/2

func _on_timer_timeout() -> void:
	if not is_chasing:
		pick_random_direction()
