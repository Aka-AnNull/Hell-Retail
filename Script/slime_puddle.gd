extends Area2D

@onready var sprite = $Sprite2D

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	SoundManager.play_sfx("puddle")
	# --- 1. APPEAR EFFECT (Pop-in like Graveyard) ---
	scale = Vector2(0.1, 0.1) # Start tiny
	var pop_tween = create_tween()
	# Bounce transition makes it feel like it splattered on the floor
	pop_tween.tween_property(self, "scale", Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	# --- 2. WAIT ---
	await get_tree().create_timer(10.0).timeout
	
	# --- 3. DISAPPEAR EFFECT (Fade Out) ---
	var fade_tween = create_tween()
	# Fade the alpha (transparency) from 1.0 to 0.0 over 1 second
	fade_tween.tween_property(self, "modulate:a", 0.0, 1.0)
	
	# Wait for the fade to finish before deleting
	await fade_tween.finished
	
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("Player"):
		if body.has_method("slow_down"):
			body.slow_down(true)

func _on_body_exited(body):
	if body.is_in_group("Player"):
		if body.has_method("slow_down"):
			body.slow_down(false)
