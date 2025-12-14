extends Node2D

var button_type = null
@onready var ske_menu = $"Skeleton Menu"
@onready var hover_sfx = $HoverSFX
@onready var click_sfx = $ClickSFX

func _ready():
	$Fade_transition.show()
	$Fade_transition/AnimationPlayer.play("Fade_out")
	ske_menu.play("Skeleton Idle")

func _on_start_pressed():
	click_sfx.play()
	button_type = "start"
	$Fade_transition.show()
	$Fade_transition/Fade_timer.start()
	$Fade_transition/AnimationPlayer.play("Fade_in")

func _on_setting_pressed():
	click_sfx.play()
	button_type = "setting"
	$Fade_transition.show()
	$Fade_transition/Fade_timer.start()
	$Fade_transition/AnimationPlayer.play("Fade_in")

func _on_quit_pressed():
	click_sfx.play()
	await click_sfx.finished
	$Fade_transition/AnimationPlayer.play("Fade_in")
	await $Fade_transition/AnimationPlayer.animation_finished
	get_tree().quit()

func _on_fade_timer_timeout():
	print("TIMER FINISHED! ATTEMPTING TO SWITCH SCENE...")
	
	if button_type == "start":
		# Just call the manager! It handles the rest.
		GameManager.start_game()
		
	elif button_type == "setting":
		pass

func _on_start_mouse_entered() -> void:
	hover_sfx.play()
func _on_setting_mouse_entered() -> void:
	hover_sfx.play()
func _on_quit_mouse_entered() -> void:
	hover_sfx.play()
