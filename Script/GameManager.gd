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

# --- DATA ---
var level_data = {
	1: {"spawn_count": 10, "spawn_rate": 10.0, "text": "Level 1:\n'Opening Day'"},
	2: {"spawn_count": 10, "spawn_rate": 9.0, "text": "Level 2:\n'Lunch Rush'"},
	3: {"spawn_count": 15, "spawn_rate": 8.0, "text": "Level 3:\n'Weekend Sale'"},
	4: {"spawn_count": 20, "spawn_rate": 7.0, "text": "Level 4:\n'Black Friday'"},
	5: {"spawn_count": 30, "spawn_rate": 6.0, "text": "Level 5:\n'Holiday Season'"},
	6: {"spawn_count": 40, "spawn_rate": 5.0, "text": "Level 6:\n'Total Chaos'"},
	7: {"spawn_count": 50, "spawn_rate": 4.0, "text": "Level 7:\n'HELL RETAIL'"}
}

signal hp_changed(new_hp)
signal wave_progress_changed(completed, total)
signal day_ended

func _ready():
	cashier_queue.clear()
	# Ensure fade layer is hidden on start if it exists to avoid blocking clicks
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
	customers_spawned = 0
	customers_completed = 0
	cashier_queue.clear()
	is_wave_active = true
	
	if level_data.has(current_level):
		total_customers_for_level = level_data[current_level]["spawn_count"]
	else:
		total_customers_for_level = 5
		
	emit_signal("wave_progress_changed", customers_completed, total_customers_for_level)

func on_customer_spawned():
	customers_spawned += 1

func on_customer_left():
	customers_completed += 1
	emit_signal("wave_progress_changed", customers_completed, total_customers_for_level)
	clean_queue()
	
	if customers_spawned >= total_customers_for_level and customers_completed >= customers_spawned:
		end_day()

func take_damage(amount):
	current_hp -= amount
	if current_hp < 0: current_hp = 0
	emit_signal("hp_changed", current_hp)
	print("GameManager: HP Left: ", current_hp)
	if current_hp == 0:
		game_over()

# --- SCENE FLOW ---

func end_day():
	print("Wave Complete!")
	is_wave_active = false
	emit_signal("day_ended")
	
	# Wait 5 seconds before starting transition
	await get_tree().create_timer(5.0).timeout
	next_level()

func next_level():
	current_level += 1
	
	# Heal Player
	current_hp = max_hp 
	emit_signal("hp_changed", current_hp)
	print("GameManager: New Day! HP Reset to 10.")
	
	# --- FADE TRANSITION LOGIC ---
	if has_node("Fade_transition/AnimationPlayer"):
		$Fade_transition.show()
		$Fade_transition/AnimationPlayer.play("Fade_in")
		await $Fade_transition/AnimationPlayer.animation_finished
	
	# Change Scene
	if current_level > max_levels:
		get_tree().change_scene_to_file("res://Scene/main_menu.tscn")
	else:
		get_tree().change_scene_to_file("res://Scene/Intermission.tscn")
		
	# Reset Fade (Optional cleanup)
	if has_node("Fade_transition/AnimationPlayer"):
		$Fade_transition/AnimationPlayer.play("Fade_out")

func game_over():
	print("GAME OVER")
	
	# --- FADE TRANSITION LOGIC ---
	if has_node("Fade_transition/AnimationPlayer"):
		$Fade_transition.show()
		$Fade_transition/AnimationPlayer.play("Fade_in")
		await $Fade_transition/AnimationPlayer.animation_finished
		
	get_tree().change_scene_to_file("res://Scene/main_menu.tscn")
	
	# Reset Fade
	if has_node("Fade_transition/AnimationPlayer"):
		$Fade_transition/AnimationPlayer.play("Fade_out")

func start_game():
	current_level = 1
	current_hp = max_hp
	get_tree().change_scene_to_file("res://Scene/Intermission.tscn")

func start_level_gameplay():
	get_tree().change_scene_to_file("res://Scene/level.tscn")
