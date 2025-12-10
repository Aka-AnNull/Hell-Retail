extends Node2D

# --- NODES ---
@onready var spawner = $Spawner
@onready var hud = $UI_Layer/HUD

# (We removed the 'shelf_container' variable because we use Groups now)

# --- SETUP VARIABLES ---
var setup_time : float = 21.0
var is_setup_phase : bool = true

func _ready():
	# 1. Play Transition
	if has_node("Fade_transition/AnimationPlayer"):
		$Fade_transition/AnimationPlayer.play("Fade_out")

	# 2. Start Setup Phase
	print("Level: Setup Phase Started. Shop opens in 20s.")
	is_setup_phase = true
	
	# Ensure the spawner is STOPPED while we wait
	if spawner:
		spawner.stop_spawning()

	# 3. CONNECT PLAYER ABILITY
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		if player.has_signal("ability_activated"):
			player.ability_activated.connect(trigger_equalizer_skill)
			print("Level: Connected to Player Equalizer Skill.")
		else:
			print("Level: Player found, but missing 'ability_activated' signal!")
	else:
		print("Level: Player node not found in group 'Player'!")

func _process(delta):
	# --- TIMER LOGIC ---
	if is_setup_phase:
		setup_time -= delta
		
		# Update the UI Label
		if hud:
			hud.update_countdown(setup_time)
		
		# CHECK IF TIMER FINISHED
		if setup_time <= 0:
			start_actual_wave()

func start_actual_wave():
	is_setup_phase = false
	print("Level: SHOP OPEN! Wave Incoming.")
	
	# 1. Update UI: Hide Timer, Show Hearts/Wave Info
	if hud:
		hud.show_game_ui()
	
	# 2. START THE DAY via GameManager
	GameManager.start_day()

# ---------------------------------------------------------
# --- SKILL LOGIC -----------------------------------------
# ---------------------------------------------------------

func trigger_equalizer_skill():
	print("Level: Received Skill Signal! Balancing shelves...")
	
	# 1. Get ALL shelves using the Group (Works with your scene structure!)
	var all_shelves = get_tree().get_nodes_in_group("Shelves")
	
	# 2. Send them to GameManager to do the math
	if all_shelves.size() > 0:
		GameManager.activate_equalizer_skill(all_shelves)
	else:
		print("ERROR: No shelves found! Make sure Shelf.gd has add_to_group('Shelves').")
