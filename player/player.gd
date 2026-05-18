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

@export_group("Dash")
@export var dash_speed : int = 300
@export var dash_duration : float = 0.3

@export_group("Combat")
@export var health : int = 100

var is_dashing : bool = false
var is_hit : bool = false
var is_dead : bool = false
var is_attacking : bool = false
var current_state : State = State.Idle

enum State{ Idle, Run, Jump, Fall, Attack, DashAttack, Hit, Death}

func _ready():
	current_state = State.Idle
	if sword_collision:
		sword_collision.disabled = true

func _physics_process(delta :float):
	if is_dead:
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		move_and_slide()
		return

	if is_dashing:
		velocity.y = 0 
		move_and_slide()
		return
		
	elif is_hit:
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		move_and_slide()
		return

	player_falling(delta)
	player_jump(delta)
	player_run(delta) 
	
	if is_on_floor() and not is_attacking and velocity.x == 0:
		player_idle(delta)
		
	if Input.is_action_just_pressed("attack") and not is_attacking:
		player_attack()
	if Input.is_action_just_pressed("dash") and not is_dashing:
		player_dash_attack()
		
	move_and_slide()
	player_animations()
	

	if Engine.get_frames_drawn() % 30 == 0:
		print("CURRENT STATE: ", State.keys()[current_state])
func take_damage(amount: int):
	if is_dead or is_dashing or is_hit: 
		return
	
	health -= amount
	print("Player Health: ", health)
	
	if health <= 0:
		start_death_logic()
	else:
		start_hit_logic()
func start_hit_logic():
	is_hit = true
	current_state = State.Hit
	velocity.x = 0
	animation_sprite_2d.play("hit")
	await animation_sprite_2d.animation_finished
	
	is_hit = false
	current_state = State.Idle
	
func start_death_logic():
	is_dead = true
	current_state = State.Death
	velocity = Vector2.ZERO
	
	animation_sprite_2d.play("death")
	
	await animation_sprite_2d.animation_finished
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()
	
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
		velocity.x = move_toward(velocity.x, 0, slow_down_speed * delta * 2)
		if abs(velocity.x) < 10:
			velocity.x = 0
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
	if is_dead:
		animation_sprite_2d.play("death")
		return
	if is_hit:
		animation_sprite_2d.play("hit")
		return
	if is_dashing: 
		return
	if is_attacking:
		animation_sprite_2d.play("attack1")
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

func player_dash_attack():
	is_dashing = true
	is_attacking = true
	
	set_collision_mask_value(3, false)
	
	$AnimationPlayer.play("dash_attack")
	
	var direction = -1 if animation_sprite_2d.flip_h else 1
	velocity.x = direction * 600 
	velocity.y = 0

	await get_tree().create_timer(dash_duration).timeout
	
	velocity.x = 0
	set_collision_mask_value(3, true) 
	is_dashing = false
	is_attacking = false
	current_state = State.Idle
	
func input_movement():
	var direction : float = Input.get_axis("move_left", "move_right")
	
	return direction
func _on_sword_area_body_entered(body):
	if body.has_method("take_damage") and is_attacking:
		body.take_damage(10)
