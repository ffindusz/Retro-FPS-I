class_name Pickup
extends Area3D
## Spinning floor pickup for health, ammo, or gold. Classic rule for
## health/ammo: refuses collection while the stat is already full, so it stays
## for later. Gold is treasure — it always collects and adds to the run score.

enum Type { POTION, CRYSTALS, QUARRELS, EMBERS, MANA, GOLD }

const HEAL_SOUND := preload("res://assets/audio/heal.wav")
const PICKUP_SOUND := preload("res://assets/audio/pickup.wav")
const COIN_SOUND := preload("res://assets/audio/coin.wav")


## Per-type glow halo (an unshaded additive billboard, NOT a light: the
## whole level is one CSG mesh, so per-mesh light limits on the mobile
## renderer would silently drop ten extra omnis). The imported prop models
## (bottles, boxes, keg) would otherwise vanish into dark rooms, and the
## color doubles as a legend — green potion, violet crystals, orange
## quarrels, red embers, cyan mana, gold treasure. Crystals were amber
## until they proved indistinguishable from the gold they sit next to.
const TYPE_GLOW := {
	Type.POTION: Color(0.45, 1.0, 0.55),
	Type.CRYSTALS: Color(0.66, 0.42, 1.0),
	Type.QUARRELS: Color(1.0, 0.6, 0.3),
	Type.EMBERS: Color(1.0, 0.35, 0.25),
	Type.MANA: Color(0.4, 0.85, 1.0),
	Type.GOLD: Color(1.0, 0.82, 0.3),
}

## Pickup-notice labels for the non-gold types (gold speaks for itself via
## collect_gold). Ammo names match the pickup legend in TYPE_GLOW.
const TYPE_NAME := {
	Type.POTION: "POTION",
	Type.CRYSTALS: "CRYSTALS",
	Type.QUARRELS: "QUARRELS",
	Type.EMBERS: "EMBERS",
	Type.MANA: "MANA",
}

@export var type := Type.POTION
@export var amount := 25

@export_group("Bob")
@export var spin_speed := 2.2  ## Radians/sec.
@export var float_speed := 0.003  ## Sine input scale applied to msec.
@export var float_min_height := 0.05
@export var float_amplitude := 0.05
@export_group("Glow")
## Size and opacity of the halo billboard. Its colour comes from TYPE_GLOW,
## which is a legend shared by every pickup of that type rather than a
## per-instance knob.
@export var glow_alpha := 0.3
@export var glow_size := 0.9
@export_group("")

var _taken := false

@onready var _visual: Node3D = $Visual


func _ready() -> void:
	add_to_group("pickups")
	# Gold joins its own group so main.gd can count the level's treasure total.
	if type == Type.GOLD:
		add_to_group("gold")
	body_entered.connect(_try_collect)
	var glow := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(glow_size, glow_size)
	glow.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_color = Color(TYPE_GLOW[type], glow_alpha)
	# Radial falloff so the quad reads as a soft halo, not a colored card.
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	var falloff := GradientTexture2D.new()
	falloff.gradient = gradient
	falloff.fill = GradientTexture2D.FILL_RADIAL
	falloff.fill_from = Vector2(0.5, 0.5)
	falloff.fill_to = Vector2(0.5, 0.0)
	mat.albedo_texture = falloff
	glow.material_override = mat
	glow.position.y = 0.35
	add_child(glow)


func _process(delta: float) -> void:
	_visual.rotate_y(delta * spin_speed)
	_visual.position.y = float_min_height \
			+ (sin(Time.get_ticks_msec() * float_speed) + 1.0) * float_amplitude


func _physics_process(_delta: float) -> void:
	# body_entered alone misses a player who is ALREADY standing on the
	# pickup when they become eligible (e.g. take damage while on a potion
	# they were too healthy to grab), so re-check overlaps continuously.
	if _taken:
		return
	for body in get_overlapping_bodies():
		_try_collect(body)


func _try_collect(body: Node3D) -> void:
	if _taken or not body.is_in_group("player"):
		return
	var applied := false
	if type == Type.POTION:
		applied = GameState.heal(amount)
	elif type == Type.GOLD:
		GameState.collect_gold(amount)
		applied = true
	else:
		var pc := body as PlayerController
		if pc:
			applied = pc.weapon_manager.add_ammo_for_type(type, amount)
	if not applied:
		return
	_taken = true
	# Gold announces itself from collect_gold; the rest post their own notice.
	if type != Type.GOLD:
		GameState.notify_pickup("+%d %s" % [amount, TYPE_NAME[type]])
	# Burst in the pickup's own legend colour rather than one amber for
	# everything: the flash is the last thing seen of it.
	var color: Color = TYPE_GLOW[type]
	var sound := PICKUP_SOUND
	if type == Type.POTION:
		sound = HEAL_SOUND
	elif type == Type.GOLD:
		sound = COIN_SOUND
	Fx.spawn_sound(self, global_position, sound)
	Fx.spawn(self, global_position + Vector3(0, 0.5, 0), color, 0.45, 0.15)
	queue_free()
