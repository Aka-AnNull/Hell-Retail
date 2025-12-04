extends Control

# Drag your images into these slots in the Inspector!
@export var logo_1: Texture2D # Godot Logo
@export var logo_2: Texture2D # Uni Logo
@export var logo_3: Texture2D # Your Name

@onready var logo_display = $LogoDisplay
@onready var anim = $Fade_transition/AnimationPlayer

func _ready():
	# The screen starts Black (because of Fade_transition)
	# --- SHOW LOGO 1 ---
	logo_display.texture = logo_1
	await show_and_hide_logo()
	
	# --- SHOW LOGO 2 ---
	logo_display.texture = logo_2
	await show_and_hide_logo()
	
	# --- DONE! GO TO MENU ---
	# Make sure this path matches your actual Main Menu file!
	get_tree().change_scene_to_file("res://Scene/main_menu.tscn")

func show_and_hide_logo():
	# 1. Reveal the logo (Fade Out black overlay)
	anim.play("Fade_out")
	await anim.animation_finished
	
	# 2. Wait for 2 seconds so people can see it
	await get_tree().create_timer(1.0).timeout
	
	# 3. Hide the logo (Fade In black overlay)
	anim.play("Fade_in")
	await anim.animation_finished
	
	# 4. Small pause while screen is black before next logo
	await get_tree().create_timer(0.5).timeout
