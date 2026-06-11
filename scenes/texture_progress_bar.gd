extends TextureProgressBar

func _ready() -> void:
	# Шукаємо об'єкт гравця у всій сцені (рекурсивний пошук)
	var player = get_tree().root.find_child("player", true, false)
	if player:
# Підключаємо сигнал зміни здоров'я гравця до нашої функції
		player.health_changed.connect(_on_player_health_changed)
		
# Ініціалізуємо максимальне значення шкали HP
		max_value = player.max_hp
		# Встановлюємо поточне значення HP на шкалі
		value = player.health
# Якщо гравця не знайдено — виводимо повідомлення в консоль
	else:
		print("Плеєра не знайдено!")

# Функція, яка викликається при зміні HP у гравця
func _on_player_health_changed(new_hp: int) -> void:
	# Оновлюємо значення шкали здоров'я
	value = new_hp
