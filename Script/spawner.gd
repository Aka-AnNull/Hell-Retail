extends Node2D

# --- SETTINGS ---
@export var ghost_scene : PackedScene 
@export var zombie_scene : PackedScene 
@export var small_bird_scene : PackedScene
@export var slime_scene : PackedScene
@export var reaper_scene : PackedScene
@export var long_bird_scene : PackedScene
@export var watching_bird_scene : PackedScene # <-- Make sure this is assigned!

@export var default_spawn_interval : float = 5.0 
@onready var timer = $Timer

# ---------------------------------------------------------
# --- 1. SPECIFIC SPAWN OVERRIDES (REPLACES CUSTOMER) ---
# ---------------------------------------------------------
# Format: LevelNumber: { CustomerNumber: "Name" }
var specific_spawns = {
	1: {
		1: "Ghost"
	},
	2: {
		1: "Zombie"
	},
	3: {
		1: "Slime"
	},
	4: {
		14: "LongBird"
	},
	5: { 
		12: "LongBird", 
		35: "LongBird" 
	},
	6: { 
		1: "SmallBird",
		12: "LongBird", 
		25: "LongBird" 
	},
	7: {
		12: "LongBird", 
		24: "LongBird",
		40: "Reaper" 
	}
}

# ---------------------------------------------------------
# --- 2. BONUS SPAWNS (SPAWNS ALONGSIDE CUSTOMER) ---
# ---------------------------------------------------------
# Format: LevelNumber: [List of Spawn Numbers]
# These numbers trigger a Watching Bird at a random marker
var bonus_spawns = {
	# Example: In Level 1, when Customer #2 spawns, a Bird also appears. 
	2: [9],
	3: [11],
	4: [14],
	5: [25,35],
	6: [17],
	7: [7,28]
}

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

	# 2. SAFETY CHECK
	if ghost_scene == null:
		print("ERROR: Ghost Scene missing!")
		return
		
	var scene_to_spawn = null
	var current_lvl = GameManager.current_level
	var current_spawn_number = GameManager.customers_spawned + 1
	
	# -----------------------------------------------------
	# A. CHECK FOR BONUS EVENT (Watching Bird) 	# This runs independently of the main spawn.
	# -----------------------------------------------------
	if bonus_spawns.has(current_lvl):
		if current_spawn_number in bonus_spawns[current_lvl]:
			spawn_watching_bird()

	# -----------------------------------------------------
	# B. CHECK FOR SPECIFIC OVERRIDE FIRST
	# -----------------------------------------------------
	if specific_spawns.has(current_lvl):
		var level_overrides = specific_spawns[current_lvl]
		if level_overrides.has(current_spawn_number):
			var monster_name = level_overrides[current_spawn_number]
			scene_to_spawn = get_scene_from_name(monster_name)
			print("Spawner: SPECIAL EVENT -> Spawn #", current_spawn_number, " is ", monster_name)

	# -----------------------------------------------------
	# C. IF NO OVERRIDE, USE RANDOM LOGIC
	# -----------------------------------------------------
	if scene_to_spawn == null:
		var roll = randf()
		
		match current_lvl:
			1: scene_to_spawn = ghost_scene
			2:
				if zombie_scene and roll <= 0.3: scene_to_spawn = zombie_scene
				else: scene_to_spawn = ghost_scene
			3:
				if zombie_scene and roll <= 0.3: scene_to_spawn = zombie_scene
				elif ghost_scene and roll <= 0.7: scene_to_spawn = ghost_scene
				else: scene_to_spawn = slime_scene
			4:
				if zombie_scene and roll <= 0.25: scene_to_spawn = zombie_scene
				elif slime_scene and roll <= 0.5: scene_to_spawn = slime_scene
				elif ghost_scene and roll <= 0.9: scene_to_spawn = ghost_scene
				else: scene_to_spawn = small_bird_scene
			5:
				if zombie_scene and roll <= 0.2: scene_to_spawn = zombie_scene
				elif long_bird_scene and roll <= 0.4: scene_to_spawn = long_bird_scene
				elif ghost_scene and roll <= 0.6: scene_to_spawn = ghost_scene
				elif slime_scene and roll <= 0.8: scene_to_spawn = slime_scene
				elif reaper_scene and roll <= 0.9: scene_to_spawn = reaper_scene
				else: scene_to_spawn = small_bird_scene
			6:
				if reaper_scene and roll <= 0.2: scene_to_spawn = reaper_scene
				elif slime_scene and roll <= 0.6: scene_to_spawn = slime_scene
				else: scene_to_spawn = zombie_scene
			7:
				if reaper_scene and roll <= 0.3: scene_to_spawn = reaper_scene
				elif slime_scene and roll <= 0.5: scene_to_spawn = slime_scene
				elif zombie_scene and roll <= 0.7: scene_to_spawn = zombie_scene
				else: scene_to_spawn = ghost_scene
			_:
				scene_to_spawn = ghost_scene

	# -----------------------------------------------------
	# D. SPAWN THE CUSTOMER
	# -----------------------------------------------------
	if scene_to_spawn:
		SoundManager.play_sfx("spawner")
		var new_customer = scene_to_spawn.instantiate()
		new_customer.global_position = global_position 
		get_parent().add_child(new_customer)
		
		# Only update manager for actual customers
		GameManager.on_customer_spawned()

# --- HELPER: SPAWN WATCHING BIRD ---
func spawn_watching_bird():
	if watching_bird_scene:
		var bird = watching_bird_scene.instantiate()
		
		# --- UPDATED LOGIC FOR PARENT GROUP ---
		var spawn_parent = get_tree().get_first_node_in_group("BirdSpots")
		
		if spawn_parent:
			var markers = spawn_parent.get_children()
			
			if markers.size() > 0:
				var random_marker = markers.pick_random()
				
				# 1. Set Position
				bird.global_position = random_marker.global_position
				
				# 2. Check for Flip (Scale X is -1)
				# We access the AnimatedSprite2D inside the bird directly
				if random_marker.scale.x < 0:
					bird.get_node("AnimatedSprite2D").flip_h = true
				else:
					bird.get_node("AnimatedSprite2D").flip_h = false
				
				print("Spawner: BONUS! Watching Bird at ", random_marker.name)
				get_parent().add_child(bird)
			else:
				print("Spawner Error: 'BirdSpawns' node has no children markers!")
		else:
			print("Spawner Error: Could not find group 'BirdSpots'!")
	else:
		print("Spawner Error: Watching Bird Scene is not assigned!")
# --- HELPER: CONVERT STRING TO SCENE ---
func get_scene_from_name(name_str: String) -> PackedScene:
	match name_str:
		"Ghost": return ghost_scene
		"Zombie": return zombie_scene
		"Slime": return slime_scene
		"Reaper": return reaper_scene
		"LongBird": return long_bird_scene
		"SmallBird": return small_bird_scene
	return ghost_scene # Fallback
