extends Node2D

## Tacho de basura: genera SU basura SOLO cuando un jugador con manos vacías
## presiona su botón de recoger cerca (igual que FuenteComida).
## Máximo un ítem activo por tacho: si el anterior sigue en juego
## (en mano, en piso o volando), no genera otro.

@export var escena_basura: PackedScene = preload("res://scenes/Basura.tscn")
@export var offset_spawn: Vector2 = Vector2(60, 0)
@export var grupo_objetivo: String = "ventana1"

var _basura_actual: Node = null


func _ready() -> void:
	add_to_group("fuente_basura")


## Llamado por el jugador al presionar recoger con manos vacías.
## Devuelve la basura generada lista para sostener, o null si no corresponde.
func solicitar_basura() -> Node:
	if is_instance_valid(_basura_actual) and _basura_actual.is_inside_tree():
		return null # ya hay una basura de este tacho en juego
	var b = escena_basura.instantiate()
	b.grupo_objetivo = grupo_objetivo
	get_parent().add_child(b)
	b.global_position = global_position + offset_spawn
	_basura_actual = b
	return b


func _on_timer_timeout() -> void:
	pass # compat: el Timer de la escena quedó sin uso (la basura es a pedido)
