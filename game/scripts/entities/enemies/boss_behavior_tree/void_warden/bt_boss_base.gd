extends BTEnemy
class_name BTBoss

## Base class for behavior tree-driven bosses
## Provides phase management, skill cooldowns, and enrage mechanics

signal phase_changed(phase: int)
signal boss_died()

@export_group("Boss Stats")
@export var boss_display_name: String = "Boss"
@export var base_health: int = 2000
@export var enrage_time: float = 300.0

@export_group("Phase Thresholds")
@export var phase_2_hp_percent: float = 0.6
@export var phase_3_hp_percent: float = 0.3

@onready var boss_health_bar: ProgressBar = $BossHealthBar
@onready var enrage_timer_node: Timer = $EnrageTimer

var current_phase: int = 1
var is_enraged: bool = false
var _skill_cooldowns: Dictionary = {}


func _ready() -> void:
	super._ready()
	_setup_boss()


func _setup_boss() -> void:
	max_health = base_health
	health.max_health = max_health
	health.current_health = max_health
	
	scale = Vector2(2.0, 2.0)
	speed = 40.0
	
	if boss_health_bar != null:
		boss_health_bar.max_value = max_health
		boss_health_bar.value = max_health
		boss_health_bar.visible = true
	
	if enrage_timer_node != null:
		enrage_timer_node.wait_time = enrage_time
		enrage_timer_node.one_shot = true
		enrage_timer_node.timeout.connect(_on_enrage)
		enrage_timer_node.start()


func _process(_delta: float) -> void:
	_update_health_bar()
	_check_phase_transition()


func _update_health_bar() -> void:
	if boss_health_bar != null and health != null:
		boss_health_bar.value = health.current_health


func _check_phase_transition() -> void:
	if health == null:
		return
	
	var hp_percent: float = float(health.current_health) / float(max_health)
	
	if current_phase == 1 and hp_percent <= phase_2_hp_percent:
		_enter_phase(2)
	elif current_phase == 2 and hp_percent <= phase_3_hp_percent:
		_enter_phase(3)


func _enter_phase(phase: int) -> void:
	current_phase = phase
	phase_changed.emit(phase)
	_play_phase_transition()
	print("[%s] Entering phase %d" % [boss_display_name, phase])


func _play_phase_transition() -> void:
	if animated_sprite != null:
		animated_sprite.modulate = Color(1.5, 0.5, 0.5, 1.0)
		var tween := create_tween()
		tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.5)


func _on_enrage() -> void:
	is_enraged = true
	speed *= 1.5
	print("[%s] ENRAGED!" % boss_display_name)


func set_skill_cooldown(skill_name: String, duration: float) -> void:
	_skill_cooldowns[skill_name] = duration


func is_skill_ready(skill_name: String) -> bool:
	return not _skill_cooldowns.has(skill_name) or _skill_cooldowns[skill_name] <= 0.0


func tick_cooldowns(delta: float) -> void:
	for skill in _skill_cooldowns:
		_skill_cooldowns[skill] = max(0.0, _skill_cooldowns[skill] - delta)


func _on_health_died() -> void:
	boss_died.emit()
	super._on_health_died()


func get_current_phase() -> int:
	return current_phase


func get_health_percent() -> float:
	if health == null:
		return 0.0
	return float(health.current_health) / float(max_health)
