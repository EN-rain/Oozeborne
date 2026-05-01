extends RefCounted
class_name MobSceneRegistry

static func build_mob_name_map(
	slime_scene: PackedScene,
	lancer_scene: PackedScene,
	archer_scene: PackedScene,
	warden_scene: PackedScene
) -> Dictionary:
	if slime_scene == null:
		push_error("MobSceneRegistry: slime_scene is not set.")
	if lancer_scene == null:
		push_error("MobSceneRegistry: lancer_scene is not set.")
	if archer_scene == null:
		push_error("MobSceneRegistry: archer_scene is not set.")
	if warden_scene == null:
		push_error("MobSceneRegistry: warden_scene is not set.")

	return {
		"slime": slime_scene,
		"lancer": lancer_scene,
		"archer": archer_scene,
		"warden": warden_scene,
		"boss": warden_scene, # boss is warden
	}

