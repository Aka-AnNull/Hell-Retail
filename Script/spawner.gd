extends Node2D

# --- SETTINGS ---
@export var ghost_scene : PackedScene 
@export var zombie_scene : PackedScene 
@export var small_bird_scene : PackedScene
@export var slime_scene : PackedScene
@export var reaper_scene : PackedScene
@export var long_bird_scene : PackedScene

# This defaults to 5.0, but GameManager will override it
@export var default_spawn_interval : float = 5.0 

@onready var timer = $Timer

func _ready():
	timer.stop()
	if not timer.timeout.is_connected(spawn_customer):
		timer.timeout.connect(spawn_customer)

func start_spawning(total_limit, time_interval):
	print("Spawner: Wave Begins! Goal: %d Customers, Rate: %.1f" % [total_limit, time_interval])

	timer.wait_time = time_interval

	timer.start()

	spawn_customer()

func stop_spawning():
	print("Spawner: Quota reached. Stopping.")
	timer.stop()

func spawn_customer():
	# 1. STOP IF LIMIT REACHED
	if GameManager.customers_spawned >= GameManager.total_customers_for_level:
		stop_spawning()
		return

	# 2. SAFETY CHECK (Just checking ghost as a baseline)
	if ghost_scene == null:
		print("ERROR: Ghost Scene missing! (At least one scene is needed)")
		return
		
	# 3. CHOOSE CUSTOMER TYPE BASED ON LEVEL
	var scene_to_spawn = ghost_scene # Default fallback
	var current_lvl = GameManager.current_level
	var roll = randf() # Returns 0.0 to 1.0
	
	match current_lvl:
		1:
			# LEVEL 1: 100%
			if ghost_scene: scene_to_spawn = ghost_scene
			
		2:
			# LEVEL 2: 30% Zombie, 70% Ghost
			if zombie_scene and roll <= 0.3:
				scene_to_spawn = zombie_scene
			else:
				scene_to_spawn = ghost_scene
				
		3:
			# LEVEL 3: 30% Zombie, 30% Ghost, 40% Small bird
			if zombie_scene and roll <= 0.3:
				scene_to_spawn = zombie_scene
			elif ghost_scene and roll <= 0.6:
				scene_to_spawn = ghost_scene
			elif small_bird_scene:
				scene_to_spawn = small_bird_scene
				
		4:
			# LEVEL 4: 50% Slime, 50% Zombie
			if slime_scene and roll <= 0.5:
				scene_to_spawn = slime_scene
			elif zombie_scene:
				scene_to_spawn = zombie_scene
				
		5:
			# LEVEL 5: 30% Slime, 30% Zombie, 40% Ghost
			if slime_scene and roll <= 0.3:
				scene_to_spawn = slime_scene
			elif zombie_scene and roll <= 0.6:
				scene_to_spawn = zombie_scene
			else:
				scene_to_spawn = ghost_scene
				
		6:
			# LEVEL 6: 20% Reaper, 80% Mix
			if reaper_scene and roll <= 0.2:
				scene_to_spawn = reaper_scene
			elif slime_scene and roll <= 0.6:
				scene_to_spawn = slime_scene
			else:
				scene_to_spawn = zombie_scene
				
		7:
			# LEVEL 7 (HELL RETAIL): Everything! High Reaper chance.
			if reaper_scene and roll <= 0.3:
				scene_to_spawn = reaper_scene
			elif slime_scene and roll <= 0.5:
				scene_to_spawn = slime_scene
			elif zombie_scene and roll <= 0.7:
				scene_to_spawn = zombie_scene
			else:
				scene_to_spawn = ghost_scene
				
		_:
			# FALLBACK: Just Ghost
			scene_to_spawn = ghost_scene

	# 4. INSTANTIATE AND ADD
	var new_customer = scene_to_spawn.instantiate()
	new_customer.global_position = global_position 
	get_parent().add_child(new_customer)
	
	# 5. TELL GAMEMANAGER
	GameManager.on_customer_spawned()
