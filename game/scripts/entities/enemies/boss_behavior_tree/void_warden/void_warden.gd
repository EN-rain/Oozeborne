extends "res://scripts/entities/enemies/boss_behavior_tree/void_warden/bt_boss_base.gd"
class_name VoidWarden

## Void Warden - A shadowy boss that manipulates space and darkness
## Phase 1 (100%-60% HP): Shadow Strike, Void Pulse
## Phase 2 (60%-30% HP): Unlocks Dark Chains
## Phase 3 (30%-0% HP): Unlocks Soul Drain


func _setup_boss() -> void:
	boss_display_name = "Void Warden"
	base_health = 2000
	enrage_time = 300.0
	
	super._setup_boss()
	
	# Void Warden specific setup
	scale = Vector2(2.5, 2.5)
	speed = 35.0
	
	print("[VoidWarden] Spawned with %d HP" % base_health)


func _enter_phase(phase: int) -> void:
	super._enter_phase(phase)
	
	match phase:
		2:
			speed = 45.0
			print("[VoidWarden] Dark Chains unlocked!")
		3:
			speed = 55.0
			print("[VoidWarden] Soul Drain unlocked!")


func _process(delta: float) -> void:
	super._process(delta)
	tick_cooldowns(delta)
