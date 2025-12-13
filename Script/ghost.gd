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
enum State { TO_MARKER_1_ENTER, TO_MARKER_2, TO_SHELF, SEARCHING, TO_CASHIER, WAITING_AT_CASHIER, TO_MARKER_1_EXIT, TO_DOOR_EXIT }
var current_state = State.TO_MARKER_1_ENTER

# --- MEMORY ---
var desired_item_name = ""   
var target_shelf_node = null 
var cashier_node = null 
var patience_timer : float = 0.0
var is_served : bool = false 

# --- FLOATING ---
var float_time = 0.0

func _ready():
	anim.play("idle") # Start Happy
	setup_patience_bar()
	
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
		print("Ghost Error: Could not find 'DoorPosition' node!")

	# START
	await get_tree().create_timer(1.0).timeout
	go_to_node("Marker1", State.TO_MARKER_1_ENTER)

func _exit_tree():
	if GameManager.has_method("leave_queue"):
		GameManager.leave_queue(self)

func _physics_process(delta):
	# If served (frozen), stop logic
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
	if next_pos == Vector2.ZERO: return
	velocity = global_position.direction_to(next_pos) * move_speed
	move_and_slide()
	anim.flip_h = velocity.x < 0

# --- SERVED LOGIC ---
func get_served():
	if is_served: return 
	
	print("Ghost: Payment started... Waiting 0.5s.")
	
	is_served = true 
	patience_timer = 0.0
	if patience_bar: patience_bar.visible = false
	
	# RESET ANIMATION: If they were angry, make them happy again
	anim.play("idle") 
	
	await get_tree().create_timer(0.5).timeout
	
	if GameManager.has_method("leave_queue"):
		GameManager.leave_queue(self)
	
	print("Ghost: Payment done. Leaving!")
	current_state = State.TO_MARKER_1_EXIT
	is_served = false 
	anim.flip_h = false
	go_to_node("Marker1", State.TO_MARKER_1_EXIT)

func handle_arrival():
	velocity = Vector2.ZERO
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
		State.TO_CASHIER:
			print("Ghost: Arrived at line.")
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
		# --- UPDATE MAX VALUE FOR CASHIER (15s) ---
		if patience_bar and patience_bar.max_value != 15.0:
			patience_bar.max_value = 15.0
			
		patience_timer += delta
		
		if patience_bar:
			patience_bar.visible = true
			patience_bar.value = patience_timer
			
		# --- CHANGED: 15 SECONDS LIMIT ---
		if patience_timer >= 15.0:
			patience_timer = 0.0
			
			# --- ANGRY: TOO SLOW ---
			print("Ghost: >:( TOO SLOW! -1 HP")
			anim.play("angry") # Switch to angry face
			GameManager.take_damage(1)
	else:
		patience_timer = 0.0
		if patience_bar: patience_bar.visible = false

func start_checkout():
	if GameManager.has_method("join_queue"):
		var can_join = GameManager.join_queue(self, max_queue_size)
		if not can_join:
			# --- ANGRY: LINE FULL ---
			print("Ghost: Line full! Angry!")
			anim.play("angry")
			GameManager.take_damage(1)
			leave_shop()
			return
	go_to_node("CashierZone", State.TO_CASHIER)

# --- ITEMS & SHELF WAITING LOGIC ---

func start_searching_logic():
	# 1. Attempt Take (Success Path)
	if attempt_take_item():
		print("Ghost: Got item! Browsing for 2s...")
		await get_tree().create_timer(2.0).timeout
		start_checkout()
		return
	
	# 2. Retry Logic (Waiting for refill)
	print("Ghost: Item empty! Waiting...")
	if patience_bar:
		# --- KEEP MAX VALUE AT 10 FOR SHELF WAITING (SAME AS BEFORE) ---
		patience_bar.max_value = 10.0
		patience_bar.visible = true
		patience_bar.value = 0.0 
	
	var time_waited = 0.0
	for i in range(20): 
		await get_tree().create_timer(0.5).timeout
		time_waited += 0.5
		if patience_bar: patience_bar.value = time_waited

		if attempt_take_item():
			print("Ghost: Found item! Browsing for 2s...")
			if patience_bar: patience_bar.visible = false 
			await get_tree().create_timer(2.0).timeout
			start_checkout()
			return
	
	# 3. Failure Path (Empty Shelf)
	print("Ghost: Still empty! Staring in disappointment for 2s...")
	if patience_bar: patience_bar.value = 10.0
	
	await get_tree().create_timer(2.0).timeout 
	if patience_bar: patience_bar.visible = false
	
	# --- ANGRY: NO ITEM ---
	print("Ghost: ANGRY! -1 HP")
	anim.play("angry") # Switch to angry face
	GameManager.take_damage(1)
	leave_shop()

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

# --- UI VISUALS ---
func setup_patience_bar():
	patience_bar = ProgressBar.new()
	add_child(patience_bar)
	
	# --- THE SQUASH TRICK ---
	patience_bar.size = Vector2(60, 20)
	patience_bar.scale = Vector2(1, 0.2) 
	patience_bar.position = Vector2(-30, -70)
	patience_bar.max_value = 10.0 # Starts at 10, but updates to 15 at cashier
	patience_bar.show_percentage = false
	patience_bar.visible = false
	patience_bar.z_index = 10 
	
	# --- STYLES ---
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
