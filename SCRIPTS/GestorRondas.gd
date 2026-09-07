extends Node

@export var duracion_ronda: int = 60
@export var total_rondas: int = 3

var ronda_actual: int = 1
var tiempo_restante: int = 60
var en_curso: bool = true
var racha_p1: int = 0
var racha_p2: int = 0

@onready var label_ronda: Label = get_node_or_null("../RondaUI/LabelRonda") as Label
@onready var label_tiempo: Label = get_node_or_null("../RondaUI/LabelTiempo") as Label
@onready var timer: Timer = $Timer

func _ready() -> void:
	tiempo_restante = duracion_ronda
	_actualizar_ui()
	timer.wait_time = 1.0
	timer.start()

func _on_timer_timeout() -> void:
	if not en_curso:
		return
	tiempo_restante -= 1
	if tiempo_restante <= 0:
		_finalizar_ronda()
	else:
		_actualizar_ui()

func _finalizar_ronda() -> void:
	var p1 = 0
	var p2 = 0
	var n1 = get_node_or_null("../Puntuacion")
	if n1 and "puntos" in n1:
		p1 = n1.puntos
	var n2 = get_node_or_null("../PuntuacionPJ2")
	if n2 and "puntos" in n2:
		p2 = n2.puntos
	var ganador = "EMPATE"
	if p1 > p2:
		ganador = "Gana P1"
		racha_p1 += 1
		racha_p2 = 0
	elif p2 > p1:
		ganador = "Gana P2"
		racha_p2 += 1
		racha_p1 = 0
	else:
		racha_p1 = 0
		racha_p2 = 0
	print("Ronda ", ronda_actual, " terminada - ", ganador, " (P1:", p1, " P2:", p2, ") - Rachas P1:", racha_p1, " P2:", racha_p2)
	if label_tiempo:
		label_tiempo.text = "00:00 - " + ganador
	if racha_p1 >= 2 or racha_p2 >= 2:
		en_curso = false
		timer.stop()
		var global_ganador = "P1" if racha_p1 >= 2 else "P2"
		if label_ronda:
			label_ronda.text = "RONDA: " + str(ronda_actual) + " - GANA " + global_ganador + " (2 seguidas)"
		print("Gana ", global_ganador, " por 2 seguidas - volviendo al menu en 5s")
		await get_tree().create_timer(5.0).timeout
		get_tree().change_scene_to_file("res://scenes/MenuPrincipal.tscn")
		return
	if ronda_actual >= total_rondas:
		en_curso = false
		timer.stop()
		if label_ronda:
			label_ronda.text = "RONDA: " + str(ronda_actual) + " - FIN"
		print("Partida terminada a 3 rondas")
		await get_tree().create_timer(5.0).timeout
		get_tree().change_scene_to_file("res://scenes/MenuPrincipal.tscn")
		return
	ronda_actual += 1
	tiempo_restante = duracion_ronda
	if n1 and n1.has_method("reiniciar"):
		n1.reiniciar()
	if n2 and n2.has_method("reiniciar"):
		n2.reiniciar()
	_actualizar_ui()

func _actualizar_ui() -> void:
	if label_ronda:
		label_ronda.text = "RONDA: " + str(ronda_actual)
	if label_tiempo:
		var m = tiempo_restante / 60
		var s = tiempo_restante % 60
		label_tiempo.text = "%02d:%02d" % [m, s]
