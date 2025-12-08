extends Node2D

# --- NODES ---
# Make sure your Spawner node is named "Spawner"
@onready var spawner = $Spawner
# Make sure your HUD is inside a CanvasLayer named "UI_Layer"
@onready var hud = $UI_Layer/HUD 

# --- SETUP VARIABLES ---
var setup_time : float = 20.0
var is_setup_phase : bool = true

func _ready():
	# 1. OLD CODE: Play the transition animation
	if has_node("Fade_transition/AnimationPlayer"):
		$Fade_transition/AnimationPlayer.play("Fade_out")

	# 2. Start Setup Phase Logic
	print("Level: Setup Phase Started. Shop opens in 20s.")
	is_setup_phase = true
	
	# 3. Ensure the Game Clock is PAUSED
	GameManager.is_day_active = false

func _process(delta):
	if is_setup_phase:
		setup_time -= delta
		
		# Update the UI Label
		if hud:
			hud.update_countdown(setup_time)
		
		# CHECK IF TIMER FINISHED
		if setup_time <= 0:
			start_actual_game()

func start_actual_game():
	is_setup_phase = false
	print("Level: SHOP OPEN!")
	
	# 1. Update UI: Hide Timer, Show Hearts
	if hud:
		hud.show_game_ui()
	
	# 2. Start the Spawner
	if spawner:
		spawner.start_spawning()
		
	# 3. Start the Day Clock (9:00 AM)
	GameManager.start_day()

# Called every frame. 'delta' is the elapsed time since the previous frame.
