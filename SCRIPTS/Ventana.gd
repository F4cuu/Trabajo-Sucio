extends Area2D

const TEX_SUCIEDAD: Texture2D = preload("res://SPRITES/suciedad.png")

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
	_mostrar_suciedad(esta_sucia)


# Capa de suciedad por encima del vidrio, cubriendo su misma área.
func _mostrar_suciedad(mostrar: bool) -> void:
	var suciedad := get_node_or_null("Suciedad") as TextureRect
	if suciedad == null:
		if visual == null:
			return
		suciedad = TextureRect.new()
		suciedad.name = "Suciedad"
		suciedad.texture = TEX_SUCIEDAD
		suciedad.offset_left = visual.offset_left
		suciedad.offset_top = visual.offset_top
		suciedad.offset_right = visual.offset_right
		suciedad.offset_bottom = visual.offset_bottom
		suciedad.expand_mode = visual.expand_mode
		suciedad.stretch_mode = visual.stretch_mode
		suciedad.mouse_filter = Control.MOUSE_FILTER_IGNORE
		suciedad.visible = false
		add_child(suciedad)
	suciedad.visible = mostrar
