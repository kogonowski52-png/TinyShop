extends Control

const INK := Color("#35455f")
const PAPER := Color("#fffdf6")
const PLUM := Color("#47395e")
const GIFT_PATH := "res://assets/art/products/gift.png"
const DISPLAY_PATH := "res://assets/fonts/display.ttf"
const DIALOG_SIZE := Vector2(484, 654)

var _panel: Panel
var _gift: TextureRect
var _backdrop: Button
var _close: Button
var _action: Button
var _offer_name: Label
var _flare: Accent
var _unwrapped := false
var _app: Control


class Accent extends Control:
	var kind: String

	func _draw() -> void:
		var center := size * 0.5
		match kind:
			"close":
				draw_line(center + Vector2(-6, -6), center + Vector2(6, 6), INK, 2.7, true)
				draw_line(center + Vector2(-6, 6), center + Vector2(6, -6), INK, 2.7, true)
			"coin":
				draw_circle(center + Vector2(0, 2), 13, Color("#c17e39"), true, -1, true)
				draw_circle(center, 13, Color("#ffd26d"), true, -1, true)
				draw_arc(center, 9.1, 0.0, TAU, 26, Color("#ca8841"), 1.4, true)
				_star(center, 6.0, Color("#986137"))
			"undo":
				draw_arc(center + Vector2(0, 1), 7.8, PI * 1.13, TAU * 1.10, 30, Color("#7552a1"), 2.7, true)
				draw_polyline(PackedVector2Array([
					center + Vector2(-9, -10), center + Vector2(-9, -4), center + Vector2(-3, -4)
				]), Color("#7552a1"), 2.7, true)
			"halo":
				draw_circle(center, 118, Color("#fff9f2", 0.30), true, -1, true)
				draw_arc(center, 118, 0.0, TAU, 100, Color("#fff8f1", 0.58), 1.5, true)
				draw_arc(center, 132, -PI * 0.80, -PI * 0.30, 32, Color("#fff8f1", 0.65), 1.3, true)
				draw_arc(center, 132, PI * 0.22, PI * 0.44, 20, Color("#fff8f1", 0.65), 1.3, true)
				_star(center + Vector2(-139, -51), 12, Color("#fff9ef"))
				_star(center + Vector2(141, -74), 15, Color("#ba9ae1"))
				_star(center + Vector2(145, 62), 10, Color("#fff9ef"))
				_star(center + Vector2(-153, 63), 7, Color("#9976c6"))
				draw_circle(center + Vector2(161, 32), 2.8, Color("#a78cc7"), true, -1, true)
				draw_circle(center + Vector2(-114, -87), 3.0, Color("#b69ad7"), true, -1, true)
			"burst":
				_star(center + Vector2(-104, -72), 21, Color("#fff9ee"))
				_star(center + Vector2(101, -67), 16, Color("#ffe290"))
				_star(center + Vector2(-143, 31), 14, Color("#fff9ee"))
				_star(center + Vector2(133, 32), 17, Color("#fff9ee"))
				_star(center + Vector2(72, 77), 9, Color("#ffe290"))
				_star(center + Vector2(-77, 94), 11, Color("#ffe290"))

	func _star(center: Vector2, radius: float, color: Color) -> void:
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(0, -radius), center + Vector2(radius * 0.24, -radius * 0.22),
			center + Vector2(radius, 0), center + Vector2(radius * 0.24, radius * 0.22),
			center + Vector2(0, radius), center + Vector2(-radius * 0.24, radius * 0.22),
			center + Vector2(-radius, 0), center + Vector2(-radius * 0.24, -radius * 0.22)
		]), color)


func setup(app: Control) -> void:
	_app = app
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_add_scrim()
	_panel = Panel.new()
	_panel.size = DIALOG_SIZE
	_panel.add_theme_stylebox_override("panel", _surface(PAPER, 34, Color("#e5d1da"), 2, 18))
	add_child(_panel)
	resized.connect(_place_dialog)
	_place_dialog()
	_add_header()
	_add_offer()
	_add_actions()
	_link_button_focus()
	_animate_entry()


func _place_dialog() -> void:
	_panel.position = ((size - DIALOG_SIZE) * 0.5).round()
	_panel.pivot_offset = DIALOG_SIZE * 0.5


func _add_scrim() -> void:
	var shade := ColorRect.new()
	shade.color = Color("#302746", 0.62)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop = Button.new()
	_backdrop.flat = true
	_backdrop.focus_mode = Control.FOCUS_NONE
	_backdrop.pressed.connect(_app.close_store)
	add_child(_backdrop)
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _add_header() -> void:
	var title := _label(_panel, "Sklepik", 51, INK, Rect2(32, 22, 311, 67), HORIZONTAL_ALIGNMENT_LEFT)
	if ResourceLoader.exists(DISPLAY_PATH):
		title.add_theme_font_override("font", load(DISPLAY_PATH))
	_close = _button("Zamknij", 17, Color.TRANSPARENT, Color("#f3e8f5"), Color("#d8c8e4"), 22, 3)
	_place(_panel, _close, Rect2(392, 31, 56, 52))
	_accent(_close, "close", Rect2(8, 6, 40, 40))
	_close.pressed.connect(_app.close_store)


func _add_offer() -> void:
	var card := Panel.new()
	card.add_theme_stylebox_override("panel", _surface(Color("#e9dcf8"), 27, Color("#d8c4ee"), 2, 4))
	_place(_panel, card, Rect2(26, 105, 432, 392))
	_offer_name = _label(card, "Pakiet na start", 26, PLUM, Rect2(20, 15, 392, 46))
	_accent(card, "halo", Rect2(24, 60, 384, 246))
	_gift = TextureRect.new()
	_gift.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_gift.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_gift.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(GIFT_PATH):
		_gift.texture = load(GIFT_PATH) as Texture2D
	_place(card, _gift, Rect2(101, 67, 230, 230))
	_gift.pivot_offset = _gift.size * 0.5
	_flare = _accent(card, "burst", Rect2(24, 60, 384, 246))
	_flare.modulate.a = 0.0
	_flare.pivot_offset = _flare.size * 0.5
	_reward_chip(card, "180 monet", "coin", Rect2(18, 315, 192, 57))
	_reward_chip(card, "2 cofnięcia", "undo", Rect2(222, 315, 192, 57))


func _reward_chip(parent: Control, value: String, icon: String, rect: Rect2) -> void:
	var chip := Panel.new()
	chip.add_theme_stylebox_override("panel", _surface(Color("#fffaf5"), 18, Color("#f6eef6"), 1, 2))
	_place(parent, chip, rect)
	_accent(chip, icon, Rect2(13, 9, 41, 39))
	_label(chip, value, 20, PLUM, Rect2(56, 0, 130, rect.size.y), HORIZONTAL_ALIGNMENT_LEFT)


func _add_actions() -> void:
	_action = _button("Otwórz próbkę", 25, Color("#174f4d"), Color("#9fe4d4"), Color("#5a9d91"), 24, 6)
	_place(_panel, _action, Rect2(26, 521, 432, 69))
	_action.pressed.connect(_unwrap)
	_label(_panel, "Podgląd oferty · bez zakupów", 17, Color("#645671"), Rect2(25, 608, 434, 28))


func _link_button_focus() -> void:
	_close.focus_neighbor_bottom = _close.get_path_to(_action)
	_close.focus_next = _close.get_path_to(_action)
	_close.focus_previous = _close.get_path_to(_action)
	_action.focus_neighbor_top = _action.get_path_to(_close)
	_action.focus_next = _action.get_path_to(_close)
	_action.focus_previous = _action.get_path_to(_close)


func _animate_entry() -> void:
	_panel.modulate.a = 0.0
	_panel.scale = Vector2.ONE * 0.94
	var show_popup := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	show_popup.tween_property(_panel, "modulate:a", 1.0, 0.23)
	show_popup.tween_property(_panel, "scale", Vector2.ONE, 0.30)


func _unwrap() -> void:
	if _unwrapped:
		_app.close_store()
		return
	_unwrapped = true
	_offer_name.text = "Pakiet rozpakowany"
	_action.text = "Gotowe"
	_gift.scale = Vector2.ONE * 0.86
	_gift.rotation_degrees = -8.0
	_flare.modulate.a = 0.95
	_flare.scale = Vector2.ONE * 0.72
	var artwork := create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	artwork.tween_property(_gift, "scale", Vector2.ONE, 0.45)
	artwork.tween_property(_gift, "rotation_degrees", 0.0, 0.46)
	artwork.tween_property(_flare, "scale", Vector2.ONE * 1.15, 0.56)
	artwork.tween_property(_flare, "modulate:a", 0.0, 0.64).set_trans(Tween.TRANS_SINE)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_app.close_store()


func _button(value: String, font_size: int, text_color: Color, fill: Color, edge: Color, radius: int, depth: int) -> Button:
	var button := Button.new()
	button.text = value
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", font_size)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(state, text_color)
	button.add_theme_stylebox_override("normal", _surface(fill, radius, edge, 1, depth))
	button.add_theme_stylebox_override("hover", _surface(fill.lightened(0.10), radius, edge, 1, depth))
	button.add_theme_stylebox_override("pressed", _surface(fill.darkened(0.09), radius, edge, 1, 2))
	var focus := _surface(Color.TRANSPARENT, radius, PLUM, 3, 0)
	focus.draw_center = false
	button.add_theme_stylebox_override("focus", focus)
	return button


func _label(parent: Control, value: String, font_size: int, color: Color, rect: Rect2, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	_place(parent, label, rect)
	return label


func _accent(parent: Control, kind: String, rect: Rect2) -> Accent:
	var accent := Accent.new()
	accent.kind = kind
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(parent, accent, rect)
	return accent


func _surface(fill: Color, radius: int, edge: Color, border: int, depth: int) -> StyleBoxFlat:
	var surface := StyleBoxFlat.new()
	surface.bg_color = fill
	surface.set_corner_radius_all(radius)
	surface.corner_detail = 12
	surface.set_border_width_all(border)
	surface.border_color = edge
	surface.shadow_color = Color(edge.darkened(0.29), 0.54)
	surface.shadow_size = depth
	surface.shadow_offset = Vector2(0, depth * 0.7)
	return surface


func _place(parent: Control, node: Control, rect: Rect2) -> void:
	parent.add_child(node)
	node.position = rect.position
	node.size = rect.size
