extends Node

@export var main_menu_packed: PackedScene
@export var main_packed: PackedScene
@export var end_game_packed: PackedScene

var current_main: Node2D
var end_game_screen: Control
var enemies_remaining: int = 0
var game_ended: bool = false


func _ready() -> void:
	if main_menu_packed == null:
		print("ERROR: Main Menu Packed is empty!")
		return

	load_main_menu("game start")


func load_main_menu(_origin: String) -> void:
	if main_menu_packed == null:
		print("ERROR: Main Menu Packed is empty!")
		return

	if has_node("MainMenu"):
		get_node("MainMenu").queue_free()

	var menu: Control = main_menu_packed.instantiate()
	menu.name = "MainMenu"

	menu.new_game_pressed.connect(new_game)
	menu.settings_pressed.connect(settings_open)
	menu.about_pressed.connect(about_open)
	menu.exit_pressed.connect(exit_game)

	add_child(menu)


func new_game(_origin: String) -> void:
	if main_packed == null:
		print("ERROR: Main Packed is empty!")
		return

	if has_node("MainMenu"):
		get_node("MainMenu").queue_free()

	if is_instance_valid(end_game_screen):
		end_game_screen.queue_free()

	end_game_screen = null
	current_main = main_packed.instantiate()
	current_main.name = "Main"
	game_ended = false
	enemies_remaining = 0

	add_child(current_main)

	var player = current_main.find_child("Player", true, false)

	# Look for "HUD" first, then fall back to "HealthBar"
	var health_bar = current_main.find_child("HUD", true, false)
	if health_bar == null:
		health_bar = current_main.find_child("HealthBar", true, false)

	if player:
		player.died.connect(_on_player_died)
	else:
		print("ERROR: Player node not found!")

	if health_bar and player:
		health_bar.set_player(player)
	else:
		if not health_bar:
			print("ERROR: HUD / HealthBar node not found!")

	var enemies = current_main.find_children(
		"*", "CharacterBody2D", true, false
	)

	for enemy in enemies:
		if enemy.name.begins_with("Slime"):
			enemies_remaining += 1

			if enemy.has_signal("died"):
				enemy.died.connect(_on_enemy_died)

	print("Slimes found: ", enemies_remaining)


func _on_player_died() -> void:
	show_end_game("GAME OVER")


func _on_enemy_died() -> void:
	if game_ended:
		return

	enemies_remaining -= 1
	print("Slimes remaining: ", enemies_remaining)

	if enemies_remaining <= 0:
		show_end_game("VICTORY!")


func show_end_game(message: String) -> void:
	if game_ended:
		return

	if end_game_packed == null:
		print("ERROR: End Game Packed is empty!")
		return

	game_ended = true

	if is_instance_valid(current_main):
		current_main.queue_free()

	current_main = null

	end_game_screen = end_game_packed.instantiate()
	add_child(end_game_screen)

	end_game_screen.show_result(message)
	end_game_screen.replay_pressed.connect(_on_replay_pressed)
	end_game_screen.main_menu_pressed.connect(_on_main_menu_pressed)


func _on_replay_pressed() -> void:
	if is_instance_valid(end_game_screen):
		end_game_screen.queue_free()

	end_game_screen = null
	new_game("retry")


func _on_main_menu_pressed() -> void:
	if is_instance_valid(end_game_screen):
		end_game_screen.queue_free()

	end_game_screen = null
	game_ended = false

	load_main_menu("end game")


func settings_open(_origin: String) -> void:
	pass


func about_open(_origin: String) -> void:
	pass


func exit_game(_origin: String) -> void:
	get_tree().quit()
