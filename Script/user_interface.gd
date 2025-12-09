extends Control

@export var full_heart_texture : Texture2D
@export var empty_heart_texture : Texture2D

@onready var container = $HeartContainer
@onready var setup_label = $SetupLabel # <--- NEW

func _ready():
	GameManager.hp_changed.connect(update_hearts)
	update_hearts(GameManager.current_hp)
	
	# Start hidden (Wait for setup phase to finish)
	container.visible = false 
	setup_label.visible = false

func update_hearts(current_hp):
	var hearts = container.get_children()
	for i in range(hearts.size()):
		if i < current_hp:
			hearts[i].texture = full_heart_texture
		else:
			hearts[i].texture = empty_heart_texture

# --- NEW FUNCTIONS FOR LEVEL SCRIPT ---

func update_countdown(time_left):
	setup_label.visible = true
	setup_label.text = "SHOP OPENS IN: " + str(int(time_left))

func show_game_ui():
	setup_label.visible = false # Hide countdown
	container.visible = true    # Show hearts
