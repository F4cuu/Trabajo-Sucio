extends Area2D

var esta_sucia: bool = false

@onready var visual: TextureRect = $Visual

func _ready() -> void:
	esta_sucia = false
	_actualizar_visual()

func ensuciar() -> void:
	if esta_sucia:
		return
	esta_sucia = true
	_actualizar_visual()

func limpiar() -> void:
	if not esta_sucia:
		return
	esta_sucia = false
	_actualizar_visual()

func _actualizar_visual() -> void:
	if visual == null:
		visual = get_node_or_null("Visual") as TextureRect
	if visual == null:
		return
	if esta_sucia:
		var tex = load("res://SPRITES/el_vidrio_sucio.png")
		if tex:
			visual.texture = tex
	else:
		var tex2 = load("res://SPRITES/el_vidrio.png")
		if tex2:
			visual.texture = tex2
