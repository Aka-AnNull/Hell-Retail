extends Node2D

var button_type = null
@onready var ske_menu = $"Skeleton Menu"

func _ready():
	# Make sure the fade blocks input ONLY during the transition if you want,
	# but setting Mouse Filter to "Ignore" is usually enough.
	$Fade_transition.show()
	$Fade_transition/AnimationPlayer.play("Fade_out")
	ske_menu.play("Skeleton Idle")

func _on_start_pressed():
	button_type = "start"
	$Fade_transition.show()
	$Fade_transition/Fade_timer.start()
	$Fade_transition/AnimationPlayer.play("Fade_in")
	# REMOVED GameManager.start_game() from here. 
	# We wait for the timer to finish first!

func _on_setting_pressed():
	button_type = "setting"
	$Fade_transition.show()
	$Fade_transition/Fade_timer.start() # Changed .setting() to .start() assuming it's a Timer
	$Fade_transition/AnimationPlayer.play("Fade_in")

func _on_quit_pressed():
	get_tree().quit()

func _on_fade_timer_timeout():
	print("TIMER FINISHED! ATTEMPTING TO SWITCH SCENE...") # <--- Add this
	if button_type == "start" :
		GameManager.start_game()
	elif button_type == "setting" :
		pass
