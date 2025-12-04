extends Node2D

@export var speed: int = 500
@onready var playerS = $"playerSprite"
# Called when the node enters the scene tree for the first time.
func _ready():
	position = Vector2(100,300)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var direction = Input.get_vector("left","right","up","down")
	position += direction*speed*delta
