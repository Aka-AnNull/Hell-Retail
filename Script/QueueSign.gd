extends Label

func _ready():
	# Update immediately on start
	_on_queue_changed(GameManager.cashier_queue.size(), 8)
	
	# Connect to the GameManager signal
	if not GameManager.queue_count_changed.is_connected(_on_queue_changed):
		GameManager.queue_count_changed.connect(_on_queue_changed)

func _on_queue_changed(current_count, max_size):
	# Update the text: "Line: 3/8"
	text =str(current_count) + "/" + str(max_size)
	
	# --- DYNAMIC COLOR LOGIC ---
	if current_count >= 7:
		modulate = Color(1, 0, 0) # RED (Critical: 7, 8)
	elif current_count >= 5:
		modulate = Color(1, 0.5, 0) # ORANGE (Warning: 5, 6)
	else:
		modulate = Color(1, 1, 1) # WHITE (Safe: 0-4)
