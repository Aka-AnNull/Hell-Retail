extends Area2D

# --- SETTINGS ---
@export var required_item : String = "Cola"
@export var max_stock : int = 6
@export var shelf_image : Texture2D

var current_stock : int = 0
var player_in_zone : bool = false

# --- NODES ---
@onready var arrow = $GuideArrow
@onready var label = $Label
@onready var max_label = $MaxLabel
@onready var sprite = $Sprite2D
@onready var prompt = $PromptLabel

var player_ref = null

func _ready():
	# --- NEW: AUTO-GROUPING ---
	# This ensures the Level can find this shelf no matter where it is in the tree
	add_to_group("Shelves")

	# 1. Setup Visuals
	if arrow:
		arrow.visible = false
		if "play" in arrow: arrow.play("bounce")
		
	if max_label: max_label.visible = false
	if prompt: prompt.visible = false
	
	if shelf_image:
		sprite.texture = shelf_image
		
	update_visuals()
	player_ref = get_tree().get_first_node_in_group("Player")

	# 2. Connect Signals
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

func _process(_delta):
	# --- VISUAL GUIDE LOGIC ---
	if player_ref:
		var has_correct_item = (player_ref.held_item_name == required_item)
		
		# 1. ARROW & MAX LABEL LOGIC
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

		# 2. PROMPT [E] LOGIC
		if prompt:
			if player_in_zone and has_correct_item:
				prompt.visible = true
			else:
				prompt.visible = false

# --- SIGNAL LOGIC ---
func _on_body_entered(body):
	if body.is_in_group("Player"):
		player_in_zone = true

func _on_body_exited(body):
	if body.is_in_group("Player"):
		player_in_zone = false
		if prompt: prompt.visible = false

# --- INTERACT LOGIC (Player) ---
func interact(player):
	if player.held_item_name == required_item:
		if current_stock < max_stock:
			current_stock += 2 # Your +2 Logic
			
			if current_stock > max_stock:
				current_stock = max_stock
				
			player.clear_item()
			update_visuals()
		else:
			print("Shelf: Full!")
	else:
		if player.held_item_name != "":
			print("Shelf: Wrong item! I need " + required_item)

# --- AI LOGIC ---
func ai_take_item():
	if current_stock > 0:
		current_stock -= 1
		update_visuals()
		return true
	return false

func update_visuals():
	if label:
		label.text = str(current_stock) + "/" + str(max_stock)

# ---------------------------------------------------------
# --- JUDGEMENT LOGIC (For Long Bird / GameManager) ---
# ---------------------------------------------------------

func get_stock_count() -> int:
	return current_stock

func set_stock_count(new_amount: int):
	current_stock = new_amount
	
	# Cap the stock so the skill doesn't overfill visual limits
	if current_stock > max_stock:
		current_stock = max_stock
		
	update_visuals()
