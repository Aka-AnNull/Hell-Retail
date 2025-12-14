extends Control

# --- NODES ---
@onready var stamp_result = $StampContainer/StampResult
@onready var stamper_tool = $StampContainer/StamperTool
@onready var stamp_container = $StampContainer
@onready var background = $Background # <--- NEW: Need this for the flicker

# --- BUTTONS ---
@onready var try_again_btn = $TryAgainButton
@onready var menu_btn = $MenuButton

# --- STATE ---
var container_start_pos : Vector2
var tool_start_pos : Vector2

func _ready():
	# 1. REMEMBER POSITIONS
	container_start_pos = stamp_container.position
	tool_start_pos = stamper_tool.position
	
	# 2. HIDE STUFF
	stamp_result.visible = false
	try_again_btn.modulate.a = 0.0
	menu_btn.modulate.a = 0.0
	
	# 3. MOVE TOOL UP
	stamper_tool.position = tool_start_pos + Vector2(0, -600)
	
	# 4. START THE HURT SEQUENCE
	play_hurt_flash_then_stamp()

func play_hurt_flash_then_stamp():
	# Save the "Normal" dark color you chose in the editor
	var normal_color = background.color
	SoundManager.play_sfx("gameover")
	# --- FLICKER EFFECT ---
	# 1. Start Pure Red
	background.color = Color.RED
	await get_tree().create_timer(0.1).timeout
	
	# 2. Flash White (Hurt!)
	background.color = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	
	# 3. Flash Red again
	background.color = Color.RED
	
	# 4. Fade to Normal Dark Color
	var tween = create_tween()
	tween.tween_property(background, "color", normal_color, 0.5)
	
	await tween.finished
	await get_tree().create_timer(2.0).timeout
	# --- NOW DO THE STAMP ---
	slam_stamp()

func slam_stamp():
	# --- SLAM DOWN ---
	SoundManager.play_sfx("stamp")
	await get_tree().create_timer(0.3).timeout
	var tween = create_tween()
	tween.tween_property(stamper_tool, "position", tool_start_pos, 0.3).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	await tween.finished
	# --- IMPACT ---
	stamp_result.visible = true
	shake_screen()
	# --- HOLD (1 Sec) ---
	await get_tree().create_timer(1.0).timeout
	SoundManager.play_music("gameover_song")
	# --- EXIT & REVEAL BUTTONS ---
	var exit_tween = create_tween()
	exit_tween.parallel().tween_property(stamper_tool, "position:y", tool_start_pos.y - 100.0, 1.0)
	exit_tween.parallel().tween_property(stamper_tool, "modulate:a", 0.0, 1.0)
	
	# Show buttons
	exit_tween.parallel().tween_property(try_again_btn, "modulate:a", 1.0, 1.0)
	exit_tween.parallel().tween_property(menu_btn, "modulate:a", 1.0, 1.0)

func shake_screen():
	var shake = create_tween()
	shake.tween_property(stamp_container, "position:x", container_start_pos.x + 10.0, 0.05)
	shake.tween_property(stamp_container, "position:x", container_start_pos.x - 10.0, 0.05)
	shake.tween_property(stamp_container, "position:y", container_start_pos.y - 10.0, 0.05)
	shake.tween_property(stamp_container, "position", container_start_pos, 0.05)

# --- BUTTONS ---
func _on_try_again_button_pressed():
	SoundManager.play_sfx("ui_click")
	SoundManager.fade_out_music(0.5)
	GameManager.current_hp = GameManager.max_hp
	if GameManager.current_level == 8:
		get_tree().change_scene_to_file("res://Scene/BossFight.tscn")
	else:
		get_tree().change_scene_to_file("res://Scene/Intermission.tscn")

func _on_menu_button_pressed():
	SoundManager.play_sfx("ui_click")
	SoundManager.fade_out_music(0.5)
	get_tree().change_scene_to_file("res://Scene/main_menu.tscn")

func _on_try_again_button_mouse_entered():
	SoundManager.play_sfx("ui_hover")
	pass 

func _on_menu_button_mouse_entered():
	SoundManager.play_sfx("ui_hover")
	pass
