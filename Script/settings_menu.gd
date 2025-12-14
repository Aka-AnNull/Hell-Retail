extends CanvasLayer

signal menu_closed
# --- NODES ---
# Note the path change: We look inside Window/SliderBox now
@onready var master_slider = $Window/SliderBox/MasterSlider
@onready var music_slider = $Window/SliderBox/MusicSlider
@onready var sfx_slider = $Window/SliderBox/SFXSlider

# The button is now a direct child of Window, not in the VBox
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
	
	# 2. SET SLIDERS
	master_slider.value = db_to_linear(AudioServer.get_bus_volume_db(master_bus_index))
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_bus_index))
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
	close_settings()
	menu_closed.emit()
