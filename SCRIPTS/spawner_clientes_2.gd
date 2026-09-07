extends Node2D

@export var escena_cliente: PackedScene = preload("res://scenes/cliente.tscn")
@export var ancho_spawneo: float = 120.0
@export var direccion_spawneo: int = +1
@export var intervalo: float = 3.0
@export var ignorar_superior: bool = false
@export var ignorar_inferior: bool = false

@onready var timer: Timer = $Timer

func _ready() -> void:
	pass

func _on_timer_timeout() -> void:
	_spawnear()

func _spawnear() -> void:
	var c = escena_cliente.instantiate()
	var offset_x = randf_range(-ancho_spawneo * 0.5, ancho_spawneo * 0.5)
	get_parent().add_child(c)
	c.global_position = global_position + Vector2(offset_x, 0)
	if c.has_method("configurar_direccion"):
		c.configurar_direccion(direccion_spawneo)
	if ignorar_superior:
		var sup = get_parent().get_node_or_null("ParedSuperior")
		if sup:
			c.add_collision_exception_with(sup)
	if ignorar_inferior:
		var inf = get_parent().get_node_or_null("ParedInferior")
		if inf:
			c.add_collision_exception_with(inf)
	print("Cliente spawneado en ", c.global_position, " dir ", c.direccion_vertical)
