extends CharacterBody2D

const SPEED = 200

@onready var anim = $AnimatedSprite2D

func _physics_process(delta):
	var direction = 0

	if Input.is_action_pressed("ui_right"):
		direction += 1
	if Input.is_action_pressed("ui_left"):
		direction -= 1

	velocity.x = direction * SPEED
	move_and_slide()

	# 🔁 Анімації
	if direction == 0:
		anim.play("idle")
	else:
		anim.play("run")
		anim.flip_h = direction < 0
		
print("RUNNING")
