extends Node

# --- CONFIGURATION ---
var current_level = 1
var max_levels = 7
var max_hp : int = 10 
var current_hp : int = 10

# --- WAVE VARIABLES ---
var total_customers_for_level : int = 0
var customers_spawned : int = 0
var customers_completed : int = 0 
var is_wave_active : bool = false

# --- THE QUEUE ---
var cashier_queue : Array = [] 

# --- REFERENCES ---
# We store the player here so we don't have to search for them every frame
var player_node = null 

# --- DATA ---
var level_data = {
	1: {"spawn_count": 15, "spawn_rate": 10.0, "text": "Level 1:\n'Opening Day'"},
	2: {"spawn_count": 15, "spawn_rate": 9.0, "text": "Level 2:\n'Lunch Rush'"},
	3: {"spawn_count": 20, "spawn_rate": 8.0, "text": "Level 3:\n'Weekend Sale'"},
	4: {"spawn_count": 25, "spawn_rate": 7.0, "text": "Level 4:\n'Black Friday'"},
	5: {"spawn_count": 40, "spawn_rate": 7.0, "text": "Level 5:\n'Holiday Season'"},
	6: {"spawn_count": 30, "spawn_rate": 6.0, "text": "Level 6:\n'Total Chaos'"},
	7: {"spawn_count": 36, "spawn_rate": 5.0, "text": "Level 7:\n'HELL RETAIL'"}
}

signal hp_changed(new_hp)
signal wave_progress_changed(completed, total)
signal day_ended

func _ready():
	cashier_queue.clear()
	# Ensure fade layer is hidden on start if it exists
	if has_node("Fade_transition"):
		$Fade_transition.visible = false

# --- QUEUE MANAGEMENT ---

func join_queue(customer_node, max_size) -> bool:
	clean_queue() 
	if customer_node in cashier_queue: return true 
	if cashier_queue.size() >= max_size: return false 
	cashier_queue.append(customer_node)
	return true

func leave_queue(customer_node):
	if customer_node in cashier_queue:
		cashier_queue.erase(customer_node)
	clean_queue()

func clean_queue():
	for i in range(cashier_queue.size() - 1, -1, -1):
		if not is_instance_valid(cashier_queue[i]):
			cashier_queue.remove_at(i)

# --- GAMEPLAY EVENTS ---

func start_day():
	# 1. Reset variables
	customers_spawned = 0
	customers_completed = 0
	cashier_queue.clear()
	is_wave_active = true
	
	# Clear cached player reference on new day to ensure it's fresh
	player_node = null 
	
	# 2. Get Data for this level
	var rate = 5.0 # Default fallback
	if level_data.has(current_level):
		total_customers_for_level = level_data[current_level]["spawn_count"]
		rate = level_data[current_level]["spawn_rate"]
	else:
		total_customers_for_level = 5
	
	emit_signal("wave_progress_changed", customers_completed, total_customers_for_level)

	# 3. TELL THE SPAWNER TO START
	var spawner = get_tree().get_first_node_in_group("Spawner")
	if spawner and spawner.has_method("start_spawning"):
		print("GameManager: Starting spawner with rate: ", rate)
		spawner.start_spawning(total_customers_for_level, rate)
	else:
		print("ERROR: No Spawner found or Spawner missing 'start_spawning' function!")

func on_customer_spawned():
	customers_spawned += 1
	# Check if we should tell spawner to stop
	if customers_spawned >= total_customers_for_level:
		var spawner = get_tree().get_first_node_in_group("Spawner")
		if spawner:
			spawner.stop_spawning()

func on_customer_left():
	customers_completed += 1
	emit_signal("wave_progress_changed", customers_completed, total_customers_for_level)
	clean_queue()
	
	if customers_spawned >= total_customers_for_level and customers_completed >= customers_spawned:
		end_day()

# --- NEW: STUN LOGIC (For Reaper) ---

func stun_player(duration: float):
	_refresh_player_cache()
	
	if player_node and player_node.has_method("apply_stun"):
		player_node.apply_stun(duration)
	else:
		print("GameManager: Could not find player to stun!")

# --- DAMAGE LOGIC ---

func take_damage(amount):
	current_hp -= amount
	if current_hp < 0: current_hp = 0
	
	emit_signal("hp_changed", current_hp)
	print("GameManager: HP Left: ", current_hp)
	
	_refresh_player_cache()
	if player_node and player_node.has_method("take_damage"):
		player_node.take_damage(amount) 

	if current_hp == 0:
		game_over()

# Helper to ensure we have a valid reference to the player
func _refresh_player_cache():
	if not is_instance_valid(player_node):
		player_node = get_tree().get_first_node_in_group("Player")

# --- SCENE FLOW ---

func end_day():
	print("Wave Complete!")
	is_wave_active = false
	emit_signal("day_ended")
	
	await get_tree().create_timer(5.0).timeout
	next_level()

func next_level():
	current_level += 1
	current_hp = max_hp 
	emit_signal("hp_changed", current_hp)
	print("GameManager: New Day! HP Reset to 10.")
	
	# Transition
	if has_node("Fade_transition/AnimationPlayer"):
		$Fade_transition.show()
		$Fade_transition/AnimationPlayer.play("Fade_in")
		await $Fade_transition/AnimationPlayer.animation_finished
	
	# Logic to check if game is beaten or next level
	if current_level > max_levels:
		get_tree().change_scene_to_file("res://Scene/main_menu.tscn")
	else:
		get_tree().change_scene_to_file("res://Scene/Intermission.tscn")
		
	if has_node("Fade_transition/AnimationPlayer"):
		$Fade_transition/AnimationPlayer.play("Fade_out")

func game_over():
	print("GAME OVER")
	
	if has_node("Fade_transition/AnimationPlayer"):
		$Fade_transition.show()
		$Fade_transition/AnimationPlayer.play("Fade_in")
		await $Fade_transition/AnimationPlayer.animation_finished
		
	get_tree().change_scene_to_file("res://Scene/main_menu.tscn")
	
	if has_node("Fade_transition/AnimationPlayer"):
		$Fade_transition/AnimationPlayer.play("Fade_out")

func start_game():
	current_level = 1
	current_hp = max_hp
	get_tree().change_scene_to_file("res://Scene/Intermission.tscn")

func start_level_gameplay():
	get_tree().change_scene_to_file("res://Scene/level.tscn")

# ----------------------------------------------------
# --- NEW: ABILITY LOGIC (EQUALIZER) -----------------
# ----------------------------------------------------

func activate_equalizer_skill(shelf_list: Array):
	print("GameManager: Activating Equalizer Skill...")
	
	var total_items : int = 0
	var shelf_count : int = shelf_list.size()
	
	if shelf_count == 0:
		return # Safety check

	# 1. SUM ALL ITEMS
	for shelf in shelf_list:
		# Ensure shelf has the getter method
		if shelf.has_method("get_stock_count"):
			total_items += shelf.get_stock_count()
	
	print("GameManager: Total items found: ", total_items)

	# 2. CALCULATE NEW AMOUNT (Round Up) 
	# ceil() rounds up (e.g. 0.1 -> 1.0)
	var average_stock = ceil(float(total_items) / float(shelf_count))
	
	# Safety: If we have items but math gave 0 (rare), force 1
	if average_stock == 0 and total_items > 0:
		average_stock = 1

	print("GameManager: Redistributing ", average_stock, " items to each shelf.")

	# 3. SET NEW STOCK
	for shelf in shelf_list:
		if shelf.has_method("set_stock_count"):
			shelf.set_stock_count(int(average_stock))
