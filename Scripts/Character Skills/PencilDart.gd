extends KinematicBody2D

var side
var damage_modifier
var size

const SPEED_X = 2250
const GRAVITY = 2000
const LIFE_TIME = 0.1
const TOTAL_LIFE_TIME = 2.0
const DAMAGE_INIT = 40
const DAMAGE_FINAL = 20
const DAMAGE_SCALE_TIME = 0.5

var damage

# Ensure that only one target is hit.
var already_hit = false

var lifetime_timer
var timestamp = 0.0

onready var movement_pattern = preload("res://Scripts/Movements/StraightLineMovement.gd").new(side * SPEED_X, 0)
onready var gravity_movement = preload("res://Scripts/Movements/GravityMovement.gd").new(self, GRAVITY)
onready var sprite = $Sprite

func initialize(side, damage_modifier, size):
	self.side = side
	self.damage_modifier = damage_modifier
	self.size = size
	damage = DAMAGE_INIT

func _ready():
	# Set facing.
	sprite.scale = Vector2(sprite.scale.x * side, sprite.scale.y)

	# Set size.
	scale = scale * size

func _process(delta):
	# Move.
	var rel_movement = movement_pattern.movement(delta) + gravity_movement.movement(delta)
	move_and_collide(rel_movement)

	# Destroy when touches a platform.
	if is_on_wall():
		movement_pattern.dx = 0
		gravity_movement.dy = 0
		gravity_movement.gravity = 0

		lifetime_timer = preload("res://Scripts/Utils/CountdownTimer.gd").new(LIFE_TIME, self, "queue_free")

	timestamp += delta

	damage = lerp(DAMAGE_INIT, DAMAGE_FINAL, timestamp / DAMAGE_SCALE_TIME)

	if timestamp >= TOTAL_LIFE_TIME:
		queue_free()

# Will be signalled when it hits an enemy.
func on_enemy_hit(area):
	if not already_hit and area.is_in_group("enemy_collider"):
		# Deal damage to enemy.
		area.get_node("../..").damaged(damage * damage_modifier)

		# Avoid damaging multiple targets.
		already_hit = true

		queue_free()