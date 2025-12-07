extends Area2D

# --- CONFIGURATION ---
var current_stock = 0
var max_stock = 6
@onready var label = $Label # Make sure you have a Label node as a child!

# --- INTERACTION ---
func interact(player):
	# Logic: If player HAS a box, take it and refill shelf
	if player.is_holding_item == true:
		
		# 1. Check if shelf is full
		if current_stock >= max_stock:
			print("DEBUG: Shelf is full!")
			return # Stop here
			
		# 2. Take item from Player
		player.is_holding_item = false
		print("DEBUG: Putting box on shelf...")
		
		# 3. Update Player Animation (Force them to look empty-handed)
		player.update_animation(Vector2.ZERO)
		
		# 4. Update Shelf Stock
		current_stock += 2
		if current_stock > max_stock:
			current_stock = max_stock
			
		update_visuals()
		
	else:
		print("DEBUG: You need a box first!")

func update_visuals():
	# Update the text label (e.g., "2/6")
	if label:
		label.text = str(current_stock) + "/" + str(max_stock)
		
func ai_take_item():
	if current_stock > 0:
		current_stock -= 1
		update_visuals()
		return true # Tell the Ghost "Yes, you got it"
	else:
		return false # Tell the Ghost "No, it's empty"
