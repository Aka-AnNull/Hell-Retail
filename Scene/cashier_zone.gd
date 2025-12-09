extends Area2D

# --- NODES ---
@onready var work_timer = $WorkTimer
@onready var prompt = $PromptLabel 

# --- STATE ---
var player_in_zone : bool = false 

func _ready():
	if prompt: prompt.visible = false
	
	# Connect Signals
	if not work_timer.timeout.is_connected(_on_work_done):
		work_timer.timeout.connect(_on_work_done)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

func _process(_delta):
	# --- SMART PROMPT LOGIC ---
	if prompt:
		# Show [E] ONLY if:
		# 1. Player is standing here
		# 2. Someone is actually in the Global Line
		# 3. We are not currently working
		var has_customers = GameManager.cashier_queue.size() > 0
		
		if player_in_zone and has_customers and work_timer.is_stopped():
			prompt.visible = true
		else:
			prompt.visible = false

# --- INTERACT LOGIC (The Important Part) ---
func interact(player):
	# 1. Check if line is empty
	if GameManager.cashier_queue.is_empty():
		print("Cashier: No customers.")
		return

	# 2. Check if already working
	if not work_timer.is_stopped():
		return

	# 3. GET THE FIRST CUSTOMER
	var current_customer = GameManager.cashier_queue[0]

	# --- FIX: CHECK IF THEY ARE ACTUALLY AT THE COUNTER ---

	if not is_instance_valid(current_customer):
		GameManager.clean_queue()
		return

	# Check if Ghost has arrived. 
	if "current_state" in current_customer:
		# If they are still walking (TO_CASHIER), do not serve yet.
		if current_customer.current_state != current_customer.State.WAITING_AT_CASHIER:
			print("Cashier: Customer is approaching but not here yet!")
			return

	# 4. INSTANTLY SERVE
	if current_customer.has_method("get_served"):
		current_customer.get_served()
		print("Cashier: Transaction started...")
		
		work_timer.start()
		if player.has_method("freeze_for_work"):
			player.freeze_for_work(2.0)

func _on_work_done():
	# The ghost has already left via get_served(), so we just finish the animation here
	print("Cashier: Work done. Next!")

# --- PLAYER DETECTION ONLY ---
# We removed the Ghost detection here because GameManager handles the queue now.
func _on_body_entered(body):
	if body.is_in_group("Player"):
		player_in_zone = true

func _on_body_exited(body):
	if body.is_in_group("Player"):
		player_in_zone = false
