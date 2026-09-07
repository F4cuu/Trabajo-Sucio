extends Node2D

@export var spawners: Array[NodePath] = []
@export var intervalo: float = 3.0

@onready var timer: Timer = $Timer

var ultimo_indice: int = -1

func _ready() -> void:
	timer.wait_time = intervalo
	timer.start()

func _on_timer_timeout() -> void:
	if spawners.is_empty():
		return
	var candidatos: Array[int] = []
	for i in spawners.size():
		if i != ultimo_indice:
			candidatos.append(i)
	if candidatos.is_empty():
		candidatos.append(ultimo_indice)
	var elegido = candidatos.pick_random()
	ultimo_indice = elegido
	var spawner = get_node_or_null(spawners[elegido])
	if spawner and spawner.has_method("_spawnear"):
		spawner._spawnear()
	elif spawner and spawner.has_method("spawnear"):
		spawner.spawnear()
