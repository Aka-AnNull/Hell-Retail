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

func _ready():
	dash_timer.timeout.connect(_on_dash_timer_timeout)

func _physics_process(_delta):
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	# 2. Check for Dash (Spacebar is usually "ui_accept")
	if Input.is_action_just_pressed("ui_accept") and can_dash and direction != Vector2.ZERO:
		start_dash()

	# 3. Calculate Velocity
	if is_dashing:
		velocity = direction * dash_speed
	else:
		velocity = direction * move_speed
	
	# 4. Move the character
	move_and_slide()
	
	# 5. Handle Animation updates
	update_animation(direction)

func _unhandled_input(event):
	# Check if player pressed "E" (Interact)
	if event.is_action_pressed("interact"):
		attempt_interaction()

# --- CUSTOM FUNCTIONS ---

func start_dash():
	is_dashing = true
	can_dash = false
	dash_timer.wait_time = dash_duration
	dash_timer.start()

func _on_dash_timer_timeout():
	is_dashing = false
	# Wait for cooldown before allowing dash again
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true

func update_animation(direction):
	# Even if you don't have PNGs yet, this logic is ready for them.
	
	if direction != Vector2.ZERO:
		# WALKING
		if is_holding_item:
			anim.play("hold_walk")
		else:
			anim.play("walk")
		
		# Flip sprite based on direction
		if direction.x < 0:
			anim.flip_h = true  # Face Left
		elif direction.x > 0:
			anim.flip_h = false # Face Right
			
	else:
		# IDLE (Standing still)
		if is_holding_item:
			anim.play("hold_idle")
		else:
			anim.play("idle")

func attempt_interaction():
	# Get list of everything touching our "Reach" area
	var interactables = interaction_area.get_overlapping_areas()
	
	for area in interactables:
		# Check if the object has a function called "interact"
		if area.has_method("interact"):
			area.interact(self)
			return # Stop after interacting with one thing
