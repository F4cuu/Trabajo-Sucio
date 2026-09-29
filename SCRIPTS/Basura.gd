extends Area2D

var grupo_objetivo: String = "ventana1"
var jugador_dueno: int = 0
# Sonidos de impacto (ventana, auto o npc): uno al azar (33% c/u)
const SONIDOS_BOOM: Array[AudioStream] = [
	preload("res://SOUNDS/Boom1.wav"),
	preload("res://SOUNDS/Boom2.wav"),
	preload("res://SOUNDS/Boom4.wav"),
]
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

# Boom posicional en el punto de impacto. El reproductor se cuelga del padre
# porque la basura se libera en el mismo frame y cortaría el sonido.
func _sonido_boom() -> void:
	var p := get_parent()
	if p == null:
		return
	var a := AudioStreamPlayer2D.new()
	a.stream = SONIDOS_BOOM.pick_random()
	p.add_child(a)
	a.global_position = global_position
	a.finished.connect(a.queue_free)
	a.play()

func _check_npcs() -> void:
	for body in get_overlapping_bodies():
		if body.is_in_group("cliente") and body.has_method("morir"):
			# Auto ya enojado: inmune, la basura lo atraviesa sin efecto
			if body.has_method("esta_enojado") and bool(body.esta_enojado()):
				continue
			if jugador_dueno == 1:
				get_tree().call_group("puntuacion", "agregar_puntos", -15, global_position)
			elif jugador_dueno == 2:
				get_tree().call_group("puntuacion_pj2", "agregar_puntos", -15, global_position)
			# Auto: se enoja (cambia el sprite y sigue); NPC: muere
			if body.has_method("es_vehiculo") and body.has_method("enojar"):
				body.enojar()
			elif body.has_method("morir"):
				if _velocidad != Vector2.ZERO:
					body.morir(_velocidad)
				else:
					body.morir(Vector2.ZERO)
			_sonido_boom()
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
			_sonido_boom()
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
