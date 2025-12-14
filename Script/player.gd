extends CharacterBody2D

# --- CONFIGURATION ---
@export var move_speed : float = 300.0
@export var dash_speed : float = 750.0
@export var dash_duration : float = 0.2
@export var dash_cooldown : float = 0.4
@export var boost_multiplier : float = 1.5 

# --- CHEAT SETTINGS ---
@export var cheat_mode_enabled : bool = true 

# --- STATE VARIABLES ---
var is_dashing : bool = false
var can_dash : bool = true
var is_working : bool = false
var is_slowed : bool = false 
var is_boosted : bool = false 
var is_taking_damage : bool = false 
var is_stunned : bool = false

# WE STORE THE NAME HERE
var held_item_name : String = "" 

# --- INTERACTION MEMORY ---
var active_interactable = null

# --- NODE REFERENCES ---
@onready var anim = $AnimatedSprite2D
@onready var dash_timer = $DashTimer
@onready var interaction_area = $InteractionArea
@onready var slash_effect = $SlashEffect 
@onready var footstep_timer = $FootstepTimer

func _ready():
	dash_timer.timeout.connect(_on_dash_timer_timeout)
	
	if slash_effect:
		slash_effect.visible = false

func _physics_process(delta):
	# 0. STOP IF STUNNED 
	if is_stunned:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# 1. STOP IF WORKING 
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
	
	if is_slowed:
		current_speed *= 0.5
		
	velocity = direction * current_speed
	
	move_and_slide()
	
	# --- [NEW] FOOTSTEP LOGIC STARTS HERE ---
	# Only play sound if moving AND the timer is ready
	if velocity.length() > 0 and footstep_timer.is_stopped():
		# Play walk sound with slight pitch randomization (0.8 to 1.2)
		SoundManager.play_sfx("walk", randf_range(0.8, 1.2))
		footstep_timer.start()
	# --- [NEW] END ---

	update_animation(direction)
	
	# 5. SMART INTERACTION CHECK
	_update_closest_interactable()

func _unhandled_input(event):
	if is_stunned or is_working:
		return

	# INTERACT (E)
	if event.is_action_pressed("interact"):
		attempt_interaction()
		
	# DROP ITEM (Q)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_Q:
		drop_held_item()

	# CHEAT: BURST STOCK (P)
	elif cheat_mode_enabled and event is InputEventKey and event.pressed and event.keycode == KEY_P:
		burst_stock()

# --- DASHING LOGIC (UPDATED) ---

func start_dash():
	if is_stunned: return 
	is_dashing = true
	can_dash = false
	SoundManager.play_sfx("dash")
	# --- NEW: SPAWN EXACTLY 4 GHOSTS ---
	spawn_ghost_trail() 
	
	dash_timer.wait_time = dash_duration
	dash_timer.start()

func spawn_ghost_trail():
	var ghost_count = 4
	# Calculate how long to wait between each ghost to fit them all in the dash
	var wait_time = dash_duration / float(ghost_count)
	
	for i in range(ghost_count):
		# Stop spawning if dash was cancelled (e.g. stunned)
		if not is_dashing: return
		
		spawn_dash_ghost()
		await get_tree().create_timer(wait_time).timeout

func _on_dash_timer_timeout():
	is_dashing = false
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true

# --- GHOST VISUALS ---

func spawn_dash_ghost():
	var ghost = Sprite2D.new()
	var frame_tex = anim.sprite_frames.get_frame_texture(anim.animation, anim.frame)
	ghost.texture = frame_tex
	
	# Copy Transform
	ghost.global_position = anim.global_position
	ghost.scale = anim.global_scale
	ghost.flip_h = anim.flip_h
	ghost.centered = anim.centered
	ghost.offset = anim.offset
	ghost.z_index = 0 
	
	# Make it visible (Grey)
	ghost.modulate = Color(0.5, 0.5, 0.5, 0.5) 
	
	get_parent().add_child(ghost)
	
	# Smooth Fade Out
	var tween = create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.5) 
	tween.tween_callback(ghost.queue_free)

# --- (Rest of your code remains the same: Stun, Damage, Boost, etc.) ---

# --- CHEAT LOGIC ---
func burst_stock():
	# Now simply calls the Manager
	GameManager.burst_stock()

# --- SMART INTERACTION LOGIC ---
func _update_closest_interactable():
	var all_areas = interaction_area.get_overlapping_areas()
	var closest_dist = 9999.0
	var closest_obj = null

	for area in all_areas:
		if area.has_method("interact"):
			var dist = global_position.distance_to(area.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest_obj = area

	if closest_obj != active_interactable:
		if active_interactable and active_interactable.has_method("hide_prompt"):
			active_interactable.hide_prompt()
		active_interactable = closest_obj
		if active_interactable and active_interactable.has_method("show_prompt"):
			active_interactable.show_prompt()

func attempt_interaction():
	if active_interactable and active_interactable.has_method("interact"):
		active_interactable.interact(self)

# --- STUN LOGIC ---
func apply_stun(duration: float):
	if is_stunned: return 
	print("Player: STUNNED by Reaper!")
	SoundManager.play_sfx("slash")
	is_stunned = true
	is_dashing = false 
	if slash_effect:
		slash_effect.visible = true
		slash_effect.play("default")
	await get_tree().create_timer(duration).timeout
	is_stunned = false
	if slash_effect:
		slash_effect.visible = false
		slash_effect.stop()

# --- DAMAGE LOGIC ---
func take_damage(amount):
	print("Player took ", amount, " damage!")
	is_taking_damage = true 
	anim.modulate = Color(1, 0, 0) 
	await get_tree().create_timer(0.2).timeout
	is_taking_damage = false
	_reset_color()

# --- SPEED BOOST LOGIC ---
func apply_speed_boost(duration: float):
	if is_boosted: return 
	is_boosted = true
	SoundManager.play_sfx("boost")
	_reset_color() 
	await get_tree().create_timer(duration).timeout
	is_boosted = false
	_reset_color()

# --- SLIME / DEBUFF LOGIC ---
func slow_down(active: bool):
	is_slowed = active
	_reset_color() 

# --- HELPER: COLOR MANAGER ---
func _reset_color():
	if is_taking_damage: return 

	if is_boosted:
		anim.modulate = Color(2, 2, 2) 
	elif is_slowed:
		anim.modulate = Color(0.7, 1, 0.7) 
	else:
		anim.modulate = Color(1, 1, 1) 

# --- ITEM MANAGEMENT ---
func pickup_item(item_type: String):
	held_item_name = item_type
	print("Player: Picked up " + item_type)
	SoundManager.play_sfx("pickup")
func clear_item():
	print("Player: Used " + held_item_name)
	held_item_name = "" 
	SoundManager.play_sfx("refill")
func drop_held_item():
	if held_item_name != "":
		print("Player: Dropped " + held_item_name + " on the floor.")
		held_item_name = "" 
		SoundManager.play_sfx("drop")
	else:
		print("Player: Nothing to drop!")

func is_holding_something() -> bool:
	return held_item_name != ""

# --- ANIMATION & WORKING ---
func update_animation(direction):
	if is_stunned: return

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
	await get_tree().create_timer(duration).timeout
	is_working = false
	can_dash = true
