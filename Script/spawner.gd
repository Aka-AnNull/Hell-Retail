extends Node2D

# --- SETTINGS ---
@export var ghost_scene : PackedScene 
@export var zombie_scene : PackedScene 
@export var default_spawn_interval : float = 5.0 

@onready var timer = $Timer

func _ready():
	pass

func start_spawning():
	var current_lvl = GameManager.current_level
	var rate = default_spawn_interval
	
	# Get Spawn Rate from GameManager Level Data
	if current_lvl in GameManager.level_data:
		var settings = GameManager.level_data[current_lvl]
		if "spawn_rate" in settings:
			rate = settings["spawn_rate"]
			
	print("Spawner: Wave %d Begins! Goal: %d Customers" % [
		current_lvl, GameManager.total_customers_for_level
	])
	
	# Configure Timer
	timer.wait_time = rate
	
	if not timer.timeout.is_connected(spawn_customer):
		timer.timeout.connect(spawn_customer)
		
	timer.start()
	
	# Spawn the first one immediately
	spawn_customer()

func stop_spawning():
	print("Spawner: Quota reached. Stopping.")
	timer.stop()

func spawn_customer():
	# 1. COUNT CHECK
	if GameManager.customers_spawned >= GameManager.total_customers_for_level:
		stop_spawning()
		return

	if ghost_scene == null:
		print("ERROR: No Ghost Scene assigned in Spawner Inspector!")
		return
		
	# 2. CHOOSE CUSTOMER TYPE BASED ON LEVEL
	var scene_to_spawn = ghost_scene # Default fallback
	var level = GameManager.current_level
	var roll = randf() # Returns 0.0 to 1.0
	
	match level:
		1:
			# LEVEL 1: 100% Ghost
			scene_to_spawn = zombie_scene
			
		2:
			# LEVEL 2: 30% Zombie, 70% Ghost
			if zombie_scene and roll <= 0.3:
				scene_to_spawn = zombie_scene
			else:
				scene_to_spawn = ghost_scene
				
		3:
			# LEVEL 3: (Currently same as Lvl 2 - Change this later for Birds!)
			if zombie_scene and roll <= 0.3:
				scene_to_spawn = zombie_scene
			else:
				scene_to_spawn = ghost_scene
				
		4:
			# LEVEL 4: (Currently same as Lvl 2 - Change this later!)
			if zombie_scene and roll <= 0.3:
				scene_to_spawn = zombie_scene
			else:
				scene_to_spawn = ghost_scene
				
		5:
			# LEVEL 5: (Currently same as Lvl 2 - Change this later!)
			if zombie_scene and roll <= 0.3:
				scene_to_spawn = zombie_scene
			else:
				scene_to_spawn = ghost_scene
				
		6:
			# LEVEL 6: (Currently same as Lvl 2 - Change this later!)
			if zombie_scene and roll <= 0.3:
				scene_to_spawn = zombie_scene
			else:
				scene_to_spawn = ghost_scene
				
		7:
			# LEVEL 7: (Currently same as Lvl 2 - Change this later!)
			if zombie_scene and roll <= 0.3:
				scene_to_spawn = zombie_scene
			else:
				scene_to_spawn = ghost_scene
				
		_:
			# FALLBACK (Level 8+): Just do Level 2 logic
			if zombie_scene and roll <= 0.3:
				scene_to_spawn = zombie_scene
			else:
				scene_to_spawn = ghost_scene

	# 3. SPAWN
	var new_customer = scene_to_spawn.instantiate()
	new_customer.global_position = global_position 
	get_parent().add_child(new_customer)
	
	# 4. UPDATE MANAGER
	GameManager.on_customer_spawned()
	
	# 5. FINAL CHECK
	if GameManager.customers_spawned >= GameManager.total_customers_for_level:
		stop_spawning()
