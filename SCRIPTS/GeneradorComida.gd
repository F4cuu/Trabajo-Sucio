extends Node2D

# Gemelo de GeneradorBasura.gd pero para COMIDA.
# Mantiene siempre 1 comida disponible: si la actual se recoge/lanza, spawnea otra.

@export var escena_comida: PackedScene = preload("res://scenes/Comida.tscn")
@export var offset_spawn: Vector2 = Vector2(60, 0)
@export var grupo_objetivo: String = "ventana1"

var _comida_actual: Node = null

@onready var timer: Timer = $Timer

func _ready() -> void:
	_spawnear_si_necesario.call_deferred()
	timer.start()

func _on_timer_timeout() -> void:
	_spawnear_si_necesario()

func _spawnear_si_necesario() -> void:
	if is_instance_valid(_comida_actual) and _comida_actual.is_inside_tree():
		return
	var c = escena_comida.instantiate()
	c.grupo_objetivo = grupo_objetivo
	get_parent().add_child(c)
	c.global_position = global_position + offset_spawn
	_comida_actual = c
