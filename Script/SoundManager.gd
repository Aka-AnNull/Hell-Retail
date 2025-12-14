extends Node

@onready var music_player = $MusicPlayer

# --- REPLACE THESE PATHS WITH YOUR ACTUAL FILES ---
var sfx_library = {
	# PLAYER
	"walk": preload("res://Audio Asset/walk.mp3"),
	"dash": preload("res://Audio Asset/dash.wav"),
	"damage": preload("res://Audio Asset/Hurt.mp3"),
	"pickup": preload("res://Audio Asset/pickup.wav"),
	"drop": preload("res://Audio Asset/drop.wav"),
	"refill": preload("res://Audio Asset/refill.wav"),
	"gameover": preload("res://Audio Asset/Gameover.mp3"),
	"stamp": preload("res://Audio Asset/Stamp.mp3"),
	"coin": preload("res://Audio Asset/coin.mp3"),
	"cashier": preload("res://Audio Asset/cashier_sound.mp3"),
	# UI
	"slash": preload("res://Audio Asset/slash.wav"),
	"ui_hover": preload("res://Audio Asset/select.wav"),
	"ui_click": preload("res://Audio Asset/confirm.wav"),
	"button_click": preload("res://Audio Asset/intermissionbutton.wav"),
	"spawner": preload("res://Audio Asset/Spawning.wav"),
	"boost": preload("res://Audio Asset/speed_boost.mp3"),
	"start": preload("res://Audio Asset/clock.wav"),
	# ENEMIES
	"ghost_angry": preload("res://Audio Asset/ghost.mp3"),
	"zombie_angry": preload("res://Audio Asset/zombie.mp3"),
	"small_angry": preload("res://Audio Asset/bite.mp3"),
	"long_bird": preload("res://Audio Asset/Judgement.mp3"),
	"slime_angry": preload("res://Audio Asset/slime_a.wav"),
	"reaper_angry": preload("res://Audio Asset/reaper.mp3"),
	"boss_laugh": preload("res://Audio Asset/Laughing.mp3"),
	# Skill
	"tomb_spawn": preload("res://Audio Asset/tombstone.wav"),
	"tomb_break": preload("res://Audio Asset/tombstone_b.wav"),
	"puddle": preload("res://Audio Asset/puddle.wav"),
	"smoke": preload("res://Audio Asset/smoke.wav"),
	"burst": preload("res://Audio Asset/burst.wav"),
}

var music_library = {
	"menu_music": preload("res://Audio Asset/Limbus Company - Main Menu Theme.mp3"),
	"level1": preload("res://Audio Asset/music_level1.mp3"),
	"level2": preload("res://Audio Asset/music_level2.mp3"),
	"level3": preload("res://Audio Asset/music_level3.mp3"),
	"level4": preload("res://Audio Asset/music_level4.mp3"),
	"level5": preload("res://Audio Asset/music_level5.mp3"),
	"level6": preload("res://Audio Asset/music_level6.mp3"),
	"level7": preload("res://Audio Asset/music_level7.mp3"),
	"boss_music": preload("res://Audio Asset/music_level8.mp3"),
	"complete_song": preload("res://Audio Asset/complete.mp3"),
	"gameover_song": preload("res://Audio Asset/gameover_song.mp3"),
	"intermission_song": preload("res://Audio Asset/intermission.mp3"),
	"level": preload("res://Audio Asset/music_level1.mp3"),
	"Theend": preload("res://Audio Asset/level9.mp3")
}

# --- DONT TOUCH THIS PART (IT WORKS) ---

func play_music(track_name: String):
	if not music_library.has(track_name):
		print("Music missing: ", track_name)
		return
	
	var stream = music_library[track_name]
	if music_player.stream == stream and music_player.playing:
		return # Already playing this song
	
	music_player.stream = stream
	music_player.play()

func play_sfx(sound_name: String, pitch_scale = 1.0):
	if not sfx_library.has(sound_name):
		print("SFX missing: ", sound_name)
		return
		
	var sfx = AudioStreamPlayer.new()
	sfx.stream = sfx_library[sound_name]
	sfx.bus = "SFX" # <--- IMPORTANT
	sfx.pitch_scale = pitch_scale
	add_child(sfx)
	sfx.play()
	
	await sfx.finished
	sfx.queue_free()

func fade_out_music(duration: float):
	# 1. Create a Tween (Animation helper)
	var tween = create_tween()
	
	# 2. Animate the volume down to -80 dB (Silence) over 'duration' seconds
	# "volume_db" is the property we are changing
	tween.tween_property(music_player, "volume_db", -80.0, duration)
	
	# 3. Wait for the fade to finish
	await tween.finished
	
	# 4. Stop the music and RESET volume for next time
	music_player.stop()
	music_player.volume_db = 0.0 # <--- Crucial! Or the next song will be silent.
