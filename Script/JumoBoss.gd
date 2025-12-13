extends CharacterBody2D

# --- SETTINGS ---
@export var slime_puddle_scene : PackedScene
@export var tombstone_scene : PackedScene

# --- NODES ---
@onready var anim = $AnimatedSprite2D

# --- STATE ---
var is_served = false
var patience_timer = 0.0 # Required for CashierZone compatibility

func _ready():
	# Start invisible and high up
	visible = false
	position.y = -600 

# --- PHASE 1: THE FALL ---
func play_entrance(target_pos):
	visible = true
	global_position = Vector2(target_pos.x, -600) # Start high above target
	
	if anim.sprite_frames.has_animation("fall"):
		anim.play("fall")
	
	# Fall Animation
	var tween = create_tween()
	tween.tween_property(self, "global_position:y", target_pos.y, 1.0).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	
	# LANDING
	if anim.sprite_frames.has_animation("idle"):
		anim.play("idle")
	
	# Screen Shake & Wipe Stock
	GameManager.activate_stock_wipe()

# --- PHASE 2: ATTACKS ---
func cast_attack(attack_type: String, markers: Array):
	if is_served: return # Don't attack if game over
	
	if anim.sprite_frames.has_animation("angry"):
		anim.play("angry")
	
	# ---------------------------------------------------------
	# FIX 1: SLIME (Spawn 2 Random Puddles from available spots)
	# ---------------------------------------------------------
	if attack_type == "slime":
		var available_spots = markers.duplicate()
		available_spots.shuffle()
		
		# Spawn exactly 2
		for i in range(2):
			if available_spots.size() > 0:
				var spot = available_spots.pop_front()
				if slime_puddle_scene:
					var slime = slime_puddle_scene.instantiate()
					slime.global_position = spot.global_position
					get_parent().add_child(slime)
			
	# ---------------------------------------------------------
	# FIX 2: WALL (Pick 2 Columns, Spawn 10 stones down)
	# ---------------------------------------------------------
	elif attack_type == "wall":
		var available_cols = markers.duplicate()
		available_cols.shuffle()
		
		# Pick 2 Columns
		for i in range(2):
			if available_cols.size() > 0:
				var start_spot = available_cols.pop_front()
				var start_pos = start_spot.global_position
				
				# Spawn 10 tombstones downwards
				if tombstone_scene:
					for j in range(10): 
						var stone = tombstone_scene.instantiate()
						# 60px gap between stones
						stone.global_position = Vector2(start_pos.x, start_pos.y + (j * 60))
						get_parent().add_child(stone)

	# Reset to idle after 1 second
	await get_tree().create_timer(1.0).timeout
	if anim.sprite_frames.has_animation("idle"):
		anim.play("idle")

# --- PHASE 3: READY TO PAY ---
func become_vulnerable():
	# Visual change: Turn Green or look happy
	modulate = Color(0.5, 1, 0.5) # Light Green
	if anim.sprite_frames.has_animation("happy"):
		anim.play("happy")
	
	print("Jumo: IMPRESSIVE. I WILL PAY NOW.")
	
	# JOIN QUEUE NOW -> This enables the CashierZone prompt!
	if GameManager.has_method("join_queue"):
		GameManager.join_queue(self, 1)

# --- CASHIER INTERFACE ---
# The CashierZone calls this to know how many buttons to spawn
func get_required_coins():
	return 20 

# The CashierZone calls this when you win the minigame
func get_served():
	if is_served: return
	is_served = true
	
	print("Jumo: TRANSACTION COMPLETE.")
	
	# Float away
	if anim.sprite_frames.has_animation("float"):
		anim.play("float")
	
	var tween = create_tween()
	# Slow float (6 seconds)
	tween.tween_property(self, "position:y", -1000.0, 6.0)
	
	await tween.finished
	
	if GameManager.has_method("leave_queue"):
		GameManager.leave_queue(self)
	
	queue_free()
