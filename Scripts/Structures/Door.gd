extends Node2D

export(String, FILE) var enter_scene_path

const HERO_FADING_DURATION = 1.0

var parent_lerper = preload("res://Scenes/Utils/Parent Opacity Lerper.tscn")

onready var collision_area = $Collision/CollisionArea

func _ready():
	collision_area.add_to_group("enemy")

func break_open():
	collision_area.remove_from_group("enemy")
	collision_area.add_to_group("door")
	$Door/AnimationPlayer.play("Explode")

func hero_enter(hero):
	hero.status.can_move = false

	var lerper = parent_lerper.instance()
	lerper.initialize(hero.modulate.a, 0.0, HERO_FADING_DURATION, self, "switch_scene")
	hero.add_child(lerper)

func switch_scene():
	get_node("/root/LoadingScene").goto_scene(enter_scene_path)

func damaged(val):
	break_open()

func stunned(duration):
	pass

func slowed(multplier, duration):
	pass

func knocked_back(vel_x, vel_y, fade_rate):
	pass

func healed(val):
	pass