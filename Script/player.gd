extends CharacterBody2D

# --- CONFIGURATION ---
@export var move_speed : float = 300.0
@export var dash_speed : float = 750.0
@export var dash_duration : float = 0.2
@export var dash_cooldown : float = 0.4

# --- STATE VARIABLES ---
var is_dashing : bool = false
var can_dash : bool = true
var is_holding_item : bool = false

# --- NODE REFERENCES ---
@onready var anim = $AnimatedSprite2D
@onready var dash_timer = $DashTimer
@onready var interaction_area = $InteractionArea
@onready var held_item_sprite = $HeldItem # <--- NEW LINE: Reference the floating box

func _ready():
	dash_timer.timeout.connect(_on_dash_timer_timeout)

func _physics_process(_delta):
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if Input.is_action_just_pressed("ui_accept") and can_dash and direction != Vector2.ZERO:
		start_dash()

	if is_dashing:
		velocity = direction * dash_speed
	else:
		velocity = direction * move_speed
	
	move_and_slide()
	update_animation(direction)

func _unhandled_input(event):
	if event.is_action_pressed("interact"):
		print("DEBUG: E key pressed!")
		attempt_interaction()

# --- CUSTOM FUNCTIONS ---

func start_dash():
	is_dashing = true
	can_dash = false
	dash_timer.wait_time = dash_duration
	dash_timer.start()

func _on_dash_timer_timeout():
	is_dashing = false
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true

func update_animation(direction):
	#this line to see what the player thinks is happening
	print("Holding: ", is_holding_item, " | Anim: ", anim.animation)

	if direction != Vector2.ZERO:
		# MOVING
		if is_holding_item:
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
		if is_holding_item:
			anim.play("hold_idle")
		else:
			anim.play("idle")

func attempt_interaction():
	var interactables = interaction_area.get_overlapping_areas()
	
	for area in interactables:
		if area.has_method("interact"):
			area.interact(self)
			return
