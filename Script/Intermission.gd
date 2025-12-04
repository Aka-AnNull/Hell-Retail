extends Control

@onready var level_label = $LevelLabel

func _ready():
	# 1. Get the data for the current level from our Global Manager
	$Fade_transition/AnimationPlayer.play("Fade_out")
	var current_lvl = GameManager.current_level
	
	# Check if we have data for this level (prevents crashing if we go past level 7)
	if GameManager.level_data.has(current_lvl):
		var data = GameManager.level_data[current_lvl]
		level_label.text = data["text"] 
	else:
		level_label.text = "Level " + str(current_lvl)

func _process(delta):
	# 2. Wait for player to press Space
	if Input.is_action_just_pressed("ui_accept"):
		print("Starting Level...")
		$Fade_transition/AnimationPlayer.play("Fade_in")
		await $Fade_transition/AnimationPlayer.animation_finished
		GameManager.start_level_gameplay()
