extends Node2D

## Spawner de autos: un solo carril (ancho chico) y una sola dirección.
## Intervalo aleatorio entre pasadas (por defecto 5 a 15 segundos).

@export var escena_vehiculo: PackedScene = preload("res://scenes/Vehiculo.tscn")
@export var direccion: int = 1
@export var velocidad: float = 450.0
@export var intervalo_min: float = 5.0
@export var intervalo_max: float = 15.0
@export var ancho_carril: float = 20.0
@export var ignorar_superior: bool = false
@export var ignorar_inferior: bool = false

@onready var timer: Timer = $Timer


func _ready() -> void:
	_reprogramar()


func _reprogramar() -> void:
	timer.wait_time = randf_range(intervalo_min, intervalo_max)
	timer.start()


func _on_timer_timeout() -> void:
	_spawnear()
	_reprogramar()


func _spawnear() -> void:
	var c = escena_vehiculo.instantiate()
	var offset_x = randf_range(-ancho_carril * 0.5, ancho_carril * 0.5)
	get_parent().add_child(c)
	c.global_position = global_position + Vector2(offset_x, 0)
	if "velocidad" in c:
		c.set("velocidad", velocidad)
	if c.has_method("configurar_direccion"):
		c.configurar_direccion(direccion)
	if ignorar_superior:
		var sup = get_parent().get_node_or_null("ParedSuperior")
		if sup:
			c.add_collision_exception_with(sup)
	if ignorar_inferior:
		var inf = get_parent().get_node_or_null("ParedInferior")
		if inf:
			c.add_collision_exception_with(inf)
