extends CharacterBody2D

# --- CONFIGURATION ---
@export var move_speed : float = 120.0 # Fast like Ghost
@export var stop_distance : float = 50.0 

# --- QUEUE SETTINGS ---
@export var line_spacing : float = 60.0
@export var line_direction : Vector2 = Vector2.DOWN
@export var max_queue_size : int = 8

# --- NODES ---
@onready var nav_agent = $NavigationAgent2D
@onready var anim = $AnimatedSprite2D

# --- UI ---
var patience_bar : ProgressBar = null

# --- STATE MACHINE ---
enum State { TO_MARKER_1_ENTER, TO_MARKER_2, TO_SHELF_1, SEARCHING_1, TO_SHELF_2, SEARCHING_2, TO_CASHIER, WAITING_AT_CASHIER, TO_MARKER_1_EXIT, TO_DOOR_EXIT }
var current_state = State.TO_MARKER_1_ENTER

# --- MEMORY ---
var item_1_node = null 
var item_2_node = null 
var cashier_node = null 
var patience_timer : float = 0.0
var is_served : bool = false 
var is_angry : bool = false # Added state tracking

# --- FLOATING ---
var float_time = 0.0

func _ready():
	anim.play("idle")
	
	# --- MECHANIC: INVISIBLE AT START ---
	anim.visible = false 
	
	setup_patience_bar()
	
	cashier_node = get_parent().find_child("CashierZone", true, false)
	
	# --- DRINK SELECTION LOGIC ---
	var drink_list = ["Cola", "Coke", "Sprite", "Pepsi", "Est", "Sarsi", "Fanta"]
	
	# Pick 2 DIFFERENT items
	var item_1_name = drink_list.pick_random()
	var item_2_name = drink_list.pick_random()
	while item_2_name == item_1_name:
		item_2_name = drink_list.pick_random()
		
	item_1_node = find_shelf_for_item(item_1_name)
	item_2_node = find_shelf_for_item(item_2_name)
	
	print("Reaper wants: ", item_1_name, " and ", item_2_name)
	
	# Validation
	if item_1_node == null or item_2_node == null:
		if GameManager.has_method("on_customer_left"):
			GameManager.on_customer_left()
		queue_free()
		return

	# SPAWN AT DOOR
	var door = get_parent().find_child("DoorPosition", true, false)
	if door: 
		global_position = door.global_position 

	# START
	await get_tree().create_timer(1.0).timeout
	go_to_node("Marker1", State.TO_MARKER_1_ENTER)

func _exit_tree():
	if GameManager.has_method("leave_queue"):
		GameManager.leave_queue(self)

func _physics_process(delta):
	if is_served: return

	# Float visual
	float_time += delta * 5.0
	anim.position.y = sin(float_time) * 5.0

	# --- QUEUE UPDATE ---
	if current_state == State.TO_CASHIER or current_state == State.WAITING_AT_CASHIER:
		update_queue_position()
		
	# --- PATIENCE LOGIC ---
	if current_state == State.WAITING_AT_CASHIER:
		process_patience(delta)
	elif current_state != State.SEARCHING_1 and current_state != State.SEARCHING_2: 
		if patience_bar: patience_bar.visible = false

	if current_state == State.SEARCHING_1 or current_state == State.SEARCHING_2: return
	
	# --- INCH FORWARD LOGIC ---
	if current_state == State.WAITING_AT_CASHIER:
		var dist_to_slot = global_position.distance_to(nav_agent.target_position)
		if dist_to_slot < 10.0:
			velocity = Vector2.ZERO
			move_and_slide()
			update_animation()
			return

	# --- ARRIVAL CHECK ---
	var dist = global_position.distance_to(nav_agent.target_position)
	var required_dist = stop_distance + 10.0
	
	if dist < required_dist:
		handle_arrival()
		return

	# --- MOVEMENT ---
	var next_pos = nav_agent.get_next_path_position()
	if next_pos == Vector2.ZERO: return
	velocity = global_position.direction_to(next_pos) * move_speed
	move_and_slide()
	
	if velocity.x < 0: anim.flip_h = true
	elif velocity.x > 0: anim.flip_h = false
	
	update_animation()

func update_animation():
	var anim_name = ""
	if velocity.length() > 5.0:
		anim_name = "walk"
	else:
		anim_name = "idle"
		
	if is_angry:
		anim_name = "angry_" + anim_name
		
	# Check if animation exists to avoid errors
	if anim.sprite_frames.has_animation(anim_name):
		anim.play(anim_name)
	else:
		# Fallback if "angry_walk" doesn't exist, just use "angry" base
		if is_angry: anim.play("angry")
		else: anim.play("idle")

# --- SERVED LOGIC ---
func get_served():
	if is_served: return 
	
	print("Reaper: Payment started... Waiting 2s.")
	
	is_served = true 
	patience_timer = 0.0
	if patience_bar: patience_bar.visible = false
	
	# Calm down
	is_angry = false
	update_animation()
	
	await get_tree().create_timer(0.5).timeout
	
	if GameManager.has_method("leave_queue"):
		GameManager.leave_queue(self)
	
	print("Reaper: Done. Leaving!")
	current_state = State.TO_MARKER_1_EXIT
	is_served = false 
	anim.flip_h = false
	go_to_node("Marker1", State.TO_MARKER_1_EXIT)

func handle_arrival():
	velocity = Vector2.ZERO
	update_animation()
	match current_state:
		State.TO_MARKER_1_ENTER:
			current_state = State.TO_MARKER_2
			go_to_node("Marker2", State.TO_MARKER_2)
		State.TO_MARKER_2:
			# Start Shopping Trip 1
			go_to_shelf(item_1_node, State.TO_SHELF_1)
		
		# --- SHOPPING TRIP 1 ---
		State.TO_SHELF_1:
			current_state = State.SEARCHING_1
			start_searching_1()
			
		# --- SHOPPING TRIP 2 ---
		State.TO_SHELF_2:
			current_state = State.SEARCHING_2
			start_searching_2()

		State.TO_CASHIER:
			print("Reaper: Arrived at line.")
			current_state = State.WAITING_AT_CASHIER
			patience_timer = 0.0
		State.TO_MARKER_1_EXIT:
			go_to_node("DoorPosition", State.TO_DOOR_EXIT)
		State.TO_DOOR_EXIT:
			GameManager.on_customer_left()
			queue_free()

# --- SEARCHING LOGIC 1 (Remains Invisible) ---
func start_searching_1():
	print("Reaper: Hunting for first soul (Invisible)...")
	
	if attempt_take_item(item_1_node):
		print("Reaper: Got first item.")
		await get_tree().create_timer(1.0).timeout
		# Go to shelf 2 immediately, STAY INVISIBLE
		go_to_shelf(item_2_node, State.TO_SHELF_2)
		return

	# If empty, wait... (Chill: 15 seconds)
	if patience_bar:
		patience_bar.max_value = 15.0
		patience_bar.visible = true
		patience_bar.value = 0.0 
	
	var time_waited = 0.0
	for i in range(30): 
		await get_tree().create_timer(0.5).timeout
		time_waited += 0.5
		if patience_bar: patience_bar.value = time_waited

		if attempt_take_item(item_1_node):
			print("Reaper: Found first item.")
			if patience_bar: patience_bar.visible = false 
			await get_tree().create_timer(1.0).timeout
			# Found it, move to next item, STILL INVISIBLE
			go_to_shelf(item_2_node, State.TO_SHELF_2)
			return
	
	# If he waits 15s here, he gets angry and STUNS player
	reaper_angry("First Shelf Empty")
	leave_shop() # Only leave if shelf is empty

# --- SEARCHING LOGIC 2 (Becomes Visible on Success) ---
func start_searching_2():
	print("Reaper: Hunting for second soul...")
	
	if attempt_take_item(item_2_node):
		print("Reaper: Got second item.")
		
		# --- MECHANIC: REVEAL FORM ---
		print("Reaper: Harvest complete. Revealing form.")
		anim.visible = true 
		
		await get_tree().create_timer(1.0).timeout
		start_checkout()
		return

	if patience_bar:
		patience_bar.max_value = 15.0
		patience_bar.visible = true
		patience_bar.value = 0.0 
	
	var time_waited = 0.0
	for i in range(30): 
		await get_tree().create_timer(0.5).timeout
		time_waited += 0.5
		if patience_bar: patience_bar.value = time_waited

		if attempt_take_item(item_2_node):
			print("Reaper: Found second item.")
			
			# --- MECHANIC: REVEAL FORM ---
			print("Reaper: Harvest complete. Revealing form.")
			anim.visible = true 
			
			if patience_bar: patience_bar.visible = false 
			await get_tree().create_timer(1.0).timeout
			start_checkout()
			return
	
	# If 15s passes here, he becomes visible and angry
	reaper_angry("Second Shelf Empty")
	leave_shop() # Only leave if shelf is empty

func reaper_angry(reason):
	# !!! CRITICAL: REAPER CASTS SKILL !!!
	anim.visible = true 
	is_angry = true
	print("Reaper CASTING SKILL: " + reason)
	update_animation()
	
	# --- SKILL: STUN PLAYER (2 Seconds) ---
	if GameManager.has_method("stun_player"):
		SoundManager.play_sfx("reaper_angry")
		GameManager.stun_player(2.0)
	else:
		print("ERROR: GameManager missing 'stun_player' function!")
	
	# Deal Damage
	if GameManager.has_method("take_damage"):
		SoundManager.play_sfx("reaper_angry")
		GameManager.take_damage(2) 

	# NOTE: We DO NOT call leave_shop() here anymore!
	# The specific failure functions call it if needed.

func attempt_take_item(shelf_node):
	if shelf_node and shelf_node.has_method("ai_take_item"):
		return shelf_node.ai_take_item() 
	return false

# --- NAVIGATION HELPERS ---

func go_to_shelf(target_node, state):
	if target_node:
		current_state = state
		nav_agent.target_position = target_node.global_position
	else:
		leave_shop()

func start_checkout():
	if GameManager.has_method("join_queue"):
		var can_join = GameManager.join_queue(self, max_queue_size)
		if not can_join:
			reaper_angry("Line Full")
			leave_shop() # Leave if line full
			return
	go_to_node("CashierZone", State.TO_CASHIER)

# --- STANDARD FUNCTIONS ---

func update_queue_position():
	if GameManager.has_method("join_queue"):
		GameManager.join_queue(self, max_queue_size)
	
	var my_index = GameManager.cashier_queue.find(self)
	if cashier_node and my_index != -1:
		var offset = line_direction * (line_spacing * my_index)
		nav_agent.target_position = cashier_node.global_position + offset

func process_patience(delta):
	if is_served: return
	
	var my_index = GameManager.cashier_queue.find(self)
	
	if my_index == 0:
		if patience_bar and patience_bar.max_value != 15.0:
			patience_bar.max_value = 15.0
			
		patience_timer += delta
		
		if patience_bar:
			patience_bar.visible = true
			patience_bar.value = patience_timer
			
		# Chill Reaper: 15 Seconds at cashier
		if patience_timer >= 15.0:
			patience_timer = 0.0
			reaper_angry("Cashier Too Slow")
	else:
		patience_timer = 0.0
		if patience_bar: patience_bar.visible = false

func find_shelf_for_item(item_name):
	for node in get_parent().get_children():
		if "required_item" in node and node.required_item == item_name:
			return node
	return null

func leave_shop():
	if GameManager.has_method("leave_queue"):
		GameManager.leave_queue(self)
	go_to_node("Marker1", State.TO_MARKER_1_EXIT)

func go_to_node(node_name, next_state):
	var target = get_parent().find_child(node_name, true, false)
	if target:
		current_state = next_state
		nav_agent.target_position = target.global_position
	else:
		queue_free()

func setup_patience_bar():
	patience_bar = ProgressBar.new()
	add_child(patience_bar)
	patience_bar.size = Vector2(60, 20)
	patience_bar.scale = Vector2(1, 0.2) 
	patience_bar.position = Vector2(-30, -70)
	patience_bar.max_value = 15.0 # Default 15s for Reaper
	patience_bar.show_percentage = false
	patience_bar.visible = false
	patience_bar.z_index = 10 
	
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color.RED
	style_box.border_width_left = 0
	style_box.border_width_top = 0
	style_box.border_width_right = 0
	style_box.border_width_bottom = 0
	patience_bar.add_theme_stylebox_override("fill", style_box)
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0, 0, 0, 0.5)
	patience_bar.add_theme_stylebox_override("background", bg_style)
