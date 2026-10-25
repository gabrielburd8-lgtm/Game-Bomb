extends Area2D

var pickup_type := "dash"
var pulse := 0.0

@onready var label: Label = $Label

func _ready() -> void:
	if pickup_type == "dash":
		label.text = "D"
		label.modulate = Color(1.0, 0.85, 0.85, 1.0)
	else:
		label.text = "S"
		label.modulate = Color(0.85, 0.95, 1.0, 1.0)
	label.add_theme_font_size_override("font_size", 20)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	queue_redraw()

func _draw() -> void:
	if pickup_type == "dash":
		var diamond := PackedVector2Array([
			Vector2(0, -20),
			Vector2(18, 0),
			Vector2(0, 20),
			Vector2(-18, 0),
		])
		draw_polygon(diamond, [Color(1.0, 0.35, 0.38, 1.0)])
		draw_line(Vector2(0, -20), Vector2(18, 0), Color(1.0, 1.0, 1.0, 0.9), 2.0)
		draw_line(Vector2(18, 0), Vector2(0, 20), Color(1.0, 1.0, 1.0, 0.9), 2.0)
		draw_line(Vector2(0, 20), Vector2(-18, 0), Color(1.0, 1.0, 1.0, 0.9), 2.0)
		draw_line(Vector2(-18, 0), Vector2(0, -20), Color(1.0, 1.0, 1.0, 0.9), 2.0)
	else:
		draw_circle(Vector2.ZERO, 18.0, Color(0.28, 0.62, 1.0, 1.0))
		draw_arc(Vector2.ZERO, 12.0, 0.0, TAU, 24, Color(0.82, 0.92, 1.0, 1.0), 3.0)
		draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 24, Color(0.82, 0.92, 1.0, 0.6), 2.0)

func set_pickup_type(type_name: String) -> void:
	pickup_type = type_name
	if pickup_type == "dash":
		modulate = Color(1.0, 0.35, 0.38, 1.0)
	else:
		modulate = Color(0.28, 0.62, 1.0, 1.0)
	queue_redraw()

func _process(delta: float) -> void:
	pulse += delta * 3.0
	queue_redraw()
