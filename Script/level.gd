extends Node2D

# --- NODES ---
@onready var spawner = $Spawner
@onready var hud = $UI_Layer/HUD 

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
	
	# (Note: We don't need to pause GameManager.is_day_active anymore, 
	# because the wave hasn't started yet.)

func _process(delta):
	if is_setup_phase:
		setup_time -= delta
		
		# Update the UI Label (Make sure HUD has this function)
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
	
	# 2. Initialize the Wave Data in GameManager
	# (This resets the customer counts for the new level)
	GameManager.start_day()
	
	# 3. Start the Spawner
	if spawner:
		# We call this NOW because Level.gd already did the waiting
		spawner.start_spawning()
