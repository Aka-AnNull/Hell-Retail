extends Area2D

# --- SETTINGS ---
@export var required_item : String = "Cola"
@export var max_stock : int = 6

# 1. SHELF APPEARANCE (The Wood/Metal)
@export var shelf_image : Texture2D 

# 2. ITEM APPEARANCE (The Cans/Books) - NEW!
@export var item_frames : SpriteFrames 

# --- NODES ---
@onready var arrow = $GuideArrow
@onready var label = $Label
@onready var max_label = $MaxLabel
@onready var prompt = $PromptLabel
@onready var body_sprite = $BodySprite 

# Safe reference for the item layer (might be null on columns)
var item_sprite : AnimatedSprite2D = null

# --- STATE ---
var current_stock : int = 0
var player_in_zone : bool = false
var player_ref = null

func _ready():
	add_to_group("Shelves")
	
	# 1. SAFELY FIND ITEM LAYER
	item_sprite = get_node_or_null("ItemSprite")

	# 2. APPLY TEXTURE (Body)
	if body_sprite and shelf_image:
		body_sprite.texture = shelf_image
	
	# 3. APPLY FRAMES (Items) - NEW!
	if item_sprite and item_frames:
		item_sprite.sprite_frames = item_frames
	
	# 4. HANDLE COLUMNS (No Required Item)
	if required_item == "None" or required_item == "":
		if item_sprite: item_sprite.visible = false
		if label: label.visible = false
	else:
		if item_sprite: item_sprite.visible = true
	
	# 5. HIDE UI
	if arrow:
		arrow.visible = false
		if "play" in arrow: arrow.play("bounce")
	if max_label: max_label.visible = false
	if prompt: prompt.visible = false
	
	update_visuals()
	
	player_ref = get_tree().get_first_node_in_group("Player")

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

func _process(_delta):
	# (Your existing guide logic)
	if player_ref:
		var has_correct_item = (player_ref.held_item_name == required_item)
		
		if required_item != "None" and required_item != "":
			if arrow and max_label:
				if has_correct_item:
					if current_stock >= max_stock:
						arrow.visible = false
						max_label.visible = true
					else:
						arrow.visible = true
						max_label.visible = false
				else:
					arrow.visible = false
					max_label.visible = false

		if prompt:
			if player_in_zone and has_correct_item and required_item != "None":
				prompt.visible = true
			else:
				prompt.visible = false

func _on_body_entered(body):
	if body.is_in_group("Player"):
		player_in_zone = true

func _on_body_exited(body):
	if body.is_in_group("Player"):
		player_in_zone = false
		if prompt: prompt.visible = false

func interact(player):
	if required_item == "None" or required_item == "": return

	if player.held_item_name == required_item:
		if current_stock < max_stock:
			current_stock += 2
			if current_stock > max_stock:
				current_stock = max_stock
			player.clear_item()
			update_visuals()
		else:
			print("Shelf: Full!")
	else:
		if player.held_item_name != "":
			print("Shelf: Wrong item! I need " + required_item)

func ai_take_item():
	if current_stock > 0:
		current_stock -= 1
		update_visuals()
		return true
	return false

# ---------------------------------------------------------
# --- VISUAL UPDATE LOGIC ---
# ---------------------------------------------------------
func update_visuals():
	if label:
		label.text = str(current_stock) + "/" + str(max_stock)
	
	# ANIMATION LOGIC
	if item_sprite and item_sprite.sprite_frames:
		# Check if we have animations loaded
		if item_sprite.sprite_frames.has_animation("default"):
			var total_frames = item_sprite.sprite_frames.get_frame_count("default")
			
			if total_frames > 0:
				var percent = float(current_stock) / float(max_stock)
				if max_stock == 0: percent = 0.0
				
				# Map percentage to specific frame number
				var target_frame = int(percent * (total_frames - 1))
				item_sprite.frame = target_frame

func get_stock_count() -> int:
	return current_stock

func set_stock_count(new_amount: int):
	if required_item == "None": return
	current_stock = new_amount
	if current_stock > max_stock:
		current_stock = max_stock
	update_visuals()
