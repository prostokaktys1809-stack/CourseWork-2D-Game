extends TextureProgressBar

func _ready() -> void:
	var player = get_tree().root.find_child("player", true, false)
	if player:

		player.health_changed.connect(_on_player_health_changed)
		

		max_value = player.max_hp
		value = player.health
	else:
		print("Плеєра не знайдено!")


func _on_player_health_changed(new_hp: int) -> void:
	value = new_hp
