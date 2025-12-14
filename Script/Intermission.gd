extends Control

# --- EXISTING NODES (Header & Fade) ---
@onready var level_label = $LevelLabel
@onready var fade_anim = $Fade_transition/AnimationPlayer

# --- NEW SLIDE NODES (The Middle Section) ---
@onready var left_btn = $HBoxContainer/LeftButton
@onready var right_btn = $HBoxContainer/RightButton

# The two different "Modes" inside the panel
@onready var image_mode_group = $HBoxContainer/SlidePanel/ImageMode
@onready var slide_image = $HBoxContainer/SlidePanel/ImageMode/SlideImage
@onready var side_label = $HBoxContainer/SlidePanel/ImageMode/SideLabel

@onready var text_mode_label = $HBoxContainer/SlidePanel/TextMode

# --- DATA: SLIDES CONFIGURATION ---
# Level Number : List of Slides
# Slide Format: { "text": "...", "image": "path/to/image.png" }
# If you want Text Only, leave "image": "" (empty string).
var slide_data = {
	1: [
		{"text": "[center][font_size=72][b]Welcome to tutorial![/b][/font_size]\n\n\n\n\n[font_size=48]You can skip this by press SPACE.[/font_size][/center]", "image": ""},
		{"text": "[center][font_size=72]Objective:[/font_size]\n\n\n\n[font_size=36]The player manages a shop by keeping shelves filled with stock items so customers can take what they need. Each customer has a patience limit, and if it runs out before they are satisfied, the player receives damage. The player must manage time and resources carefully to complete 7 working days.[/font_size][/center]", "image": ""},
		{"text": "[left][font_size=48]Use WASD to Move.\nPress SPACE to dash.[/font_size][/left]", "image": "res://Sprite/Intermission/intermission_3.png"},
		{"text": "[left][font_size=60]Press E to \ntake from stock.\n[/font_size][/left]", "image": "res://Sprite/Intermission/intermission.png"},
		{"text": "[left][font_size=60]Press Q to Discard the item.\n[/font_size][font_size=48] -If you somehow \n  pick up wrong item.[/font_size][/left]", "image": "res://Sprite/Intermission/intermission_4.png"},
		{"text": "[left][font_size=60]Press E to \nrestock shelf.\n[/font_size][font_size=48] -Follow the arrows, \n  as each item has \n  its designated \n  shelf.[/font_size][/left]", "image": "res://Sprite/Intermission/intermission_2.png"},
		{"text": "[center][font_size=60][b]There are 7 shelves in the shop. Each shelf has its own stock item.[/b][/font_size][/center]", "image": ""},
		{"text": "[left][font_size=60]Press E at the cashier.\n[/font_size][font_size=48] -to serve \n  customers when \n  they are \n  waiting in line.[/font_size][/left]", "image": "res://Sprite/Intermission/intermission_5.png"},
		{"text": "[left][font_size=60]Serve Customer.\n[/font_size][font_size=48] -you must click \n  5 coins at \n  the cashier.[/font_size][/left]", "image": "res://Sprite/Intermission/intermission_6.png"},
		{"text": "[left][font_size=72]Player Hitpoint.\n[/font_size][font_size=48]The player has 10 hit points (HP), which decrease when customer angry.[/font_size][/left]", "image": "res://Sprite/player/HP.png"},
		{"text": "[left][font_size=72]Hitpoint reach zero.\n[/font_size][font_size=48]will result in Gameover.[/font_size][/left]", "image": "res://Sprite/player/HPlose.png"},
		{"text": "[left][font_size=72]Customers\n[/font_size][font_size=48]Customers enter the shop, take the items they need from the shelves, and then pay at the cashier.[/font_size][/left]", "image": "res://Sprite/Intermission/intermission_7.png"},
		{"text": "[left][font_size=60]Beware that customers have a patience limit.\n[/font_size][font_size=48]If it reaches the maximum, you will take damage, and some customers may punish you.[/font_size][/left]", "image": "res://Sprite/Customer/Ghost/pixil-layer-Layer 1 (1).png"},
		{"text": "[left][font_size=60]Beware that the cashier line has a limit.\n[/font_size][font_size=48]When the line is full, customers become angry instantly, and some may punish you.[/font_size][/left]", "image": "res://Sprite/Intermission/intermission_8.png"},
		{"text": "[left][font_size=72]Ghost.\n[/font_size][font_size=48]Our first customer has an average patience of 10 seconds and will randomly take 1 items from the 7 shelves.[/font_size][/left]", "image": "res://Sprite/Customer/Ghost/Ghost1.png"},
		{"text": "[center][font_size=84]Good luck \non your first day!.[/font_size][/center]", "image": ""},
	],
	2: [
		{"text": "[left][font_size=72]Zombie.\n[/font_size][font_size=48]The Zombie has a patience of 7.5 seconds and will slowly move through the shop, randomly [color=red]taking 2 items[/color] from the 4 middle shelves.[/font_size][/left]", "image": "res://Sprite/Customer/Zombie/Zombie1.png"},
		{"text": "[left][font_size=72][color=red]Tombstone.[/color]\n[/font_size][font_size=48]When the zombie becomes angry, it places a tombstone that [color=red]blocks the player.[/color] Click the tombstone 5 times to destroy it.[/font_size][/left]", "image": "res://Sprite/Customer/Zombie/Tombstone.png"},
		{"text": "[left][font_size=72][color=gold]Watching Bird.[/color]\n[/font_size][font_size=48]A special entity appears around the map. [color=gold]Interact with it to gain a reward[/color]-move fast, as it won't stay for long!.[/font_size][/left]", "image": "res://Sprite/Customer/Watching_Bird/Watching1.png"},
		],
	3: [
		{"text": "[left][font_size=72]Recycler Slime.\n[/font_size][font_size=48]The Slime has a patience of 7.5 seconds and will slowly move through the shop, randomly [color=red]taking 2 items [/color]from the 3 wall shelves.[/font_size][/left]", "image": "res://Sprite/Customer/Slime/slime1.png"},
		{"text": "[left][font_size=72][color=red]Slime Puddle.[/color]\n[/font_size][font_size=48]When the Slime becomes angry, it places slime puddles randomly. [color=red]These puddles slow you down [/color]but dissolve after 10 seconds.[/font_size][/left]", "image": "res://Sprite/Customer/Slime/Puddle.png"},
		],
	4: [
		{"text": "[left][font_size=72]Small Bird.\n[/font_size][font_size=48]The Small Bird is fast and short-tempered, with the [color=red]lowest patience at 5 seconds.[/color] It randomly takes 1 item from the 7 shelves.[/font_size][/left]", "image": "res://Sprite/Customer/Small_Bird/SmallBird6.png"},
		{"text": "[left][font_size=60][color=red]High risk-reward[/color]\n[/font_size][font_size=48]Grants the player a 10 second speed boost when served perfectly, but will deal [color=red]2-3 damage[/color] if its patience reaches the maximum.[/font_size][/left]", "image": "res://Sprite/Customer/Small_Bird/SmallBird1.png"},
		],
	5: [
		{"text": "[left][font_size=72]Reaper.\n[/font_size][font_size=48]Has 15 seconds of patience and stays [color=red]invisible [/color]until satisfied or angry, taking 1 item from 2 different shelves out of the 7.[/font_size][/left]", "image": "res://Sprite/Customer/Reaper/Reaper2.png"},
		{"text": "[left][font_size=72][color=red]Soul Slash[/color]\n[/font_size][font_size=48]Slashes the player and stuns them for 2 seconds when angry while dealing at least [color=red]2 damage.[/color][/font_size][/left]", "image": "res://Sprite/Customer/Reaper/slash3.png"},
		{"text": "[left][font_size=60][color=Blue]Judgement Bird.[/color]\n[/font_size][font_size=48]It does not deal damage and stays for a long time. This is a strategic entity-use it wisely! \ntaking 1 item from 7 shelves.[/font_size][/left]", "image": "res://Sprite/Customer/Long_Bird/Birb1.png"},
		{"text": "[left][font_size=72][color=Blue]Justice[/color]\n[/font_size][font_size=48]Activates when facing an empty shelf within 5 seconds or by clicking it.\nEqualize all shelves.[/font_size][/left]", "image": "res://Sprite/Intermission/intermission_10.png"},
		{"text": "[left][font_size=72][color=Blue]Justice[/color]\n[/font_size][font_size=48]When the cashier line is full, it cuts the line in half and does not have a patience bar at the cashier.[/font_size][/left]", "image": "res://Sprite/Intermission/intermission_8.png"},
		],
	7: [
		{"text": "[center][font_size=72][color=red]You hear his laughter echoing in the distance.[/color][/font_size][/center]", "image": ""},
		],
}

# --- STATE ---
var current_slides = []
var slide_index = 0

func _ready():
	# -----------------------------------------------------
	# PART 1: TOP HEADER (Your Original Logic)
	# -----------------------------------------------------
	SoundManager.play_music("intermission_song")
	fade_anim.play("Fade_out")
	var current_lvl = GameManager.current_level
	
	# Check GameManager for the Level Title (e.g. "Level 1: Orientation")
	if GameManager.level_data.has(current_lvl):
		var data = GameManager.level_data[current_lvl]
		level_label.text = data["text"]
	else:
		level_label.text = "Level " + str(current_lvl)

	# -----------------------------------------------------
	# PART 2: MIDDLE SLIDES (New Logic)
	# -----------------------------------------------------
	# Load slides for the current level
	if current_lvl in slide_data:
		current_slides = slide_data[current_lvl]
	else:
		# Fallback if you forgot to add data
		current_slides = [{"text": "[center][font_size=72]Get ready for the shift![/font_size][/center]", "image": ""}]
	
	slide_index = 0
	update_slide_ui()

func update_slide_ui():
	# Get the data for the current slide
	var data = current_slides[slide_index]
	
	# LOGIC: Check if we have a valid image path
	if data["image"] != "" and ResourceLoader.exists(data["image"]):
		# --- MODE A: IMAGE + TEXT ---
		text_mode_label.visible = false       # Hide center text
		image_mode_group.visible = true       # Show image group
		
		slide_image.texture = load(data["image"])
		side_label.text = data["text"]
	else:
		# --- MODE B: TEXT ONLY ---
		image_mode_group.visible = false      # Hide image group
		text_mode_label.visible = true        # Show center text
		
		text_mode_label.text = data["text"]

	# BUTTONS: Hide Left if at start, Hide Right if at end
	if slide_index == 0:
		left_btn.disabled = true       # Can't click
		left_btn.modulate.a = 0.0      # Invisible (but still takes space)
	else:
		left_btn.disabled = false
		left_btn.modulate.a = 1.0      # Visible
	
	# 2. HANDLE RIGHT BUTTON
	if slide_index == current_slides.size() - 1:
		right_btn.disabled = true
		right_btn.modulate.a = 0.0
	else:
		right_btn.disabled = false
		right_btn.modulate.a = 1.0

# --- BUTTON SIGNALS ---
# Connect these in the Editor: Node Tab -> "pressed"
func _on_left_button_pressed():
	if slide_index > 0:
		slide_index -= 1
		SoundManager.play_sfx("button_click")
		update_slide_ui()

func _on_right_button_pressed():
	if slide_index < current_slides.size() - 1:
		slide_index += 1
		SoundManager.play_sfx("button_click")
		update_slide_ui()

func _process(_delta):
	# -----------------------------------------------------
	# PART 3: START LEVEL (Your Original Logic)
	# -----------------------------------------------------
	if Input.is_action_just_pressed("ui_accept"):
		SoundManager.fade_out_music(0.5)
		SoundManager.play_sfx("start")
		print("Starting Level...")
		fade_anim.play("Fade_in")
		await fade_anim.animation_finished
		GameManager.start_level_gameplay()
