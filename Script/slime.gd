extends CharacterBody2D

# --- SLIME SETTINGS ---
@export var puddle_scene : PackedScene 

# --- CONFIGURATION ---
@export var move_speed : float = 90.0 # Slow
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
enum State { TO_MARKER_1_ENTER, TO_MARKER_2, TO_SHELF, SEARCHING, TO_CASHIER, WAITING_AT_CASHIER, TO_PUDDLE_MARKER, TO_MARKER_1_EXIT, TO_DOOR_EXIT }
var current_state = State.TO_MARKER_1_ENTER

# --- MEMORY ---
var desired_item_name = ""   
var target_shelf_node = null 
var cashier_node = null 
var patience_timer : float = 0.0
var is_served : bool = false 
var is_angry : bool = false 

func _ready():
	anim.play("idle")
	setup_patience_bar()
	
	cashier_node = get_parent().find_child("CashierZone", true, false)
	
	# SLIME SHOPPING LIST (Vertical Items)
	var shopping_list = ["Fanta", "Sarsi", "Est"] 
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
	else:
		print("Slime Error: Could not find 'DoorPosition' node!")

	await get_tree().create_timer(1.0).timeout
	go_to_node("Marker1", State.TO_MARKER_1_ENTER)

func _exit_tree():
	if GameManager.has_method("leave_queue"):
		GameManager.leave_queue(self)

func _physics_process(delta):
	if is_served: return

	# --- QUEUE UPDATE ---
	if current_state == State.TO_CASHIER or current_state == State.WAITING_AT_CASHIER:
		update_queue_position()
		
	# --- PATIENCE LOGIC ---
	if current_state == State.WAITING_AT_CASHIER:
		process_patience(delta)
	elif current_state != State.SEARCHING: 
		if patience_bar: patience_bar.visible = false

	if current_state == State.SEARCHING: 
		update_animation()
		return
	
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
	
	# --- FLIP LOGIC (UPDATED FOR SLIME) ---
	# Velocity < 0 (Moving Left) -> flip_h = false (Because sprite faces Left by default)
	# Velocity > 0 (Moving Right) -> flip_h = true  (Flip to face Right)
	if velocity.x < 0: 
		anim.flip_h = false
	elif velocity.x > 0: 
		anim.flip_h = true
	
	update_animation()

# --- SLIME ANGER LOGIC ---
func become_angry(reason: String):
	print("Slime Angry: " + reason)
	is_angry = true
	update_animation()
	
	GameManager.take_damage(1)
	
	if reason == "Shelf Empty":
		print("Slime: Empty Shelf! Moving to sabotage floor...")
		var random_marker = ["Puddle1", "Puddle2", "Puddle3"].pick_random()
		go_to_node(random_marker, State.TO_PUDDLE_MARKER)
		
	else:
		print("Slime: Mad at cashier/line.")
		leave_shop()

func spawn_puddle_here():
	if puddle_scene:
		print("Slime: SPLAT! Spawning Puddle at " + str(global_position))
		var puddle = puddle_scene.instantiate()
		puddle.global_position = global_position
		get_parent().add_child(puddle)

func update_animation():
	var anim_name = ""
	
	if velocity.length() > 5.0:
		anim_name = "walk"
	else:
		anim_name = "idle"
		
	if is_angry:
		anim_name = "angry_" + anim_name
		
	anim.play(anim_name)

# --- SERVED LOGIC ---
func get_served():
	if is_served: return 
	
	print("Slime: Payment started... Waiting 2s.")
	
	is_served = true 
	patience_timer = 0.0
	if patience_bar: patience_bar.visible = false
	
	# CALM DOWN
	is_angry = false
	update_animation()
	
	await get_tree().create_timer(2.0).timeout
	
	if GameManager.has_method("leave_queue"):
		GameManager.leave_queue(self)
	
	print("Slime: Payment done. Leaving!")
	current_state = State.TO_MARKER_1_EXIT
	is_served = false 
	# Reset flip for exit (usually implies facing right/door, adjust if needed)
	anim.flip_h = true 
	go_to_node("Marker1", State.TO_MARKER_1_EXIT)

func handle_arrival():
	velocity = Vector2.ZERO
	update_animation()
	match current_state:
		State.TO_MARKER_1_ENTER:
			current_state = State.SEARCHING
			await get_tree().create_timer(2.0).timeout
			go_to_node("Marker2", State.TO_MARKER_2)
		State.TO_MARKER_2:
			current_state = State.SEARCHING
			await get_tree().create_timer(1.0).timeout
			go_to_target_shelf()
		State.TO_SHELF:
			current_state = State.SEARCHING
			start_searching_logic()
		# --- ARRIVED AT SABOTAGE SPOT ---
		State.TO_PUDDLE_MARKER:
			spawn_puddle_here() 
			leave_shop()        
		# -------------------------------------
		State.TO_CASHIER:
			print("Slime: Arrived at line.")
			current_state = State.WAITING_AT_CASHIER
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
			
		if patience_timer >= 15.0:
			patience_timer = 0.0
			become_angry("Cashier Too Slow")
	else:
		patience_timer = 0.0
		if patience_bar: patience_bar.visible = false

func start_checkout():
	if GameManager.has_method("join_queue"):
		var can_join = GameManager.join_queue(self, max_queue_size)
		if not can_join:
			become_angry("Line Full")
			return
	go_to_node("CashierZone", State.TO_CASHIER)

# --- ITEMS & SHELF WAITING LOGIC ---

func start_searching_logic():
	if attempt_take_item():
		print("Slime: Got item! Browsing for 2s...")
		await get_tree().create_timer(2.0).timeout
		start_checkout()
		return
	
	print("Slime: Item empty! Waiting...")
	if patience_bar:
		patience_bar.max_value = 7.5
		patience_bar.visible = true
		patience_bar.value = 0.0 
	
	var time_waited = 0.0
	
	for i in range(15): 
		await get_tree().create_timer(0.5).timeout
		time_waited += 0.5
		if patience_bar: patience_bar.value = time_waited

		if attempt_take_item():
			print("Slime: Found item! Browsing for 2s...")
			if patience_bar: patience_bar.visible = false 
			await get_tree().create_timer(2.0).timeout
			start_checkout()
			return
	
	print("Slime: Still empty! SPLAT!")
	if patience_bar: patience_bar.value = time_waited
	
	await get_tree().create_timer(2.0).timeout 
	if patience_bar: patience_bar.visible = false
	
	become_angry("Shelf Empty")

func attempt_take_item():
	if target_shelf_node and target_shelf_node.has_method("ai_take_item"):
		var success = target_shelf_node.ai_take_item()
		if success:
			target_shelf_node.ai_take_item() 
			return true
	return false

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
		if next_state == State.TO_PUDDLE_MARKER:
			print("Slime: Can't find " + node_name + ", leaving instead.")
			leave_shop()
		elif current_state != State.TO_DOOR_EXIT:
			leave_shop()
		else:
			queue_free()
		
func go_to_target_shelf():
	if target_shelf_node:
		current_state = State.TO_SHELF
		nav_agent.target_position = target_shelf_node.global_position

# --- UI VISUALS ---
func setup_patience_bar():
	patience_bar = ProgressBar.new()
	add_child(patience_bar)
	patience_bar.size = Vector2(60, 20)
	patience_bar.scale = Vector2(1, 0.2) 
	patience_bar.position = Vector2(-30, -70)
	patience_bar.max_value = 7.5 
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
