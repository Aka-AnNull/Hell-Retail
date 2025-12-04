extends Node

# VARIABLES
var current_level = 1
var max_levels = 7
var score = 0

# LEVEL CONFIGURATION
# We can tweak these numbers later to make the game harder!
var level_data = {
	1: {"goal_money": 50, "customer_speed": 1.0, "text": "Level 1: Opening Day"},
	2: {"goal_money": 100, "customer_speed": 1.2, "text": "Level 2: Lunch Rush"},
	3: {"goal_money": 150, "customer_speed": 1.5, "text": "Level 3: Weekend Sale"},
	4: {"goal_money": 200, "customer_speed": 1.8, "text": "Level 4: Black Friday"},
	5: {"goal_money": 300, "customer_speed": 2.0, "text": "Level 5: Holiday Season"},
	6: {"goal_money": 400, "customer_speed": 2.5, "text": "Level 6: Total Chaos"},
	7: {"goal_money": 500, "customer_speed": 3.0, "text": "Level 7: HELL RETAIL"}
}

# SCENE SWITCHING FUNCTIONS
func start_game():
	current_level = 1
	score = 0
	# Make sure this points to where you saved your Intermission scene!
	# If you saved Intermission inside the Scene folder, change this to:
	# get_tree().change_scene_to_file("res://Scene/Intermission.tscn")
	get_tree().change_scene_to_file("res://Scene/Intermission.tscn")

func next_level():
	current_level += 1
	if current_level > max_levels:
		$Fade_transition/AnimationPlayer.play("Fade_in")
		print("YOU WIN THE GAME!")
		get_tree().change_scene_to_file("res://Scene/main_menu.tscn")
	else:
		$Fade_transition/AnimationPlayer.play("Fade_in")
		get_tree().change_scene_to_file("res://Scene/Intermission.tscn")

func start_level_gameplay():
	# UPDATE THIS LINE TO MATCH YOUR ACTUAL LEVEL FILE

	get_tree().change_scene_to_file("res://Scene/level.tscn")
