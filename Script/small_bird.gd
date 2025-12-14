extends CharacterBody2D

# --- BIRD SETTINGS ---
@export var move_speed : float = 240.0 
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
enum State { TO_MARKER_1_ENTER, TO_MARKER_2, TO_SHELF, SEARCHING, TO_CASHIER, WAITING_AT_CASHIER, TO_MARKER_1_EXIT, TO_DOOR_EXIT }
var current_state = State.TO_MARKER_1_ENTER

# --- MEMORY ---
var desired_item_name = ""   
var target_shelf_node = null 
var cashier_node = null 
var patience_timer : float = 0.0
var is_served : bool = false 

# --- MOOD STATE ---
# STARTS FALSE: Bird enters the store Angry by default
var is_satisfied : bool = false 
var is_angry_at_cashier : bool = false

func _ready():
	# Ensure animation is updated immediately
	update_animation()
	setup_patience_bar()
	
	cashier_node = get_parent().find_child("CashierZone", true, false)
	
	var shopping_list = ["Cola", "Coke", "Sprite", "Pepsi" , "Est", "Sarsi" , "Fanta"] 
	desired_item_name = shopping_list.pick_random()
	target_shelf_node = find_shelf_for_item(desired_item_name)
	
	if target_shelf_node == null:
		if GameManager.has_method("on_customer_left"):
			GameManager.on_customer_left()
		queue_free()
		return

	var door = get_parent().find_child("DoorPosition", true, false)
	if door: 
		global_position = door.global_position 
	
	# Small delay before starting
	await get_tree().create_timer(1.0).timeout
	go_to_node("Marker1", State.TO_MARKER_1_ENTER)

func _exit_tree():
	if GameManager.has_method("leave_queue"):
		GameManager.leave_queue(self)

func _physics_process(delta):
	if is_served: return

	# 1. Update Queue Position continuously if heading to or waiting at cashier
	if current_state == State.TO_CASHIER or current_state == State.WAITING_AT_CASHIER:
		update_queue_position()
		
	# 2. Handle Patience Logic
	if current_state == State.WAITING_AT_CASHIER:
		process_patience(delta)
	elif current_state != State.SEARCHING: 
		if patience_bar: patience_bar.visible = false

	# 3. Stop movement logic if searching (handled by coroutine)
	if current_state == State.SEARCHING: 
		update_animation()
		return
	
	# 4. Stop if close to queue slot
	if current_state == State.WAITING_AT_CASHIER:
		var dist_to_slot = global_position.distance_to(nav_agent.target_position)
		if dist_to_slot < 10.0:
			velocity = Vector2.ZERO
			move_and_slide()
			update_animation()
			return

	# 5. General Movement Logic
	var dist = global_position.distance_to(nav_agent.target_position)
	var required_dist = stop_distance + 10.0
	
	if dist < required_dist:
		handle_arrival()
		return

	var next_pos = nav_agent.get_next_path_position()
	if next_pos == Vector2.ZERO: return
	
	velocity = global_position.direction_to(next_pos) * move_speed
	move_and_slide()
	
	update_animation()

func update_animation():
	# --- RAGE LOGIC START ---
	# If NOT satisfied (start of level) OR angry at cashier (end of level rage)
	if not is_satisfied or is_angry_at_cashier:
		anim.play("angry")
		# FLIP LOGIC
		if velocity.x < 0: anim.flip_h = false # Facing Left
		elif velocity.x > 0: anim.flip_h = true  # Facing Right
		
	# --- NORMAL BEHAVIOR ---
	else:
		if velocity.length() > 5.0:
			anim.play("walk")
			# FLIP LOGIC
			if velocity.x < 0: anim.flip_h = false 
			elif velocity.x > 0: anim.flip_h = true  
		else:
			anim.play("idle")

func process_patience(delta):
	if is_served: return
	
	var my_index = -1
	if GameManager.has_method("join_queue"):
		my_index = GameManager.cashier_queue.find(self)
	
	# Only lose patience if at the FRONT of the line
	if my_index == 0:
		if patience_bar and patience_bar.max_value != 15.0:
			patience_bar.max_value = 15.0
			
		patience_timer += delta 
		
		if patience_bar:
			patience_bar.visible = true
			patience_bar.value = patience_timer
		
		if patience_timer >= 15.0:
			patience_timer = 0.0
			# RAGE LOGIC: Took too long, revert to Angry Mode
			is_angry_at_cashier = true 
			update_animation() 
			GameManager.take_damage(2) 
	else:
		patience_timer = 0.0
		if patience_bar: patience_bar.visible = false

# --- SERVED LOGIC ---
func get_served():
	if is_served: return 
	
	print("Bird: Payment started...")
	is_served = true 
	patience_timer = 0.0 
	if patience_bar: patience_bar.visible = false
	
	await get_tree().create_timer(0.5).timeout

	# --- CHECK REWARD ---
	if not is_angry_at_cashier:
		print("Bird: Service complete! Granting Player Speed Boost.")
		var player = get_tree().get_first_node_in_group("Player")
		if player and player.has_method("apply_speed_boost"):
			player.apply_speed_boost(10.0) 
	else:
		print("Bird: Service complete, but I stayed angry.")
	
	# Set to satisfied so it leaves peacefully
	is_satisfied = true
	is_angry_at_cashier = false
	update_animation()
	
	if GameManager.has_method("leave_queue"):
		GameManager.leave_queue(self)
	
	print("Bird: Leaving store.")
	current_state = State.TO_MARKER_1_EXIT
	is_served = false 
	anim.flip_h = false 
	go_to_node("Marker1", State.TO_MARKER_1_EXIT)

func start_searching_logic():
	# Try to take item immediately
	if attempt_take_item():
		# RAGE LOGIC: Found item, now we calm down
		is_satisfied = true 
		update_animation()
		await get_tree().create_timer(1.0).timeout
		start_checkout()
		return
	
	if patience_bar:
		patience_bar.max_value = 5.0
		patience_bar.visible = true
		patience_bar.value = 0.0 
	
	var time_waited = 0.0
	for i in range(10): 
		await get_tree().create_timer(0.5).timeout
		time_waited += 0.5
		if patience_bar: patience_bar.value = time_waited

		if attempt_take_item():
			is_satisfied = true
			update_animation() 
			
			if patience_bar: patience_bar.visible = false 
			await get_tree().create_timer(1.0).timeout
			start_checkout()
			return
	
	# If never found item
	if patience_bar: patience_bar.value = 5.0
	await get_tree().create_timer(1.0).timeout 
	if patience_bar: patience_bar.visible = false
	
	GameManager.take_damage(3) 
	leave_shop()

func attempt_take_item():
	if target_shelf_node and target_shelf_node.has_method("ai_take_item"):
		return target_shelf_node.ai_take_item() 
	return false

func handle_arrival():
	velocity = Vector2.ZERO
	update_animation() 
	match current_state:
		State.TO_MARKER_1_ENTER:
			current_state = State.SEARCHING
			await get_tree().create_timer(1.0).timeout 
			go_to_node("Marker2", State.TO_MARKER_2)
		State.TO_MARKER_2:
			current_state = State.SEARCHING
			await get_tree().create_timer(0.5).timeout 
			go_to_target_shelf()
		State.TO_SHELF:
			current_state = State.SEARCHING
			start_searching_logic()
		State.TO_CASHIER:
			current_state = State.WAITING_AT_CASHIER
			patience_timer = 0.0
		State.TO_MARKER_1_EXIT:
			go_to_node("DoorPosition", State.TO_DOOR_EXIT)
		State.TO_DOOR_EXIT:
			GameManager.on_customer_left()
			queue_free()

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
			# --- FIX: TURN ANGRY BEFORE LEAVING ---
			print("Bird: Line Full! Leaving ANGRY.")
			is_satisfied = false # Revert to angry state
			is_angry_at_cashier = true 
			update_animation()
			
			GameManager.take_damage(2) 
			leave_shop()
			return
	go_to_node("CashierZone", State.TO_CASHIER)

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
		if current_state != State.TO_DOOR_EXIT:
			leave_shop()
		else:
			queue_free()
		
func go_to_target_shelf():
	if target_shelf_node:
		current_state = State.TO_SHELF
		nav_agent.target_position = target_shelf_node.global_position
	else:
		leave_shop()

func setup_patience_bar():
	patience_bar = ProgressBar.new()
	add_child(patience_bar)
	patience_bar.size = Vector2(60, 20)
	patience_bar.scale = Vector2(1, 0.2) 
	patience_bar.position = Vector2(-30, -70)
	patience_bar.max_value = 5.0 # Starts at shelf value
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
