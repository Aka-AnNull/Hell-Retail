extends Area2D

# 1. CONNECT SIGNALS
# You must connect the "area_entered" and "area_exited" signals 
# from the Node tab (next to Inspector) to this script.

func _on_area_entered(area):
	# Check if the "Reach" area of the player entered
	if area.name == "InteractionArea": 
		print("DEBUG: You can press E now!")

func _on_area_exited(area):
	if area.name == "InteractionArea":
		print("DEBUG: You walked away.")

# 2. THE INTERACTION LOGIC
func interact(player):
	if not player.is_holding_item:
		print("DEBUG: Taking box...")
		
		# A. Change the Variable
		player.is_holding_item = true
		
		# B. Force Animation Update Immediately
		# We pass Vector2.ZERO so it defaults to the "hold_idle" animation
		player.update_animation(Vector2.ZERO) 
		
	else:
		print("DEBUG: You are already holding a box!")
