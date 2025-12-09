extends CharacterBody2D

# --- CONFIGURATION ---
@export var move_speed : float = 300.0
@export var dash_speed : float = 750.0
@export var dash_duration : float = 0.2
@export var dash_cooldown : float = 0.4

# --- STATE VARIABLES ---
var is_dashing : bool = false
var can_dash : bool = true
var is_working : bool = false
var is_slowed : bool = false # <--- NEW: For Slime Logic

# WE STORE THE NAME HERE
var held_item_name : String = "" 

# --- NODE REFERENCES ---
@onready var anim = $AnimatedSprite2D
@onready var dash_timer = $DashTimer
@onready var interaction_area = $InteractionArea

func _ready():
	dash_timer.timeout.connect(_on_dash_timer_timeout)

func _physics_process(_delta):
	# 1. STOP IF WORKING (Cashier Frozen)
	if is_working:
		velocity = Vector2.ZERO
		move_and_slide()
		update_animation(Vector2.ZERO) # Force idle anim
		return

	# 2. MOVEMENT INPUT
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# 3. DASH INPUT
	if Input.is_action_just_pressed("ui_accept") and can_dash and direction != Vector2.ZERO:
		start_dash()

	# 4. CALCULATE SPEED (Merged Logic)
	var current_speed = move_speed
	
	if is_dashing:
		current_speed = dash_speed
	
	# Apply Slime Penalty (50% Slow)
	if is_slowed:
		current_speed *= 0.5
		
	velocity = direction * current_speed
	
	move_and_slide()
	update_animation(direction)

func _unhandled_input(event):
	# INTERACT (E)
	if event.is_action_pressed("interact"):
		attempt_interaction()
		
	# DROP ITEM (Q)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_Q:
		drop_held_item()

# --- INTERACTION LOGIC ---

func attempt_interaction():
	var interactables = interaction_area.get_overlapping_areas()
	
	# We prefer the closest one, or just the first one found
	for area in interactables:
		if area.has_method("interact"):
			area.interact(self) # Pass 'self' so the shelf can read held_item_name
			return

# --- ITEM MANAGEMENT ---

func pickup_item(item_type: String):
	held_item_name = item_type
	print("Player: Picked up " + item_type)
	
func clear_item():
	# Called when giving item to shelf
	print("Player: Used " + held_item_name)
	held_item_name = "" 

func drop_held_item():
	if held_item_name != "":
		print("Player: Dropped " + held_item_name + " on the floor.")
		held_item_name = "" # Clear hands
	else:
		print("Player: Nothing to drop!")

# Helper to check if we hold anything
func is_holding_something() -> bool:
	return held_item_name != ""

# --- DASHING LOGIC ---

func start_dash():
	is_dashing = true
	can_dash = false
	dash_timer.wait_time = dash_duration
	dash_timer.start()

func _on_dash_timer_timeout():
	is_dashing = false
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true

# --- SLIME / DEBUFF LOGIC (NEW) ---

func slow_down(active: bool):
	is_slowed = active
	if is_slowed:
		print("Player: Stuck in slime! Speed reduced.")
		anim.modulate = Color(0.7, 1, 0.7) # Visual tint green
	else:
		print("Player: Free from slime.")
		anim.modulate = Color(1, 1, 1) # Reset color

# --- ANIMATION & WORKING ---

func update_animation(direction):
	# CHECK: Are we holding something?
	var holding = is_holding_something()

	if direction != Vector2.ZERO:
		# MOVING
		if holding:
			anim.play("hold_walk")
		else:
			anim.play("walk")
		
		# Flip sprite
		if direction.x < 0:
			anim.flip_h = true 
		elif direction.x > 0:
			anim.flip_h = false
			
	else:
		# IDLE
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
