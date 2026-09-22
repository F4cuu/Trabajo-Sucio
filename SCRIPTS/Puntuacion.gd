extends Node2D

const FORMATO := "P1:%d"

var puntos := 0

@onready var label: Label = $Label


func _ready() -> void:
	z_index = 100
	z_as_relative = false
	_actualizar()


func agregar_puntos(cantidad: int, pos_mundo: Vector2 = Vector2.INF) -> void:
	puntos = maxi(0, puntos + cantidad)
	_actualizar()
	_mostrar_flotante(cantidad, pos_mundo)


func _mostrar_flotante(cantidad: int, pos_mundo: Vector2) -> void:
	if cantidad == 0:
		return
	# Siempre arriba del personaje que consiguió los puntos (P1).
	var pos := pos_mundo
	var pj := _buscar_jugador()
	if pj != null:
		pos = (pj as Node2D).global_position + Vector2(0, -90)
	elif pos == Vector2.INF:
		pos = global_position
	var escena := get_tree().current_scene
	TextoFlotante.mostrar(escena if escena != null else get_parent(), pos, cantidad)


func _buscar_jugador() -> Node:
	var pj = get_parent().get_node_or_null("PJ1")
	if pj == null:
		pj = get_tree().current_scene.get_node_or_null("PJ1") if get_tree().current_scene != null else null
	return pj


func reiniciar() -> void:
	puntos = 0
	_actualizar()


func _actualizar() -> void:
	label.text = FORMATO % puntos
