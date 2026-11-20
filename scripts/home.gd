extends Control

const CANVAS := Vector2(540, 960)
const INK := Color("#35455f")
const PAPER := Color("#fffdf6")
const MINT := Color("#9fe4d4")
const SHOPFRONT_PATH := "res://assets/art/shopfront.webp"
const DISPLAY_PATH := "res://assets/fonts/display.ttf"

var _content: Control
var _hero_material: ShaderMaterial
var _wordmark: Control
var _actions: Control
var _display_font: Font


class Mark extends Control:
	var kind: String

	func _draw() -> void:
		var center := size * 0.5
		match kind:
			"coin":
				draw_circle(center + Vector2(0, 2), 17.0, Color("#c98433"), true, -1, true)
				draw_circle(center, 17.0, Color("#ffd26d"), true, -1, true)
				draw_arc(center, 12.4, 0, TAU, 40, Color("#dca34d"), 1.5, true)
				_star(center, 8.6, Color("#a85e30"))
			"bag":
				var outline := PackedVector2Array([
					center + Vector2(-11, -5), center + Vector2(11, -5),
					center + Vector2(13, 11), center + Vector2(10, 14),
					center + Vector2(-10, 14), center + Vector2(-13, 11),
					center + Vector2(-11, -5)
				])
				draw_colored_polygon(outline, Color("#c6b8f4"))
				draw_polyline(outline, INK, 2.3, true)
				draw_arc(center + Vector2(0, -5), 5.4, PI, TAU, 18, INK, 2.3, true)
			"play":
				draw_circle(center, 19, Color("#ffffff", 0.48), true, -1, true)
				draw_colored_polygon(PackedVector2Array([
					center + Vector2(-4, -7), center + Vector2(7, 0),
					center + Vector2(-4, 7)
				]), Color("#235b58"))
			"sparkle":
				_star(center, minf(size.x, size.y) * 0.43, Color("#b47749"))
			"rule":
				draw_line(Vector2(0, center.y), Vector2(size.x, center.y), Color("#a46b56", 0.4), 1.3, true)

	func _star(center: Vector2, radius: float, color: Color) -> void:
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(0, -radius), center + Vector2(radius * 0.24, -radius * 0.22),
			center + Vector2(radius, 0), center + Vector2(radius * 0.24, radius * 0.22),
			center + Vector2(0, radius), center + Vector2(-radius * 0.24, radius * 0.22),
			center + Vector2(-radius, 0), center + Vector2(-radius * 0.24, -radius * 0.22)
		]), color)


func setup(app: Control) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if ResourceLoader.exists(DISPLAY_PATH):
		_display_font = load(DISPLAY_PATH) as Font
	_add_backdrop()
	_content = Control.new()
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.size = CANVAS
	add_child(_content)
	_add_top_bar(app)
	_add_wordmark()
	_add_actions(app)
	resized.connect(_place_content)
	_place_content()
	_animate_entrance()


func _place_content() -> void:
	var extra_height := maxf(0.0, size.y - CANVAS.y)
	_content.position.x = (size.x - CANVAS.x) * 0.5
	_content.size.y = maxf(CANVAS.y, size.y)
	_wordmark.position.y = 121.0 + extra_height * 0.36
	_actions.position.y = 760.0 + extra_height * 0.75
	if _hero_material:
		_hero_material.set_shader_parameter("view_height", size.y)
		_hero_material.set_shader_parameter("image_top", 95.0 + extra_height * 0.56)


func _add_backdrop() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("#f5e2cf")
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if ResourceLoader.exists(SHOPFRONT_PATH):
		var hero := TextureRect.new()
		hero.texture = load(SHOPFRONT_PATH) as Texture2D
		hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hero.stretch_mode = TextureRect.STRETCH_SCALE
		# Blend the artwork into its studio backdrop to keep the full storefront in view.
		var shader := Shader.new()
		shader.code = """
			shader_type canvas_item;
			uniform float view_height = 960.0;
			uniform float image_top = 95.0;
			varying vec4 tint;
			void vertex() {
				tint = COLOR;
			}
			void fragment() {
				float image_height = 540.0 * TEXTURE_PIXEL_SIZE.x / TEXTURE_PIXEL_SIZE.y;
				float image_y = (UV.y * view_height - image_top) / image_height;
				vec4 photo = texture(TEXTURE, vec2(UV.x, clamp(image_y, 0.0, 1.0)));
				vec4 top_color = texture(TEXTURE, vec2(0.5, 0.004));
				vec4 bottom_color = texture(TEXTURE, vec2(0.5, 0.996));
				photo = mix(top_color, photo, smoothstep(-0.06, 0.04, image_y));
				photo = mix(photo, bottom_color, smoothstep(0.96, 1.06, image_y));
				COLOR = photo * tint;
			}
		"""
		_hero_material = ShaderMaterial.new()
		_hero_material.shader = shader
		hero.material = _hero_material
		hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(hero)
		hero.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _add_top_bar(app: Control) -> void:
	var wallet := Panel.new()
	wallet.add_theme_stylebox_override("panel", _surface(Color("#fffdf6", 0.95), 26, Color("#fff7ec"), 2, 4))
	wallet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(_content, wallet, Rect2(30, 29, 119, 54))
	_mark(wallet, "coin", Rect2(6, 7, 40, 40))
	_label(wallet, str(app.coins), 23, INK, Rect2(49, 0, 57, 54))

	var shop := _button("Sklep", 20, INK, PAPER, Color("#e6d2d1"), 26)
	_place(_content, shop, Rect2(384, 29, 126, 54))
	_label(shop, "Sklep", 20, INK, Rect2(48, 0, 64, 52))
	_mark(shop, "bag", Rect2(9, 8, 37, 37))
	shop.pressed.connect(app.show_store)


func _add_wordmark() -> void:
	_wordmark = Control.new()
	_wordmark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(_content, _wordmark, Rect2(23, 121, 494, 164))
	var title := _label(_wordmark, "TINY SHOP", 78, INK, Rect2(0, 6, 494, 104))
	if _display_font:
		title.add_theme_font_override("font", _display_font)
	title.add_theme_color_override("font_shadow_color", Color("#fff7ec", 0.8))
	title.add_theme_constant_override("shadow_offset_y", 3)
	_mark(_wordmark, "rule", Rect2(112, 128, 24, 10))
	_mark(_wordmark, "rule", Rect2(358, 128, 24, 10))
	_label(_wordmark, "S O R T  &  R E S T O R E", 17, INK, Rect2(143, 110, 208, 45))
	_mark(_wordmark, "sparkle", Rect2(53, 13, 19, 19))
	_mark(_wordmark, "sparkle", Rect2(422, 87, 16, 16))


func _add_actions(app: Control) -> void:
	_actions = Control.new()
	_actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(_content, _actions, Rect2(48, 760, 444, 155))
	var level := Panel.new()
	level.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level.add_theme_stylebox_override("panel", _surface(Color("#fffdf6", 0.96), 21, Color("#f4dcbb"), 1, 4))
	_place(_actions, level, Rect2(151, 0, 142, 37))
	_label(level, "POZIOM 1", 15, INK, Rect2(16, 0, 110, 36))

	var play := _button("Zagraj", 27, Color("#174f4d"), MINT, Color("#488c80"), 31)
	_place(_actions, play, Rect2(28, 48, 388, 78))
	_label(play, "Zagraj", 27, Color("#174f4d"), Rect2(105, 0, 178, 75))
	_mark(play, "play", Rect2(323, 17, 43, 43))
	play.pressed.connect(app.show_game)


func _animate_entrance() -> void:
	_wordmark.modulate.a = 0.0
	_wordmark.pivot_offset = _wordmark.size * 0.5
	_wordmark.scale = Vector2.ONE * 0.97
	_actions.modulate.a = 0.0
	_actions.pivot_offset = _actions.size * 0.5
	_actions.scale = Vector2.ONE * 0.95
	var enter := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	enter.tween_property(_wordmark, "modulate:a", 1.0, 0.30)
	enter.tween_property(_wordmark, "scale", Vector2.ONE, 0.38)
	enter.tween_property(_actions, "modulate:a", 1.0, 0.35).set_delay(0.08)
	enter.tween_property(_actions, "scale", Vector2.ONE, 0.42).set_delay(0.08)


func _button(accessible_text: String, font_size: int, text_color: Color, fill: Color, base: Color, radius: int) -> Button:
	var button := Button.new()
	button.text = accessible_text
	button.tooltip_text = ""
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	# The visible text sits in a separate label to make room for the custom icon.
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color", "font_disabled_color"]:
		button.add_theme_color_override(state, Color(text_color, 0))
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_stylebox_override("normal", _surface(fill, radius, base, 1, 6))
	button.add_theme_stylebox_override("hover", _surface(fill.lightened(0.11), radius, base, 1, 6))
	button.add_theme_stylebox_override("pressed", _surface(fill.darkened(0.08), radius, base, 1, 2))
	var focus := _surface(Color.TRANSPARENT, radius, INK, 3, 0)
	focus.draw_center = false
	button.add_theme_stylebox_override("focus", focus)
	button.button_down.connect(func() -> void:
		button.pivot_offset = button.size * 0.5
		button.scale = Vector2(0.98, 0.96)
	)
	button.button_up.connect(func() -> void:
		button.scale = Vector2.ONE
	)
	return button


func _label(parent: Control, value: String, font_size: int, color: Color, rect: Rect2) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	_place(parent, label, rect)
	return label


func _mark(parent: Control, kind: String, rect: Rect2) -> void:
	var mark := Mark.new()
	mark.kind = kind
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(parent, mark, rect)


func _surface(fill: Color, radius: int, edge: Color, border: int, depth: int) -> StyleBoxFlat:
	var surface := StyleBoxFlat.new()
	surface.bg_color = fill
	surface.set_corner_radius_all(radius)
	surface.corner_detail = 12
	surface.set_border_width_all(border)
	surface.border_color = edge
	surface.shadow_color = Color(edge, 0.78)
	surface.shadow_size = depth
	surface.shadow_offset = Vector2(0, depth * 0.68)
	return surface


func _place(parent: Control, node: Control, rect: Rect2) -> void:
	parent.add_child(node)
	node.position = rect.position
	node.size = rect.size
