extends Area2D

# Gemelo de Basura.gd pero para COMIDA:
# - Se recoge/lanza con las mismas teclas (misma API: es_proyectil/set_sostenida/lanzar/recoger)
# - Al golpear un cliente lo ALIMENTA (+50 al dueño) en vez de matarlo/penalizar
# - No ensucia ventanas: si golpea una ventana se destruye sin puntos

var grupo_objetivo: String = "ventana1" # sin uso real, se mantiene por compatibilidad con el generador
# Tipo de comida ("generica", "hamburguesa", "bebida", "papas", "pizza").
# Por ahora alimenta igual; los pedidos específicos de clientes vienen después.
@export var tipo_comida: String = "generica"
var jugador_dueno: int = 0
var _es_proyectil: bool = false
var _velocidad: Vector2 = Vector2.ZERO
var _sostenida: bool = false

func _ready() -> void:
	add_to_group("comida")
	monitoring = true
	monitorable = true
	collision_mask = 15

func _physics_process(delta: float) -> void:
	if _es_proyectil:
		global_position += _velocidad * delta
		_check_clientes()
		if global_position.x < -100 or global_position.x > 2020 or global_position.y < -200 or global_position.y > 1300:
			queue_free()

func es_proyectil() -> bool:
	return _es_proyectil

func set_sostenida(v: bool) -> void:
	_sostenida = v
	if v:
		_es_proyectil = false
		_velocidad = Vector2.ZERO

func lanzar(vel: Vector2) -> void:
	_es_proyectil = true
	_velocidad = vel
	_sostenida = false
	monitoring = true
	monitorable = true
	if has_node("CollisionShape2D"):
		get_node("CollisionShape2D").set_deferred("disabled", false)

func recoger() -> void:
	queue_free()

func _check_clientes() -> void:
	for body in get_overlapping_bodies():
		if body.is_in_group("cliente"):
			# Solo alimenta si el NPC espera en el frente Y la comida coincide
			# con su pedido. Si va caminando o quiere otra cosa, la atraviesa.
			var acepta := false
			if body.has_method("acepta_comida"):
				acepta = body.acepta_comida(tipo_comida)
			elif body.has_method("es_cliente_esperando"):
				acepta = body.es_cliente_esperando()
			if not acepta:
				continue
			# Alimentar: +50 al jugador que la arrojó, el cliente se va contento
			if jugador_dueno == 1:
				get_tree().call_group("puntuacion", "agregar_puntos", 50, global_position)
			elif jugador_dueno == 2:
				get_tree().call_group("puntuacion_pj2", "agregar_puntos", 50, global_position)
			body.queue_free()
			queue_free()
			return
