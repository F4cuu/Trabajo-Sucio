extends Control

@onready var panel: Panel = $OpcionesPanel
@onready var slider_musica: HSlider = $OpcionesPanel/VBox/MusicaBox/SliderMusica
@onready var slider_efectos: HSlider = $OpcionesPanel/VBox/EfectosBox/SliderEfectos

const SAVE_PATH := "user://settings.cfg"

func _ready() -> void:
	# Si se vino del podio con la cortina cerrada, abrirla (sin cortina no hace nada)
	TransicionCortina.abrir(get_tree(), 0.7)
	_agregar_boton_b_a_aceptar()
	_cargar_volumenes()
	slider_musica.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")))
	slider_efectos.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))
	panel.visible = false

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

func _on_jugar_pressed() -> void:
	await TransicionCortina.cerrar(get_tree(), 1.0)
	get_tree().change_scene_to_file("res://scenes/trabajo_sucio.tscn")

func _on_opciones_pressed() -> void:
	panel.visible = true
	$Botones.visible = false
	($OpcionesPanel/VBox/MusicaBox/BtnMusicaMenos as Button).grab_focus()


# Mando en el menú: el joystick (y la cruceta) ya mueven el foco por las
# acciones ui_* por defecto; acá se suma el botón B (este) como seleccionar.
func _agregar_boton_b_a_aceptar() -> void:
	for e in InputMap.action_get_events("ui_accept"):
		if e is InputEventJoypadButton and (e as InputEventJoypadButton).button_index == JOY_BUTTON_B:
			($Botones/Jugar as Button).grab_focus()
			return
	var ev := InputEventJoypadButton.new()
	ev.button_index = JOY_BUTTON_B
	InputMap.action_add_event("ui_accept", ev)
	($Botones/Jugar as Button).grab_focus()


func _on_salir_pressed() -> void:
	get_tree().quit()

func _on_volver() -> void:
	panel.visible = false
	$Botones.visible = true
	($Botones/Jugar as Button).grab_focus()

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
