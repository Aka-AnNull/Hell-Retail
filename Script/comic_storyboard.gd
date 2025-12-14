extends Control

# --- CONFIGURATION ---
@export var comic_images : Array[Texture2D] 
@export var reveal_time : float = 3.0
@export_file("*.tscn") var next_scene_path : String 

# --- NODES ---
@onready var grid = $VBoxContainer/GridContainer
# Use "SkipButton" or "Button" depending on your scene tree name
@onready var next_button = $VBoxContainer/SkipButton 
@onready var timer = $Timer
@onready var fade_overlay = $FadeOverlay # <--- NEW NODE

# --- STATE ---
var panels : Array[TextureRect] = []
var current_panel_index : int = 0
var max_panels : int = 0 

func _ready():
	# -----------------------------------------------------
	# 1. SCENE START TRANSITION (Black -> Clear)
	# -----------------------------------------------------
	fade_overlay.visible = true
	fade_overlay.color.a = 1.0 # Start fully black
	
	var start_tween = create_tween()
	start_tween.tween_property(fade_overlay, "color:a", 0.0, 1.5) # Fade to transparent over 1s
	# -----------------------------------------------------

	# 2. Grab all TextureRects
	for child in grid.get_children():
		if child is TextureRect:
			panels.append(child)
			
	max_panels = comic_images.size()
	print("DEBUG: Found ", max_panels, " images.") 

	# 3. Setup Images & Transparency
	for i in range(panels.size()):
		if i < max_panels:
			panels[i].texture = comic_images[i]
			
			if i == 0:
				panels[i].modulate.a = 1.0 
			else:
				panels[i].modulate.a = 0.0 
		else:
			panels[i].visible = false 

	# 4. Connect Button
	if not next_button.pressed.is_connected(_on_button_pressed):
		next_button.pressed.connect(_on_button_pressed)

	# 5. Start Timer
	if max_panels > 0:
		timer.wait_time = reveal_time
		if not timer.timeout.is_connected(reveal_next_panel):
			timer.timeout.connect(reveal_next_panel)
		timer.start()

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		reveal_next_panel()

func reveal_next_panel():
	if current_panel_index >= max_panels - 1:
		return

	current_panel_index += 1
	
	# Image Fade In Effect
	var tween = create_tween()
	tween.tween_property(panels[current_panel_index], "modulate:a", 1.0, 0.5)
	
	timer.start() 
	
	if current_panel_index == max_panels - 1: 
		finish_comic_state()

func finish_comic_state():
	timer.stop()
	next_button.text = "CONTINUE >>"

func _on_button_pressed():
	# -----------------------------------------------------
	# SCENE END TRANSITION (Clear -> Black)
	# -----------------------------------------------------
	next_button.disabled = true # Prevent double clicks
	
	var end_tween = create_tween()
	end_tween.tween_property(fade_overlay, "color:a", 1.0, 1.5) # Fade to black over 0.5s
	
	# Wait for the fade to finish
	await end_tween.finished
	
	# NOW change the scene
	if next_scene_path:
		get_tree().change_scene_to_file(next_scene_path)
	else:
		get_tree().change_scene_to_file("res://Scene/main_menu.tscn")
