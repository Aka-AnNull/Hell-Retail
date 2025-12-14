extends Control

# --- NODES ---
@onready var panel_1 = $Panel1
@onready var panel_2 = $Panel2
@onready var panel_3 = $Panel3
@onready var scam_label = $ScamLabel
@onready var black_overlay = $BlackOverlay
@onready var game_logo = $GameLogo
@onready var end_ui = $EndUI
@onready var main_menu_button = $EndUI/MainMenuButton

# --- SETTINGS ---
var fade_speed = 1.0 # How fast items fade in (1 second)

func _ready():
	# 1. Setup Initial States (Make sure everything is invisible)
	panel_1.modulate.a = 0.0
	panel_2.modulate.a = 0.0
	scam_label.modulate.a = 0.0
	black_overlay.modulate.a = 0.0
	game_logo.modulate.a = 0.0
	end_ui.modulate.a = 0.0
	
	# Disable button so you can't click it while invisible
	main_menu_button.disabled = true
	
	# 2. Start the Music (Optional)
	if SoundManager:
		SoundManager.play_music("Theend") # Or whatever your sad/happy song is
	
	# 3. Start the Sequence
	start_ending_sequence()

func start_ending_sequence():
	# Create a Tween to handle the timeline
	var tween = create_tween()
	
	# --- STEP 1: Fade In Panel 1 (Jumo Ascend) ---
	tween.tween_property(panel_1, "modulate:a", 1.0, fade_speed)
	# Wait 4 seconds
	tween.tween_interval(4.0)
	
	# --- STEP 2: Fade In Panel 2 (We grab Jumo hand) ---
	tween.tween_property(panel_2, "modulate:a", 1.0, fade_speed)
	# Wait 4 seconds
	tween.tween_interval(4.0)
	
	# --- STEP 3: Label shows "It not a scam after all" ---
	tween.tween_property(panel_3, "modulate:a", 1.0, fade_speed)
	tween.tween_property(scam_label, "modulate:a", 1.0, fade_speed)
	# Wait 6 seconds (Long pause for emotional effect)
	tween.tween_interval(7.0)
	
	# --- STEP 4: Fade in Black Overlay (Covers everything) ---
	tween.tween_property(black_overlay, "modulate:a", 1.0, 2.0) # Slower fade (2s)
	# Wait 2 seconds
	tween.tween_interval(2.0)
	
	# --- STEP 5: Fade in Game Logo ---
	tween.tween_property(game_logo, "modulate:a", 1.0, fade_speed)
	# Wait 2 seconds
	tween.tween_interval(2.0)
	
	# --- STEP 6: Fade in "The End" and Button ---
	tween.tween_property(end_ui, "modulate:a", 1.0, fade_speed)
	# Now allow clicking
	tween.tween_callback(enable_button)

func enable_button():
	main_menu_button.disabled = false
	# Optional: Grab focus for keyboard support
	main_menu_button.grab_focus()

func _on_main_menu_button_pressed():
	# Play click sound
	if SoundManager:
		SoundManager.play_sfx("ui_click")
	SoundManager.fade_out_music(0.5)
	await get_tree().create_timer(0.5).timeout
	# Go back to Main Menu (Replace with your actual Main Menu path)
	get_tree().change_scene_to_file("res://Scene/main_menu.tscn")


func _on_main_menu_button_mouse_entered() -> void:
	SoundManager.play_sfx("ui_hover")
