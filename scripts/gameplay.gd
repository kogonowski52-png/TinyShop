extends Control

const BOARD_SIZE := Vector2(540, 960)
const TRAY_SIZE := 7
const REWARD := 120
const PRODUCT_IDS := [
	"bear", "bunny", "mug", "plant",
	"car", "cookie", "gift", "apple",
	"bottle", "figurine", "candle", "cupcake",
]
const PRODUCT_NAMES := [
	"Pluszowy miś", "Króliczek", "Kolorowy kubek", "Roślina",
	"Samochodzik", "Ciastko", "Prezent", "Jabłko",
	"Buteleczka", "Figurka", "Świeczka", "Babeczka",
]

const INK := Color("#35455F")
const INK_DARK := Color("#273B49")
const MUTED := Color("#566777")
const CREAM := Color("#FFF7EC")
const WHITE := Color("#FFFDF7")
const DARK_MINT := Color("#276357")
const PLUM := Color("#8F4150")
const DISPLAY_FONT := preload("res://assets/fonts/display.ttf")
const CABINET_ART := preload("res://assets/art/cabinet.webp")
const LANDING_FRACTIONS := [0.335, 0.591, 0.864]
const PRODUCT_SIZE := Vector2(104, 104)

var _app: Control
var _stocks: Array[Array] = []
var _tray: Array[int] = []
var _textures: Array[Texture2D] = []
var _feet: Array[float] = []
var _product_icons: Array[TextureRect] = []
var _product_buttons: Array[Button] = []
var _stock_badges: Array[Label] = []
var _stock_shadows: Array[Glyph] = []
var _tray_icons: Array[TextureRect] = []
var _previous: Dictionary = {}
var _matched := 0
var _busy := false
var _rewarded := false
var _round_reward := 0
var _artboard: Control
var _heading: Control
var _shelf: Control
var _cabinet: TextureRect
var _tray_panel: Control
var _actions: Control
var _back_button: Button
var _coin_count: Label
var _summary: Label
var _progress_fill: Panel
var _tray_count: Label
var _hint: Label
var _undo_button: Button
var _reset_button: Button
var _store_button: Button


class Glyph extends Control:
	var symbol := ""
	var ink := Color("#35455F")

	func _draw() -> void:
		var center := size / 2.0
		var x := center.x
		var y := center.y
		match symbol:
			"back":
				draw_line(Vector2(x - 9, y), Vector2(x + 9, y), ink, 2.5, true)
				draw_polyline(PackedVector2Array([
					Vector2(x - 2, y - 7), Vector2(x - 9, y), Vector2(x - 2, y + 7),
				]), ink, 2.5, true)
			"undo", "reset":
				var start := deg_to_rad(-140.0 if symbol == "undo" else -130.0)
				draw_arc(center, 8.0, start, deg_to_rad(165.0), 30, ink, 2.1, true)
				var tip := center + Vector2.from_angle(start) * 8
				draw_polyline(PackedVector2Array([
					tip + Vector2(-1, -5), tip + Vector2(-1, 1), tip + Vector2(5, 1),
				]), ink, 2.1, true)
			"bag":
				draw_arc(Vector2(x, y - 4), 4, PI, TAU, 12, ink, 2, true)
				draw_polyline(PackedVector2Array([
					Vector2(x - 7, y - 4), Vector2(x + 7, y - 4), Vector2(x + 9, y + 8),
					Vector2(x - 9, y + 8), Vector2(x - 7, y - 4),
				]), ink, 2, true)
			"coin":
				draw_circle(center + Vector2(0, 1.4), 11, Color("#B57931"), true, -1, true)
				draw_circle(center, 10.3, Color("#FFD26D"), true, -1, true)
				draw_arc(center, 7.5, 0, TAU, 32, Color("#D5963D"), 1.4, true)
				draw_polyline(PackedVector2Array([
					Vector2(x - 3, y - 1), Vector2(x, y - 5), Vector2(x + 3, y - 1),
					Vector2(x, y + 4), Vector2(x - 3, y - 1),
				]), Color("#A5692F"), 1.4, true)
			"shadow":
				draw_set_transform(center, 0, Vector2(1, 0.13))
				draw_circle(Vector2.ZERO, 37, Color("#523421", 0.18), true, -1, true)
				draw_circle(Vector2.ZERO, 32, Color("#523421", 0.14), true, -1, true)


func setup(app: Control) -> void:
	_app = app
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for product in PRODUCT_IDS:
		var path := "res://assets/art/products/%s.png" % product
		var texture := load(path) as Texture2D
		var pixels := texture.get_image()
		_textures.append(texture)
		_feet.append(float(pixels.get_used_rect().end.y) / pixels.get_height())

	var background := ColorRect.new()
	background.color = CREAM
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_artboard = _layer(self)
	_build_header()
	_build_cabinet()
	_build_tray()
	resized.connect(_place_layout)
	_place_layout()
	_reset()


func _build_header() -> void:
	_panel(_artboard, Rect2(0, 0, 540, 77), WHITE, 0)
	_panel(_artboard, Rect2(24, 76, 492, 1), Color("#E9DDCF"), 0)

	_back_button = _button(_artboard, Rect2(24, 21, 52, 44), WHITE, INK, Color("#D9D0C6"))
	_back_button.accessibility_name = "Wróć do menu"
	_glyph("back", _back_button, Rect2(0, 0, 52, 44))
	_back_button.pressed.connect(func() -> void: _app.call("show_home"))

	_panel(_artboard, Rect2(225, 27, 90, 31), Color("#E0F3ED"), 15)
	_label(_artboard, "POZIOM 1", Rect2(225, 27, 90, 31), 14, DARK_MINT, HORIZONTAL_ALIGNMENT_CENTER)

	_panel(_artboard, Rect2(408, 21, 108, 44), Color("#FBEAC9"), 22, Color("#EBD5AA"), 1)
	_glyph("coin", _artboard, Rect2(418, 21, 30, 44))
	_coin_count = _label(_artboard, "", Rect2(449, 21, 57, 44), 19, INK_DARK)

	_heading = _layer(_artboard)
	var title := _label(_heading, "Przytulny regał", Rect2(24, 93, 492, 49), 41, INK_DARK)
	title.add_theme_font_override("font", DISPLAY_FONT)
	_label(_heading, "Dotknij produktów i zbierz trójki.", Rect2(27, 147, 486, 28), 20, MUTED)
	_summary = _label(_heading, "", Rect2(27, 181, 486, 21), 15, DARK_MINT)
	_panel(_heading, Rect2(27, 207, 486, 6), Color("#E8E1D3"), 3)
	_progress_fill = _panel(_heading, Rect2(27, 207, 0, 6), Color("#63AB98"), 3)


func _build_cabinet() -> void:
	_shelf = _layer(_artboard)
	_shelf.position.x = 24
	_cabinet = _texture(_shelf, Rect2(0, 0, 492, 474))
	_cabinet.texture = CABINET_ART
	_cabinet.stretch_mode = TextureRect.STRETCH_SCALE
	var feather := Shader.new()
	feather.code = """
		shader_type canvas_item;
		void fragment() {
			vec2 distance = min(UV, vec2(1.0) - UV);
			COLOR.a *= smoothstep(0.0, 0.008, min(distance.x, distance.y));
		}
	"""
	var frame_material := ShaderMaterial.new()
	frame_material.shader = feather
	_cabinet.material = frame_material

	for index in range(PRODUCT_IDS.size()):
		var x := 29.0 + (index % 4) * 109
		_stock_shadows.append(_glyph("shadow", _shelf, Rect2(x + 14, 0, 80, 12)))
		var picture := _texture(_shelf, Rect2(Vector2(x + 2, 0), PRODUCT_SIZE))
		_product_icons.append(picture)

		var hit := _button(_shelf, Rect2(x, 0, 108, 117), Color.TRANSPARENT, INK, Color.TRANSPARENT)
		hit.add_theme_stylebox_override("hover", _style(Color(1, 1, 1, 0.13), 13))
		hit.add_theme_stylebox_override("pressed", _style(Color(0.14, 0.34, 0.25, 0.17), 13))
		_product_buttons.append(hit)
		hit.pressed.connect(_take_product.bind(index))

		var badge := _label(_shelf, "", Rect2(x + 81, 0, 22, 21), 13, INK_DARK,
			HORIZONTAL_ALIGNMENT_CENTER)
		badge.add_theme_stylebox_override("normal", _style(WHITE, 10, Color("#D5C9AD"), 1))
		_stock_badges.append(badge)


func _place_layout() -> void:
	var extra := maxf(0.0, size.y - BOARD_SIZE.y)
	_artboard.position.x = (size.x - BOARD_SIZE.x) * 0.5
	_heading.position.y = extra * 0.09
	_shelf.position.y = 227 + extra * 0.18
	_cabinet.size.y = 474 + extra * 0.57
	_tray_panel.position.y = 719 + extra * 0.86
	_actions.position.y = 891 + extra * 0.97
	for index in range(_stocks.size()):
		_place_stock(index)


func _place_stock(index: int) -> void:
	var row := floori(float(index) / 4.0)
	var landing := _cabinet.size.y * float(LANDING_FRACTIONS[row])
	_stock_shadows[index].position.y = landing - 11
	_stock_badges[index].position.y = landing - 24
	_product_buttons[index].position.y = landing - 108
	if not _stocks[index].is_empty():
		var product: int = _stocks[index][0]
		_product_icons[index].position.y = landing - 4 - PRODUCT_SIZE.y * _feet[product]


func _build_tray() -> void:
	_tray_panel = _layer(_artboard)
	_panel(_tray_panel, Rect2(24, 0, 492, 153), WHITE, 25, Color("#EBDBCD"), 1, 8)
	var title := _label(_tray_panel, "Tacka", Rect2(43, 11, 240, 31), 25, INK_DARK)
	title.add_theme_font_override("font", DISPLAY_FONT)
	_tray_count = _label(_tray_panel, "", Rect2(397, 14, 99, 27), 17, DARK_MINT,
		HORIZONTAL_ALIGNMENT_RIGHT)

	for index in range(TRAY_SIZE):
		var slot := Rect2(42 + index * 66.0, 48, 60, 60)
		_panel(_tray_panel, slot, Color("#DDD0BE"), 13)
		_panel(_tray_panel, Rect2(slot.position + Vector2(2, 3), slot.size - Vector2(4, 5)),
			Color("#F3EADF"), 11, Color("#EADBCB"), 1)
		_tray_icons.append(_texture(_tray_panel, Rect2(slot.position + Vector2(3, 3), Vector2(54, 54))))

	_hint = _label(_tray_panel, "", Rect2(42, 116, 456, 25), 16, MUTED)
	_actions = _layer(_artboard)
	_undo_button = _action("Cofnij", "undo", 24, 152, Color("#F5ECE1"), INK)
	_reset_button = _action("Od nowa", "reset", 194, 152, Color("#F5ECE1"), INK)
	_store_button = _action("Sklep", "bag", 364, 152, Color("#D5EDE2"), DARK_MINT)
	_undo_button.pressed.connect(_undo)
	_reset_button.pressed.connect(_reset)
	_store_button.pressed.connect(func() -> void: _app.call("show_store"))


func _action(caption: String, symbol: String, x: float, width: float, fill: Color,
		ink: Color) -> Button:
	var action := _button(_actions, Rect2(x, 0, width, 48), fill, ink, fill.darkened(0.09))
	var glyph := _glyph(symbol, action, Rect2(13, 0, 27, 45), ink)
	var label := _label(action, caption, Rect2(45, 0, width - 46, 45), 17, ink)
	action.accessibility_name = caption
	action.draw.connect(func() -> void:
		var opacity := 0.47 if action.disabled else 1.0
		glyph.modulate.a = opacity
		label.modulate.a = opacity
	)
	return action


func _reset() -> void:
	if _busy:
		return
	_stocks.clear()
	for index in range(PRODUCT_IDS.size()):
		# Adjacent stocks interleave. Clearing a pair yields three of each kind.
		_stocks.append([index, index ^ 1, index])
	_tray.clear()
	_previous.clear()
	_matched = 0
	_round_reward = 0
	_sync()


func _undo() -> void:
	if _busy or _previous.is_empty() or _matched == PRODUCT_IDS.size():
		return
	_stocks = _previous["stocks"]
	_tray = _previous["tray"]
	_matched = _previous["matched"]
	_previous.clear()
	_sync()


func _take_product(index: int) -> void:
	if _busy or _stocks[index].is_empty() or _tray.size() == TRAY_SIZE:
		return

	_previous = {"stocks": _stocks.duplicate(true), "tray": _tray.duplicate(), "matched": _matched}
	var product: int = _stocks[index].pop_front()
	var source := _product_icons[index]
	var target := _tray_icons[_tray.size()]
	var flying := _texture(_artboard, Rect2(source.global_position - _artboard.global_position, source.size))
	_show_product(flying, product)
	flying.z_index = 5
	_busy = true
	_sync()

	var travel := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	travel.tween_property(flying, "position", target.global_position - _artboard.global_position, 0.25)
	travel.tween_property(flying, "size", target.size, 0.25)
	await travel.finished
	flying.queue_free()

	_tray.append(product)
	_sync_tray()
	if _tray.count(product) == 3:
		await _collect_match(product)
	_busy = false
	_sync()
	if _matched == PRODUCT_IDS.size() and not _rewarded:
		_rewarded = true
		_round_reward = REWARD
		_app.call("add_coins", REWARD)
		_sync()


func _collect_match(product: int) -> void:
	var disappear := create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	for index in range(_tray.size()):
		if _tray[index] == product:
			var picture := _tray_icons[index]
			picture.pivot_offset = picture.size / 2
			disappear.tween_property(picture, "scale", Vector2(0.55, 0.55), 0.23)
			disappear.tween_property(picture, "modulate:a", 0.0, 0.23)
	await disappear.finished
	for count in range(3):
		_tray.erase(product)
	_matched += 1


func _sync() -> void:
	var tray_full := _tray.size() == TRAY_SIZE
	var complete := _matched == PRODUCT_IDS.size()
	for index in range(_stocks.size()):
		var stock := _stocks[index]
		var available := not stock.is_empty()
		_product_buttons[index].visible = available
		_product_buttons[index].disabled = _busy or tray_full
		_stock_shadows[index].visible = available
		_stock_badges[index].visible = stock.size() > 1
		_stock_badges[index].text = str(stock.size())
		_show_product(_product_icons[index], stock[0] if available else -1)
		if available:
			_product_buttons[index].accessibility_name = PRODUCT_NAMES[stock[0]]
		_place_stock(index)

	_sync_tray()
	_coin_count.text = str(_app.get("coins"))
	_summary.text = "%d / %d kompletów" % [_matched, PRODUCT_IDS.size()]
	_progress_fill.visible = _matched > 0
	_progress_fill.size.x = 486.0 * _matched / PRODUCT_IDS.size()
	_undo_button.disabled = _busy or complete or _previous.is_empty()
	_back_button.disabled = _busy
	_reset_button.disabled = _busy
	_store_button.disabled = _busy

	_hint.add_theme_color_override("font_color", MUTED)
	if complete:
		_hint.text = "Regał uporządkowany!"
		if _round_reward > 0:
			_hint.text += "  +%d monet" % _round_reward
		_hint.add_theme_color_override("font_color", DARK_MINT)
	elif tray_full:
		_hint.text = "Pełna tacka. Cofnij ruch lub zacznij od nowa."
		_hint.add_theme_color_override("font_color", PLUM)
	else:
		_hint.text = "Kolejne produkty czekają w głębi półek."


func _sync_tray() -> void:
	_tray_count.text = "%d / %d" % [_tray.size(), TRAY_SIZE]
	for index in range(TRAY_SIZE):
		var picture := _tray_icons[index]
		picture.scale = Vector2.ONE
		picture.modulate = Color.WHITE
		_show_product(picture, _tray[index] if index < _tray.size() else -1)


func _show_product(picture: TextureRect, product: int) -> void:
	picture.visible = product >= 0
	picture.texture = _textures[product] if product >= 0 else null


func _style(fill: Color, radius: int, stroke: Color = Color.TRANSPARENT,
		border: int = 0, shadow: int = 0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_corner_radius_all(radius)
	box.border_color = stroke
	box.set_border_width_all(border)
	box.shadow_color = Color(0.19, 0.22, 0.20, 0.21)
	box.shadow_size = shadow
	box.shadow_offset = Vector2(0, 3) if shadow > 0 else Vector2.ZERO
	return box


func _layer(parent: Control) -> Control:
	var node := Control.new()
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node


func _panel(parent: Control, rect: Rect2, fill: Color, radius: int, stroke: Color = Color.TRANSPARENT,
		border: int = 0, shadow: int = 0) -> Panel:
	var node := Panel.new()
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_theme_stylebox_override("panel", _style(fill, radius, stroke, border, shadow))
	parent.add_child(node)
	node.position = rect.position
	node.size = rect.size
	return node


func _label(parent: Control, caption: String, rect: Rect2, font_size: int, ink: Color,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var node := Label.new()
	node.text = caption
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", ink)
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.horizontal_alignment = align
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	node.position = rect.position
	node.size = rect.size
	return node


func _button(parent: Control, rect: Rect2, fill: Color, ink: Color, stroke: Color) -> Button:
	var node := Button.new()
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.add_theme_stylebox_override("normal", _style(fill, 17, stroke, 1))
	node.add_theme_stylebox_override("hover", _style(fill.lightened(0.1), 17, stroke, 1))
	node.add_theme_stylebox_override("pressed", _style(fill.darkened(0.1), 17, stroke, 1))
	node.add_theme_stylebox_override("disabled", _style(fill.darkened(0.04), 17, stroke, 1))
	var focus := _style(Color.TRANSPARENT, 17, ink, 2)
	focus.draw_center = false
	node.add_theme_stylebox_override("focus", focus)
	parent.add_child(node)
	node.position = rect.position
	node.size = rect.size
	return node


func _glyph(symbol: String, parent: Control, rect: Rect2, ink: Color = INK) -> Glyph:
	var node := Glyph.new()
	node.symbol = symbol
	node.ink = ink
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	node.position = rect.position
	node.size = rect.size
	return node


func _texture(parent: Control, rect: Rect2) -> TextureRect:
	var picture := TextureRect.new()
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(picture)
	picture.position = rect.position
	picture.size = rect.size
	return picture
