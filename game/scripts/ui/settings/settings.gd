extends Control

signal settings_closed

@onready var back_button: Button = %BackButton
@onready var master_volume_slider: HSlider = %MasterVolumeSlider
@onready var music_volume_slider: HSlider = %MusicVolumeSlider
@onready var sfx_volume_slider: HSlider = %SFXVolumeSlider
@onready var fullscreen_check: CheckBox = %FullscreenCheck
@onready var vsync_check: CheckBox = %VsyncCheck
@onready var fps_limit_input: SpinBox = %FPSLimitInput
@onready var screen_shake_check: CheckBox = %ScreenShakeCheck
@onready var show_damage_numbers_check: CheckBox = %ShowDamageNumbersCheck
@onready var show_fps_check: CheckBox = %ShowFPSCheck
@onready var language_option: OptionButton = %LanguageOption

@export_file("*.tscn") var main_menu_scene_path: String = "res://scenes/ui/main_menu.tscn"

const SETTINGS_PATH := "user://settings.cfg"


func _ready() -> void:
	_load_settings()
	_connect_signals()


func _connect_signals() -> void:
	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)
	if master_volume_slider != null:
		master_volume_slider.value_changed.connect(_on_master_volume_changed)
	if music_volume_slider != null:
		music_volume_slider.value_changed.connect(_on_music_volume_changed)
	if sfx_volume_slider != null:
		sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	if fullscreen_check != null:
		fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	if vsync_check != null:
		vsync_check.toggled.connect(_on_vsync_toggled)
	if fps_limit_input != null:
		fps_limit_input.value_changed.connect(_on_fps_limit_changed)
	if screen_shake_check != null:
		screen_shake_check.toggled.connect(_on_screen_shake_toggled)
	if show_damage_numbers_check != null:
		show_damage_numbers_check.toggled.connect(_on_show_damage_numbers_toggled)
	if show_fps_check != null:
		show_fps_check.toggled.connect(_on_show_fps_toggled)
	if language_option != null:
		language_option.item_selected.connect(_on_language_selected)


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		_apply_defaults()
		return

	# Audio
	var master_vol: float = config.get_value("audio", "master_volume", 1.0)
	var music_vol: float = config.get_value("audio", "music_volume", 0.8)
	var sfx_vol: float = config.get_value("audio", "sfx_volume", 1.0)

	if master_volume_slider != null:
		master_volume_slider.value = master_vol
	if music_volume_slider != null:
		music_volume_slider.value = music_vol
	if sfx_volume_slider != null:
		sfx_volume_slider.value = sfx_vol

	# Video
	var fullscreen: bool = config.get_value("video", "fullscreen", false)
	var vsync: bool = config.get_value("video", "vsync", true)
	var fps_limit: int = config.get_value("video", "fps_limit", 0)

	if fullscreen_check != null:
		fullscreen_check.button_pressed = fullscreen
	if vsync_check != null:
		vsync_check.button_pressed = vsync
	if fps_limit_input != null:
		fps_limit_input.value = fps_limit

	# Gameplay
	var screen_shake: bool = config.get_value("gameplay", "screen_shake", true)
	var show_damage_numbers: bool = config.get_value("gameplay", "show_damage_numbers", true)

	if screen_shake_check != null:
		screen_shake_check.button_pressed = screen_shake
	if show_damage_numbers_check != null:
		show_damage_numbers_check.button_pressed = show_damage_numbers

	# HUD
	var show_fps: bool = config.get_value("hud", "show_fps", false)
	var language: int = config.get_value("hud", "language", 0)

	if show_fps_check != null:
		show_fps_check.button_pressed = show_fps
	if language_option != null:
		language_option.select(language)

	_apply_video_settings()


func _apply_defaults() -> void:
	if master_volume_slider != null:
		master_volume_slider.value = 1.0
	if music_volume_slider != null:
		music_volume_slider.value = 0.8
	if sfx_volume_slider != null:
		sfx_volume_slider.value = 1.0
	if fullscreen_check != null:
		fullscreen_check.button_pressed = false
	if vsync_check != null:
		vsync_check.button_pressed = true
	if fps_limit_input != null:
		fps_limit_input.value = 0
	if screen_shake_check != null:
		screen_shake_check.button_pressed = true
	if show_damage_numbers_check != null:
		show_damage_numbers_check.button_pressed = true
	if show_fps_check != null:
		show_fps_check.button_pressed = false
	if language_option != null:
		language_option.select(0)


func _save_settings() -> void:
	var config := ConfigFile.new()

	# Audio
	if master_volume_slider != null:
		config.set_value("audio", "master_volume", master_volume_slider.value)
	if music_volume_slider != null:
		config.set_value("audio", "music_volume", music_volume_slider.value)
	if sfx_volume_slider != null:
		config.set_value("audio", "sfx_volume", sfx_volume_slider.value)

	# Video
	if fullscreen_check != null:
		config.set_value("video", "fullscreen", fullscreen_check.button_pressed)
	if vsync_check != null:
		config.set_value("video", "vsync", vsync_check.button_pressed)
	if fps_limit_input != null:
		config.set_value("video", "fps_limit", int(fps_limit_input.value))

	# Gameplay
	if screen_shake_check != null:
		config.set_value("gameplay", "screen_shake", screen_shake_check.button_pressed)
	if show_damage_numbers_check != null:
		config.set_value("gameplay", "show_damage_numbers", show_damage_numbers_check.button_pressed)

	# HUD
	if show_fps_check != null:
		config.set_value("hud", "show_fps", show_fps_check.button_pressed)
	if language_option != null:
		config.set_value("hud", "language", language_option.selected)

	config.save(SETTINGS_PATH)


func _apply_video_settings() -> void:
	if fullscreen_check != null:
		if fullscreen_check.button_pressed:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	if vsync_check != null:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync_check.button_pressed else DisplayServer.VSYNC_DISABLED)

	if fps_limit_input != null:
		Engine.max_fps = int(fps_limit_input.value)


func _on_back_pressed() -> void:
	_save_settings()
	if not main_menu_scene_path.is_empty():
		get_tree().change_scene_to_file(main_menu_scene_path)
	else:
		settings_closed.emit()


func _on_master_volume_changed(value: float) -> void:
	# Apply to audio bus
	var bus_idx := AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))


func _on_music_volume_changed(value: float) -> void:
	var bus_idx := AudioServer.get_bus_index("Music")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))


func _on_sfx_volume_changed(value: float) -> void:
	var bus_idx := AudioServer.get_bus_index("SFX")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))


func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_vsync_toggled(toggled_on: bool) -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if toggled_on else DisplayServer.VSYNC_DISABLED)


func _on_fps_limit_changed(value: float) -> void:
	Engine.max_fps = int(value)


func _on_screen_shake_toggled(_toggled_on: bool) -> void:
	pass  # Handled by gameplay systems


func _on_show_damage_numbers_toggled(_toggled_on: bool) -> void:
	pass  # Handled by gameplay systems


func _on_show_fps_toggled(_toggled_on: bool) -> void:
	pass  # Handled by HUD systems


func _on_language_selected(_index: int) -> void:
	pass  # Handled by localization system
