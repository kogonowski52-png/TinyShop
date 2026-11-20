extends Control

const HOME := preload("res://scripts/home.gd")
const GAME := preload("res://scripts/gameplay.gd")
const STORE := preload("res://scripts/store.gd")
const BODY := preload("res://assets/fonts/body.ttf")
const INK := Color("#35455f")

var coins: int = 120
var current_screen: Control
var store_screen: Control


func _ready() -> void:
	get_tree().set_quit_on_go_back(false)
	theme = Theme.new()
	theme.default_font = BODY
	theme.default_font_size = 20
	theme.set_color("font_color", "Label", INK)
	theme.set_color("font_color", "Button", INK)
	show_home()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and not _go_back():
		get_tree().quit()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _go_back():
		get_viewport().set_input_as_handled()


func show_home() -> void:
	_show_screen(HOME)


func show_game() -> void:
	_show_screen(GAME)


func show_store() -> void:
	if is_instance_valid(store_screen):
		return
	current_screen.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	store_screen = _mount(STORE)


func close_store() -> void:
	if is_instance_valid(store_screen):
		remove_child(store_screen)
		store_screen.queue_free()
		store_screen = null
		current_screen.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_INHERITED


func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	coins += amount


func _go_back() -> bool:
	if is_instance_valid(store_screen):
		close_store()
		return true
	if is_instance_valid(current_screen) and current_screen.get_script() == GAME:
		show_home()
		return true
	return false


func _show_screen(screen: GDScript) -> void:
	close_store()
	if is_instance_valid(current_screen):
		remove_child(current_screen)
		current_screen.queue_free()
	current_screen = _mount(screen)
	current_screen.modulate.a = 0.0
	current_screen.create_tween().tween_property(current_screen, "modulate:a", 1.0, 0.24)


func _mount(screen: GDScript) -> Control:
	var control: Control = screen.new()
	add_child(control)
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	control.call("setup", self)
	return control
