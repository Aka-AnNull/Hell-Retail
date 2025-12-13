extends Node2D

# --- NODES ---
@onready var jumo = $JumoBoss
@onready var timer_label = $BossUI/TimerLabel
@onready var black_screen = $BossUI/BlackScreen
@onready var cutscene_label = $BossUI/BlackScreen/CutsceneLabel

# --- MARKER GROUPS ---
@onready var wall_spots = $WallSpots.get_children()
@onready var slime_spots = $SlimeSpots.get_children()
@onready var bird_spots = $BirdSpots.get_children()
@onready var cashier_stand = $CashierStand # Jumo spawns here

# --- SETTINGS ---
var game_time : float = 120.0
var attack_timer : float = 0.0
var phase = "CUTSCENE"
var birds_spawned = false
var game_won = false

@export var watching_bird_scene : PackedScene 

func _ready():
	timer_label.visible = false
	black_screen.visible = true
	black_screen.modulate.a = 1.0
	cutscene_label.text = ""
	
	start_intro_cutscene()

func start_intro_cutscene():
	await show_text("HE IS COMING...")
	await show_text("HE DEMANDS PERFECTION...")
	await show_text("FILL. ALL. SHELVES.")
	
	var tween = create_tween()
	tween.tween_property(black_screen, "modulate:a", 0.0, 2.0)
	await tween.finished
	black_screen.visible = false
	
	if jumo:
		# Jumo falls directly to the cashier stand
		jumo.play_entrance(cashier_stand.global_position)
		await get_tree().create_timer(2.0).timeout
	
	phase = "FIGHT"
	timer_label.visible = true
	attack_timer = 10.0

func show_text(text_content):
	cutscene_label.text = text_content
	cutscene_label.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(cutscene_label, "modulate:a", 1.0, 1.0)
	tween.tween_interval(1.5)
	tween.tween_property(cutscene_label, "modulate:a", 0.0, 1.0)
	await tween.finished

func _process(delta):
	if phase == "FIGHT":
		# 1. TIMER
		game_time -= delta
		update_timer_ui()
		
		if game_time <= 0:
			game_over_lose()
			return

		# 2. BIRDS (60s)
		if game_time <= 60.0 and not birds_spawned:
			spawn_bonus_birds()
			birds_spawned = true

		# 3. ATTACKS
		attack_timer -= delta
		if attack_timer <= 0:
			attack_timer = 15.0
			trigger_boss_attack()

		# 4. CHECK WIN CONDITION (Shelves Full)
		if check_all_shelves_full():
			start_cashier_phase()

	# 5. CHECK FINAL WIN (Boss Gone)
	if phase == "CASHIER" and not is_instance_valid(jumo) and not game_won:
		game_won = true
		game_over_win()

func update_timer_ui():
	var mins = floor(game_time / 60)
	var secs = int(game_time) % 60
	timer_label.text = "%02d:%02d" % [mins, secs]
	if game_time < 30: timer_label.modulate = Color(1, 0, 0)
	else: timer_label.modulate = Color(1, 1, 1)

func trigger_boss_attack():
	if not is_instance_valid(jumo): return
	var attack_type = ["wall", "slime"].pick_random()
	if attack_type == "wall": jumo.cast_attack("wall", wall_spots)
	else: jumo.cast_attack("slime", slime_spots)

func check_all_shelves_full() -> bool:
	var shelves = get_tree().get_nodes_in_group("Shelves")
	for s in shelves:
		if s.current_stock < s.max_stock: 
			return false
	return true

func start_cashier_phase():
	phase = "CASHIER"
	timer_label.modulate = Color(0, 1, 0) # Green
	print("ALL SHELVES FULL! JUMO VULNERABLE.")
	
	# Tell Jumo to join queue
	if is_instance_valid(jumo):
		jumo.become_vulnerable()

func spawn_bonus_birds():
	if not watching_bird_scene: return
	
	var available_spots = bird_spots.duplicate()
	available_spots.shuffle()
	
	var spawned_birds = []
	
	for i in range(2):
		if available_spots.size() > 0:
			var spot = available_spots.pop_front()
			var bird = watching_bird_scene.instantiate()
			
			bird.is_boss_mode = true
			
			# 1. ADD CHILD FIRST (This loads the @onready vars)
			add_child(bird)
			
			# 2. THEN SETUP (Now it can find the sprite to flip)
			bird.setup_at_marker(spot) 
			
			spawned_birds.append(bird)
	
	# CONNECT SIGNALS
	if spawned_birds.size() == 2:
		var bird1 = spawned_birds[0]
		var bird2 = spawned_birds[1]
		
		bird1.was_interacted.connect(bird2.vanish)
		bird2.was_interacted.connect(bird1.vanish)
		
func game_over_lose():
	phase = "LOST"
	GameManager.game_over()

func game_over_win():
	print("YOU BEAT THE GAME!")
	# Transition to Main Menu or Victory Screen
	await get_tree().create_timer(3.0).timeout
	GameManager.game_over()
