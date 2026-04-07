extends Node

const SLIME_VARIANT_ORDER := [
	"blue", "red", "green", "purple", "gold",
	"pink", "dark", "orange", "white", "cyan",
	"lime", "crimson", "teal", "brown",
]

const SLIME_SCENE_PATHS := {
	"blue": "res://scenes/entities/player/slime_blue.tscn",
	"red": "res://scenes/entities/player/slime_red.tscn",
	"green": "res://scenes/entities/player/slime_green.tscn",
	"purple": "res://scenes/entities/player/slime_purple.tscn",
	"gold": "res://scenes/entities/player/slime_gold.tscn",
	"pink": "res://scenes/entities/player/slime_pink.tscn",
	"dark": "res://scenes/entities/player/slime_dark.tscn",
	"orange": "res://scenes/entities/player/slime_orange.tscn",
	"white": "res://scenes/entities/player/slime_white.tscn",
	"cyan": "res://scenes/entities/player/slime_cyan.tscn",
	"lime": "res://scenes/entities/player/slime_lime.tscn",
	"crimson": "res://scenes/entities/player/slime_crimson.tscn",
	"teal": "res://scenes/entities/player/slime_teal.tscn",
	"brown": "res://scenes/entities/player/slime_brown.tscn",
}

const SLIME_PREVIEW_COLORS := {
	"blue": {"highlight": Color(0.52549, 0.890196, 0.996078, 1), "mid": Color(0.454902, 0.843137, 1, 1), "shadow": Color(0.34902, 0.741176, 0.905882, 1), "outline": Color(0.082353, 0.141176, 0.27451, 1), "iris": Color(0.109804, 0.184314, 0.360784, 1)},
	"red": {"highlight": Color(1, 0.52549, 0.52549, 1), "mid": Color(1, 0.337255, 0.337255, 1), "shadow": Color(1, 0.196078, 0.196078, 1), "outline": Color(0.368627, 0.047059, 0.047059, 1), "iris": Color(0.380392, 0.058824, 0.117647, 1)},
	"green": {"highlight": Color(0.52549, 0.996078, 0.690196, 1), "mid": Color(0.337255, 0.909804, 0.478431, 1), "shadow": Color(0.196078, 0.788235, 0.341176, 1), "outline": Color(0.058824, 0.286275, 0.121569, 1), "iris": Color(0.086275, 0.258824, 0.14902, 1)},
	"purple": {"highlight": Color(0.847059, 0.52549, 0.996078, 1), "mid": Color(0.756863, 0.337255, 1, 1), "shadow": Color(0.6, 0.196078, 1, 1), "outline": Color(0.231373, 0.070588, 0.380392, 1), "iris": Color(0.203922, 0.078431, 0.321569, 1)},
	"gold": {"highlight": Color(0.996078, 0.941176, 0.52549, 1), "mid": Color(1, 0.85098, 0.196078, 1), "shadow": Color(1, 0.737255, 0, 1), "outline": Color(0.431373, 0.27451, 0.043137, 1), "iris": Color(0.34902, 0.219608, 0.054902, 1)},
	"pink": {"highlight": Color(1, 0.701961, 0.85098, 1), "mid": Color(1, 0.501961, 0.752941, 1), "shadow": Color(1, 0.301961, 0.65098, 1), "outline": Color(0.470588, 0.082353, 0.278431, 1), "iris": Color(0.431373, 0.098039, 0.278431, 1)},
	"dark": {"highlight": Color(0.541176, 0.541176, 0.619608, 1), "mid": Color(0.290196, 0.290196, 0.415686, 1), "shadow": Color(0.101961, 0.101961, 0.227451, 1), "outline": Color(0.035294, 0.035294, 0.109804, 1), "iris": Color(0.760784, 0.733333, 0.878431, 1)},
	"orange": {"highlight": Color(0.996078, 0.784314, 0.52549, 1), "mid": Color(1, 0.615686, 0.25098, 1), "shadow": Color(1, 0.466667, 0, 1), "outline": Color(0.427451, 0.180392, 0.031373, 1), "iris": Color(0.407843, 0.180392, 0.05098, 1)},
	"white": {"highlight": Color(1, 1, 1, 1), "mid": Color(0.839216, 0.941176, 1, 1), "shadow": Color(0.658824, 0.847059, 0.941176, 1), "outline": Color(0.305882, 0.447059, 0.560784, 1), "iris": Color(0.360784, 0.541176, 0.760784, 1)},
	"cyan": {"highlight": Color(0.682353, 0.996078, 1, 1), "mid": Color(0.384314, 0.952941, 1, 1), "shadow": Color(0.117647, 0.784314, 0.878431, 1), "outline": Color(0.047059, 0.286275, 0.329412, 1), "iris": Color(0.058824, 0.270588, 0.317647, 1)},
	"lime": {"highlight": Color(0.847059, 1, 0.52549, 1), "mid": Color(0.658824, 0.960784, 0.258824, 1), "shadow": Color(0.454902, 0.823529, 0.121569, 1), "outline": Color(0.196078, 0.321569, 0.047059, 1), "iris": Color(0.211765, 0.317647, 0.062745, 1)},
	"crimson": {"highlight": Color(1, 0.603922, 0.635294, 1), "mid": Color(1, 0.360784, 0.423529, 1), "shadow": Color(0.788235, 0.164706, 0.227451, 1), "outline": Color(0.411765, 0.062745, 0.145098, 1), "iris": Color(0.380392, 0.05098, 0.129412, 1)},
	"teal": {"highlight": Color(0.560784, 1, 0.878431, 1), "mid": Color(0.211765, 0.85098, 0.705882, 1), "shadow": Color(0.082353, 0.560784, 0.470588, 1), "outline": Color(0.043137, 0.243137, 0.184314, 1), "iris": Color(0.054902, 0.239216, 0.180392, 1)},
	"brown": {"highlight": Color(0.85098, 0.627451, 0.4, 1), "mid": Color(0.658824, 0.419608, 0.235294, 1), "shadow": Color(0.431373, 0.239216, 0.121569, 1), "outline": Color(0.203922, 0.109804, 0.047059, 1), "iris": Color(0.219608, 0.12549, 0.054902, 1)},
}


func get_variant_order() -> Array:
	return SLIME_VARIANT_ORDER.duplicate()


func get_scene_path(variant: String) -> String:
	return String(SLIME_SCENE_PATHS.get(variant, SLIME_SCENE_PATHS["blue"]))


func get_preview_palette(variant: String) -> Dictionary:
	return SLIME_PREVIEW_COLORS.get(variant, SLIME_PREVIEW_COLORS["blue"])
