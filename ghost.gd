extends CharacterBody2D

# --- CONFIGURATION ---
@export var move_speed : float = 120.0
@export var stop_distance : float = 20.0 

# --- SHOPPING LIST ---
# List every shelf name you have here. The Ghost will pick one at random.
var available_shelves = ["Shelf1"]

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
var target_shelf_name = "" # Will be chosen randomly
var target_shelf_node = null

# --- FLOATING VISUAL ---
var float_time = 0.0

func _ready():
	anim.play("idle")
	
	# 1. PICK A RANDOM SHELF
	# Since Ghost buys "all types", he picks one at random.
	if target_shelf_name == "":
		target_shelf_name = available_shelves.pick_random()
		print("Ghost: I decided to buy from: ", target_shelf_name)
	
	# 2. Start the Path
	go_to_node("Marker1", State.TO_MARKER_1_ENTER)

func _physics_process(delta):
	# 1. Float Effect
	float_time += delta * 5.0
	anim.position.y = sin(float_time) * 5.0

	# 2. STOP IF BUSY (Physics Lock)
	if current_state == State.SEARCHING or current_state == State.WAITING_AT_CASHIER:
		velocity = Vector2.ZERO
		move_and_slide()
		
		# --- NEW: VISUAL LOCK ---
		# If waiting at cashier, ignore movement and just stare at the player
		if current_state == State.WAITING_AT_CASHIER:
			anim.flip_h = true # Force Face LEFT (change to false if he looks backwards)
		# ------------------------
		
		return

	# 3. CHECK ARRIVAL
	var dist = global_position.distance_to(nav_agent.target_position)
	var required_dist = 50.0 if current_state == State.TO_CASHIER else stop_distance
	
	if dist < required_dist:
		handle_arrival()
		return

	# 4. MOVE
	var next_pos = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_pos)
	velocity = direction * move_speed
	move_and_slide()
	
	# 5. STANDARD FACING (Only runs if we are moving)
	# This handles the walk to the door, shelf, etc.
	if direction.x < 0: 
		anim.flip_h = true
	elif direction.x > 0: 
		anim.flip_h = false
func handle_arrival():
	velocity = Vector2.ZERO # Hard Stop
	
	match current_state:
		State.TO_MARKER_1_ENTER:
			# Go to Marker 2 (Right side)
			go_to_node("Marker2", State.TO_MARKER_2)
			
		State.TO_MARKER_2:
			# Go to the Randomly Chosen Shelf
			go_to_node(target_shelf_name, State.TO_SHELF)
			
		State.TO_SHELF:
			print("Ghost: At Shelf. Searching...")
			current_state = State.SEARCHING
			start_searching_logic()
			
		State.TO_CASHIER:
			print("Ghost: At Cashier. Waiting for Player.")
			current_state = State.WAITING_AT_CASHIER
			
		State.TO_MARKER_1_EXIT:
			# Go to Door to despawn
			go_to_node("DoorPosition", State.TO_DOOR_EXIT)
			
		State.TO_DOOR_EXIT:
			print("Ghost: Bye bye!")
			queue_free()

# --- ACTION LOGIC ---

func start_searching_logic():
	# Try to take 1 item
	if attempt_take_item():
		print("Ghost: Found it! Waiting 2s...")
		await get_tree().create_timer(2.0).timeout
		go_to_node("CashierZone", State.TO_CASHIER)
	else:
		print("Ghost: Empty! Waiting 10s...")
		await get_tree().create_timer(10.0).timeout
		
		# Try again
		if attempt_take_item():
			print("Ghost: Finally found it!")
			go_to_node("CashierZone", State.TO_CASHIER)
		else:
			print("Ghost: STILL EMPTY! I'M MAD!")
			leave_shop()

func attempt_take_item():
	if target_shelf_node == null:
		# If the node name doesn't exist (e.g., you haven't built Shelf7 yet), this prevents a crash
		target_shelf_node = get_parent().find_child(target_shelf_name, true, false)
	
	if target_shelf_node and target_shelf_node.has_method("ai_take_item"):
		return target_shelf_node.ai_take_item() 
	return false

func leave_shop():
	# Go straight to exit, skipping cashier
	go_to_node("Marker1", State.TO_MARKER_1_EXIT)

func go_to_node(node_name, next_state):
	var target = get_parent().find_child(node_name, true, false)
	if target:
		target_shelf_node = target # Cache if it is a shelf
		current_state = next_state
		
		var offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
		nav_agent.target_position = target.global_position + offset
	else:
		print("ERROR: Could not find node: ", node_name)
		# Fallback: If we can't find a shelf, just leave
		if "Shelf" in node_name:
			leave_shop()
