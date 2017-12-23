extends Node2D

# Sockute AI:
# 1. Wait for a certain period
# 2. Spawns a lightning ball which enlarges overtime.
# 3. Release the lightning ball and travel to the nearest player.
# 4. Repeat 1.

enum { NONE, NOT_ACTIVE, ACTIVATE, SPAWN_BALL, RECOVER }

export(float) var activate_interval = 5.0

const ACTIVATE_RANGE = 1500

const ACTIVATE_ANIMATION_DURATION = 0.5
const RECOVER_ANIMATION_DURATION = 0.5
const SPAWNING_DURATION = 1.5

var status = NOT_ACTIVE
var status_timer = null
var curr_ball = null

var cd_timer = preload("res://Scripts/Utils/CountdownTimer.gd")
var target_detect = preload("res://Scripts/Algorithms/TargetDetection.gd")

var lightning_ball = preload("res://Scenes/Enemies/Computer Room/Sockute Lightning Ball.tscn")
onready var ball_spawn_pos = get_node("Lightning Ball Spawn Pos")
onready var spawn_node = get_node("..")

onready var animator = get_node("Animation/AnimationPlayer")
onready var char_average_pos = get_node("../../../../Character Average Position")

func _ready():
	animator.play("Still")
	set_process(true)

func _process(delta):
	if status == NOT_ACTIVE:
		check_for_active()
	elif status == ACTIVATE:
		play_activate_animation()
	elif status == SPAWN_BALL:
		spawn_lightning_ball()
	elif status == RECOVER:
		play_recover_animation()

func change_status(to_status):
	status = to_status
	if status_timer != null:
		status_timer.destroy_timer()
		status_timer = null

func check_for_active():
	if char_average_pos.get_global_pos().distance_squared_to(get_global_pos()) <= ACTIVATE_RANGE * ACTIVATE_RANGE:
		change_status(ACTIVATE)

func play_activate_animation():
	change_status(NONE)
	animator.play("Activate")
	status_timer = cd_timer.new(ACTIVATE_ANIMATION_DURATION, self, "change_status", SPAWN_BALL)

func spawn_lightning_ball():
	change_status(NONE)

	curr_ball = lightning_ball.instance()
	spawn_node.add_child(curr_ball)
	curr_ball.set_global_pos(ball_spawn_pos.get_global_pos())

	status_timer = cd_timer.new(SPAWNING_DURATION, self, "change_status", RECOVER)

func play_recover_animation():
	change_status(NONE)
	animator.play("Recover")

	release_lightning_ball()

	status_timer = cd_timer.new(RECOVER_ANIMATION_DURATION + activate_interval, self, "change_status", ACTIVATE)

func release_lightning_ball():
	var target_pos = target_detect.get_nearest(self, char_average_pos.characters).get_global_pos()
	curr_ball.start_travel(target_pos)
	curr_ball = null