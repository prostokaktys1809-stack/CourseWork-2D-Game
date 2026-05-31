extends Area2D

@onready var panel = get_node_or_null("CanvasLayer/Panel")
@onready var label = get_node_or_null("CanvasLayer/Panel/RichTextLabel")

var is_player_near = false

func _ready():
	if panel:
		panel.visible = false
	print("Дід готовий! Шар колізії: ", collision_layer)

func _process(_delta):
	if is_player_near and Input.is_action_just_pressed("interact"):
		if panel:
			panel.visible = !panel.visible
			if panel.visible:
				_show_text()

func _show_text():
	label.visible_ratio = 0.0
	var tween = create_tween()
	

	tween.tween_property(label, "visible_ratio", 1.0, 7.0).set_trans(Tween.TRANS_LINEAR)
	
	print("Текст пішов повільно!")
func _on_body_entered(body):
	print("Хтось зайшов: ", body.name) 
	if body.name == "player":
		is_player_near = true

func _on_body_exited(body):
	print("Хтось пішов: ", body.name)
	if body.name == "player":
		is_player_near = false
		if panel: panel.visible = false
