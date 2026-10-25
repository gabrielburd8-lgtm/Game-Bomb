extends Area2D

var countdown := randf_range(2.2, 3.1)
var explosion_radius := randf_range(90.0, 120.0)
var exploded := false

@onready var label: Label = $Label

func _ready() -> void:
	label.text = str(int(ceil(countdown)))
	label.modulate = Color(1, 1, 1, 1)
	label.add_theme_font_size_override("font_size", 22)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	queue_redraw()

func _process(delta: float) -> void:
	if exploded:
		return
	countdown -= delta
	if countdown <= 1.0:
		label.modulate = Color(1.0, 0.62, 0.18, 1.0)
	elif countdown <= 2.0:
		label.modulate = Color(1.0, 0.85, 0.25, 1.0)
	else:
		label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	label.text = str(max(0, ceil(countdown)))
	if countdown <= 0.0:
		explode()
	queue_redraw()

func _draw() -> void:
	if exploded:
		draw_circle(Vector2.ZERO, explosion_radius, Color(1.0, 0.35, 0.15, 0.18))
		draw_circle(Vector2.ZERO, explosion_radius * 0.7, Color(1.0, 0.62, 0.2, 0.24))
		return

	var body_color := Color(1.0, 0.55, 0.18, 1.0)
	var outer_color := Color(0.95, 0.82, 0.4, 0.7)
	if countdown <= 1.0:
		body_color = Color(1.0, 0.26, 0.08, 1.0)
		draw_arc(Vector2.ZERO, 22.0, 0.0, TAU, 20, Color(1.0, 0.7, 0.15, 0.8), 4.0)
	var pulse_radius := 18.0 + sin(Time.get_ticks_msec() * 0.01) * 3.0
	draw_circle(Vector2.ZERO, pulse_radius, body_color)
	draw_circle(Vector2.ZERO, 9.0, Color(1.0, 0.95, 0.85, 1.0))
	draw_arc(Vector2.ZERO, 22.0, 0.0, TAU, 20, outer_color, 3.0)

func explode() -> void:
	if exploded:
		return
	exploded = true
	label.visible = false
	monitoring = false
	queue_redraw()

	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		if player != null and player.is_inside_tree() and player.alive and player.global_position.distance_to(global_position) <= explosion_radius:
			if not player.is_protected_from_explosion():
				player.die()
	await get_tree().create_timer(0.16).timeout
	if is_inside_tree():
		queue_free()
