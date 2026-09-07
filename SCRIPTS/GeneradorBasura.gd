extends Node2D

@export var escena_basura: PackedScene = preload("res://scenes/Basura.tscn")
@export var offset_spawn: Vector2 = Vector2(60, 0)
@export var grupo_objetivo: String = "ventana1"

var _basura_actual: Node = null

@onready var timer: Timer = $Timer

func _ready() -> void:
	_spawnear_si_necesario.call_deferred()
	timer.start()

func _on_timer_timeout() -> void:
	_spawnear_si_necesario()

func _spawnear_si_necesario() -> void:
	if is_instance_valid(_basura_actual) and _basura_actual.is_inside_tree():
		return
	var b = escena_basura.instantiate()
	b.grupo_objetivo = grupo_objetivo
	get_parent().add_child(b)
	b.global_position = global_position + offset_spawn
	_basura_actual = b
