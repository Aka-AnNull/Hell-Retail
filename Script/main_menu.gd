extends Node2D

var button_type = null

# --- NODES ---
@onready var ske_menu = $"Skeleton Menu"
@onready var hover_sfx = $HoverSFX
@onready var click_sfx = $ClickSFX

# Add this line! Make sure the node name matches your scene tree
@onready var settings_menu = $SettingsMenu 

func _ready():
	$Fade_transition.show()
	$Fade_transition/AnimationPlayer.play("Fade_out")
	ske_menu.play("Skeleton Idle")
	
	# Make sure settings are hidden at start
	if settings_menu:
		settings_menu.visible = false

# --- BUTTONS ---

func _on_start_pressed():
	click_sfx.play()
	button_type = "start"
	$Fade_transition.show()
	$Fade_transition/Fade_timer.start()
	$Fade_transition/AnimationPlayer.play("Fade_in")

func _on_setting_pressed():
	click_sfx.play()
	# NO FADE NEEDED. Just open the popup directly.
	settings_menu.open_settings()

func _on_quit_pressed():
	click_sfx.play()
	await click_sfx.finished
	# We can keep the fade for quitting if you like the dramatic exit
	$Fade_transition.show() 
	$Fade_transition/AnimationPlayer.play("Fade_in")
	await $Fade_transition/AnimationPlayer.animation_finished
	get_tree().quit()

# --- TIMER (Only for Scene Changes) ---

func _on_fade_timer_timeout():
	print("TIMER FINISHED! ATTEMPTING TO SWITCH SCENE...")
	
	if button_type == "start":
		GameManager.start_game()
	
	# We removed "setting" from here because it doesn't use the timer anymore.

# --- HOVER SFX ---
func _on_start_mouse_entered() -> void:
	hover_sfx.play()
func _on_setting_mouse_entered() -> void:
	hover_sfx.play()
func _on_quit_mouse_entered() -> void:
	hover_sfx.play()
