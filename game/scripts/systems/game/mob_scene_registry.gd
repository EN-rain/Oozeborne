extends RefCounted
class_name MobSceneRegistry

static func build_mob_name_map(
	slime_scene: PackedScene,
	common_scene: PackedScene,
	lancer_scene: PackedScene,
	archer_scene: PackedScene,
	warden_scene: PackedScene,
	boss_scene: PackedScene
) -> Dictionary:
	if common_scene == null:
		push_error("MobSceneRegistry: common_scene is not set.")
	if lancer_scene == null:
		push_error("MobSceneRegistry: lancer_scene is not set.")
	if archer_scene == null:
		push_error("MobSceneRegistry: archer_scene is not set.")
	if warden_scene == null:
		push_error("MobSceneRegistry: warden_scene is not set.")

	var resolved_slime_scene := slime_scene if slime_scene != null else common_scene
	var resolved_boss_scene := boss_scene if boss_scene != null else warden_scene

	return {
		"slime": resolved_slime_scene,
		"common": common_scene,
		"lancer": lancer_scene,
		"archer": archer_scene,
		"warden": warden_scene,
		"boss": resolved_boss_scene,
	}

