extends StaticBody2D

# --- CONFIGURATION ---
var health : int = 5

@onready var sprite = $Sprite2D

func _ready():
	# Optional: Add a small "pop" effect when it spawns
	SoundManager.play_sfx("tomb_spawn")
	scale = Vector2(0.1, 0.1)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BOUNCE)

func _input_event(viewport, event, shape_idx):
	# Detect Left Mouse Click
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		take_hit()

func take_hit():
	health -= 1
	SoundManager.play_sfx("tomb_break")
	# --- VISUAL FEEDBACK (Shake/Scale) ---
	# This makes it feel satisfying to click
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(0.12, 0.12), 0.05) # Squash
	tween.tween_property(sprite, "scale", Vector2(0.1, 0.1), 0.05) # Return
	
	# Optional: Flash red
	sprite.modulate = Color(1, 0.5, 0.5) 
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color(1, 1, 1)

	if health <= 0:
		break_grave()

func break_grave():
	# Optional: Spawn particle effect or play sound here
	print("Graveyard Destroyed!")
	queue_free()
