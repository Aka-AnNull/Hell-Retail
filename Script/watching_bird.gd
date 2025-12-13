extends Area2D

# --- SETTINGS ---
@export var lifetime : float = 7.0 
@onready var prompt = $PromptLabel 
@onready var bird_sprite = $AnimatedSprite2D 
@onready var smoke_effect = $SmokeEffect     

# --- STATE ---
var is_active : bool = false 
var is_boss_mode : bool = false 

# --- SIGNALS ---
signal was_interacted 

func _ready():
	# NO GROUP NEEDED: Player detects 'has_method("interact")' automatically.
	
	if prompt: prompt.visible = false
	
	# Start hidden
	bird_sprite.visible = false
	bird_sprite.play("default") 
	
	if smoke_effect: smoke_effect.visible = false
	
	# Begin spawn sequence
	spawn_sequence()

# ---------------------------------------------------------
# --- NEW HELPER: HANDLE POSITION & FLIPPING ---
# ---------------------------------------------------------
func setup_at_marker(marker_node):
	# 1. Set Position
	global_position = marker_node.global_position
	
	# 2. Check Scale for Flip
	# If the marker in the level is scaled -1 on X, flip the bird!
	if marker_node.scale.x < 0:
		if bird_sprite: bird_sprite.flip_h = true
		# Optional: If you want smoke to flip too, uncomment below
		# if smoke_effect: smoke_effect.flip_h = true
	else:
		if bird_sprite: bird_sprite.flip_h = false

# ---------------------------------------------------------

func spawn_sequence():
	# 1. Play Smoke
	if smoke_effect:
		smoke_effect.visible = true
		smoke_effect.play("default")
		await get_tree().create_timer(0.2).timeout
	
	# 2. Show Bird
	bird_sprite.visible = true
	is_active = true
	
	# 3. Start Timer (ONLY IF NOT BOSS MODE)
	if not is_boss_mode:
		start_lifetime_timer()
	
	# 4. Hide Smoke
	if smoke_effect:
		await smoke_effect.animation_finished
		smoke_effect.visible = false

func start_lifetime_timer():
	await get_tree().create_timer(lifetime).timeout
	
	# If player hasn't caught it yet, leave
	if is_active:
		leave_sequence(false) 

# --- INTERACT LOGIC ---
func interact(player):
	if not is_active: return
	
	print("Watching Bird: CAUGHT BY PLAYER!")
	
	emit_signal("was_interacted")
	
	leave_sequence(true) 

# --- BOSS MODE HELPER ---
func vanish():
	if is_active:
		leave_sequence(false)

# --- EXIT SEQUENCE ---
func leave_sequence(give_reward: bool):
	is_active = false
	if prompt: prompt.visible = false
	
	# 1. TRIGGER REWARD
	if give_reward:
		if GameManager.has_method("burst_stock"):
			GameManager.burst_stock()

	# 2. POOF EFFECT (Exit)
	if smoke_effect:
		smoke_effect.visible = true
		smoke_effect.play("default")
		await get_tree().create_timer(0.1).timeout
	
	# 3. HIDE BIRD
	bird_sprite.visible = false
	
	# 4. CLEANUP
	if smoke_effect:
		await smoke_effect.animation_finished
	
	queue_free()

# --- PROMPT SYSTEM ---
func show_prompt():
	if prompt and is_active: prompt.visible = true

func hide_prompt():
	if prompt: prompt.visible = false
