extends Node2D

const FORMATO := "P2:%d"

var puntos := 0

@onready var label: Label = $Label


func _ready() -> void:
	_actualizar()


func agregar_puntos(cantidad: int) -> void:
	puntos += cantidad
	_actualizar()


func reiniciar() -> void:
	puntos = 0
	_actualizar()


func _actualizar() -> void:
	label.text = FORMATO % puntos
