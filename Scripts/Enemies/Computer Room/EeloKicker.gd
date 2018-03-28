extends KinematicBody2D

# Eelo Kicker AI:
# 1. Roam randomly.
# 2. When a character is in range, move towards the nearest character.
# 3. If a character is in range, kick!!
# 4. Run to the healing fountain and heal for some time.
# 5. Go to 1.
# ===
# Don't play hurt animation while kicking.
# When stunned, go to 1.

enum { NONE, ROAM, MOVE_TO_CHAR, KICK, SEEK_HEAL, HEALING }

export(int) var activate_range_x = 1000
export(int) var activate_range_y = 1500
export(NodePath) var fountain_path

const MAX_HEALTH = 150

# Attack.
const ATTACK_RANGE_X = 100
const ATTACK_RANGE_Y = 250
const DAMAGE = 40
const KNOCK_BACK_VEL_X = 700
const KNOCK_BACK_VEL_Y = 250
const KNOCK_BACK_FADE_RATE = 1100

# Movement.
const SPEED_X = 200
const GRAVITY = 600
const CHASE_RANGE = 700
const SEEK_HEAL_SPEED = 300
const HEAL_DURATION = 2.2
const RANDOM_MOVEMENT_STEP = 5
const RANDOM_MOVEMENT_MIN_TIME_PER_STEP = 1.5
const RANDOM_MOVEMENT_MAX_TIME_PER_STEP = 2.5

const HEAL_RANGE = 175

# Animation.
const DIE_ANIMATION_DURATION = 0.8
const SINGLE_KICK_DURATION = 0.6

var status_timer = null
var kick_timer = null
var kick_sequence = ["Left Kick", "Right Kick", "Double Kick"]
var attack_target = null
var facing = -1

onready var ec = preload("res://Scripts/Enemies/Common/EnemyCommon.gd").new(self)

onready var heal_pos = get_node(fountain_path)

func activate():
	ec.init_gravity_movement(GRAVITY)
	ec.init_straight_line_movement(0, 0)
	set_process(true)
	ec.change_status(ROAM)
	$"Animation/Damage Area".add_to_group("enemy")

func _process(delta):
	if ec.not_hurt_dying_stunned():
		match ec.status:
			ROAM:
				roam_randomly(delta)
			MOVE_TO_CHAR:
			 move_to_attack_target(delta)
			KICK:
				kick()
			SEEK_HEAL:
				move_to_healing_fountain(delta)
			HEALING:
				heal_up()

	ec.perform_gravity_movement(delta)
	ec.perform_knock_back_movement(delta)

func change_status(to_status):
	ec.change_status(to_status)

func roam_randomly(delta):
	ec.play_animation("Walk")
	if ec.random_movement == null:
		ec.init_random_movement("movement_not_ended", "movement_ended", SPEED_X, 0, true, RANDOM_MOVEMENT_STEP, RANDOM_MOVEMENT_STEP, RANDOM_MOVEMENT_MIN_TIME_PER_STEP, RANDOM_MOVEMENT_MAX_TIME_PER_STEP)

	ec.perform_random_movement(delta)

	for character in ec.hero_average_pos.characters:
		if abs(character.global_position.x - global_position.x) <= CHASE_RANGE:
			attack_target = character
			ec.change_status(MOVE_TO_CHAR)
			ec.discard_random_movement()
			return

func movement_not_ended(movement_dir):
	facing = movement_dir
	ec.turn_sprites_x(facing)

func movement_ended():
	return

func move_to_attack_target(delta):
	ec.play_animation("Walk")

	facing = sign(attack_target.global_position.x - global_position.x)
	ec.turn_sprites_x(facing)
	ec.straight_line_movement.dx = facing * SPEED_X
	ec.perform_straight_line_movement(delta)

	if abs(attack_target.global_position.x - global_position.x) <= ATTACK_RANGE_X && abs(attack_target.global_position.y - global_position.y) <= ATTACK_RANGE_Y:
		ec.change_status(KICK)

func kick():
	ec.change_status(NONE)
	swap_kick_sequence_randomly()
	perform_kick_sequence(0)
	
# Actually, only pick one pair to swap.
# Also, the randomness isn't distributed equally. But who cares.
func swap_kick_sequence_randomly():
	var i = ec.rng.randi_range(1, kick_sequence.size())
	var j = ec.rng.randi_range(0, i)
	var temp = kick_sequence[i]
	kick_sequence[i] = kick_sequence[j]
	kick_sequence[j] = temp

func perform_kick_sequence(index):
	if index >= kick_sequence.size():
		ec.change_status(SEEK_HEAL)
		return

	ec.play_animation(kick_sequence[index])
	kick_timer = ec.cd_timer.new(SINGLE_KICK_DURATION, self, "perform_kick_sequence", index + 1)

func on_right_kick_hit(area):
	if area.is_in_group("hero"):
		apply_kick_damage(area.get_node(".."), -facing)

func on_left_kick_hit(area):
	if area.is_in_group("hero"):
		apply_kick_damage(area.get_node(".."), facing)

func apply_kick_damage(character, dir):
	character.damaged(DAMAGE)
	character.knocked_back(dir * KNOCK_BACK_VEL_X, -KNOCK_BACK_VEL_Y, KNOCK_BACK_FADE_RATE)

func move_to_healing_fountain(delta):
	ec.play_animation("Walk")

	facing = sign(heal_pos.global_position.x - global_position.x)
	ec.straight_line_movement.dx = facing * SEEK_HEAL_SPEED
	ec.turn_sprites_x(facing)
	ec.perform_straight_line_movement(delta)

	if abs(global_position.x - heal_pos.global_position.x) <= HEAL_RANGE:
		ec.change_status(HEALING)

func heal_up():
	ec.play_animation("Healing")
	ec.change_status(NONE)
	status_timer = ec.cd_timer.new(HEAL_DURATION, self, "change_status", ROAM)

func damaged(val):
	ec.damaged(val, ec.animator.current_animation != "Walk")

func resume_from_damaged():
	ec.resume_from_damaged()

func stunned(duration):
	ec.change_status(ROAM)
	ec.stunned(duration)

func resume_from_stunned():
	ec.resume_from_stunned()

func healed(val):
	ec.healed(val)

func knocked_back(vel_x, vel_y, fade_rate):
	ec.knocked_back(vel_x, vel_y, fade_rate)

func slowed(multiplier, duration):
	ec.slowed(multiplier, duration)

func slowed_recover(label):
	ec.slowed_recover(label)

func die():
	ec.die()
	status_timer = ec.cd_timer.new(DIE_ANIMATION_DURATION, self, "queue_free")