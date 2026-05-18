extends CharacterBody2D

@onready var hitbox_collision = $Node2D/Hitbox/CollisionShape2D
@onready var attack_node = $Node2D
@export var patrol_points : Node
@export var speed : int = 1500
@export var wait_time : int = 2
@export var health : int = 30
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var timer = $Timer

const GRAVITY = 1000

var is_hit : bool = false
var is_dead : bool = false
var can_walk : bool

enum State { Idle, Walk, Hit, Death, Attack }

var current_state : State
var direction : Vector2 = Vector2.LEFT
var number_of_points : int
var point_positions : Array[Vector2]
var current_point : Vector2
var current_point_position : int 

func _ready():
	if patrol_points != null:
		number_of_points = patrol_points.get_children().size()
		for point in patrol_points.get_children():
			point_positions.append(point.global_position)
		current_point = point_positions[current_point_position]
	else:
		print("No patrol points")
	
	timer.wait_time = wait_time
	current_state = State.Idle
	hitbox_collision.disabled = true

func _physics_process(delta: float):
	if is_dead or is_hit or current_state == State.Attack:
		enemy_gravity(delta)
		move_and_slide()
		return

	enemy_gravity(delta)
	
	var player = get_tree().root.find_child("player", true, false)
	

	if player:
		var distance = global_position.distance_to(player.global_position)
		
		if distance < 400 and distance > 60:   
			can_walk = true
			direction = (player.global_position - global_position).normalized()
			velocity.x = direction.x * (speed * 0.7) * delta 
			current_state = State.Walk

			animated_sprite_2d.flip_h = direction.x > 0
			attack_node.scale.x = -1 if direction.x > 0 else 1
		elif distance <= 60:
			velocity.x = 0
			enemy_attack_logic()
		else:

			enemy_idle(delta)
			enemy_walk(delta)
	else:

		enemy_idle(delta)
		enemy_walk(delta)

	move_and_slide()
	enemy_animations()

func enemy_gravity(delta : float):
	velocity.y += GRAVITY * delta 

func enemy_idle(delta : float):
	if !can_walk: 
		velocity.x = move_toward(velocity.x, 0, speed * delta)
		current_state = State.Idle

func enemy_walk(delta : float):
	if !can_walk:
		return
	if abs(position.x - current_point.x) > 0.5:
		velocity.x = direction.x * speed * delta
		current_state = State.Walk
	else:
		current_point_position += 1
		if current_point_position >= number_of_points:
			current_point_position = 0
		current_point = point_positions[current_point_position]
		direction = Vector2.RIGHT if current_point.x > position.x else Vector2.LEFT
		can_walk = false
		timer.start()
	
	animated_sprite_2d.flip_h = direction.x > 0 
	attack_node.scale.x = -1 if direction.x > 0 else 1

func enemy_animations():
	if is_dead:
		animated_sprite_2d.play("death")
	elif is_hit:
		animated_sprite_2d.play("hit")
	elif current_state == State.Attack:
		animated_sprite_2d.play("attack")
	elif current_state == State.Idle:
		animated_sprite_2d.play("idle")
	elif current_state == State.Walk:
		animated_sprite_2d.play("walk")

func _on_timer_timeout() -> void:
	can_walk = true

func _on_hurtbox_area_entered(area):
	if area.name == "SwordArea":
		take_damage(10)
	else:
		print("Ігнорую контакт з: ", area.name)

func take_damage(amount: int):
	if is_dead or is_hit:
		return
	health -= amount
	if health <= 0:
		start_death_logic()
	else:
		start_hit_logic()

func start_hit_logic():
	is_hit = true
	can_walk = false 
	current_state = State.Hit
	velocity = Vector2.ZERO
	animated_sprite_2d.play("hit")
	await animated_sprite_2d.animation_finished
	is_hit = false
	can_walk = true
	current_state = State.Idle

func start_death_logic():
	is_dead = true
	current_state = State.Death
	velocity.x = 0
	animated_sprite_2d.play("death")
	await animated_sprite_2d.animation_finished
	queue_free() 

func enemy_attack_logic():
	current_state = State.Attack
	can_walk = false
	velocity.x = 0
	animated_sprite_2d.play("attack")
	

	await get_tree().create_timer(0.4).timeout
	if hitbox_collision: hitbox_collision.disabled = false 
	
	await animated_sprite_2d.animation_finished
	if hitbox_collision: hitbox_collision.disabled = true 
	
	current_state = State.Idle
	can_walk = true



func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.name == "Hurtbox":
		if area.get_parent().has_method("take_damage"):
			area.get_parent().take_damage(10)
			print("Голем влучив по гравцю!")
