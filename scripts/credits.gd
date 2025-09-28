extends Control

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var jobname: Label = $PanelContainer/VBoxContainer/Name
@onready var job: Label = $PanelContainer/VBoxContainer/Job

var employees = {
	"Name": ['Irumva Ivan Petrov', 'Cyusa Gael', 'UGUKUNDA SUGIRA Santos','Rukundo michel'],
	"Job": ['Leading Game Developer \n Game programmer','Junior Game Developer \n UI,UX Designer  ','3D modeler  \n animator and rigger','Sound producer  \n SFX']
}

var current_index := 0

func _ready() -> void:
	show_current_employee()
	anim_player.play("credits")

func show_current_employee():
	jobname.text = employees.Name[current_index]
	job.text = employees.Job[current_index]

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "credits":
		current_index += 1
		if current_index >= employees.Name.size():
			Global.targetScene = 'res://scenes/homescreen.tscn'
			get_tree().change_scene_to_file('res://scenes/loading_screen.tscn')
		else:
			show_current_employee()
			anim_player.play("credits")


func _on_skip_credits_pressed() -> void:
	Global.targetScene = 'res://scenes/homescreen.tscn'
	get_tree().change_scene_to_file('res://scenes/loading_screen.tscn')
