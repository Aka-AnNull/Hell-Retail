extends Control

# --- CONFIGURATION ---
@export var next_scene_path : String = "res://Scene/Intermission.tscn"

# --- NODES ---
# We reference Sprite2D nodes even though the root is Control
@onready var level_sprite = $LevelSprite
@onready var complete_sprite = $CompleteSprite
@onready var skip_text = $SkipText
@onready var fade_overlay = $FadeOverlay
@onready var coin_particles = $CPUParticles2D

var skipped = false

func _ready():
	# 1. Start Invisible
	level_sprite.modulate.a = 0.0
	complete_sprite.modulate.a = 0.0
	skip_text.modulate.a = 0.0
	SoundManager.play_music("complete_song")
	# 2. Fade In Red Background (Black -> Red)
	fade_overlay.visible = true
	fade_overlay.color = Color.BLACK
	
	var boot_tween = create_tween()
	boot_tween.tween_property(fade_overlay, "color:a", 0.0, 1)
	
	# 3. Start Sequence
	start_animation_sequence()

func start_animation_sequence():
	# Wait 1s (Blank Red Screen)
	await get_tree().create_timer(1.0).timeout
	if skipped: return

	# --- ANIMATION 1: LEVEL SPRITE ---
	# Flash White effect
	level_sprite.modulate = Color(5, 5, 5, 0) # Super Bright & Transparent
	var t1 = create_tween()
	t1.tween_property(level_sprite, "modulate:a", 1.0, 0.1) # Appear
	t1.parallel().tween_property(level_sprite, "modulate", Color.WHITE, 0.5) # Fade to normal color
	
	await get_tree().create_timer(1.0).timeout
	if skipped: return

	# --- ANIMATION 2: COMPLETE SPRITE ---
	complete_sprite.modulate = Color(5, 5, 5, 0)
	var t2 = create_tween()
	t2.tween_property(complete_sprite, "modulate:a", 1.0, 0.1)
	t2.parallel().tween_property(complete_sprite, "modulate", Color.WHITE, 0.5)
	coin_particles.emitting = true
	await get_tree().create_timer(1.0).timeout
	if skipped: return
	
	# --- SHOW TEXT ---
	var t3 = create_tween()
	t3.tween_property(skip_text, "modulate:a", 1.0, 0.5)
	
	# --- AUTO EXIT (9s total) ---
	await get_tree().create_timer(3.0).timeout
	if not skipped:
		go_next_scene()

func _input(event):
	if event.is_action_pressed("ui_accept") and not skipped:
		go_next_scene()

func go_next_scene():
	if skipped: return
	skipped = true
	
	# Fade to Black
	var out_tween = create_tween()
	out_tween.tween_property(fade_overlay, "color:a", 1.0, 1)
	await out_tween.finished
	
	get_tree().change_scene_to_file(next_scene_path)
