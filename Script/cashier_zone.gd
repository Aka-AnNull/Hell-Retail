extends Area2D

# --- NODES ---
@onready var prompt = $PromptLabel
@onready var minigame_layer = $MinigameLayer
@onready var background_panel = $MinigameLayer/Background
@onready var coin_effect = $CoinEffect 

# --- RESOURCES ---
@export var coin_frames : SpriteFrames 

# --- SETTINGS ---
# Adjust this number in the Inspector to make buttons bigger/smaller!
@export var coin_scale_modifier : float = 3.0 
var total_buttons = 5
var buttons_clicked = 0
var is_minigame_active = false
var player_ref = null
var player_in_zone : bool = false 

# --- SCREEN SETTINGS ---
var border_margin = 20 

func _ready():
	if minigame_layer: minigame_layer.visible = false
	if background_panel: background_panel.visible = false
	if coin_effect: coin_effect.visible = false
	if prompt: prompt.visible = false
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

func _process(_delta):
	if prompt:
		var has_customers = GameManager.cashier_queue.size() > 0
		if player_in_zone and has_customers and not is_minigame_active:
			var front_customer = GameManager.cashier_queue[0]
			if is_instance_valid(front_customer) and front_customer.get("is_served"):
				prompt.visible = false
			else:
				prompt.visible = true
		else:
			prompt.visible = false

# --- INTERACT LOGIC ---
func interact(player):
	if is_minigame_active: return
	if GameManager.cashier_queue.is_empty(): return

	var current_customer = GameManager.cashier_queue[0]
	if not is_instance_valid(current_customer):
		GameManager.clean_queue()
		return

	if current_customer.get("is_served"): return

	if "current_state" in current_customer:
		if current_customer.current_state != current_customer.State.WAITING_AT_CASHIER:
			return

	start_minigame(player)

# --- MINIGAME LOGIC ---

func start_minigame(player):
	print("Cashier: Starting Coin Game!")
	is_minigame_active = true
	buttons_clicked = 0
	player_ref = player
	
	if player_ref and player_ref.has_method("freeze_for_work"):
		player_ref.is_working = true 
	
	minigame_layer.visible = true
	background_panel.visible = true
	background_panel.position = (get_viewport_rect().size - background_panel.size) / 2
	
	if prompt: prompt.visible = false
	
	spawn_random_coins()

func spawn_random_coins():
	# Clear old stuff
	for child in background_panel.get_children():
		child.queue_free()
		
	if not coin_frames:
		print("ERROR: No SpriteFrames assigned to Cashier!")
		return

	var panel_size = background_panel.size
	
	# --- AUTO-SIZING LOGIC ---
	var first_texture = coin_frames.get_frame_texture("default", 0)
	var button_size = Vector2(50, 50) # Fallback default
	
	if first_texture:
		# We multiply the raw image size by your modifier (e.g. x3)
		button_size = first_texture.get_size() * coin_scale_modifier
	
	var existing_rects = []
	
	for i in range(total_buttons):
		# 1. Invisible Button
		var btn = Button.new()
		btn.size = button_size
		btn.flat = true 
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		
		# 2. Animated Sprite
		var anim_sprite = AnimatedSprite2D.new()
		anim_sprite.sprite_frames = coin_frames
		anim_sprite.play("default")
		
		# --- KEY: Apply the same scale to the sprite ---
		anim_sprite.scale = Vector2(coin_scale_modifier, coin_scale_modifier)
		anim_sprite.centered = false 
		
		btn.add_child(anim_sprite)
		
		# 3. Positioning (No Overlap)
		var safe_pos = Vector2.ZERO
		var attempts = 0
		var found_spot = false
		
		while attempts < 50 and not found_spot:
			attempts += 1
			
			var min_x = border_margin
			var max_x = panel_size.x - button_size.x - border_margin
			var min_y = border_margin
			var max_y = panel_size.y - button_size.y - border_margin
			
			# Safety check if button is bigger than panel
			if min_x > max_x: max_x = min_x
			if min_y > max_y: max_y = min_y
			
			var random_x = randf_range(min_x, max_x)
			var random_y = randf_range(min_y, max_y)
			var candidate_rect = Rect2(random_x, random_y, button_size.x, button_size.y)
			
			var overlap = false
			for r in existing_rects:
				if candidate_rect.intersects(r.grow(5)): 
					overlap = true
					break
			
			if not overlap:
				safe_pos = Vector2(random_x, random_y)
				existing_rects.append(candidate_rect)
				found_spot = true
		
		btn.position = safe_pos
		btn.pressed.connect(_on_coin_clicked.bind(btn, anim_sprite))
		background_panel.add_child(btn)

func _on_coin_clicked(btn_node, sprite_node):
	# Change animation to "pressed" (green coin)
	if sprite_node.sprite_frames.has_animation("pressed"):
		sprite_node.play("pressed")
	else:
		sprite_node.modulate = Color(0.5, 0.5, 0.5)
	
	btn_node.disabled = true
	buttons_clicked += 1
	
	if buttons_clicked >= total_buttons:
		await get_tree().create_timer(0.2).timeout
		finish_minigame()

func finish_minigame():
	print("Cashier: Transaction Complete!")
	
	background_panel.visible = false
	minigame_layer.visible = false
	is_minigame_active = false
	
	if player_ref:
		player_ref.is_working = false
	
	if GameManager.cashier_queue.size() > 0:
		var customer = GameManager.cashier_queue[0]
		if is_instance_valid(customer) and not customer.get("is_served"):
			if customer.has_method("get_served"):
				customer.get_served()
	
	play_coin_animation()

func play_coin_animation():
	if not coin_effect: return
	
	coin_effect.visible = true
	coin_effect.position = Vector2(0, -60) 
	coin_effect.modulate.a = 1.0 
	
	if "play" in coin_effect:
		coin_effect.play("default") 
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(coin_effect, "position:y", -120.0, 1.0) 
	tween.tween_property(coin_effect, "modulate:a", 0.0, 1.0)     
	
	await tween.finished
	coin_effect.visible = false
	coin_effect.stop()

# --- PLAYER DETECTION ---
func _on_body_entered(body):
	if body.is_in_group("Player"):
		player_in_zone = true
		player_ref = body

func _on_body_exited(body):
	if body.is_in_group("Player"):
		player_in_zone = false
		player_ref = null
		if prompt: prompt.visible = false
