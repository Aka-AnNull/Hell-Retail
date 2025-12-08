extends CharacterBody2D

# --- CONFIGURATION ---
@export var move_speed : float = 120.0
@export var stop_distance : float = 20.0 

# --- SHOPPING LIST (ITEM NAMES) ---
var shopping_list = ["Cola", "Coke", "Sprite", "Pepsi"] 

# --- NODES ---
@onready var nav_agent = $NavigationAgent2D
@onready var anim = $AnimatedSprite2D

# --- STATE MACHINE ---
enum State { 
	TO_MARKER_1_ENTER, 
	TO_MARKER_2, 
	TO_SHELF, 
	SEARCHING, 
	TO_CASHIER, 
	WAITING_AT_CASHIER, 
	TO_MARKER_1_EXIT, 
	TO_DOOR_EXIT 
}
var current_state = State.TO_MARKER_1_ENTER

# --- MEMORY ---
var desired_item_name = ""   # "Cola"
var target_shelf_node = null # The actual node (Shelf1)

# --- FLOATING VISUAL ---
var float_time = 0.0

func _ready():
	anim.play("idle")
	
	# 1. SETUP: Pick a random ITEM
	desired_item_name = shopping_list.pick_random()
	print("Ghost: I want to buy " + desired_item_name)
	
	# 2. LOCATE: Find which shelf has this item
	target_shelf_node = find_shelf_for_item(desired_item_name)
	
	if target_shelf_node == null:
		print("Ghost: I wanted " + desired_item_name + " but no shelf has it! Leaving.")
		queue_free()
		return

	# 3. SPAWN: Teleport to Door
	var door = get_parent().find_child("DoorPosition", true, false)
	if door: global_position = door.global_position 
	
	# 4. START: Wait random time then go
	await get_tree().create_timer(randf_range(0.1, 2.0)).timeout
	go_to_node("Marker1", State.TO_MARKER_1_ENTER)

func _physics_process(delta):
	# Float Effect
	float_time += delta * 5.0
	anim.position.y = sin(float_time) * 5.0

	# STOP IF BUSY
	if current_state == State.SEARCHING or current_state == State.WAITING_AT_CASHIER:
		velocity = Vector2.ZERO
		move_and_slide()
		if current_state == State.WAITING_AT_CASHIER: anim.flip_h = true 
		return

	# CHECK ARRIVAL
	var dist = global_position.distance_to(nav_agent.target_position)
	var required_dist = 60.0 if current_state == State.TO_CASHIER else stop_distance
	
	if dist < required_dist:
		handle_arrival()
		return

	# MOVE
	var next_pos = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_pos)
	velocity = direction * move_speed
	move_and_slide()
	
	# FACE DIRECTION
	if direction.x < 0: anim.flip_h = true
	elif direction.x > 0: anim.flip_h = false

func handle_arrival():
	velocity = Vector2.ZERO 
	
	match current_state:
		State.TO_MARKER_1_ENTER:
			print("Ghost: Wait 5s at entrance...")
			current_state = State.SEARCHING
			await get_tree().create_timer(5.0).timeout
			go_to_node("Marker2", State.TO_MARKER_2)
			
		State.TO_MARKER_2:
			print("Ghost: Wait 3s at hallway...")
			current_state = State.SEARCHING
			await get_tree().create_timer(3.0).timeout
			
			# Go to the shelf found in _ready
			go_to_target_shelf()
			
		State.TO_SHELF:
			print("Ghost: Arrived at " + desired_item_name + " shelf.")
			current_state = State.SEARCHING
			start_searching_logic()
			
		State.TO_CASHIER:
			print("Ghost: In line.")
			current_state = State.WAITING_AT_CASHIER
			
		State.TO_MARKER_1_EXIT:
			go_to_node("DoorPosition", State.TO_DOOR_EXIT)
			
		State.TO_DOOR_EXIT:
			queue_free() 

# --- SMART LOGIC ---

func find_shelf_for_item(item_name):
	# Look through all nodes in the Level
	var all_nodes = get_parent().get_children()
	for node in all_nodes:
		# Check if it has the variable 'required_item' (It's a Shelf)
		if "required_item" in node:
			if node.required_item == item_name:
				print("Ghost: Found " + item_name + " at " + node.name)
				return node
	return null

func start_searching_logic():
	# 1. Try take immediately
	if attempt_take_item():
		print("Ghost: Got " + desired_item_name + "!")
		go_to_node("CashierZone", State.TO_CASHIER)
		return

	# 2. Loop Wait (10s)
	print("Ghost: " + desired_item_name + " is empty! Waiting 10s...")
	var timer = 0.0
	while timer < 10.0:
		await get_tree().create_timer(0.5).timeout
		timer += 0.5
		if attempt_take_item():
			print("Ghost: Refilled! Got " + desired_item_name)
			go_to_node("CashierZone", State.TO_CASHIER)
			return 
	
	# 3. Failed
	print("Ghost: Angry! -1 HP")
	GameManager.take_damage(1)
	leave_shop()

func attempt_take_item():
	if target_shelf_node and target_shelf_node.has_method("ai_take_item"):
		return target_shelf_node.ai_take_item() 
	return false

func leave_shop():
	current_state = State.TO_MARKER_1_EXIT
	anim.flip_h = false 
	go_to_node("Marker1", State.TO_MARKER_1_EXIT)

# --- MOVEMENT HELPERS ---

func go_to_node(node_name, next_state):
	var target = get_parent().find_child(node_name, true, false)
	move_to_target(target, next_state)

func go_to_target_shelf():
	move_to_target(target_shelf_node, State.TO_SHELF)

func move_to_target(target_node, next_state):
	if target_node:
		current_state = next_state
		var offset = Vector2(randf_range(-15, 15), randf_range(-15, 15))
		nav_agent.target_position = target_node.global_position + offset
	else:
		print("ERROR: Target node missing")
		if current_state != State.TO_DOOR_EXIT:
			go_to_node("DoorPosition", State.TO_DOOR_EXIT)
