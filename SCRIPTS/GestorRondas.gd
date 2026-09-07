extends Node

@export var duracion_ronda: int = 60
@export var total_rondas: int = 3

var ronda_actual: int = 1
var tiempo_restante: int = 60
var en_curso: bool = true
var racha_p1: int = 0
var racha_p2: int = 0
var _pos_inicial_p1: Vector2
var _pos_inicial_p2: Vector2
var _tiene_pos_p1: bool = false
var _tiene_pos_p2: bool = false

@onready var label_ronda: Label = get_node_or_null("../RondaUI/LabelRonda") as Label
@onready var label_tiempo: Label = get_node_or_null("../RondaUI/LabelTiempo") as Label
@onready var timer: Timer = $Timer

func _ready() -> void:
	tiempo_restante = duracion_ronda
	_actualizar_ui()
	timer.wait_time = 1.0
	timer.start()
	# Guardar posiciones iniciales de los jugadores para reset entre rondas
	_guardar_posiciones_iniciales.call_deferred()


func _guardar_posiciones_iniciales() -> void:
	var p1 = get_node_or_null("../PJ1")
	if p1:
		_pos_inicial_p1 = p1.global_position
		_tiene_pos_p1 = true
	var p2 = get_node_or_null("../PJ2")
	if p2:
		_pos_inicial_p2 = p2.global_position
		_tiene_pos_p2 = true

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
	_limpiar_npcs_y_resetear_jugadores()
	_actualizar_ui()

func _limpiar_npcs_y_resetear_jugadores() -> void:
	# 1) Resetear ventanas a estado limpio
	_resetear_ventanas()
	# 2) Eliminar NPCs sueltos (grupo "cliente")
	for c in get_tree().get_nodes_in_group("cliente"):
		if is_instance_valid(c):
			c.queue_free()
	# 3) Eliminar basura suelta/proyectiles (grupo "basura")
	# Si la basura está siendo sostenida (hija de un jugador), limpiamos la referencia del jugador primero
	for b in get_tree().get_nodes_in_group("basura"):
		if not is_instance_valid(b):
			continue
		var parent = b.get_parent()
		if parent and ("basura_sostenida" in parent) and parent.get("basura_sostenida") == b:
			parent.set("basura_sostenida", null)
		b.queue_free()
	# 4) Resetear jugadores a posición inicial
	var p1 = get_node_or_null("../PJ1")
	if p1 and _tiene_pos_p1:
		p1.global_position = _pos_inicial_p1
		if "velocity" in p1:
			p1.velocity = Vector2.ZERO
		if "esta_revoleando" in p1:
			p1.esta_revoleando = false
		if "_revolear_tiempo" in p1:
			p1.set("_revolear_tiempo", 0.0)
		if "basura_sostenida" in p1 and p1.get("basura_sostenida") != null:
			var b = p1.get("basura_sostenida")
			if is_instance_valid(b):
				b.queue_free()
			p1.set("basura_sostenida", null)
	var p2 = get_node_or_null("../PJ2")
	if p2 and _tiene_pos_p2:
		p2.global_position = _pos_inicial_p2
		if "velocity" in p2:
			p2.velocity = Vector2.ZERO
		if "esta_revoleando" in p2:
			p2.esta_revoleando = false
		if "basura_sostenida" in p2 and p2.get("basura_sostenida") != null:
			var b2 = p2.get("basura_sostenida")
			if is_instance_valid(b2):
				b2.queue_free()
			p2.set("basura_sostenida", null)


func _resetear_ventanas() -> void:
	var tex_limpio = load("res://SPRITES/el_vidrio.png")
	for grupo in ["ventana1", "ventana2"]:
		for ventana in get_tree().get_nodes_in_group(grupo):
			if not is_instance_valid(ventana):
				continue
			# Si tiene script Ventana.gd, forzar estado limpio
			if ventana.has_method("limpiar"):
				# limpiar() chequea esta_sucia, pero Basura.gd ensucia sin usar el flag
				# forzamos flag y actualizamos
				if "esta_sucia" in ventana:
					ventana.set("esta_sucia", false)
				if ventana.has_method("_actualizar_visual"):
					ventana._actualizar_visual()
				else:
					ventana.limpiar()
			elif "esta_sucia" in ventana:
				ventana.set("esta_sucia", false)
			# Fallback manual por si no hay script o el flag quedó desincronizado (Basura.gd escribe textura directo)
			var visual = ventana.get_node_or_null("Visual")
			if visual == null:
				continue
			if visual is TextureRect:
				if tex_limpio:
					visual.texture = tex_limpio
				visual.modulate = Color(1, 1, 1, 1)
			elif visual is ColorRect:
				visual.modulate = Color(1, 1, 1, 1)


func _actualizar_ui() -> void:
	if label_ronda:
		label_ronda.text = "RONDA: " + str(ronda_actual)
	if label_tiempo:
		var m = tiempo_restante / 60
		var s = tiempo_restante % 60
		label_tiempo.text = "%02d:%02d" % [m, s]
