extends Node2D

var button_type = null
@onready var ske_menu = $"Skeleton Menu"

func _ready():
	$Fade_transition/AnimationPlayer.play("Fade_out")
	ske_menu.play("Skeleton Idle")
func _on_start_pressed():
	button_type = "start"
	$Fade_transition.show()
	$Fade_transition/Fade_timer.start()
	$Fade_transition/AnimationPlayer.play("Fade_in")


func _on_setting_pressed():
	button_type = "setting"
	$Fade_transition.show()
	$Fade_transition/Fade_timer.setting()
	$Fade_transition/AnimationPlayer.play("Fade_in")


func _on_quit_pressed():
	get_tree().quit()


func _on_fade_timer_timeout():
	if button_type == "start" :
		get_tree().change_scene_to_file("res://Scene/level.tscn")
		
	elif button_type == "setting" :
		pass
