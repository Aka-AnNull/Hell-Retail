extends Area2D

@onready var work_timer = $WorkTimer
var current_customer = null 

func _ready():
	# Connect signals via code to be safe
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	work_timer.timeout.connect(_on_work_done)

func _on_body_entered(body):
	# Detect if the Ghost arrived
	if "Ghost" in body.name: 
		current_customer = body
		print("Cashier: Customer waiting! Press E.")

func _on_body_exited(body):
	if body == current_customer:
		current_customer = null

# This function is called when PLAYER presses E inside the zone
func interact(player):
	if current_customer != null:
		if work_timer.is_stopped():
			print("Cashier: Processing transaction...")  
			# 1. Start the Timer logic
			work_timer.start()
			# 2. FREEZE THE PLAYER
			if player.has_method("freeze_for_work"):
				player.freeze_for_work(2.0) # Freeze for 2 seconds
		else:
			print("Cashier: Already working!")

func _on_work_done():
	print("Cashier: Done!")
	if current_customer and current_customer.has_method("leave_shop"):
		current_customer.leave_shop()
	current_customer = null
