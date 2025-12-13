extends Area2D

@export var item_name : String = "Cola"
@export var stock_image : Texture2D 

@onready var sprite = $Sprite2D 
@onready var prompt = $PromptLabel 

func _ready():
	# 1. Setup
	if stock_image: sprite.texture = stock_image
	if prompt: prompt.visible = false 
	
	# We strictly add this to a group so we can find it later if needed, 
	# but we don't strictly need body_entered for prompts anymore.
	add_to_group("Interactable")

# --- NEW: CONTROLLED BY PLAYER ---
func show_prompt():
	if prompt: prompt.visible = true

func hide_prompt():
	if prompt: prompt.visible = false

# --- INTERACTION ---
func interact(player):
	if player.held_item_name == "":
		player.pickup_item(item_name)
	else:
		print("Stock: Hands full!")
