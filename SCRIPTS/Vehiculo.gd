extends CharacterBody2D

## Auto que cruza la calle en un solo carril y una sola dirección.
## Está en el grupo "cliente" para reutilizar reglas existentes:
## - La basura lo enoja una vez (-15 al dueño): cambia a su animación de
##   enojado direccional, sigue su camino y después es inmune.
## - La comida lo atraviesa (nunca espera pedidos).
## - KillZone y el cambio de ronda lo limpian.

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
	var sprite := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		return
	if _enojado:
		# Enojado animado según la dirección que llevaba
		sprite.play("enojao_arriba" if direccion_vertical < 0 else "enojao_abajo")
		return
	# De frente si baja (+Y), de atrás si sube (-Y)
	sprite.play("arriba" if direccion_vertical < 0 else "abajo")


# Los autos nunca esperan pedidos: la comida los atraviesa sin efecto.
func es_cliente_esperando() -> bool:
	return false


func es_vehiculo() -> bool:
	return true


# Basurazo recibido: pasa a la animación de enojado direccional y sigue su
# camino. Solo se enoja una vez: después es inmune (ver esta_enojado).
func enojar() -> void:
	if _enojado:
		return
	_enojado = true
	_actualizar_sprite()


func esta_enojado() -> bool:
	return _enojado


func morir(_direccion: Vector2 = Vector2.ZERO) -> void:
	if _muerto:
		return
	_muerto = true
	queue_free()
