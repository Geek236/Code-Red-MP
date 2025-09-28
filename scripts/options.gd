extends Control
@onready var error: Label = $mode/PanelContainer/PanelContainer/VBoxContainer2/error

var gameOption = {
	"gameMode": null,
	"timeLimit": null,
	"map": null
}

var errors: Array = []

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func check_errors() -> Array:
	errors.clear()

	if gameOption.gameMode == null:
		errors.append("Game mode not selected.")

	if gameOption.timeLimit == null:
		errors.append("Time limit not selected.")

	if gameOption.map == null:
		errors.append("Map not selected.")

	return errors


func _on_game_mode_item_selected(index: int) -> void:
	match index:
		0:
			gameOption.gameMode = null
		1:
			gameOption.gameMode = "Team deathmatch"
		2:
			gameOption.gameMode = "Free for all"
		3:
			gameOption.gameMode = "Capture the flag"


func _on_time_limit_item_selected(index: int) -> void:
	match index:
		0:
			gameOption.timeLimit = null
		1:
			gameOption.timeLimit = 5
		2:
			gameOption.timeLimit = 10
		3:
			gameOption.timeLimit = 15
		4:
			gameOption.timeLimit = 20
		5:
			gameOption.timeLimit = 30
		6:
			gameOption.timeLimit = "unlimited"


func _on_map_item_selected(index: int) -> void:
	match index:
		0:
			gameOption.map = null
		1:
			gameOption.map = "Map 1"
		2:
			gameOption.map = "Map 2"


func _on_apply_options_pressed() -> void:
	var result = check_errors()
	if result.size() > 0:
		
		error.text = "\n".join(result)
	else:
		error.text = "All options are valid! Starting game..."
		Global.gameOption= gameOption
		get_tree().change_scene_to_file('res://scenes/loading_screen.tscn')
		Global.targetScene='res://scenes/world.tscn'
