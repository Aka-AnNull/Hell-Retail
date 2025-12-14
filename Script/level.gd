extends Node2D

# --- NODES ---
@onready var spawner = $Spawner
@onready var hud = $UI_Layer/HUD
@onready var incoming_label = $UI_Layer/IncomingLabel 

# --- SETUP VARIABLES ---
# CHANGED: Set to 3.0 for testing (Change back to 21.0 when done!)
var setup_time : float = 21.0 
var is_setup_phase : bool = true

func _ready():
	# ---------------------------------------------------------
	# 1. PLAY MUSIC IMMEDIATELY (The Fix)
	# ---------------------------------------------------------
	var lvl = GameManager.current_level
	var track_name = "level" # Default fallback
	
	if GameManager.level_data.has(lvl):
		track_name = GameManager.level_data[lvl].get("music", "level")
	
	print("Level: Scene Loaded. Playing Music -> ", track_name)
	SoundManager.play_music(track_name)

	# ---------------------------------------------------------
	# 2. TRANSITION SETUP
	# ---------------------------------------------------------
	if not GameManager.request_level_transition.is_connected(_on_transition_requested):
		GameManager.request_level_transition.connect(_on_transition_requested)

	if has_node("Fade_transition/AnimationPlayer"):
		$Fade_transition.show()
		$Fade_transition/AnimationPlayer.play("Fade_out")

	# ---------------------------------------------------------
	# 3. ANIMATE DECORATIONS
	# ---------------------------------------------------------
	var torches = get_tree().get_nodes_in_group("Torches")
	for torch in torches:
		if torch is AnimatedSprite2D:
			torch.play("default")

	# ---------------------------------------------------------
	# 4. START SETUP PHASE
	# ---------------------------------------------------------
	print("Level: Setup Phase Started.")
	is_setup_phase = true
	
	if spawner:
		spawner.stop_spawning()

	# ---------------------------------------------------------
	# 5. CONNECT PLAYER ABILITY
	# ---------------------------------------------------------
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		if player.has_signal("ability_activated"):
			player.ability_activated.connect(trigger_equalizer_skill)
		else:
			print("Level: Player missing 'ability_activated' signal!")
	else:
		print("Level: Player node not found!")

func _process(delta):
	# ---------------------------------------------------------
	# 1. TIMER LOGIC
	# ---------------------------------------------------------
	if is_setup_phase:
		setup_time -= delta
		
		if hud:
			hud.update_countdown(setup_time)
		
		if setup_time <= 0:
			start_actual_wave()
			
	# ---------------------------------------------------------
	# 2. INCOMING MONSTER COUNTER
	# ---------------------------------------------------------
	if incoming_label:
		var display_number = 0
		
		if is_setup_phase:
			var lvl = GameManager.current_level
			if GameManager.level_data.has(lvl):
				display_number = GameManager.level_data[lvl]["spawn_count"]
			else:
				display_number = 5 
		else:
			var total = GameManager.total_customers_for_level
			var spawned = GameManager.customers_spawned
			display_number = total - spawned
		
		# Boss Logic
		if GameManager.current_level == 7:
			display_number += 1
		
		if display_number < 0: display_number = 0
		incoming_label.text = str(display_number)
func start_actual_wave():
	is_setup_phase = false
	print("Level: SHOP OPEN! Wave Incoming.")
	
	if hud:
		hud.show_game_ui()
	
	GameManager.start_day()

# ---------------------------------------------------------
# --- SKILL LOGIC -----------------------------------------
# ---------------------------------------------------------

func trigger_equalizer_skill():
	print("Level: Received Skill Signal! Balancing shelves...")
	
	var all_shelves = get_tree().get_nodes_in_group("Shelves")
	
	if all_shelves.size() > 0:
		GameManager.activate_equalizer_skill(all_shelves)
	else:
		print("ERROR: No shelves found! Make sure Shelf.gd has add_to_group('Shelves').")

# ---------------------------------------------------------
# --- TRANSITION LOGIC ------------------------------------
# ---------------------------------------------------------

func _on_transition_requested():
	print("Level: Transition requested. Fading to black...")
	
	if has_node("Fade_transition/AnimationPlayer"):
		$Fade_transition.show()
		var anim = $Fade_transition/AnimationPlayer
		
		anim.play("Fade_in")
		
		await anim.animation_finished
		
		GameManager.change_scene_now()
	else:
		GameManager.change_scene_now()
