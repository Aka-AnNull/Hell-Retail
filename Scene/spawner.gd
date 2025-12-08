extends Node2D

# --- SETTINGS ---
# IMPORTANT: Drag your Ghost.tscn here in the Inspector!
@export var customer_scene : PackedScene 
@export var spawn_interval : float = 5.0

@onready var timer = $Timer

func _ready():
	# We do NOT start automatically.
	# We wait for Level.gd to call start_spawning()
	pass

func start_spawning():
	print("Spawner: Shop Open! Customers incoming for Level " + str(GameManager.current_level))
	
	# Reset timer settings
	timer.wait_time = spawn_interval
	
	# Connect if not already connected
	if not timer.timeout.is_connected(spawn_customer):
		timer.timeout.connect(spawn_customer)
		
	timer.start()

func stop_spawning():
	print("Spawner: Stopping.")
	timer.stop()

func spawn_customer():
	if customer_scene == null:
		print("ERROR: No customer scene assigned in Spawner Inspector!")
		return
		
	# 1. Create Customer
	var new_customer = customer_scene.instantiate()
	
	# 2. Apply Level Difficulty (Speed Multiplier)
	var current_lvl = GameManager.current_level
	if current_lvl in GameManager.level_data:
		var settings = GameManager.level_data[current_lvl]
		if "customer_speed" in settings:
			# Base speed (120) * Multiplier
			new_customer.move_speed = 120.0 * settings["customer_speed"]
	
	# 3. Add to the Level
	get_parent().add_child(new_customer)
