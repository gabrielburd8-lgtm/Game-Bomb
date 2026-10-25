extends Node2D

const PLAYER_SCENE = preload("res://scenes/Player.tscn")
const BOMB_SCENE = preload("res://scenes/Bomb.tscn")
const PICKUP_SCENE = preload("res://scenes/Pickup.tscn")

const ARENA_WIDTH := 1280.0
const ARENA_HEIGHT := 720.0
const STARTING_BOMBS := 8
const MAX_ACTIVE_BOMBS := 20
const COLOR_OPTIONS := [
	{"name": "Red", "color": Color(1.0, 0.30, 0.35)},
	{"name": "Orange", "color": Color(1.0, 0.60, 0.20)},
	{"name": "Yellow", "color": Color(1.0, 0.85, 0.25)},
	{"name": "Green", "color": Color(0.30, 0.82, 0.42)},
	{"name": "Blue", "color": Color(0.28, 0.60, 1.0)},
	{"name": "Indigo", "color": Color(0.40, 0.42, 0.90)},
	{"name": "Violet", "color": Color(0.72, 0.50, 1.0)},
]

enum GameMode {
	SOLO,
	LOCAL_MULTIPLAYER,
}

var game_mode: int = GameMode.SOLO
var round_active := false
var match_started := false
var elapsed_time := 0.0
var players: Array = []
var bombs: Array = []
var pickups: Array = []

var world_root: Node2D
var ui_root: CanvasLayer
var timer_label: Label
var info_label: Label
var results_panel: PanelContainer
var bomb_spawn_timer: Timer
var pickup_spawn_timer: Timer

var solo_color_index := 0
var p1_color_index := 0
var p2_color_index := 1

func _ready() -> void:
	randomize()
	world_root = Node2D.new()
	world_root.name = "World"
	add_child(world_root)

	ui_root = CanvasLayer.new()
	ui_root.name = "UI"
	add_child(ui_root)

	show_main_menu()

func _process(delta: float) -> void:
	if round_active:
		elapsed_time += delta
		update_timer_label()
		check_for_game_over()

	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

func clear_world() -> void:
	for child in world_root.get_children():
		child.queue_free()
	players.clear()
	bombs.clear()
	pickups.clear()

func clear_ui() -> void:
	for child in ui_root.get_children():
		child.queue_free()

func make_button_style(color_value: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color_value
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(1, 1, 1, 0.65)
	return style

func make_menu_button(text_value: String, size: Vector2 = Vector2(260, 56), text_size: int = 22, base_color: Color = Color(0.15, 0.20, 0.32, 0.96)) -> Button:
	var btn := Button.new()
	btn.text = text_value
	btn.custom_minimum_size = size
	btn.add_theme_font_size_override("font_size", text_size)
	btn.focus_mode = Control.FOCUS_NONE

	var normal := StyleBoxFlat.new()
	normal.bg_color = base_color
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.border_color = Color(0.82, 0.9, 1.0, 0.9)
	normal.corner_radius_top_left = 10
	normal.corner_radius_top_right = 10
	normal.corner_radius_bottom_left = 10
	normal.corner_radius_bottom_right = 10
	btn.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate()
	hover.bg_color = base_color.lightened(0.14)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate()
	pressed.bg_color = base_color.darkened(0.12)
	btn.add_theme_stylebox_override("pressed", pressed)

	return btn

func make_color_choice_button(color_data: Dictionary, selected_callback: Callable) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(110, 42)
	btn.text = color_data["name"]
	btn.focus_mode = Control.FOCUS_NONE

	var style := make_button_style(color_data["color"])
	btn.add_theme_stylebox_override("normal", style)

	var hover := style.duplicate()
	hover.bg_color = color_data["color"].lightened(0.10)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := style.duplicate()
	pressed.bg_color = color_data["color"].darkened(0.10)
	btn.add_theme_stylebox_override("pressed", pressed)

	var text_color := Color(1, 1, 1, 1)
	if color_data["color"].get_luminance() > 0.75:
		text_color = Color(0, 0, 0, 1)
	btn.add_theme_color_override("font_color", text_color)
	btn.add_theme_color_override("font_hover_color", text_color)
	btn.add_theme_color_override("font_pressed_color", text_color)
	btn.pressed.connect(selected_callback)
	return btn

func show_main_menu() -> void:
	match_started = false
	round_active = false
	elapsed_time = 0.0
	clear_ui()
	clear_world()
	stop_bomb_spawn_loop()
	stop_pickup_spawn_loop()

	var menu_panel := PanelContainer.new()
	menu_panel.custom_minimum_size = Vector2(820, 500)
	menu_panel.position = Vector2(230, 105)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.13, 0.22, 0.96)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.72, 0.80, 0.94, 1.0)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	menu_panel.add_theme_stylebox_override("panel", style)
	ui_root.add_child(menu_panel)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_panel.add_child(box)

	var title := Label.new()
	title.text = "BOMB DODGE"
	title.add_theme_font_size_override("font_size", 54)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(1, 1, 1, 1)
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Choose game mode"
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.modulate = Color(0.84, 0.9, 1.0, 1.0)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(subtitle)

	var button_box := VBoxContainer.new()
	button_box.alignment = BoxContainer.ALIGNMENT_CENTER
	button_box.custom_minimum_size = Vector2(320, 0)
	box.add_child(button_box)

	var solo_button := make_menu_button("Solo", Vector2(300, 58), 24)
	solo_button.pressed.connect(func() -> void:
		show_color_selection(GameMode.SOLO)
	)
	button_box.add_child(solo_button)

	var mp_button := make_menu_button("Local Multiplayer", Vector2(300, 58), 24)
	mp_button.pressed.connect(func() -> void:
		show_color_selection(GameMode.LOCAL_MULTIPLAYER)
	)
	button_box.add_child(mp_button)

	var exit_button := make_menu_button("Exit", Vector2(300, 58), 24)
	exit_button.pressed.connect(func() -> void:
		get_tree().quit()
	)
	button_box.add_child(exit_button)

func show_color_selection(mode: int) -> void:
	game_mode = mode
	clear_ui()

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(980, 560)
	panel.position = Vector2(150, 80)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.16, 0.24, 0.96)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.7, 0.79, 0.96, 1.0)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	panel.add_theme_stylebox_override("panel", style)
	ui_root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Choose your colors"
	title.add_theme_font_size_override("font_size", 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(1, 1, 1, 1)
	vbox.add_child(title)

	if game_mode == GameMode.SOLO:
		var preview_box := ColorRect.new()
		preview_box.custom_minimum_size = Vector2(130, 130)
		preview_box.color = COLOR_OPTIONS[solo_color_index]["color"]
		vbox.add_child(preview_box)

		var swatches := HBoxContainer.new()
		swatches.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_child(swatches)
		for i in range(COLOR_OPTIONS.size()):
			var pick_index := i
			var btn := make_color_choice_button(COLOR_OPTIONS[i], func() -> void:
				solo_color_index = pick_index
				preview_box.color = COLOR_OPTIONS[pick_index]["color"]
			)
			swatches.add_child(btn)

		var start_button := make_menu_button("Start Match", Vector2(220, 56), 22)
		start_button.pressed.connect(func() -> void:
			start_match()
		)
		vbox.add_child(start_button)
	else:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_child(row)

		var p1_box := VBoxContainer.new(); p1_box.alignment = BoxContainer.ALIGNMENT_CENTER; row.add_child(p1_box)
		var p1_label := Label.new(); p1_label.text = "Player 1"; p1_label.add_theme_font_size_override("font_size", 22); p1_box.add_child(p1_label)
		var p1_preview := ColorRect.new(); p1_preview.custom_minimum_size = Vector2(110, 110); p1_preview.color = COLOR_OPTIONS[p1_color_index]["color"]; p1_box.add_child(p1_preview)
		var p1_swatch_row := HBoxContainer.new(); p1_swatch_row.alignment = BoxContainer.ALIGNMENT_CENTER; p1_box.add_child(p1_swatch_row)
		for i in range(COLOR_OPTIONS.size()):
			var pick_index := i
			var btn := make_color_choice_button(COLOR_OPTIONS[i], func() -> void:
				p1_color_index = pick_index
				p1_preview.color = COLOR_OPTIONS[p1_color_index]["color"]
				if p1_color_index == p2_color_index:
					var alt := get_next_available_color_index([p1_color_index])
					if alt != -1:
						p2_color_index = alt
						p2_preview.color = COLOR_OPTIONS[p2_color_index]["color"]
			)
			p1_swatch_row.add_child(btn)

		var p2_box := VBoxContainer.new(); p2_box.alignment = BoxContainer.ALIGNMENT_CENTER; row.add_child(p2_box)
		var p2_label := Label.new(); p2_label.text = "Player 2"; p2_label.add_theme_font_size_override("font_size", 22); p2_box.add_child(p2_label)
		var p2_preview := ColorRect.new(); p2_preview.custom_minimum_size = Vector2(110, 110); p2_preview.color = COLOR_OPTIONS[p2_color_index]["color"]; p2_box.add_child(p2_preview)
		var p2_swatch_row := HBoxContainer.new(); p2_swatch_row.alignment = BoxContainer.ALIGNMENT_CENTER; p2_box.add_child(p2_swatch_row)
		for i in range(COLOR_OPTIONS.size()):
			var pick_index := i
			var btn := make_color_choice_button(COLOR_OPTIONS[i], func() -> void:
				if pick_index == p1_color_index:
					var alt := get_next_available_color_index([p1_color_index])
					if alt == -1:
						return
					p2_color_index = alt
				else:
					p2_color_index = pick_index
				p2_preview.color = COLOR_OPTIONS[p2_color_index]["color"]
			)
			p2_swatch_row.add_child(btn)

		var start_button := make_menu_button("Start Match", Vector2(220, 56), 22)
		start_button.pressed.connect(func() -> void:
			start_match()
		)
		vbox.add_child(start_button)

	var back_button := make_menu_button("Back to Menu", Vector2(220, 56), 22)
	back_button.pressed.connect(func() -> void:
		show_main_menu()
	)
	vbox.add_child(back_button)

func get_next_available_color_index(excluded_indices: Array) -> int:
	for i in range(COLOR_OPTIONS.size()):
		if not excluded_indices.has(i):
			return i
	return -1

func create_arena() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(ARENA_WIDTH, ARENA_HEIGHT)
	bg.color = Color(0.03, 0.10, 0.18, 1.0)
	world_root.add_child(bg)

	var border_color := Color(0.36, 0.52, 0.80, 1.0)
	var border_thickness := 4.0
	var border_nodes := [
		[Vector2(0, 0), Vector2(ARENA_WIDTH, border_thickness)],
		[Vector2(0, ARENA_HEIGHT - border_thickness), Vector2(ARENA_WIDTH, border_thickness)],
		[Vector2(0, 0), Vector2(border_thickness, ARENA_HEIGHT)],
		[Vector2(ARENA_WIDTH - border_thickness, 0), Vector2(border_thickness, ARENA_HEIGHT)],
	]
	for data in border_nodes:
		var border := ColorRect.new()
		border.position = data[0]
		border.size = data[1]
		border.color = border_color
		world_root.add_child(border)

func create_match_ui() -> void:
	if timer_label != null:
		timer_label.queue_free()
	if info_label != null:
		info_label.queue_free()
	if results_panel != null:
		results_panel.queue_free()
	results_panel = null

	timer_label = Label.new()
	timer_label.text = "Time: 0.0s"
	timer_label.add_theme_font_size_override("font_size", 34)
	timer_label.modulate = Color(1, 1, 1, 1)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.custom_minimum_size = Vector2(420, 42)
	timer_label.position = Vector2((ARENA_WIDTH - 420) * 0.5, 18)
	ui_root.add_child(timer_label)

	info_label = Label.new()
	info_label.add_theme_font_size_override("font_size", 18)
	info_label.modulate = Color(0.84, 0.88, 1.0, 1.0)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.custom_minimum_size = Vector2(620, 32)
	info_label.position = Vector2((ARENA_WIDTH - 620) * 0.5, ARENA_HEIGHT - 42)
	ui_root.add_child(info_label)

	update_timer_label()

func update_timer_label() -> void:
	if timer_label != null:
		timer_label.text = "Time: %.1fs" % elapsed_time

func start_match() -> void:
	clear_ui()
	clear_world()
	round_active = true
	match_started = true
	elapsed_time = 0.0
	create_arena()
	create_match_ui()
	spawn_players()
	spawn_initial_bombs()
	start_bomb_spawn_loop()
	start_pickup_spawn_loop()

	if game_mode == GameMode.SOLO:
		info_label.text = "WASD to move and survive"
	else:
		info_label.text = "Player 1: WASD | Player 2: Arrow Keys"

func spawn_players() -> void:
	players.clear()
	if game_mode == GameMode.SOLO:
		var player := PLAYER_SCENE.instantiate()
		player.name = "Player1"
		player.position = Vector2(150, ARENA_HEIGHT * 0.5)
		player.set_player_name("Player")
		player.set_player_id(1)
		player.set_player_color(COLOR_OPTIONS[solo_color_index]["color"])
		player.set_control_scheme("solo")
		player.set_ability_type_from_color(player.get_player_color())
		world_root.add_child(player)
		players.append(player)
		create_player_hud(player)
		return

	var player1 := PLAYER_SCENE.instantiate()
	player1.name = "Player1"
	player1.position = Vector2(180, ARENA_HEIGHT * 0.5)
	player1.set_player_name("Player 1")
	player1.set_player_id(1)
	player1.set_player_color(COLOR_OPTIONS[p1_color_index]["color"])
	player1.set_control_scheme("p1")
	player1.set_ability_type_from_color(player1.get_player_color())
	world_root.add_child(player1)
	players.append(player1)
	create_player_hud(player1)

	var player2 := PLAYER_SCENE.instantiate()
	player2.name = "Player2"
	player2.position = Vector2(ARENA_WIDTH - 180, ARENA_HEIGHT * 0.5)
	player2.set_player_name("Player 2")
	player2.set_player_id(2)
	player2.set_player_color(COLOR_OPTIONS[p2_color_index]["color"])
	player2.set_control_scheme("p2")
	player2.set_ability_type_from_color(player2.get_player_color())
	world_root.add_child(player2)
	players.append(player2)
	create_player_hud(player2)

func create_player_hud(player: Node) -> void:
	var hud := VBoxContainer.new()
	hud.alignment = BoxContainer.ALIGNMENT_CENTER
	if player.player_id == 1:
		hud.position = Vector2(18, 70)
	else:
		hud.position = Vector2(ARENA_WIDTH - 170, 70)
	ui_root.add_child(hud)

	var label := Label.new()
	label.text = player.player_name
	label.add_theme_font_size_override("font_size", 18)
	label.modulate = Color(1, 1, 1, 1)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_child(label)

	var button := Button.new()
	button.custom_minimum_size = Vector2(115, 38)
	button.focus_mode = Control.FOCUS_NONE
	button.text = "Ability"
	button.modulate = Color(1, 1, 1, 1)
	button.visible = false
	button.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.double_click:
			player.activate_ability_from_hud()
	)
	hud.add_child(button)

	var status := Label.new()
	status.text = "Ready"
	status.add_theme_font_size_override("font_size", 15)
	status.modulate = Color(0.8, 0.9, 1.0, 1.0)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.visible = false
	hud.add_child(status)

	player.set_meta("hud_button", button)
	player.set_meta("hud_status", status)
	update_player_hud(player)

func update_player_hud(player: Node) -> void:
	var button: Button = player.get_meta("hud_button", null)
	var status: Label = player.get_meta("hud_status", null)
	if button == null or status == null:
		return

	if player.ability_type == "dash":
		button.text = "DASH"
		button.modulate = Color(1.0, 0.35, 0.38)
		if player.dash_inventory:
			button.visible = true
			status.visible = true
			status.text = "Ready"
		else:
			button.visible = false
			status.visible = false
	elif player.ability_type == "shield":
		button.text = "SHIELD"
		button.modulate = Color(0.30, 0.65, 1.0)
		if player.shield_inventory:
			button.visible = true
			status.visible = true
			status.text = "Ready"
		else:
			button.visible = false
			status.visible = false
	else:
		button.visible = false
		status.visible = false

	if player.ability_type == "shield" and player.shield_active:
		button.visible = true
		status.visible = true
		status.text = "%.1fs" % player.shield_timer

func update_all_huds() -> void:
	for player in players:
		if player != null:
			update_player_hud(player)

func start_bomb_spawn_loop() -> void:
	if bomb_spawn_timer != null:
		bomb_spawn_timer.stop()
		bomb_spawn_timer.queue_free()

	bomb_spawn_timer = Timer.new()
	bomb_spawn_timer.wait_time = 0.6
	bomb_spawn_timer.autostart = true
	bomb_spawn_timer.one_shot = false
	bomb_spawn_timer.timeout.connect(_spawn_bomb_tick)
	world_root.add_child(bomb_spawn_timer)

func stop_bomb_spawn_loop() -> void:
	if bomb_spawn_timer != null:
		bomb_spawn_timer.stop()
		bomb_spawn_timer.queue_free()
		bomb_spawn_timer = null

func start_pickup_spawn_loop() -> void:
	if pickup_spawn_timer != null:
		pickup_spawn_timer.stop()
		pickup_spawn_timer.queue_free()

	pickup_spawn_timer = Timer.new()
	pickup_spawn_timer.wait_time = 7.0
	pickup_spawn_timer.autostart = true
	pickup_spawn_timer.one_shot = false
	pickup_spawn_timer.timeout.connect(_spawn_pickup_tick)
	world_root.add_child(pickup_spawn_timer)

func stop_pickup_spawn_loop() -> void:
	if pickup_spawn_timer != null:
		pickup_spawn_timer.stop()
		pickup_spawn_timer.queue_free()
		pickup_spawn_timer = null

func spawn_initial_bombs() -> void:
	for i in range(STARTING_BOMBS):
		_spawn_bomb(false)

func _spawn_bomb_tick() -> void:
	if not round_active:
		return
	if bombs.size() < MAX_ACTIVE_BOMBS:
		_spawn_bomb(true)

func _spawn_pickup_tick() -> void:
	if not round_active:
		return
	if pickups.size() >= 3:
		return
	var options := []
	for player in players:
		if player != null and player.ability_type != "":
			options.append(player.ability_type)
	if options.size() == 0:
		return
	var type := options[randi() % options.size()]
	_spawn_pickup(type)

func _spawn_bomb(_allow_delay: bool) -> void:
	if bombs.size() >= MAX_ACTIVE_BOMBS:
		return

	var safe_pos := find_valid_bomb_position()
	if safe_pos == null:
		return

	var bomb := BOMB_SCENE.instantiate()
	bomb.position = safe_pos
	bomb.name = "Bomb"
	world_root.add_child(bomb)
	bombs.append(bomb)
	bomb.tree_exiting.connect(func() -> void:
		if bombs.has(bomb):
			bombs.erase(bomb)
	)

func _spawn_pickup(type_name: String) -> void:
	var pos := find_valid_pickup_position()
	if pos == null:
		return
	var pickup := PICKUP_SCENE.instantiate()
	pickup.position = pos
	pickup.set_pickup_type(type_name)
	world_root.add_child(pickup)
	pickups.append(pickup)
	pickup.body_entered.connect(func(body: Node) -> void:
		if body is CharacterBody2D and body.alive:
			if body.ability_type == type_name:
				body.collect_pickup(type_name)
				if pickups.has(pickup):
					pickups.erase(pickup)
				pickup.queue_free()
	)

func find_valid_bomb_position() -> Vector2:
	for i in range(120):
		var x := randf_range(90.0, ARENA_WIDTH - 90.0)
		var y := randf_range(90.0, ARENA_HEIGHT - 90.0)
		var pos := Vector2(x, y)
		var valid := true
		for player in players:
			if player != null and player.is_inside_tree():
				if player.global_position.distance_to(pos) < 150.0:
					valid = false
					break
		if not valid:
			continue
		for bomb in bombs:
			if bomb != null and bomb.is_inside_tree():
				if bomb.global_position.distance_to(pos) < 90.0:
					valid = false
					break
		if valid:
			return pos
	return Vector2.ZERO

func find_valid_pickup_position() -> Vector2:
	for i in range(120):
		var x := randf_range(80.0, ARENA_WIDTH - 80.0)
		var y := randf_range(80.0, ARENA_HEIGHT - 80.0)
		var pos := Vector2(x, y)
		var valid := true
		for player in players:
			if player != null and player.is_inside_tree() and player.global_position.distance_to(pos) < 90.0:
				valid = false
				break
		if not valid:
			continue
		for bomb in bombs:
			if bomb != null and bomb.is_inside_tree() and bomb.global_position.distance_to(pos) < 70.0:
				valid = false
				break
		if valid:
			return pos
	return Vector2.ZERO

func check_for_game_over() -> void:
	var alive_players: Array = []
	for player in players:
		if player != null and player.alive:
			alive_players.append(player)

	if game_mode == GameMode.SOLO:
		if alive_players.size() == 0:
			finish_match(alive_players)
		return

	if alive_players.size() <= 1:
		finish_match(alive_players)

func finish_match(alive_players: Array) -> void:
	if not round_active:
		return
	round_active = false
	stop_bomb_spawn_loop()
	stop_pickup_spawn_loop()
	show_results(alive_players)

func show_results(alive_players: Array) -> void:
	if results_panel != null:
		results_panel.queue_free()
		results_panel = null

	results_panel = PanelContainer.new()
	results_panel.custom_minimum_size = Vector2(640, 360)
	results_panel.position = Vector2((ARENA_WIDTH - 640) * 0.5, 170)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.18, 0.35, 1.0)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.70, 0.83, 1.0, 1.0)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	results_panel.add_theme_stylebox_override("panel", style)
	ui_root.add_child(results_panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	results_panel.add_child(vbox)

	var title := Label.new()
	title.add_theme_font_size_override("font_size", 42)
	title.modulate = Color(1, 1, 1, 1)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var time_label := Label.new()
	time_label.add_theme_font_size_override("font_size", 28)
	time_label.modulate = Color(1, 1, 1, 1)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(time_label)

	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.custom_minimum_size = Vector2(420, 64)
	vbox.add_child(button_row)

	if game_mode == GameMode.SOLO:
		title.text = "GAME OVER"
		time_label.text = "Final time: %.1fs" % elapsed_time
	else:
		if alive_players.size() == 0:
			title.text = "DRAW"
			time_label.text = "Final time: %.1fs" % elapsed_time
		elif alive_players.size() == 1:
			var winner: Node = alive_players[0]
			title.text = "PLAYER %d WINS" % winner.player_id
			time_label.text = "Final time: %.1fs" % elapsed_time
		else:
			title.text = "DRAW"
			time_label.text = "Final time: %.1fs" % elapsed_time

	var restart_button := make_menu_button("Restart", Vector2(180, 56), 20)
	restart_button.pressed.connect(func() -> void:
		start_match()
	)
	button_row.add_child(restart_button)

	var menu_button := make_menu_button("Main Menu", Vector2(180, 56), 20)
	menu_button.pressed.connect(func() -> void:
		show_main_menu()
	)
	button_row.add_child(menu_button)

func _process_ui_state() -> void:
	update_all_huds()
	if info_label != null:
		if game_mode == GameMode.SOLO:
			info_label.text = "WASD to move and survive"
		else:
			info_label.text = "Player 1: WASD | Player 2: Arrow Keys"
	if round_active:
		update_timer_label()
