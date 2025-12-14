extends Node

# --- CONFIGURATION ---
var current_level = 1
var max_levels = 9
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
	1: {"spawn_count": 14, "spawn_rate": 10.0, "text": "Level 1\n'Opening Day'", "music": "level1"},
	2: {"spawn_count": 18, "spawn_rate": 9.0, "text": "Level 2\n'Lunch Rush'",  "music": "level2"},
	3: {"spawn_count": 22, "spawn_rate": 8.0, "text": "Level 3\n'Weekend Sale'", "music": "level3"},
	4: {"spawn_count": 28, "spawn_rate": 7.0, "text": "Level 4\n'Black Friday'", "music": "level4"},
	5: {"spawn_count": 50, "spawn_rate": 7.0, "text": "Level 5\n'Holiday Season'","music": "level5"},
	6: {"spawn_count": 34, "spawn_rate": 6.5, "text": "Level 6\n'Total Chaos'",  "music": "level6"},
	7: {"spawn_count": 40, "spawn_rate": 6.0, "text": "Level 7\n'HELL RETAIL'", "music": "level7"}
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
	# 2. RESET WAVE VARIABLES
	customers_spawned = 0
	customers_completed = 0
	cashier_queue.clear()
	is_wave_active = true
	player_node = null 
	
	emit_signal("queue_count_changed", 0, 8)
	
	# 3. SETUP SPAWNER
	var rate = 5.0
	if level_data.has(current_level):
		total_customers_for_level = level_data[current_level]["spawn_count"]
		rate = level_data[current_level]["spawn_rate"]
	else:
		total_customers_for_level = 5

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
	SoundManager.play_sfx("damage")
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
	SoundManager.fade_out_music(0.5)
	print("Wave Complete!")
	is_wave_active = false
	emit_signal("day_ended")
	await get_tree().create_timer(2.0).timeout
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
		SoundManager.fade_out_music(0.5)
		await get_tree().create_timer(1).timeout
		# Go STRAIGHT to the Boss Fight.
		print("GameManager: Level 7 Complete. IMMEDIATE BOSS START.")
		get_tree().change_scene_to_file("res://Scene/BossFight.tscn")
		

	elif current_level > 8:
		print("GameManager: BOSS DEFEATED! Playing Ending.")
		get_tree().change_scene_to_file("res://Scene/EndingCutscene.tscn")
	# SITUATION: We finished Level 1, 2, 3, 4, 5, or 6.
	
	else:
		print("GameManager: Level Complete. Showing Score Screen.")
		# Go to the Level Complete animation first
		get_tree().change_scene_to_file("res://Scene/LevelComplete.tscn")
func game_over():
	print("GameManager: HP is 0. GAME OVER.")
	SoundManager.fade_out_music(0.5)
	get_tree().change_scene_to_file("res://Scene/GameOver.tscn")

func start_game():
	current_level = 1
	current_hp = max_hp
	# CHANGED: Go to Cutscene first, not Intermission
	get_tree().change_scene_to_file("res://Scene/IntroCutscene.tscn")

func start_level_gameplay():
	get_tree().change_scene_to_file("res://Scene/level.tscn")

# ----------------------------------------------------
# --- ABILITY LOGIC (SKILLS) -------------------------
# ----------------------------------------------------

func burst_stock():
	print("GameManager: Burst Stock! Adding +2 to all shelves.")
	SoundManager.play_sfx("burst")
	var shelves = get_tree().get_nodes_in_group("Shelves")
	for shelf in shelves:
		if "current_stock" in shelf and "max_stock" in shelf:
			shelf.current_stock += 2
			if shelf.current_stock > shelf.max_stock:
				shelf.current_stock = shelf.max_stock
			if shelf.has_method("update_visuals"):
				shelf.update_visuals()

func activate_equalizer_skill(shelf_list: Array):
	SoundManager.play_sfx("long_bird")
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
	SoundManager.play_sfx("long_bird")
	print("GameManager: Long Bird is purging the line...")
	while cashier_queue.size() > 4:
		var victim = cashier_queue.pop_back() 
		if is_instance_valid(victim):
			if victim.has_method("queue_free"):
				victim.queue_free()
			on_customer_left()
	emit_signal("queue_count_changed", cashier_queue.size(), 8)

func activate_stock_wipe():
	SoundManager.play_sfx("long_bird")
	print("GameManager: JUMO SMASH! Wiping all shelves to 0.")
	var shelves = get_tree().get_nodes_in_group("Shelves")
	for shelf in shelves:
		if "current_stock" in shelf:
			shelf.current_stock = 0
			if shelf.has_method("update_visuals"):
				shelf.update_visuals()
