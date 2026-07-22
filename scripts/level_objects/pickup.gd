class_name Pickup
extends Area3D
## Spinning floor pickup for health, ammo, or gold. Classic rule for
## health/ammo: refuses collection while the stat is already full, so it stays
## for later. Gold is treasure — it always collects and adds to the run score.

enum Type { HEALTH, BULLETS, SHELLS, ROCKETS, CELLS, GOLD }

const HEAL_SOUND := preload("res://assets/audio/heal.wav")
const PICKUP_SOUND := preload("res://assets/audio/pickup.wav")
const COIN_SOUND := preload("res://assets/audio/coin.wav")

const SPIN_SPEED := 2.2  ## Radians/sec.
const FLOAT_SPEED := 0.003  ## Sine input scale applied to msec.
const FLOAT_MIN_HEIGHT := 0.05
const FLOAT_AMPLITUDE := 0.05

## Per-type glow halo (an unshaded additive billboard, NOT a light: the
## whole level is one CSG mesh, so per-mesh light limits on the mobile
## renderer would silently drop ten extra omnis). The imported prop models
## (bottles, boxes, keg) would otherwise vanish into dark rooms, and the
## color doubles as a legend — green health, amber bullets, orange shells,
## red rockets, cyan cells, gold treasure.
const TYPE_GLOW := {
	Type.HEALTH: Color(0.45, 1.0, 0.55),
	Type.BULLETS: Color(1.0, 0.85, 0.45),
	Type.SHELLS: Color(1.0, 0.6, 0.3),
	Type.ROCKETS: Color(1.0, 0.35, 0.25),
	Type.CELLS: Color(0.4, 0.85, 1.0),
	Type.GOLD: Color(1.0, 0.82, 0.3),
}
const GLOW_ALPHA := 0.3
const GLOW_SIZE := 0.9

@export var type := Type.HEALTH
@export var amount := 25

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
	quad.size = Vector2(GLOW_SIZE, GLOW_SIZE)
	glow.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_color = Color(TYPE_GLOW[type], GLOW_ALPHA)
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
	_visual.rotate_y(delta * SPIN_SPEED)
	_visual.position.y = FLOAT_MIN_HEIGHT \
			+ (sin(Time.get_ticks_msec() * FLOAT_SPEED) + 1.0) * FLOAT_AMPLITUDE


func _physics_process(_delta: float) -> void:
	# body_entered alone misses a player who is ALREADY standing on the
	# pickup when they become eligible (e.g. take damage while on a medkit
	# they were too healthy to grab), so re-check overlaps continuously.
	if _taken:
		return
	for body in get_overlapping_bodies():
		_try_collect(body)


func _try_collect(body: Node3D) -> void:
	if _taken or not body.is_in_group("player"):
		return
	var applied := false
	if type == Type.HEALTH:
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
	var color := Color(0.6, 1.0, 0.7) if type == Type.HEALTH else Color(1.0, 0.9, 0.5)
	var sound := PICKUP_SOUND
	if type == Type.HEALTH:
		sound = HEAL_SOUND
	elif type == Type.GOLD:
		sound = COIN_SOUND
	Fx.spawn_sound(self, global_position, sound)
	Fx.spawn(self, global_position + Vector3(0, 0.5, 0), color, 0.45, 0.15)
	queue_free()
