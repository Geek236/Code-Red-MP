extends Node

var targetScene
var optionsApplied = false

var gameOption = {
	"gameMode": "",
	"timeLimit": null,
	"map": ""
}
var shooter_tips = [
	"Always reload before entering a fight.",
	"Headshots deal more damage—aim high!",
	"Use cover to minimize exposure to enemies.",
	"Keep moving to make yourself harder to hit.",
	"Listen carefully for footsteps and gunfire.",
	"Throw grenades to flush enemies out of cover.",
	"Watch your corners when entering buildings.",
	"Conserve ammo by firing in short bursts.",
	"Check your minimap regularly for enemy activity.",
	"Don’t stay scoped in for too long—stay aware of your surroundings.",
	"Flanking is often more effective than direct attacks.",
	"Use higher ground for a better view of the battlefield.",
	"Stay close to teammates for support.",
	"Switch to your pistol if your main weapon runs out of ammo mid-fight.",
	"Don’t waste grenades—use them strategically.",
	"Learn recoil patterns to improve accuracy.",
	"Don’t chase kills recklessly; survive first, fight second.",
	"Use sound cues to track enemy movement.",
	"Sometimes retreating is better than forcing a fight.",
	"Keep an eye on your health and armor—retreat to heal if needed."
]

func _process(delta: float) -> void:
	optionsApplied = _check_options_applied()

func _check_options_applied() -> bool:
	for key in gameOption.keys():
		var value = gameOption[key]
		if value != null and str(value) != "":
			return true  
	return false
