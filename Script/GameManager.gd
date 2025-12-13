extends Node

# --- CONFIGURATION ---
var current_level = 1
var max_levels = 8
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
var player_node = null 

# --- DATA ---
var level_data = {
	1: {"spawn_count": 14, "spawn_rate": 10.0, "text": "Level 1:\n'Opening Day'"},
	2: {"spawn_count": 18, "spawn_rate": 9.0, "text": "Level 2:\n'Lunch Rush'"},
	3: {"spawn_count": 22, "spawn_rate": 8.0, "text": "Level 3:\n'Weekend Sale'"},
	4: {"spawn_count": 28, "spawn_rate": 7.0, "text": "Level 4:\n'Black Friday'"},
	5: {"spawn_count": 50, "spawn_rate": 7.0, "text": "Level 5:\n'Holiday Season'"},
	6: {"spawn_count": 34, "spawn_rate": 6.5, "text": "Level 6:\n'Total Chaos'"},
	7: {"spawn_count": 40, "spawn_rate": 6.0, "text": "Level 7:\n'HELL RETAIL'"}
}

signal hp_changed(new_hp)
signal wave_progress_changed(completed, total)
signal day_ended
signal queue_count_changed(current_count, max_size)
signal request_level_transition # <-- Critical Signal for fading

func _ready():
	cashier_queue.clear()
	# Check if we have an internal fader (we shouldn't, Level handles it now)
	if has_node("Fade_transition"):
		$Fade_transition.visible = false

# --- QUEUE MANAGEMENT ---

func join_queue(customer_node, max_size) -> bool:
	clean_queue() 
	if customer_node in cashier_queue: return true 
	if cashier_queue.size() >= max_size: return false 
	
	cashier_queue.append(customer_node)
	emit_signal("queue_count_changed", cashier_queue.size(), max_size)
	return true

func leave_queue(customer_node):
	if customer_node in cashier_queue:
		cashier_queue.erase(customer_node)
	clean_queue()
	emit_signal("queue_count_changed", cashier_queue.size(), 8)

func clean_queue():
	for i in range(cashier_queue.size() - 1, -1, -1):
		if not is_instance_valid(cashier_queue[i]):
			cashier_queue.remove_at(i)

# --- GAMEPLAY EVENTS ---

func start_day():
	customers_spawned = 0
	customers_completed = 0
	cashier_queue.clear()
	is_wave_active = true
	player_node = null 
	
	emit_signal("queue_count_changed", 0, 8)
	
	var rate = 5.0
	if level_data.has(current_level):
		total_customers_for_level = level_data[current_level]["spawn_count"]
		rate = level_data[current_level]["spawn_rate"]
	else:
		total_customers_for_level = 5

	# ---------------------------------------------------------
	# --- [TEST CODE] SKIP TO END OF LEVEL 7 ---
	# ---------------------------------------------------------
	#if current_level == 7:
		#print("DEBUG: Skipping to customer 39...")
		## We pretend 39 people already came...
		#customers_spawned = 39 
		## ...AND that they already finished/left.
		#customers_completed = 39 
	# ---------------------------------------------------------
	
	emit_signal("wave_progress_changed", customers_completed, total_customers_for_level)

	var spawner = get_tree().get_first_node_in_group("Spawner")
	if spawner and spawner.has_method("start_spawning"):
		print("GameManager: Starting spawner with rate: ", rate)
		spawner.start_spawning(total_customers_for_level, rate)
	else:
		print("ERROR: No Spawner found or Spawner missing 'start_spawning' function!")

func on_customer_spawned():
	customers_spawned += 1
	if customers_spawned >= total_customers_for_level:
		var spawner = get_tree().get_first_node_in_group("Spawner")
		if spawner:
			spawner.stop_spawning()

func on_customer_left():
	customers_completed += 1
	emit_signal("wave_progress_changed", customers_completed, total_customers_for_level)
	clean_queue()
	emit_signal("queue_count_changed", cashier_queue.size(), 8)
	
	if customers_spawned >= total_customers_for_level and customers_completed >= customers_spawned:
		end_day()

# --- REAPER STUN LOGIC ---

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

# ---------------------------------------------------------
# --- TRANSITION LOGIC ---
# ---------------------------------------------------------

# 1. Start the process (Called when wave ends)
func next_level():
	current_level += 1
	current_hp = max_hp 
	emit_signal("hp_changed", current_hp)
	
	# Tell the Level: "Please play your fade animation now!"
	emit_signal("request_level_transition")

# 2. Finish the process (Called by Level.gd after animation is done)
func change_scene_now():
	if current_level == 8:
		# LEVEL 8 IS THE BOSS FIGHT
		print("GameManager: ENTERING BOSS FIGHT!")
		get_tree().change_scene_to_file("res://Scene/BossFight.tscn")
		# BossLevel.gd handles the fade out (Black -> Clear)
		
	elif current_level > 8:
		# BEAT THE BOSS -> MAIN MENU
		get_tree().change_scene_to_file("res://Scene/main_menu.tscn")
		
	else:
		# NORMAL LEVELS
		get_tree().change_scene_to_file("res://Scene/Intermission.tscn")

func game_over():
	print("GAME OVER")
	# Simple direct scene change since game over is abrupt
	get_tree().change_scene_to_file("res://Scene/main_menu.tscn")

func start_game():
	current_level = 1
	current_hp = max_hp
	get_tree().change_scene_to_file("res://Scene/Intermission.tscn")

func start_level_gameplay():
	get_tree().change_scene_to_file("res://Scene/level.tscn")

# ----------------------------------------------------
# --- ABILITY LOGIC (SKILLS) -------------------------
# ----------------------------------------------------

func burst_stock():
	print("GameManager: Burst Stock! Adding +2 to all shelves.")
	var shelves = get_tree().get_nodes_in_group("Shelves")
	for shelf in shelves:
		if "current_stock" in shelf and "max_stock" in shelf:
			shelf.current_stock += 2
			if shelf.current_stock > shelf.max_stock:
				shelf.current_stock = shelf.max_stock
			if shelf.has_method("update_visuals"):
				shelf.update_visuals()

func activate_equalizer_skill(shelf_list: Array):
	print("GameManager: Activating Equalizer Skill...")
	var total_items : int = 0
	var shelf_count : int = shelf_list.size()
	if shelf_count == 0: return 

	for shelf in shelf_list:
		if shelf.has_method("get_stock_count"):
			total_items += shelf.get_stock_count()
	
	var average_stock = ceil(float(total_items) / float(shelf_count))
	if average_stock == 0 and total_items > 0: average_stock = 1
	print("GameManager: Redistributing ", average_stock, " items to each shelf.")
	for shelf in shelf_list:
		if shelf.has_method("set_stock_count"):
			shelf.set_stock_count(int(average_stock))

func activate_line_cut_skill():
	print("GameManager: Long Bird is purging the line...")
	while cashier_queue.size() > 4:
		var victim = cashier_queue.pop_back() 
		if is_instance_valid(victim):
			if victim.has_method("queue_free"):
				victim.queue_free()
			on_customer_left()
	emit_signal("queue_count_changed", cashier_queue.size(), 8)

func activate_stock_wipe():
	print("GameManager: JUMO SMASH! Wiping all shelves to 0.")
	var shelves = get_tree().get_nodes_in_group("Shelves")
	for shelf in shelves:
		if "current_stock" in shelf:
			shelf.current_stock = 0
			if shelf.has_method("update_visuals"):
				shelf.update_visuals()
