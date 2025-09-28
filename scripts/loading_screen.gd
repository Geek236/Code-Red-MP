extends Control
@onready var anim_player: AnimationPlayer = $AnimationPlayer
var targetScene
@onready var tip: Label = $PanelContainer/MarginContainer/VBoxContainer/tip


func _ready() -> void:
	anim_player.play("loading")
	targetScene = Global.targetScene
	var random_tip = Global.shooter_tips[randi() % Global.shooter_tips.size()]
	tip.text = "Tip: " + random_tip



func _process(delta: float) -> void:
	pass


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name=='loading':
		get_tree().change_scene_to_file(targetScene)
