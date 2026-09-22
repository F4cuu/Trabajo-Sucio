extends CharacterBody2D

## Auto que cruza la calle en un solo carril y una sola dirección.
## Está en el grupo "cliente" para reutilizar reglas existentes:
## - La basura arrojada le pega (-15 al dueño) y lo destruye.
## - La comida lo atraviesa (nunca espera pedidos).
## - KillZone y el cambio de ronda lo limpian.

const TEX_ATRAS: Texture2D = preload("res://SPRITES/auto_atras.png")
const TEX_FRENTE: Texture2D = preload("res://SPRITES/auto_frente.png")
const TEX_ENOJO: Texture2D = preload("res://SPRITES/OUCH.png")

@export var velocidad: float = 450.0
@export var direccion_vertical: int = 1

var _muerto: bool = false
var _enojado: bool = false


func _ready() -> void:
	add_to_group("cliente")
	if direccion_vertical == 0:
		direccion_vertical = 1
	_actualizar_sprite()


func _physics_process(_delta: float) -> void:
	if _muerto:
		return
	velocity = Vector2(0, direccion_vertical * velocidad)
	move_and_slide()
	if global_position.y < -700 or global_position.y > 1300:
		queue_free()


func configurar_direccion(dir: int) -> void:
	direccion_vertical = dir
	if is_inside_tree():
		_actualizar_sprite()


func _actualizar_sprite() -> void:
	var sprite = get_node_or_null("Sprite2D")
	if sprite == null:
		return
	# De frente si baja (+Y), de atrás si sube (-Y)
	sprite.texture = TEX_FRENTE if direccion_vertical > 0 else TEX_ATRAS


# Los autos nunca esperan pedidos: la comida los atraviesa sin efecto.
func es_cliente_esperando() -> bool:
	return false


func es_vehiculo() -> bool:
	return true


# Basurazo recibido: -30 ya aplicados por la basura. El auto NO muere,
# sigue su camino pero con marca de enojo sobre su sprite direccional.
func enojar() -> void:
	if _enojado:
		return
	_enojado = true
	var marca := Sprite2D.new()
	marca.name = "Enojo"
	marca.texture = TEX_ENOJO
	marca.position = Vector2(0, -60)
	marca.scale = Vector2(2, 2)
	marca.z_index = 10
	add_child(marca)


func morir(_direccion: Vector2 = Vector2.ZERO) -> void:
	if _muerto:
		return
	_muerto = true
	queue_free()
