extends CharacterBody2D

const SPEED := 330.0
const DASH_SPEED := 760.0
const DASH_TIME := 0.18

var alive := true
var player_name := "Player"
var player_id := 1
var player_color := Color(0.28, 0.62, 1.0)
var ability_type := ""
var input_scheme := "solo"
var dash_inventory := false
var shield_inventory := false
var dash_active := false
var shield_active := false
var dash_timer := 0.0
var shield_timer := 0.0
var last_movement := Vector2(1.0, 0.0)

func _ready() -> void:
	add_to_group("players")
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not alive:
		return

	if dash_timer > 0.0:
		dash_timer -= delta
		if dash_timer <= 0.0:
			dash_timer = 0.0
			dash_active = false

	if shield_active:
		shield_timer -= delta
		if shield_timer <= 0.0:
			shield_active = false
			shield_timer = 0.0

	var move := Vector2.ZERO
	if input_scheme == "solo":
		if Input.is_key_pressed(KEY_W): move.y -= 1
		if Input.is_key_pressed(KEY_S): move.y += 1
		if Input.is_key_pressed(KEY_A): move.x -= 1
		if Input.is_key_pressed(KEY_D): move.x += 1
	elif input_scheme == "p1":
		if Input.is_key_pressed(KEY_W): move.y -= 1
		if Input.is_key_pressed(KEY_S): move.y += 1
		if Input.is_key_pressed(KEY_A): move.x -= 1
		if Input.is_key_pressed(KEY_D): move.x += 1
	elif input_scheme == "p2":
		if Input.is_key_pressed(KEY_UP): move.y -= 1
		if Input.is_key_pressed(KEY_DOWN): move.y += 1
		if Input.is_key_pressed(KEY_LEFT): move.x -= 1
		if Input.is_key_pressed(KEY_RIGHT): move.x += 1

	if move.length() > 0.0:
		move = move.normalized()
		last_movement = move

	if dash_active:
		velocity = last_movement.normalized() * DASH_SPEED
	elif move.length() > 0.0:
		velocity = move * SPEED
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	queue_redraw()

func _draw() -> void:
	if not alive:
		return

	var outline_color := Color(0.75, 0.92, 1.0, 1.0)
	var fill_color := Color(0.0, 0.0, 0.0, 1.0)
	if shield_active:
		fill_color = Color(0.2, 0.7, 1.0, 0.85)
		draw_circle(Vector2.ZERO, 30.0, Color(0.35, 0.85, 1.0, 0.22))
		draw_arc(Vector2.ZERO, 30.0, 0.0, TAU, 24, Color(0.35, 0.85, 1.0, 0.8), 3.0)

	draw_circle(Vector2.ZERO, 24.0, fill_color)
	draw_arc(Vector2.ZERO, 24.0, 0.0, TAU, 24, outline_color, 3.0)

func set_player_name(name_text: String) -> void:
	player_name = name_text

func get_player_name() -> String:
	return player_name

func set_player_id(id: int) -> void:
	player_id = id

func get_player_id() -> int:
	return player_id

func set_player_color(color_value: Color) -> void:
	player_color = color_value
	queue_redraw()

func get_player_color() -> Color:
	return player_color

func set_control_scheme(scheme: String) -> void:
	input_scheme = scheme

func set_ability_type_from_color(color_value: Color) -> void:
	var red := Color(1.0, 0.33, 0.38)
	var blue := Color(0.28, 0.62, 1.0)
	if color_value.is_equal_approx(red):
		ability_type = "dash"
	elif color_value.is_equal_approx(blue):
		ability_type = "shield"
	else:
		ability_type = ""

func activate_ability_from_hud() -> void:
	if not alive:
		return
	if ability_type == "dash":
		activate_dash()
	elif ability_type == "shield":
		activate_shield()

func activate_dash() -> void:
	if not alive:
		return
	if ability_type != "dash" or not dash_inventory:
		return
	if dash_active:
		return
	dash_inventory = false
	dash_active = true
	dash_timer = DASH_TIME
	if last_movement.length() == 0.0:
		last_movement = Vector2(1.0, 0.0)

func activate_shield() -> void:
	if not alive:
		return
	if ability_type != "shield" or not shield_inventory:
		return
	if shield_active:
		return
	shield_inventory = false
	shield_active = true
	shield_timer = 10.0

func collect_pickup(kind: String) -> void:
	if kind == "dash" and ability_type == "dash":
		dash_inventory = true
	elif kind == "shield" and ability_type == "shield":
		shield_inventory = true

func is_protected_from_explosion() -> bool:
	return shield_active

func die() -> void:
	if not alive:
		return
	alive = false
	visible = false
	set_physics_process(false)
	queue_redraw()
