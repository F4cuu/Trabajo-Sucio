extends Control

## Datos que deja GestorRondas antes de cambiar a esta escena.
static var ganador: String = ""
static var victorias_p1: int = 0
static var victorias_p2: int = 0

const TEX_P1_WIN: Texture2D = preload("res://SPRITES/P1_Win.png")
const TEX_P1_TRISTE: Texture2D = preload("res://SPRITES/P1_triste.png")
const TEX_P2_WIN: Texture2D = preload("res://SPRITES/P2_Win.png")
const TEX_P2_TRISTE: Texture2D = preload("res://SPRITES/P2_triste.png")

var _salio := false

@onready var titulo: Label = get_node_or_null("Titulo") as Label
@onready var puntaje: Label = get_node_or_null("Puntaje") as Label
@onready var ganador_tex: TextureRect = get_node_or_null("Ganador") as TextureRect
@onready var perdedor_tex: TextureRect = get_node_or_null("Perdedor") as TextureRect
@onready var paso_ganador: ColorRect = get_node_or_null("PasoGanador") as ColorRect
@onready var paso_perdedor: ColorRect = get_node_or_null("PasoPerdedor") as ColorRect


func _ready() -> void:
	# La cortina se abre revelando el podio (si se vino del gameplay)
	TransicionCortina.abrir(get_tree())
	_armar_podio()
	await get_tree().create_timer(8.0).timeout
	_salir()


func _armar_podio() -> void:
	if puntaje:
		puntaje.text = "Rondas  P1: %d - %d :P2" % [victorias_p1, victorias_p2]
	# El ganador siempre va en la tarima alta (plataforma 1): solo cambian
	# las texturas, las posiciones quedan fijas en la escena.
	# Los guards evitan un crash si algún nodo se borra desde el editor.
	if ganador == "P2":
		if titulo:
			titulo.text = "¡GANA P2!"
		if ganador_tex:
			ganador_tex.texture = TEX_P2_WIN
		if perdedor_tex:
			perdedor_tex.texture = TEX_P1_TRISTE
	elif ganador == "EMPATE":
		if titulo:
			titulo.text = "EMPATE"
		if ganador_tex:
			ganador_tex.texture = TEX_P1_WIN
		if perdedor_tex:
			perdedor_tex.texture = TEX_P2_WIN
	else:
		if titulo:
			titulo.text = "¡GANA P1!"
		if ganador_tex:
			ganador_tex.texture = TEX_P1_WIN
		if perdedor_tex:
			perdedor_tex.texture = TEX_P2_TRISTE


func _on_volver_pressed() -> void:
	_salir()


func _salir() -> void:
	if _salio:
		return
	_salio = true
	# La cortina se cierra sobre el podio y el menú la vuelve a abrir
	await TransicionCortina.cerrar(get_tree(), 0.7)
	get_tree().change_scene_to_file("res://scenes/MenuPrincipal.tscn")
