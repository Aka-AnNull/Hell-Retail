extends Node2D
# Called when the node enters the scene tree for the first time.
func _ready():
	$Fade_transition/AnimationPlayer.play("Fade_out")

# Called every frame. 'delta' is the elapsed time since the previous frame.
