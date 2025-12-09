extends Node2D

# --- SETTINGS ---
@export var customer_scene : PackedScene 
@export var default_spawn_interval : float = 5.0 

@onready var timer = $Timer

func _ready():
	pass

func start_spawning():
	# REMOVED the 'await' here because Level.gd handles the wait!
	
	var current_lvl = GameManager.current_level
	var rate = default_spawn_interval
	
	# Get Spawn Rate from GameManager Level Data
	if current_lvl in GameManager.level_data:
		var settings = GameManager.level_data[current_lvl]
		if "spawn_rate" in settings:
			rate = settings["spawn_rate"]
			
	print("Spawner: Wave %d Begins! Goal: %d Ghosts" % [
		current_lvl, GameManager.total_customers_for_level
	])
	
	# Configure Timer
	timer.wait_time = rate
	
	if not timer.timeout.is_connected(spawn_customer):
		timer.timeout.connect(spawn_customer)
		
	timer.start()
	
	# Spawn the first one immediately so the shop isn't empty
	spawn_customer()

func stop_spawning():
	print("Spawner: Quota reached. Stopping.")
	timer.stop()

func spawn_customer():
	# 1. COUNT CHECK: Do we have enough customers?
	if GameManager.customers_spawned >= GameManager.total_customers_for_level:
		stop_spawning()
		return

	if customer_scene == null:
		print("ERROR: No customer scene assigned in Spawner Inspector!")
		return
		
	# 2. SPAWN
	var new_customer = customer_scene.instantiate()
	get_parent().add_child(new_customer)
	
	# 3. UPDATE MANAGER
	GameManager.on_customer_spawned()
	
	# 4. FINAL CHECK
	if GameManager.customers_spawned >= GameManager.total_customers_for_level:
		stop_spawning()
