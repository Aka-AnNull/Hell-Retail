extends Area2D

# --- NODES ---
@onready var work_timer = $WorkTimer
# This looks for the label you just added as a child
@onready var prompt = $PromptLabel 

# --- STATE ---
var customer_queue = [] 
var player_in_zone : bool = false 

func _ready():
	if prompt: prompt.visible = false
	
	# Connect Signals (Safety check)
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
		# 2. There is a customer waiting
		# 3. We are not currently working
		if player_in_zone and customer_queue.size() > 0 and work_timer.is_stopped():
			prompt.visible = true
		else:
			prompt.visible = false

# --- SIGNAL LOGIC ---
func _on_body_entered(body):
	# 1. Is it a Ghost? (Customer)
	if body.has_method("leave_shop"):
		if not body in customer_queue:
			customer_queue.append(body)
			print("Cashier: Customer added.")

	# 2. Is it the Player? (For the Label)
	if body.is_in_group("Player"):
		player_in_zone = true

func _on_body_exited(body):
	# 1. Is it a Ghost?
	if body in customer_queue:
		if work_timer.is_stopped():
			customer_queue.erase(body)

	# 2. Is it the Player?
	if body.is_in_group("Player"):
		player_in_zone = false

# --- INTERACT LOGIC ---
func interact(player):
	if customer_queue.size() > 0:
		if work_timer.is_stopped():
			print("Cashier: Serving...")
			work_timer.start()
			if player.has_method("freeze_for_work"):
				player.freeze_for_work(2.0)
	else:
		print("Cashier: No customers.")

func _on_work_done():
	if customer_queue.size() > 0:
		var served = customer_queue.pop_front()
		if is_instance_valid(served):
			served.leave_shop()
