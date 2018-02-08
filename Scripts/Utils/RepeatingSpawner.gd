extends Node2D

export(String, FILE) var mob_path
export(int) var activate_range = 3000
export(int) var spawn_delay = 0.75
export(int) var total_count

const MOB_FADE_IN_DURATION = 0.5
const PARTICLE_DURATION = 1.5

var curr_count = 0
var stopped = false
var timer = null
var curr_particle
var particle_timer

var cd_timer = preload("res://Scripts/Utils/CountdownTimer.gd")
var opacity_lerper = preload("res://Scenes/Utils/Parent Opacity Lerper.tscn")
var spawning_particle = preload("res://Scenes/Particles/Spawn Mob Particles.tscn")

onready var mob_to_spawn = load(mob_path)
onready var spawn_pos = get_node("..")

signal completed

# Call this function to spawn the first mob.
func spawn_mob():
    if stopped:
        return

    curr_particle = spawning_particle.instance()
    add_child(curr_particle)
    particle_timer = cd_timer.new(PARTICLE_DURATION, curr_particle, "queue_free")

    timer = cd_timer.new(spawn_delay, self, "actually_spawn")

func actually_spawn():
    var new_mob = mob_to_spawn.instance()
    new_mob.ACTIVATE_RANGE = activate_range
    new_mob.set_opacity(0.0)
    spawn_pos.add_child(new_mob)

    var new_alpha_lerper = opacity_lerper.instance()
    new_alpha_lerper.initialize(0.0, 1.0, MOB_FADE_IN_DURATION)
    new_mob.add_child(new_alpha_lerper)
    new_mob.set_global_pos(get_global_pos())

    curr_count += 1
    if curr_count == total_count:
        new_mob.connect("defeated", self, "complete_spawning")
    else:
        new_mob.connect("defeated", self, "spawn_mob")

func complete_spawning():
    emit_signal("completed")

func stop_further_spawning():
    stopped = true