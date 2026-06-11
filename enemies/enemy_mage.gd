extends CharacterBody2D
# Посилання на вузли
@onready var sprite = $AnimatedSprite2D
@onready var attack_pivot = $AttackPivot
@onready var staff_hitbox = $AttackPivot/StaffHitbox/CollisionShape2D
@onready var health_bar = $TextureProgressBar
@onready var timer = $Timer
# Налаштування ворога
@export var patrol_points : Node
@export var speed : int = 3000 
@export var wait_time : int = 2
@export var health : int = 55
const GRAVITY = 1000
# Стани ворога
var is_hit : bool = false
var is_dead : bool = false
var can_walk : bool = true
var home_position : Vector2
# Перелік можливих станів
enum State { Idle, Walk, Hit, Death, Attack }
var current_state : State = State.Idle
# Точки патрулювання
var point_positions : Array[Vector2]
var current_point : Vector2
var current_point_position : int = 0

func _ready():
	# Отримання точок патрулювання
	if patrol_points != null:
		for point in patrol_points.get_children():
			point_positions.append(point.global_position)
		if point_positions.size() > 0:
			current_point = point_positions[0]
			home_position = point_positions[0]
	# Налаштування таймера
	timer.wait_time = wait_time
	# Вимкнення хітбокса атаки
	staff_hitbox.disabled = true
	# Ініціалізація смуги здоров’я
	if health_bar:
		health_bar.max_value = health
		health_bar.value = health

func _physics_process(delta: float):
	enemy_gravity(delta) 
	# Блокування руху під час атаки, смерті або отримання урону
	if is_dead or is_hit or current_state == State.Attack:
		move_and_slide()
		return
	# Пошук гравця
	var player = get_tree().root.find_child("player", true, false)
	var can_see_player = false
	
	if player:
	# Перевірка чи гравець знаходиться поруч із маршрутом патрулювання
		for point_pos in point_positions:
			if player.global_position.distance_to(point_pos) < 400:
				can_see_player = true
				break
		
		var dist_to_player = global_position.distance_to(player.global_position)
		
		if can_see_player:
	
			timer.stop() 
			can_walk = true 
			# Атака на близькій відстані
			if dist_to_player <= 100: 
				velocity.x = 0
				mage_attack_logic()
			else:
				# Переслідування гравця
				var dir_to_player = (player.global_position - global_position).normalized()

				velocity.x = dir_to_player.x * (speed / 15.0) 
				current_state = State.Walk
				flip_mage(dir_to_player.x)
		else:

			enemy_patrol_logic(delta)
	else:
		enemy_patrol_logic(delta)

	move_and_slide()
	update_animations()

func mage_attack_logic():
	# Виконання атаки
	current_state = State.Attack
	can_walk = false
	velocity.x = 0
	
	
	var attack_type = randi() % 2 
	if attack_type == 0:
		sprite.play("Attack1")
	else:
		sprite.play("Attack2")
	
	await get_tree().create_timer(0.2).timeout
	if !is_dead: staff_hitbox.disabled = false
	
	await sprite.animation_finished
	staff_hitbox.disabled = true
	current_state = State.Idle
	can_walk = true

func take_damage(amount):
	# Отримання пошкодження
	if is_dead or is_hit: return
	health -= amount
	if health_bar: health_bar.value = health
	
	if health <= 0:
		is_dead = true
		current_state = State.Death
		sprite.play("Death")
		await sprite.animation_finished
		queue_free()
	else:
		is_hit = true
		current_state = State.Hit
		sprite.play("Take hit")
		await sprite.animation_finished
		is_hit = false
		current_state = State.Idle

func flip_mage(dir_x):
	# Поворот персонажа
	sprite.flip_h = dir_x < 0
	attack_pivot.scale.x = -1 if dir_x < 0 else 1

func enemy_patrol_logic(delta):
	# Патрулювання між точками
	if can_walk and point_positions.size() > 0:
		if abs(global_position.x - current_point.x) > 20:
			var dir_to_point = (current_point - global_position).normalized()
			velocity.x = dir_to_point.x * (speed / 25.0)
			current_state = State.Walk
			flip_mage(dir_to_point.x)
		else:
			velocity.x = 0
			current_state = State.Idle
			can_walk = false
			current_point_position = (current_point_position + 1) % point_positions.size()
			current_point = point_positions[current_point_position]
			timer.start()
	else:
		velocity.x = move_toward(velocity.x, 0, speed * delta)

func update_animations():
	# Оновлення анімації
	if is_dead: return
	if is_hit: return
	if current_state == State.Attack: return
	
	if velocity.x != 0:
		sprite.play("Run")
	else:
		sprite.play("Idle")

func enemy_gravity(delta):
	# Застосування гравітації
	velocity.y += GRAVITY * delta

func _on_timer_timeout():
	# Продовження руху після паузи
	can_walk = true


func _on_staff_hitbox_area_entered(area):
	# Нанесення шкоди гравцю
	if area.name == "Hurtbox": 
		if area.get_parent().has_method("take_damage"):
			area.get_parent().take_damage(15)
			print("Маг влучив!")

func _on_hurtbox_area_entered(area):
	# Отримання шкоди від меча
	if area.name == "SwordArea":
		take_damage(10)
		print("Маг отримав урон!")
