extends CharacterBody2D

@onready var animation_sprite_2d = $AnimatedSprite2D
@onready var sword_collision = $SwordArea/SwordCollision

const GRAVITY = 1000
@export var speed : int = 1000
@export var max_horizontal_speed: int = 300
@export var slow_down_speed : int = 1500

@export var jump : int = -300
@export var jump_horizontal_speed: int = 1000
@export var max_jump_horizontal_speed: int = 300

enum State{ Idle, Run, Jump, Fall, Attack}
var is_attacking : bool = false
var current_state : State = State.Idle



func _ready():
	current_state = State.Idle

func _physics_process(delta :float):
	player_falling(delta)
	player_jump(delta)
	player_run(delta) 
	
	if is_on_floor() and not is_attacking and velocity.x == 0:
		player_idle(delta)
		
	if Input.is_action_just_pressed("attack") and not is_attacking:
		player_attack()
	
	move_and_slide()
	
	player_animations()
	
	print("State: ", State.keys()[current_state])
	

func player_falling(delta :float):
	if !is_on_floor():
		velocity.y += GRAVITY * delta
		if velocity.y > 0:
			current_state = State.Fall


func player_idle(_delta :float):
	if is_on_floor() and velocity.x == 0:
		current_state = State.Idle
		



func player_run(delta :float):
	if !is_on_floor():
		return

	var direction = input_movement()

	if direction:
		velocity.x += direction * speed * delta
		velocity.x = clamp(velocity.x, -max_horizontal_speed, max_horizontal_speed)
		
		current_state = State.Run
		animation_sprite_2d.flip_h = (direction < 0)
		
		if direction > 0:
			$SwordArea.scale.x = 1
		else:
			$SwordArea.scale.x = -1
	else:
		velocity.x = move_toward(velocity.x, 0, slow_down_speed * delta)
		current_state = State.Idle


func player_jump(delta :float):
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump
		current_state = State.Jump
	
	if !is_on_floor():
		if velocity.y < 0:
			current_state = State.Jump
		else:
			current_state = State.Fall
		var direction = input_movement()
		velocity.x += direction * jump_horizontal_speed * delta
		velocity.x = clamp(velocity.x, -max_jump_horizontal_speed, max_jump_horizontal_speed)



func player_animations():
	if is_attacking:
		animation_sprite_2d.play("attack")
		return
	if current_state == State.Idle:
		animation_sprite_2d.play("idle")
	elif current_state == State.Run:
		animation_sprite_2d.play("run")
	elif current_state == State.Jump:
		animation_sprite_2d.play("jump")
	elif current_state == State.Fall:
		animation_sprite_2d.play("fall")

func player_attack():
	is_attacking = true
	current_state = State.Attack

	sword_collision.set_deferred("disabled", false)
	
	animation_sprite_2d.play("attack1")
	
	await animation_sprite_2d.animation_finished
	sword_collision.set_deferred("disabled", true)
	is_attacking = false
	current_state = State.Idle


func input_movement():
	var direction : float = Input.get_axis("move_left", "move_right")
	
	return direction
