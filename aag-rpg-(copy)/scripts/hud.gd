extends CanvasLayer

const HEART_SIZE: int = 20

const HEART_FULL = preload("res://assets/images/ui/lifebar/Heart_full.png")
const HEART_HALF = preload("res://assets/images/ui/lifebar/Heart_half.png")
const HEART_EMPTY = preload("res://assets/images/ui/lifebar/Heart_empty.png")

var player: Node = null

@onready var hearts_container: HBoxContainer = $Hearts


func set_player(p: Node) -> void:
	player = p
	print("HUD: set_player called")

	if player:
		if not player.health_changed.is_connected(_update_health):
			player.health_changed.connect(_update_health)
		_update_health(player.health)


func _update_health(new_health: int) -> void:
	print("HUD: health updated -> ", new_health)

	var hearts = hearts_container.get_children()

	for i in hearts.size():
		var heart_value: int = new_health - i * HEART_SIZE

		if heart_value >= HEART_SIZE:
			hearts[i].texture = HEART_FULL
		elif heart_value > 0:
			hearts[i].texture = HEART_HALF
		else:
			hearts[i].texture = HEART_EMPTY
