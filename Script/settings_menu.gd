extends CanvasLayer

signal menu_closed

# --- NODES ---
@onready var master_slider = $Window/SliderBox/MasterSlider
@onready var music_slider = $Window/SliderBox/MusicSlider
@onready var sfx_slider = $Window/SliderBox/SFXSlider
@onready var back_button = $Window/BackButton 

# --- BUS INDICES ---
var master_bus_index
var music_bus_index
var sfx_bus_index

func _ready():
	visible = false
	
	# 1. GET BUS INDICES
	master_bus_index = AudioServer.get_bus_index("Master")
	music_bus_index = AudioServer.get_bus_index("Music")
	sfx_bus_index = AudioServer.get_bus_index("SFX")
	
	# --- ADD THIS: FORCE SFX TO 50% ---
	# We set the actual audio volume to 0.5 (50%) immediately
	AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(0.5))
	
	# 2. SET SLIDERS
	# The sliders will now read the values we just set
	master_slider.value = db_to_linear(AudioServer.get_bus_volume_db(master_bus_index))
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_bus_index))
	
	# This will now automatically become 0.5 because we set the AudioServer above
	sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_bus_index))

# --- OPEN/CLOSE ---
func open_settings():
	visible = true

func close_settings():
	visible = false

# --- SIGNALS ---

func _on_master_slider_value_changed(value):
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(value))

func _on_music_slider_value_changed(value):
	AudioServer.set_bus_volume_db(music_bus_index, linear_to_db(value))

func _on_sfx_slider_value_changed(value):
	AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(value))

func _on_back_button_pressed():
	SoundManager.play_sfx("ui_click")
	close_settings()
	menu_closed.emit()

func _on_back_button_mouse_entered() -> void:
	SoundManager.play_sfx("ui_hover")
