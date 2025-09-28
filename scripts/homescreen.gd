extends Control

@onready var play: Button = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer2/VBoxContainer/play
@onready var settings: Button = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer2/VBoxContainer/settings
@onready var credits: Button = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer2/VBoxContainer/credits
@onready var quit: Button = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer2/VBoxContainer/quit

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file('res://scenes/loading_screen.tscn')
	Global.targetScene='res://scenes/world.tscn'

func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file('res://scenes/loading_screen.tscn')
	Global.targetScene='res://scenes/credits.tscn'


func _on_quit_pressed() -> void:
	get_tree().quit()
