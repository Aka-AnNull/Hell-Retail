extends CharacterBody2D

# --- CONFIGURATION ---
@export var move_speed : float = 300.0
@export var dash_speed : float = 750.0
@export var dash_duration : float = 0.2
@export var dash_cooldown : float = 0.4
@export var boost_multiplier : float = 1.5 

# --- STATE VARIABLES ---
var is_dashing : bool = false
var can_dash : bool = true
var is_working : bool = false
var is_slowed : bool = false 
var is_boosted : bool = false 
var is_taking_damage : bool = false # Prevents color overrides
var is_stunned : bool = false

# WE STORE THE NAME HERE
var held_item_name : String = "" 

# --- SIGNALS ---
# Signal removed: Player no longer triggers ability directly
# signal ability_activated 

# --- NODE REFERENCES ---
@onready var anim = $AnimatedSprite2D
@onready var dash_timer = $DashTimer
@onready var interaction_area = $InteractionArea
@onready var slash_effect = $SlashEffect 

func _ready():
	dash_timer.timeout.connect(_on_dash_timer_timeout)
	
	# Hide the effect initially just in case
	if slash_effect:
		slash_effect.visible = false

func _physics_process(delta):
	# 0. STOP IF STUNNED (Highest Priority)
	if is_stunned:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# 1. STOP IF WORKING (Cashier Frozen)
	if is_working:
		velocity = Vector2.ZERO
		move_and_slide()
		update_animation(Vector2.ZERO)
		return

	# 2. MOVEMENT INPUT
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# 3. DASH INPUT
	if Input.is_action_just_pressed("ui_accept") and can_dash and direction != Vector2.ZERO:
		start_dash()

	# 4. CALCULATE SPEED
	var current_speed = move_speed
	
	if is_dashing:
		current_speed = dash_speed
	elif is_boosted: 
		current_speed *= boost_multiplier
	
	# Apply Slime Penalty (50% Slow)
	if is_slowed:
		current_speed *= 0.5
		
	velocity = direction * current_speed
	
	move_and_slide()
	update_animation(direction)

func _unhandled_input(event):
	# Prevent interaction if Stunned or Working
	if is_stunned or is_working:
		return

	# INTERACT (E)
	if event.is_action_pressed("interact"):
		attempt_interaction()
		
	# DROP ITEM (Q)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_Q:
		drop_held_item()

	# (REMOVED 'P' KEY LOGIC HERE)

# --- STUN LOGIC ---

func apply_stun(duration: float):
	if is_stunned: return # Don't stack stuns
	
	print("Player: STUNNED by Reaper!")
	is_stunned = true
	is_dashing = false # Cancel dash if active
	
	# Show the Slash Effect
	if slash_effect:
		slash_effect.visible = true
		slash_effect.play("default")
		
	# Wait for duration
	await get_tree().create_timer(duration).timeout
	
	# Reset
	is_stunned = false
	print("Player: Recovered from stun.")
	
	# Hide the Slash Effect
	if slash_effect:
		slash_effect.visible = false
		slash_effect.stop()

# --- DAMAGE LOGIC ---

func take_damage(amount):
	print("Player took ", amount, " damage!")
	
	# 1. Set flag so other colors don't override this
	is_taking_damage = true 
	
	# 2. Turn Red
	anim.modulate = Color(1, 0, 0) 
	
	# 3. Wait a split second
	await get_tree().create_timer(0.2).timeout
	
	# 4. Release flag and reset
	is_taking_damage = false
	_reset_color()

# --- SPEED BOOST LOGIC ---

func apply_speed_boost(duration: float):
	if is_boosted:
		return # Don't stack boosts
		
	is_boosted = true
	print("Player: SPEED BOOST!")
	_reset_color() # Update color to White
	
	await get_tree().create_timer(duration).timeout
	
	is_boosted = false
	print("Player: Boost ended.")
	_reset_color()

# --- SLIME / DEBUFF LOGIC ---

func slow_down(active: bool):
	is_slowed = active
	if is_slowed:
		print("Player: Stuck in slime! Speed reduced.")
	else:
		print("Player: Free from slime.")
	
	# Update color
	_reset_color() 

# --- HELPER: COLOR MANAGER (PRIORITY SYSTEM) ---
func _reset_color():
	# PRIORITY 1: Taking Damage (Red Flash)
	if is_taking_damage:
		return 

	# PRIORITY 2: Speed Boost (Bright White)
	if is_boosted:
		anim.modulate = Color(2, 2, 2) 
		
	# PRIORITY 3: Slime (Sickly Green)
	elif is_slowed:
		anim.modulate = Color(0.7, 1, 0.7) 
		
	# PRIORITY 4: Normal (White/No Tint)
	else:
		anim.modulate = Color(1, 1, 1) 

# --- INTERACTION LOGIC ---

func attempt_interaction():
	var interactables = interaction_area.get_overlapping_areas()
	for area in interactables:
		if area.has_method("interact"):
			area.interact(self) 
			return

# --- ITEM MANAGEMENT ---

func pickup_item(item_type: String):
	held_item_name = item_type
	print("Player: Picked up " + item_type)
	
func clear_item():
	print("Player: Used " + held_item_name)
	held_item_name = "" 

func drop_held_item():
	if held_item_name != "":
		print("Player: Dropped " + held_item_name + " on the floor.")
		held_item_name = "" 
	else:
		print("Player: Nothing to drop!")

func is_holding_something() -> bool:
	return held_item_name != ""

# --- DASHING LOGIC ---

func start_dash():
	if is_stunned: return # Cannot dash if stunned
	
	is_dashing = true
	can_dash = false
	dash_timer.wait_time = dash_duration
	dash_timer.start()

func _on_dash_timer_timeout():
	is_dashing = false
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true

# --- ANIMATION & WORKING ---

func update_animation(direction):
	if is_stunned:
		# Optional: play "hurt" animation if you have one
		return

	var holding = is_holding_something()

	if direction != Vector2.ZERO:
		if holding:
			anim.play("hold_walk")
		else:
			anim.play("walk")
		
		if direction.x < 0:
			anim.flip_h = true 
		elif direction.x > 0:
			anim.flip_h = false
	else:
		if holding:
			anim.play("hold_idle")
		else:
			anim.play("idle")

func freeze_for_work(duration):
	is_working = true
	can_dash = false 
	print("Player: Working hard...")
	
	await get_tree().create_timer(duration).timeout
	
	is_working = false
	can_dash = true
	print("Player: Done working!")
