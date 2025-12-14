extends CanvasLayer

@onready var settings_menu = $SettingsMenu
@onready var content = $CenterContainer

func _ready():
	visible = false
	settings_menu.visible = false
	
	# 1. CONNECT THE SIGNAL
	# When settings says "menu_closed", run "_on_settings_closed"
	if not settings_menu.menu_closed.is_connected(_on_settings_closed):
		settings_menu.menu_closed.connect(_on_settings_closed)

func _on_settings_closed():
	# The settings just closed, so show the Pause Buttons again!
	content.visible = true
	
func _input(event):
	if event.is_action_pressed("ui_cancel"): # ESC Key
		toggle_pause()

func toggle_pause():
	# 1. Close Settings if open
	if settings_menu.visible:
		settings_menu.close_settings()
		content.visible = true
		return

	# 2. Toggle Pause
	visible = not visible
	get_tree().paused = visible
	
	if visible:
		content.visible = true

# --- BUTTONS ---
# Make sure you connected the TextureButton signals to these!

func _on_resume_button_pressed():
	SoundManager.play_sfx("ui_click")
	toggle_pause()

func _on_restart_button_pressed():
	SoundManager.play_sfx("ui_click")
	toggle_pause() # Unpause first!
	GameManager.current_hp = GameManager.max_hp
	if GameManager.current_level == 8:
		get_tree().change_scene_to_file("res://Scene/BossFight.tscn")
	else:
		get_tree().change_scene_to_file("res://Scene/level.tscn")

func _on_settings_button_pressed():
	SoundManager.play_sfx("ui_click")
	content.visible = false # Hide buttons so they don't block the settings
	settings_menu.open_settings()

func _on_quit_button_pressed():
	SoundManager.play_sfx("ui_click")
	toggle_pause()
	get_tree().change_scene_to_file("res://Scene/main_menu.tscn")


func _on_resume_button_mouse_entered() -> void:
	SoundManager.play_sfx("ui_hover")
func _on_restart_button_mouse_entered() -> void:
	SoundManager.play_sfx("ui_hover")
func _on_settings_button_mouse_entered() -> void:
	SoundManager.play_sfx("ui_hover")
func _on_quit_button_mouse_entered() -> void:
	SoundManager.play_sfx("ui_hover")
