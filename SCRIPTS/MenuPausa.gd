extends CanvasLayer

@onready var menu: Control = $Menu
@onready var panel_opciones: Panel = $Menu/OpcionesPanel
@onready var botones: VBoxContainer = $Menu/Botones
@onready var slider_musica: HSlider = $Menu/OpcionesPanel/VBox/MusicaBox/SliderMusica
@onready var slider_efectos: HSlider = $Menu/OpcionesPanel/VBox/EfectosBox/SliderEfectos

const SAVE_PATH := "user://settings.cfg"

var pausado := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	menu.visible = false
	panel_opciones.visible = false
	botones.visible = true
	_cargar_volumenes()
	slider_musica.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")))
	slider_efectos.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pausa()
		get_viewport().set_input_as_handled()


func toggle_pausa() -> void:
	if pausado:
		reanudar()
	else:
		pausar()


func pausar() -> void:
	pausado = true
	get_tree().paused = true
	menu.visible = true
	panel_opciones.visible = false
	botones.visible = true


func reanudar() -> void:
	pausado = false
	get_tree().paused = false
	menu.visible = false
	panel_opciones.visible = false
	botones.visible = true


func _on_continuar_pressed() -> void:
	reanudar()


func _on_salir_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()


func _on_menu_principal_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MenuPrincipal.tscn")


func _on_opciones_pressed() -> void:
	panel_opciones.visible = true
	botones.visible = false


func _on_volver_opciones_pressed() -> void:
	panel_opciones.visible = false
	botones.visible = true


func _cargar_volumenes() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		var m = cfg.get_value("audio", "music", 1.0)
		var s = cfg.get_value("audio", "sfx", 1.0)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(clampf(m, 0.001, 1.0)))
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), m <= 0.001)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(clampf(s, 0.001, 1.0)))
		AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), s <= 0.001)


func _guardar_volumenes() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("audio", "music", slider_musica.value)
	cfg.set_value("audio", "sfx", slider_efectos.value)
	cfg.save(SAVE_PATH)


func _on_slider_musica(value: float) -> void:
	var idx = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(value, 0.001, 1.0)))
	AudioServer.set_bus_mute(idx, value <= 0.001)
	_guardar_volumenes()


func _on_slider_efectos(value: float) -> void:
	var idx = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(value, 0.001, 1.0)))
	AudioServer.set_bus_mute(idx, value <= 0.001)
	_guardar_volumenes()


func _on_musica_menos() -> void:
	slider_musica.value = max(0.0, slider_musica.value - 0.05)
	_on_slider_musica(slider_musica.value)


func _on_musica_mas() -> void:
	slider_musica.value = min(1.0, slider_musica.value + 0.05)
	_on_slider_musica(slider_musica.value)


func _on_efectos_menos() -> void:
	slider_efectos.value = max(0.0, slider_efectos.value - 0.05)
	_on_slider_efectos(slider_efectos.value)


func _on_efectos_mas() -> void:
	slider_efectos.value = min(1.0, slider_efectos.value + 0.05)
	_on_slider_efectos(slider_efectos.value)
