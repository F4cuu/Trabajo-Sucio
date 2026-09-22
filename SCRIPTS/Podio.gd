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

@onready var titulo: Label = $Titulo
@onready var puntaje: Label = $Puntaje
@onready var ganador_tex: TextureRect = $Ganador
@onready var perdedor_tex: TextureRect = $Perdedor
@onready var paso_ganador: ColorRect = $PasoGanador
@onready var paso_perdedor: ColorRect = $PasoPerdedor


func _ready() -> void:
	_armar_podio()
	await get_tree().create_timer(8.0).timeout
	_salir()


func _armar_podio() -> void:
	puntaje.text = "Rondas  P1: %d - %d :P2" % [victorias_p1, victorias_p2]
	if ganador == "P2":
		titulo.text = "¡GANA P2!"
		ganador_tex.texture = TEX_P2_WIN
		perdedor_tex.texture = TEX_P1_TRISTE
		_mover_a(perdedor_tex, -650, 80, -350, 340)
		_mover_a(paso_perdedor, -610, 260, -390, 360)
	elif ganador == "EMPATE":
		titulo.text = "EMPATE"
		ganador_tex.texture = TEX_P1_WIN
		perdedor_tex.texture = TEX_P2_WIN
		_mover_a(ganador_tex, -350, -70, -50, 190)
		_mover_a(perdedor_tex, 50, -70, 350, 190)
		_mover_a(paso_ganador, -320, 245, -80, 360)
		_mover_a(paso_perdedor, 80, 245, 320, 360)
		paso_ganador.color = Color(0.5, 0.5, 0.55)
	else:
		titulo.text = "¡GANA P1!"
		ganador_tex.texture = TEX_P1_WIN
		perdedor_tex.texture = TEX_P2_TRISTE
		# Posiciones por defecto del tscn (ganador centro, perdedor derecha)


func _mover_a(control: Control, l: float, t: float, r: float, b: float) -> void:
	control.offset_left = l
	control.offset_top = t
	control.offset_right = r
	control.offset_bottom = b


func _on_volver_pressed() -> void:
	_salir()


func _salir() -> void:
	if _salio:
		return
	_salio = true
	get_tree().change_scene_to_file("res://scenes/MenuPrincipal.tscn")
