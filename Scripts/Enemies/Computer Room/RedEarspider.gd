extends KinematicBody2D

# Red Earspider AI:
# 1. Wait until a character is in range.
# 2. Drop down on the floor.
# 3. Countdown.
# 4. Explode. (Die)
# ===
# Cannot be damaged.

const TRIGGER_RANGE_X = 450
const GRAVITY = 800

# Explosion Attack.
const DAMAGE = 20
const STUN_DURATION = 1.0
const KNOCK_BACK_VEL_X = 2000
const KNOCK_BACK_FADE_RATE_X = 5000
const KNOCK_BACK_VEL_Y = 2000

# Animation.
const COUNTDOWN_ANIMATION_DURATION = 4.0
const EXPLOSION_ANIMATION_DURATION = 0.5

enum { WAITING, COUNTDOWN }

var status = WAITING
var timer = null
var damage_timer = null

var countdown_timer = preload("res://Scripts/Utils/CountdownTimer.gd")
var target_detection = preload("res://Scripts/Algorithms/TargetDetection.gd")

onready var movement_type = preload("res://Scripts/Movements/GravityMovement.gd").new(self, GRAVITY)
onready var char_average_pos = get_node("../../../../Character Average Position")
onready var animator = get_node("Animation/AnimationPlayer")
onready var explosion_particles = get_node("Explosion Particles")

func _ready():
	animator.play("Still")
	set_process(true)

func _process(delta):
	if status == WAITING:
		check_nearest_char()
		return

	# Movement.
	move_to(movement_type.movement(get_global_pos(), delta))

	if status == COUNTDOWN && timer == null:
		start_counting_down()

func check_nearest_char():
	var nearest_target = target_detection.get_nearest(self, char_average_pos.characters)

	if abs(nearest_target.get_global_pos().x - get_global_pos().x) <= TRIGGER_RANGE_X:
		status = COUNTDOWN

func start_counting_down():
	timer = countdown_timer.new(COUNTDOWN_ANIMATION_DURATION, self, "explode_attack")
	animator.play("Count Down")

func explode_attack():
	animator.play("Explode")
	explosion_particles.set_emitting(true)

	timer = countdown_timer.new(EXPLOSION_ANIMATION_DURATION, self, "queue_free")

func explosion_attack_hit(area):
	if area.is_in_group("player_collider"):
		var character = area.get_node("..")
		character.stunned(STUN_DURATION)
		character.damaged(DAMAGE)
		knock_back(character)

func knock_back(character):
	var center_pos = get_node("Animation/Explosion Area/Center").get_global_pos()
	var char_pos = character.get_global_pos()

	var dir_x = 1 if center_pos.x < char_pos.x else -1
	var dir_y = 1 if center_pos.y < char_pos.y else -1

	character.knocked_back(dir_x * KNOCK_BACK_VEL_X, dir_y * KNOCK_BACK_VEL_Y, KNOCK_BACK_FADE_RATE_X)