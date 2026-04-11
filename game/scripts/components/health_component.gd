extends Node
class_name HealthComponent

signal health_changed(current_health: int, max_health: int)
signal damage_taken(amount: int)
signal died()

@export var max_health: int = 100
@export var health_bar_hide_time: float = 5.0

var current_health: int
var health_bar: ProgressBar
@onready var hide_timer: Timer = $HideTimer
var is_dead := false

func initialize(healthbar: ProgressBar):
	current_health = max_health
	
	# Setup hide timer
	hide_timer.wait_time = health_bar_hide_time
	hide_timer.timeout.connect(_on_hide_timer_timeout)
	
	# Setup health bar
	health_bar = healthbar
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
		health_bar.visible = false

func take_damage(amount: int) -> bool:
	if is_dead:
		return false
	
	current_health -= amount
	current_health = max(0, current_health)
	
	# Update health bar
	if health_bar:
		health_bar.value = current_health
		health_bar.visible = true
		if hide_timer:
			hide_timer.start()
	
	health_changed.emit(current_health, max_health)
	damage_taken.emit(amount)
	
	if current_health <= 0:
		is_dead = true
		died.emit()
		return true  # Indicates death
	
	return false  # Still alive

func heal(amount: int):
	if is_dead:
		return
	
	current_health += amount
	current_health = min(current_health, max_health)
	
	if health_bar:
		health_bar.value = current_health
	
	health_changed.emit(current_health, max_health)

func _on_hide_timer_timeout():
	if health_bar:
		health_bar.visible = false

func get_health_percent() -> float:
	return float(current_health) / float(max_health)
