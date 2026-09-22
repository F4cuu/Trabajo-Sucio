extends Area2D

var grupo_objetivo: String = "ventana1"
var jugador_dueno: int = 0
var _es_proyectil: bool = false
var _velocidad: Vector2 = Vector2.ZERO
var _sostenida: bool = false

func _ready() -> void:
	add_to_group("basura")
	monitoring = true
	monitorable = true
	collision_mask = 15

func _physics_process(delta: float) -> void:
	if _es_proyectil:
		global_position += _velocidad * delta
		_check_npcs()
		_check_ventanas()
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

func _check_npcs() -> void:
	for body in get_overlapping_bodies():
		if body.is_in_group("cliente") and body.has_method("morir"):
			if jugador_dueno == 1:
				get_tree().call_group("puntuacion", "agregar_puntos", -15, global_position)
			elif jugador_dueno == 2:
				get_tree().call_group("puntuacion_pj2", "agregar_puntos", -15, global_position)
			if body.has_method("morir"):
				if _velocidad != Vector2.ZERO:
					body.morir(_velocidad)
				else:
					body.morir(Vector2.ZERO)
			queue_free()
			return

func _check_ventanas() -> void:
	for area in get_overlapping_areas():
		if area.is_in_group(grupo_objetivo):
			if jugador_dueno == 1:
				get_tree().call_group("puntuacion", "agregar_puntos", 15, global_position)
			elif jugador_dueno == 2:
				get_tree().call_group("puntuacion_pj2", "agregar_puntos", 15, global_position)
			_manshar_ventana(area)
			queue_free()
			return

func _manshar_ventana(ventana: Area2D) -> void:
	if ventana.has_method("ensuciar"):
		ventana.ensuciar() # marca esta_sucia + muestra el overlay de suciedad
		return
	var visual = ventana.get_node_or_null("Visual")
	if visual == null:
		return
	if visual is ColorRect:
		visual.color = Color(0.2, 0.85, 0.2, 0.7)
	elif visual is TextureRect:
		var tex = load("res://SPRITES/el_vidrio_sucio.png")
		if tex:
			visual.texture = tex
		else:
			visual.modulate = Color(0.5, 1, 0.5, 1)
