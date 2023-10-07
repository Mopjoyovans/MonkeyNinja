extends CharacterBody2D

@export var movement_data: PlayerMovementData

@onready var animated_sprite_2d = %AnimatedSprite2D
@onready var coyote_jump_timer = %CoyoteJumpTimer
@onready var coyote_wall_jump_timer = %CoyoteWallJumpTimer

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var can_double_jump = true
var can_wall_jump = true
var stored_wall_normal = Vector2.ZERO


func _physics_process(delta):
	var movement_axis = Input.get_axis("move_left", "move_right")

	apply_air_resistance(movement_axis, delta)
	apply_friction(movement_axis, delta)
	apply_gravity(delta)
	
	handle_acceleration(movement_axis, delta)
	handle_air_acceleration(movement_axis, delta)
	handle_jump()
	handle_wall_jump()
	
	recharge_jumps()
	update_animations(movement_axis)
	move_and_slide()


func apply_air_resistance(movement_axis, delta):
	if movement_axis == 0 and not is_on_floor():
		velocity.x = move_toward(velocity.x, 0, movement_data.air_resistance * delta)


func apply_friction(movement_axis, delta):
	if movement_axis == 0 and is_on_floor():
		velocity.x = move_toward(velocity.x, 0, movement_data.friction * delta)


func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * movement_data.gravity_scale * delta
		
		
func handle_acceleration(movement_axis, delta):
	if not is_on_floor():
		return

	if movement_axis != 0:
		velocity.x = move_toward(velocity.x, movement_data.speed * movement_axis, movement_data.acceleration * delta)
		

func handle_air_acceleration(movement_axis, delta):
	if is_on_floor():
		return
		
	if movement_axis != 0:
		velocity.x = move_toward(velocity.x, movement_data.speed * movement_axis, movement_data.air_acceleration * delta)


func handle_jump():
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or coyote_jump_timer.time_left > 0.0:
			velocity.y = movement_data.jump_velocity
		elif can_double_jump:
			handle_double_jump()
			can_double_jump = false


func handle_double_jump():
	velocity.y = movement_data.jump_velocity * 0.8
	
	
func handle_wall_jump():
	if is_on_wall_only():
		stored_wall_normal = get_wall_normal()
	
	if not is_on_wall_only() and coyote_wall_jump_timer.time_left <= 0.0:
		return
		
	var wall_normal = get_wall_normal()
	if coyote_wall_jump_timer.time_left > 0.0:
		wall_normal = stored_wall_normal
	
	if Input.is_action_just_pressed("jump") and can_wall_jump and (wall_normal == Vector2.LEFT or wall_normal == Vector2.RIGHT):
		velocity.x = wall_normal.x * movement_data.speed
		velocity.y = movement_data.jump_velocity
#		can_wall_jump = false


func recharge_jumps():
	if is_on_floor():
		can_double_jump = true
		can_wall_jump = true


func update_animations(movement_axis):
	if is_on_wall_only():
		animated_sprite_2d.play("wall_jump")
		return
	
	if not is_on_floor():
		if not can_double_jump:
			animated_sprite_2d.play("double_jump")
			return
		elif velocity.y <= 0:
			animated_sprite_2d.play("jump")
		else:
			animated_sprite_2d.play("fall")

	if movement_axis != 0:
		animated_sprite_2d.flip_h = movement_axis < 0
		animated_sprite_2d.play("run")
	else:
		animated_sprite_2d.play("idle")
