extends Control

signal replay_pressed
signal main_menu_pressed

@onready var result: Label = $VB/Result
@onready var replay: TextureButton = $VB/Buttons/Replay
@onready var main_menu: TextureButton = $VB/Buttons/MainMenu


func _ready() -> void:
	replay.pressed.connect(_on_replay_pressed)
	main_menu.pressed.connect(_on_main_menu_pressed)


func show_result(message: String) -> void:
	result.text = message


func _on_replay_pressed() -> void:
	replay_pressed.emit()


func _on_main_menu_pressed() -> void:
	main_menu_pressed.emit()
