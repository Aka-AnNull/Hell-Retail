extends Area2D

@export var item_name : String = "Cola"
@export var stock_image : Texture2D 

@onready var sprite = $Sprite2D 
@onready var prompt = $PromptLabel # Make sure this matches your Label name!

func _ready():
	if stock_image: sprite.texture = stock_image
	if prompt: prompt.visible = false 
	
	# Connect signals
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	# DEBUG PRINT: What touched me?
	print("Stock touched by: ", body.name)
	
	if body.is_in_group("Player"):
		print("SUCCESS: Player detected. Showing label.")
		if prompt: prompt.visible = true
	else:
		print("FAIL: Touched object is not in 'Player' group.")

func _on_body_exited(body):
	if body.is_in_group("Player"):
		if prompt: prompt.visible = false

func interact(player):
	if player.held_item_name == "":
		player.pickup_item(item_name)
	else:
		print("Stock: Hands full!")
