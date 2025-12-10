extends CharacterBody2D

# --- CONFIGURATION ---
@export var move_speed : float = 120.0
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
# Added a dummy state "EXITING_HOLY" to stop movement logic
enum State { TO_MARKER_1_ENTER, TO_MARKER_2, TO_SHELF, SEARCHING, TO_CASHIER, WAITING_AT_CASHIER, TO_MARKER_1_EXIT, TO_DOOR_EXIT, EXITING_HOLY }
var current_state = State.TO_MARKER_1_ENTER

# --- MEMORY ---
var desired_item_name = ""   
var target_shelf_node = null 
var cashier_node = null 
var patience_timer : float = 0.0
var is_served : bool = false 

# --- LONG BIRD LOGIC ---
var can_be_clicked : bool = true 

func _ready():
	anim.play("idle")
	setup_patience_bar()
	
	# --- NEW: CONNECT CLICK AREA ---
	# We look for the Area2D you added to make clicking easier
	if has_node("ClickArea"):
		var click_area = $ClickArea
		# Connect the input_event signal via code
		click_area.input_event.connect(_on_click_area_input)
	else:
		print("LongBird Warning: No 'ClickArea' found! Clicking might be hard.")
		# Fallback to root pickable if user forgot the Area2D
		input_pickable = true 
	
	cashier_node = get_parent().find_child("CashierZone", true, false)
	
	# SHOPPING LIST
	var shopping_list = ["Cola", "Coke", "Sprite", "Pepsi" , "Est", "Sarsi" , "Fanta"] 
	desired_item_name = shopping_list.pick_random()
	target_shelf_node = find_shelf_for_item(desired_item_name)
	
	if target_shelf_node == null:
		GameManager.on_customer_left()
		queue_free()
		return

	# SPAWN AT DOOR
	var door = get_parent().find_child("DoorPosition", true, false)
	if door: 
		global_position = door.global_position 
	else:
		print("Bird Error: Could not find 'DoorPosition' node!")

	# START
	await get_tree().create_timer(1.0).timeout
	go_to_node("Marker1", State.TO_MARKER_1_ENTER)

func _exit_tree():
	if GameManager.has_method("leave_queue"):
		GameManager.leave_queue(self)

# --- CLICK LOGIC (UPDATED) ---

# 1. This handles the new Area2D click (The big hitbox)
func _on_click_area_input(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_click()

# 2. This handles the old direct click (Backup)
func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_click()

func handle_click():
	if can_be_clicked:
		print("Long Bird: Clicked by Player! Triggering Blessing.")
		trigger_equalizer_effect()

func _physics_process(delta):
	# STOP everything if we are in the holy exit state
	if current_state == State.EXITING_HOLY: return
	if is_served: return

	# --- ANIMATION SWITCHING ---
	if velocity.length() > 0:
		anim.play("walk")
	else:
		anim.play("idle")

	# --- QUEUE UPDATE ---
	if current_state == State.TO_CASHIER or current_state == State.WAITING_AT_CASHIER:
		update_queue_position()
		
	# --- PATIENCE LOGIC ---
	if current_state == State.WAITING_AT_CASHIER:
		if patience_bar: patience_bar.visible = false
		pass 
	elif current_state != State.SEARCHING: 
		if patience_bar: patience_bar.visible = false

	if current_state == State.SEARCHING: return
	
	# --- INCH FORWARD LOGIC ---
	if current_state == State.WAITING_AT_CASHIER:
		var dist_to_slot = global_position.distance_to(nav_agent.target_position)
		if dist_to_slot < 10.0:
			velocity = Vector2.ZERO
			move_and_slide()
			return

	# --- ARRIVAL CHECK ---
	var dist = global_position.distance_to(nav_agent.target_position)
	var required_dist = stop_distance + 10.0
	
	if dist < required_dist:
		handle_arrival()
		return

	# --- MOVEMENT ---
	var next_pos = nav_agent.get_next_path_position()
	if next_pos == Vector2.ZERO: 
		velocity = Vector2.ZERO
		return
		
	velocity = global_position.direction_to(next_pos) * move_speed
	move_and_slide()
	anim.flip_h = velocity.x < 0

# --- SERVED LOGIC ---
func get_served():
	if is_served: return 
	
	print("Bird: Payment started... Waiting 2s.")
	
	is_served = true 
	patience_timer = 0.0
	if patience_bar: patience_bar.visible = false
	
	anim.play("idle") 
	
	await get_tree().create_timer(2.0).timeout
	
	if GameManager.has_method("leave_queue"):
		GameManager.leave_queue(self)
	
	print("Bird: Payment done. Leaving!")
	current_state = State.TO_MARKER_1_EXIT
	is_served = false 
	anim.flip_h = false
	go_to_node("Marker1", State.TO_MARKER_1_EXIT)

func handle_arrival():
	velocity = Vector2.ZERO
	match current_state:
		State.TO_MARKER_1_ENTER:
			current_state = State.SEARCHING
			await get_tree().create_timer(10.0).timeout
			go_to_node("Marker2", State.TO_MARKER_2)
		State.TO_MARKER_2:
			current_state = State.SEARCHING
			await get_tree().create_timer(5.0).timeout
			go_to_target_shelf()
		State.TO_SHELF:
			current_state = State.SEARCHING
			start_searching_logic()
		State.TO_CASHIER:
			print("Bird: Arrived at line.")
			current_state = State.WAITING_AT_CASHIER
			can_be_clicked = false 
			patience_timer = 0.0
		State.TO_MARKER_1_EXIT:
			go_to_node("DoorPosition", State.TO_DOOR_EXIT)
		State.TO_DOOR_EXIT:
			GameManager.on_customer_left()
			queue_free()

# --- QUEUE & LOGIC ---

func update_queue_position():
	if GameManager.has_method("join_queue"):
		GameManager.join_queue(self, max_queue_size)
	
	var my_index = GameManager.cashier_queue.find(self)
	if cashier_node and my_index != -1:
		var offset = line_direction * (line_spacing * my_index)
		nav_agent.target_position = cashier_node.global_position + offset

func start_checkout():
	if GameManager.has_method("join_queue"):
		var can_join = GameManager.join_queue(self, max_queue_size)
		if not can_join:
			leave_shop()
			return
	go_to_node("CashierZone", State.TO_CASHIER)

# --- ITEMS & SHELF WAITING LOGIC ---

func start_searching_logic():
	if attempt_take_item():
		print("Bird: Got item! Browsing for 2s...")
		can_be_clicked = false 
		await get_tree().create_timer(2.0).timeout
		start_checkout()
		return
	
	print("Bird: Item empty! Waiting 5s...")
	if patience_bar:
		patience_bar.max_value = 5.0 
		patience_bar.visible = true
		patience_bar.value = 0.0 
	
	var time_waited = 0.0
	for i in range(10): 
		# Safety check: If we were clicked during the wait, stop searching
		if not can_be_clicked: return

		await get_tree().create_timer(0.5).timeout
		time_waited += 0.5
		if patience_bar: patience_bar.value = time_waited

		if attempt_take_item():
			print("Bird: Found item!")
			if patience_bar: patience_bar.visible = false 
			can_be_clicked = false
			await get_tree().create_timer(2.0).timeout
			start_checkout()
			return
	
	# 3. Failure Path -> ACTIVATE SKILL
	print("Bird: Patience runs out! ACTIVATING EQUALIZER!")
	trigger_equalizer_effect()

func trigger_equalizer_effect():
	# 1. LOCK STATE
	can_be_clicked = false
	current_state = State.EXITING_HOLY # Stops physics movement
	velocity = Vector2.ZERO
	anim.play("idle")
	if patience_bar: patience_bar.visible = false
	
	# Leave queue if we were in it (edge case)
	if GameManager.has_method("leave_queue"):
		GameManager.leave_queue(self)
	
	# 2. GLOW PHASE (2 Seconds)
	var tween = create_tween()
	# Glow to bright white over 0.5s
	tween.tween_property(self, "modulate", Color(10, 10, 10, 1), 0.5) 
	# Stay bright for 1.5s
	tween.tween_interval(1.5)
	
	await tween.finished
	
	# 3. EQUALIZE (The Magic)
	var all_shelves = get_tree().get_nodes_in_group("Shelves")
	GameManager.activate_equalizer_skill(all_shelves)
	
	# 4. DISAPPEAR PHASE
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 1.0)
	
	await fade_tween.finished
	
	# 5. Done
	GameManager.on_customer_left() 
	queue_free()

func attempt_take_item():
	if target_shelf_node and target_shelf_node.has_method("ai_take_item"):
		return target_shelf_node.ai_take_item() 
	return false

func find_shelf_for_item(item_name):
	for node in get_parent().get_children():
		if "required_item" in node and node.required_item == item_name:
			return node
	return null

func leave_shop():
	can_be_clicked = false 
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
		
func go_to_target_shelf():
	if target_shelf_node:
		current_state = State.TO_SHELF
		nav_agent.target_position = target_shelf_node.global_position

func setup_patience_bar():
	patience_bar = ProgressBar.new()
	add_child(patience_bar)
	patience_bar.size = Vector2(60, 20)
	patience_bar.scale = Vector2(1, 0.2) 
	patience_bar.position = Vector2(-30, -70)
	patience_bar.max_value = 5.0 
	patience_bar.show_percentage = false
	patience_bar.visible = false
	patience_bar.z_index = 10 
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color.ROYAL_BLUE
	patience_bar.add_theme_stylebox_override("fill", style_box)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0, 0, 0, 0.5)
	patience_bar.add_theme_stylebox_override("background", bg_style)
