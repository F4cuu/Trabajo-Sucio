extends Node2D

## Fuente de comida (horno, heladera, freidora, horno pizzero).
## Genera su ítem característico SOLO cuando un jugador con manos vacías
## presiona su botón de recoger cerca. Máximo un ítem activo por fuente:
## si el anterior sigue en juego (en mano, en piso o volando), no genera otro.

@export var tipo_comida: String = "generica"
@export var escena_comida: PackedScene = null
@export var radio_interaccion: float = 110.0
@export var offset_salida: Vector2 = Vector2(40, 0)

var _item_activo: Node = null


func _ready() -> void:
	add_to_group("fuente_comida")


## Llamado por el jugador al presionar recoger con manos vacías.
## Devuelve el ítem generado listo para sostener, o null si no corresponde.
func solicitar_comida() -> Node:
	if is_instance_valid(_item_activo) and _item_activo.is_inside_tree():
		return null # ya hay uno de este horno en juego
	if escena_comida == null:
		return null
	var item = escena_comida.instantiate()
	get_parent().add_child(item)
	item.global_position = global_position + offset_salida
	_item_activo = item
	return item
