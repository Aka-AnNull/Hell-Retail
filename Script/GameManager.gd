extends Node

# --- LEVEL & SCORE VARIABLES ---
var current_level = 1
var max_levels = 7
var score = 0

# --- HP VARIABLES ---
var max_hp : int = 10 
var current_hp : int = 10

# --- TIME / DAY VARIABLES ---
var time_elapsed : float = 0.0
var day_duration : float = 120.0 # Day lasts 2 minutes (120s)
var is_day_active : bool = false

# --- SIGNALS ---
signal hp_changed(new_hp)
signal time_changed(time_string)
signal day_ended
signal money_changed(new_amount) # If you use money later

# --- LEVEL CONFIGURATION ---
var level_data = {
	1: {"goal_money": 50, "customer_speed": 1.0, "text": "Level 1: 'Opening Day'"},
	2: {"goal_money": 100, "customer_speed": 1.2, "text": "Level 2: 'Lunch Rush'"},
	3: {"goal_money": 150, "customer_speed": 1.5, "text": "Level 3: 'Weekend Sale'"},
	4: {"goal_money": 200, "customer_speed": 1.8, "text": "Level 4: 'Black Friday'"},
	5: {"goal_money": 300, "customer_speed": 2.0, "text": "Level 5: 'Holiday Season'"},
	6: {"goal_money": 400, "customer_speed": 2.5, "text": "Level 6: 'Total Chaos'"},
	7: {"goal_money": 500, "customer_speed": 3.0, "text": "Level 7: 'HELL RETAIL'"}
}

func _process(delta):
	# Calculate Time (9 AM to 5 PM) only if the day is active
	if is_day_active:
		time_elapsed += delta
		
		var progress = time_elapsed / day_duration
		var start_hour = 9.0
		var end_hour = 17.0 # 5 PM
		var current_hour = start_hour + (progress * (end_hour - start_hour))
		
		# Format Time String (e.g. "12:30 PM")
		var hour_int = int(current_hour)
		var minute_int = int((current_hour - hour_int) * 60)
		var am_pm = "AM" if hour_int < 12 else "PM"
		if hour_int > 12: hour_int -= 12
		
		var time_str = "%02d:%02d %s" % [hour_int, minute_int, am_pm]
		emit_signal("time_changed", time_str)
		
		# End of Day Check
		if time_elapsed >= day_duration:
			end_day()

# --- DAY CYCLE FUNCTIONS ---
func start_day():
	print("GameManager: Day Started!")
	time_elapsed = 0.0
	is_day_active = true

func end_day():
	print("GameManager: Day Ended!")
	is_day_active = false
	emit_signal("day_ended")
	# Logic for what happens at end of day (e.g. show results) goes here

# --- HP LOGIC ---
func take_damage(amount):
	current_hp -= amount
	if current_hp < 0: current_hp = 0
	emit_signal("hp_changed", current_hp)
	print("GameManager: Took damage. HP: ", current_hp)
	
	if current_hp == 0:
		game_over()

func heal(amount):
	current_hp += amount
	if current_hp > max_hp: current_hp = max_hp
	emit_signal("hp_changed", current_hp)

# --- SCENE SWITCHING (Your Old Code) ---
func start_game():
	current_level = 1
	score = 0
	current_hp = max_hp 
	get_tree().change_scene_to_file("res://Scene/Intermission.tscn")

func next_level():
	current_level += 1
	if current_level > max_levels:
		if has_node("Fade_transition/AnimationPlayer"):
			$Fade_transition/AnimationPlayer.play("Fade_in")
		print("YOU WIN THE GAME!")
		get_tree().change_scene_to_file("res://Scene/main_menu.tscn")
	else:
		if has_node("Fade_transition/AnimationPlayer"):
			$Fade_transition/AnimationPlayer.play("Fade_in")
		get_tree().change_scene_to_file("res://Scene/Intermission.tscn")

func start_level_gameplay():
	get_tree().change_scene_to_file("res://Scene/level.tscn")

func game_over():
	print("GAME OVER")
