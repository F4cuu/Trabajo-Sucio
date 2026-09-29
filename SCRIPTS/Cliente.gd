extends CharacterBody2D

@export var velocidad: float = 120.0
@export var direccion_vertical: int = 1
# Debug temporal: imprime la ruta de cada cliente (poner en false cuando termine la prueba)
const DEBUG_RUTA := true
# Pedidos posibles (1/4 cada uno) y su globito correspondiente
const PEDIDOS := ["hamburguesa", "pizza", "bebida", "papas"]
const TEX_GLOBO := {
	"hamburguesa": preload("res://SPRITES/quiero_hamburguesa.png"),
	"pizza": preload("res://SPRITES/quiero_pizza.png"),
	"bebida": preload("res://SPRITES/quiero_bebida.png"),
	"papas": preload("res://SPRITES/quiero_papa.png"),
}
# Sonidito feliz al ser alimentado (se reproduce con pitch alegre)
const SONIDO_RICO: AudioStream = preload("res://SOUNDS/Puntitos.wav")

var _en_pausa: bool = false
var _tiempo_pausa: float = 0.0
var _tiempo_chequeo: float = 0.0
var _muerto: bool = false
# Celebrando tras ser alimentado: quieto en el lugar hasta desaparecer
var _celebrando: bool = false
var _usar_segundo_sprite: bool = false
# Cliente que va a pedir comida: sigue la ruta de su vereda y espera en la fila
var _va_al_mostrador: bool = false
var _esperando_pedido: bool = false
var _destino_mostrador: Vector2 = Vector2.ZERO
# Ruta preestablecida (markers Punto1, Punto2... dentro de RutaPJ1/RutaPJ2)
var _ruta: Array[Vector2] = []
var _indice_ruta: int = 0
# Fila (slots Fila0, Fila1... dentro de FilaPJ1/FilaPJ2).
# PJ1 atiende en Fila0; PJ2 atiende en el slot más alto (pegado a la barra).
var _nombre_fila: String = ""
var _slot_fila: int = -1
var _moviendose_en_fila: bool = false
var _tiempo_chequeo_fila: float = 0.0
# Destino fijado por el spawner que lo creó (0 = automático por lado, 1 = PJ1, 2 = PJ2)
var destino_forzado: int = 0
# El cliente reserva su slot de fila al decidir ir al mostrador (true =
# _slot_fila ya está reservado en el grupo y no hay que volver a elegir)
var _slot_reservado: bool = false
# Lo que quiere comer ("hamburguesa", "pizza", "bebida" o "papas"). Vacío = acepta todo.
var pedido: String = ""

func _ready() -> void:
	z_index = 0
	z_as_relative = false
	if direccion_vertical == 0:
		direccion_vertical = 1
	_usar_segundo_sprite = randf() < 0.5
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.visible = not _usar_segundo_sprite
	if has_node("AnimatedSprite2D2"):
		$AnimatedSprite2D2.visible = _usar_segundo_sprite
	_actualizar_animacion()

func _physics_process(delta: float) -> void:
	if _muerto:
		return
	if _celebrando:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if _esperando_pedido:
		velocity = Vector2.ZERO
		move_and_slide()
		_chequear_avance_fila(delta)
		return
	if _moviendose_en_fila:
		if _avanzar_cardinal(_destino_mostrador, 12.0):
			_llegar_a_fila()
			return
		# Si el mostrador lo frena antes del punto exacto, igual da por llegado.
		# Radio amplio (95) porque el Fila0 está pegado al sólido del mostrador
		# y el cliente se detiene apoyado en el borde, lejos del centro del slot.
		if _bloqueado_cerca((_destino_mostrador - global_position).length(), 95.0):
			_llegar_a_fila()
		return
	if _va_al_mostrador:
		# Sin puntos de ruta: comportamiento viejo (al mostrador por ejes)
		if _ruta.is_empty():
			if _avanzar_cardinal(_destino_mostrador, 15.0):
				_va_al_mostrador = false
				if not _ir_a_slot_reservado():
					_entrar_en_fila()
				move_and_slide()
				return
			if _bloqueado_cerca((_destino_mostrador - global_position).length()):
				_va_al_mostrador = false
				if not _ir_a_slot_reservado():
					_entrar_en_fila()
				move_and_slide()
			return
		# Con ruta: seguir Punto1, Punto2... en orden, de a un punto por vez.
		# Al Punto2 solo se va cuando se llegó al Punto1, y así sucesivamente.
		# No hay pausas: al pisar un punto se apunta al siguiente en el acto.
		if _indice_ruta >= _ruta.size():
			_va_al_mostrador = false
			_ruta.clear()
			if not _ir_a_slot_reservado():
				_entrar_en_fila()
			move_and_slide()
			return
		var objetivo: Vector2 = _ruta[_indice_ruta]
		if _avanzar_cardinal(objetivo, 15.0):
			_indice_ruta += 1
			if DEBUG_RUTA:
				print("[Cliente ", get_instance_id(), "] punto OK, ahora índice ", _indice_ruta, "/", _ruta.size(), " en ", global_position)
			move_and_slide()
			return
		# Si una pared lo frena cerca del punto, no se queda empujando: pasa al siguiente
		if _bloqueado_cerca((objetivo - global_position).length()):
			_indice_ruta += 1
		return
	if _en_pausa:
		_tiempo_pausa -= delta
		velocity = Vector2.ZERO
		if _tiempo_pausa <= 0.0:
			_en_pausa = false
			_actualizar_animacion()
	else:
		_tiempo_chequeo -= delta
		if _tiempo_chequeo <= 0.0:
			_tiempo_chequeo = 1.0
			if randf() < 0.10:
				_ir_al_mostrador()
				move_and_slide()
				return
			if randf() < 0.05:
				_en_pausa = true
				_tiempo_pausa = 1.0
				velocity = Vector2.ZERO
				var s = _get_sprite_activo()
				if s:
					if direccion_vertical > 0:
						s.play("IDLE DOWN")
					else:
						s.play("IDLE UP")
				move_and_slide()
				return
		velocity = Vector2(0, direccion_vertical * velocidad)
	move_and_slide()
	if global_position.y < -700 or global_position.y > 1300:
		queue_free()

func morir(direccion: Vector2 = Vector2.ZERO) -> void:
	if _muerto or _celebrando:
		return
	_muerto = true
	_en_pausa = false
	var globo_muerto = get_node_or_null("GloboPedido")
	if globo_muerto:
		globo_muerto.visible = false
	velocity = Vector2.ZERO
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	var sprite = _get_sprite_activo()
	if sprite:
		if direccion != Vector2.ZERO:
			sprite.flip_h = direccion.x < 0
		sprite.play("DEATH")
		sprite.animation_finished.connect(_on_death_finished, CONNECT_ONE_SHOT)

func _on_death_finished() -> void:
	queue_free()


# Lo llama Comida.gd al alimentar: en vez de desaparecer en seco, el cliente
# festeja en su lugar (globito que revienta, saltito con squash, estrellitas
# y sonidito) y recién ahí se va. Libera su slot al terminar.
func alimentado() -> void:
	if _muerto or _celebrando:
		return
	_celebrando = true
	_va_al_mostrador = false
	_moviendose_en_fila = false
	_esperando_pedido = false
	_en_pausa = false
	velocity = Vector2.ZERO
	remove_from_group("cliente_esperando")
	_reventar_globo()
	_sonido_rico()
	_saltito_feliz()
	_lluvia_estrellas()
	await get_tree().create_timer(0.85).timeout
	queue_free()


# El globito del pedido revienta (colapsa rapidito) en vez de apagarse
func _reventar_globo() -> void:
	var globo := get_node_or_null("GloboPedido") as Sprite2D
	if globo == null:
		return
	globo.visible = true
	var tw := globo.create_tween()
	tw.tween_property(globo, "scale", Vector2.ZERO, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(globo.queue_free)


# Sonidito feliz: el blip de puntos con pitch alegre y aleatorio
func _sonido_rico() -> void:
	var a := AudioStreamPlayer.new()
	a.stream = SONIDO_RICO
	a.pitch_scale = randf_range(1.35, 1.6)
	a.volume_db = -4.0
	add_child(a)
	a.finished.connect(a.queue_free)
	a.play()


# Saltito en el lugar: anticipación (agacharse), salto estirado, caída y
# aplaste al aterrizar. Solo anima el sprite, el cuerpo queda quieto.
func _saltito_feliz() -> void:
	var s := _get_sprite_activo()
	if s == null:
		return
	var p0 := s.position
	var e0 := s.scale
	var tw := create_tween()
	tw.tween_property(s, "scale", Vector2(e0.x * 0.85, e0.y * 1.15), 0.1)
	tw.tween_property(s, "position:y", p0.y - 46.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(s, "scale", Vector2(e0.x * 1.1, e0.y * 0.9), 0.25)
	tw.tween_property(s, "position:y", p0.y, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(s, "scale", Vector2(e0.x * 1.25, e0.y * 0.75), 0.08)
	tw.tween_property(s, "scale", e0, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# Tres estrellitas que salen de la cabeza, suben girando y se desvanecen
func _lluvia_estrellas() -> void:
	var colores := [Color(1.0, 0.45, 0.65), Color(1.0, 0.85, 0.25), Color(0.55, 0.9, 1.0)]
	for i in 3:
		var est := Polygon2D.new()
		est.polygon = _puntos_estrella(13.0, 5.5)
		est.color = colores[i]
		est.position = Vector2(19.0 + randf_range(-14.0, 14.0), -50.0)
		est.z_index = 60
		est.z_as_relative = false
		add_child(est)
		var tw := est.create_tween().set_parallel(true)
		tw.tween_property(est, "position:y", est.position.y - randf_range(55.0, 85.0), 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(0.08 * i)
		tw.tween_property(est, "rotation", randf_range(-2.5, 2.5), 0.6).set_delay(0.08 * i)
		tw.tween_property(est, "modulate:a", 0.0, 0.3).set_delay(0.08 * i + 0.3)
		tw.chain().tween_callback(est.queue_free)


func _puntos_estrella(radio_ext: float, radio_int: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var radio := radio_ext if i % 2 == 0 else radio_int
		var ang := -PI / 2.0 + float(i) * PI / 5.0
		pts.append(Vector2(cos(ang), sin(ang)) * radio)
	return pts

func es_cliente_esperando() -> bool:
	if _celebrando:
		return false
	if not _esperando_pedido:
		return false
	# Solo el del frente puede ser alimentado (ver _es_frente)
	return _es_frente()


# Solo el del frente muestra lo que quiere pedir: así los carteles no
# invaden la pantalla y hay que atender en orden para ver el pedido.
func _es_frente() -> bool:
	if _nombre_fila == "":
		return true
	# PJ1 atiende en Fila0, PJ2 en el slot más alto (pegado a la barra)
	if _nombre_fila == "FilaPJ2":
		return _slot_fila >= _max_slot_fila()
	return _slot_fila <= 0


# True si este cliente acepta la comida arrojada: tiene que estar esperando
# en el frente y el tipo tiene que coincidir con su pedido.
func acepta_comida(tipo: String) -> bool:
	if not es_cliente_esperando():
		return false
	if pedido == "" or tipo == "generica":
		return true
	return pedido == tipo


func _ir_al_mostrador() -> void:
	# Cada vereda va a su local: izquierda (x < 960) -> RutaPJ1/FilaPJ1 (PJ1),
	# derecha -> RutaPJ2/FilaPJ2 (PJ2). El spawner puede forzar el destino.
	var es_pj1: bool
	if destino_forzado == 1:
		es_pj1 = true
	elif destino_forzado == 2:
		es_pj1 = false
	else:
		es_pj1 = global_position.x < 960.0
	var nombre_ruta = "RutaPJ1" if es_pj1 else "RutaPJ2"
	_nombre_fila = "FilaPJ1" if es_pj1 else "FilaPJ2"
	var escena = get_tree().current_scene
	if escena == null:
		return
	# Armar ruta con los Marker2D hijos de RutaPJ1/RutaPJ2 (Punto1, Punto2...).
	# El cliente pasa por su Punto1 (puerta del local) para no chocar contra
	# el ventanal/muro, pero reserva YA el lugar desocupado más cercano a la
	# barra para ir directo a él al salir de la ruta, sin paradas intermedias.
	_ruta = _cargar_puntos(escena, nombre_ruta)
	_indice_ruta = 0
	_slot_reservado = false
	if _ruta.is_empty():
		var nombre_mostrador = "MostradorPJ1" if es_pj1 else "MostradorPJ2"
		var mostrador = escena.get_node_or_null(nombre_mostrador)
		if mostrador == null:
			return
		_destino_mostrador = (mostrador as Node2D).global_position
	# Reserva inmediata del lugar desocupado más cercano a la barra (vale para
	# ambos lados): queda apartado en el grupo y nadie lo ocupa en el camino.
	var slot_reserva := _pedir_slot_libre()
	if slot_reserva >= 0:
		_slot_fila = slot_reserva
		_slot_reservado = true
		add_to_group("cliente_en_fila")
		_destino_mostrador = _posicion_slot(escena, _nombre_fila, slot_reserva)
	# Sin entrada en L: el cliente va DIRECTO al Punto1 fijo de su ruta
	# (Spawner2/3 -> Punto1 de RutaPJ1, Spawner/4 -> Punto1 de RutaPJ2)
	# y de ahí sigue Punto2, Punto3... en orden, esté donde esté.
	_asignar_pedido()
	_va_al_mostrador = true
	_en_pausa = false
	if DEBUG_RUTA:
		print("[Cliente ", get_instance_id(), "] a ", nombre_ruta, " puntos=", _ruta, " fila=", _nombre_fila, " reserva=", _slot_fila if _slot_reservado else -1, " desde=", global_position)


# Avanza hacia el objetivo SOLO en ejes cardinales (sin diagonales).
# Va por el eje con más distancia restante; si una pared lo frena, prueba
# el otro eje en el mismo frame (rodeo en L: el camino más corto que
# esquiva la colisión en vez de empujarla). Devuelve true si llegó.
func _avanzar_cardinal(objetivo: Vector2, radio: float) -> bool:
	var d := objetivo - global_position
	if d.length() < radio:
		velocity = Vector2.ZERO
		return true
	var dir := _eje_prioritario_y(d)
	velocity = dir * velocidad
	_animar_movimiento(dir)
	move_and_slide()
	if _esta_bloqueado() and (_ruta_no_llego(objetivo, radio)):
		var alt := _eje_alternativo(d, dir)
		if alt != Vector2.ZERO:
			velocity = alt * velocidad
			_animar_movimiento(alt)
			move_and_slide()
	return false


func _ruta_no_llego(objetivo: Vector2, radio: float) -> bool:
	return (objetivo - global_position).length() >= radio


func _esta_bloqueado() -> bool:
	if get_slide_collision_count() > 0:
		return true
	return get_real_velocity().length() < velocidad * 0.2


# Eje cardinal con prioridad en Y: primero corrige la altura (arriba/abajo)
# y cuando está alineado en Y (a menos de 4px), recién ahí va en X (izq/der).
func _eje_prioritario_y(d: Vector2) -> Vector2:
	if absf(d.y) >= 4.0 and d.y != 0.0:
		return Vector2(0.0, signf(d.y))
	if d.x == 0.0:
		return Vector2.ZERO
	return Vector2(signf(d.x), 0.0)


# El otro eje, apuntando también hacia el objetivo (para rodear).
# Si ya está alineado en ese eje, devuelve ZERO (no hay rodeo útil).
func _eje_alternativo(d: Vector2, actual: Vector2) -> Vector2:
	if actual.x != 0.0:
		if absf(d.y) < 4.0 or d.y == 0.0:
			return Vector2.ZERO
		return Vector2(0.0, signf(d.y))
	else:
		if absf(d.x) < 4.0 or d.x == 0.0:
			return Vector2.ZERO
		return Vector2(signf(d.x), 0.0)


# Elige el pedido al azar (1/4 cada uno) y muestra el globito sobre la cabeza.
func _asignar_pedido() -> void:
	pedido = PEDIDOS.pick_random()
	var viejo = get_node_or_null("GloboPedido")
	if viejo:
		viejo.queue_free()
	var globo := Sprite2D.new()
	globo.name = "GloboPedido"
	globo.texture = TEX_GLOBO.get(pedido)
	globo.position = Vector2(20, -70)
	globo.scale = Vector2(2, 2)
	globo.z_index = 10
	globo.visible = false # solo visible cuando espera en la fila
	add_child(globo)


# El globito solo se muestra mientras espera quieto en la fila.
func _mostrar_globo(mostrar: bool) -> void:
	var globo = get_node_or_null("GloboPedido")
	if globo:
		(globo as Sprite2D).visible = mostrar


func _llegar_a_fila() -> void:
	_moviendose_en_fila = false
	_esperando_pedido = true
	velocity = Vector2.ZERO
	add_to_group("cliente_esperando")
	_actualizar_z_fila()
	# El globito solo aparece si está primero: al avanzar al frente se revela
	_mostrar_globo(_es_frente())
	var s_fila = _get_sprite_activo()
	if s_fila:
		if _nombre_fila == "FilaPJ2":
			# Lado derecho: la fila está debajo de la barra, mira al mostrador
			s_fila.flip_h = false
			s_fila.play("IDLE UP")
		else:
			# Mira hacia su local: izquierda si es PJ1, derecha si es PJ2
			s_fila.flip_h = global_position.x > 960.0
			s_fila.play("IDLE DOWN")
	move_and_slide()


# True si está cerca del objetivo pero una pared (mostrador) lo frena.
# Evita que el NPC empuje el mostrador para siempre sin dar por llegado.
func _bloqueado_cerca(dist_objetivo: float, limite: float = 70.0) -> bool:
	if dist_objetivo > limite:
		return false
	if get_slide_collision_count() > 0:
		return true
	return get_real_velocity().length() < velocidad * 0.2


# Al terminar la ruta va DIRECTO al slot reservado al decidirse,
# sin volver a elegir ni frenar en puntos intermedios.
# Devuelve true si tenía reserva (ya queda caminando hacia su slot).
func _ir_a_slot_reservado() -> bool:
	if not _slot_reservado or _slot_fila < 0 or _nombre_fila == "":
		_slot_reservado = false
		return false
	_slot_reservado = false
	_moviendose_en_fila = true
	_esperando_pedido = false
	_mostrar_globo(false)
	# Ya está en el grupo "cliente_en_fila" desde la reserva
	var escena = get_tree().current_scene
	_destino_mostrador = _posicion_slot(escena, _nombre_fila, _slot_fila)
	if DEBUG_RUTA:
		print("[Cliente ", get_instance_id(), "] a slot reservado ", _nombre_fila, " ", _slot_fila, " -> ", _destino_mostrador)
	return true


# Profundidad en la fila: el del frente se ve por encima del segundo, el
# segundo por encima del tercero, etc. Sin slot vuelve a z 0.
func _actualizar_z_fila() -> void:
	if _nombre_fila == "" or _slot_fila < 0:
		z_index = 0
		return
	if _nombre_fila == "FilaPJ2":
		z_index = _slot_fila
	else:
		z_index = _max_slot_fila() - _slot_fila


func _entrar_en_fila() -> void:
	var escena = get_tree().current_scene
	var slot := _pedir_slot_libre()
	if slot < 0:
		# Fila llena o sin nodo de fila: esperar donde está (comportamiento viejo)
		var era_pj2 := _nombre_fila == "FilaPJ2"
		_nombre_fila = ""
		_slot_fila = -1
		_actualizar_z_fila()
		_esperando_pedido = true
		velocity = Vector2.ZERO
		add_to_group("cliente_esperando")
		_mostrar_globo(true)
		var s = _get_sprite_activo()
		if s:
			if era_pj2:
				s.flip_h = false
				s.play("IDLE UP")
			else:
				s.flip_h = global_position.x > 960.0
				s.play("IDLE DOWN")
		return
	_slot_fila = slot
	_moviendose_en_fila = true
	_esperando_pedido = false
	add_to_group("cliente_en_fila")
	_destino_mostrador = _posicion_slot(escena, _nombre_fila, slot)
	if DEBUG_RUTA:
		print("[Cliente ", get_instance_id(), "] entra fila ", _nombre_fila, " slot ", _slot_fila, " -> ", _destino_mostrador)


func _chequear_avance_fila(delta: float) -> void:
	if _nombre_fila == "" or _moviendose_en_fila:
		return
	# PJ1 avanza hacia Fila0, PJ2 hacia el slot más alto (pegado a la barra)
	var siguiente := _slot_fila - 1
	if _nombre_fila == "FilaPJ2":
		if _slot_fila >= _max_slot_fila():
			return
		siguiente = _slot_fila + 1
	elif _slot_fila <= 0:
		return
	_tiempo_chequeo_fila -= delta
	if _tiempo_chequeo_fila > 0.0:
		return
	_tiempo_chequeo_fila = 0.3
	if _slot_ocupado(_nombre_fila, siguiente):
		return
	# Avanzar un puesto
	_slot_fila = siguiente
	var escena = get_tree().current_scene
	_destino_mostrador = _posicion_slot(escena, _nombre_fila, _slot_fila)
	_moviendose_en_fila = true
	_esperando_pedido = false
	remove_from_group("cliente_esperando")
	_mostrar_globo(false)


# Devuelve el slot libre más cercano a la barra de su fila: en PJ1 es el de
# índice más bajo (Fila0, pegado al mostrador) y en PJ2 el más alto (Fila3).
# Los siguientes encolan detrás y avanzan hacia su frente. -1 si está llena.
func _pedir_slot_libre() -> int:
	var escena = get_tree().current_scene
	if escena == null or _nombre_fila == "":
		return -1
	var fila = escena.get_node_or_null(_nombre_fila)
	if fila == null:
		return -1
	var slots := _hijos_marker_ordenados(fila)
	if _nombre_fila == "FilaPJ1":
		for i in range(slots.size()):
			if not _slot_ocupado(_nombre_fila, i):
				return i
		return -1
	for i in range(slots.size() - 1, -1, -1):
		if not _slot_ocupado(_nombre_fila, i):
			return i
	return -1


func _slot_ocupado(nombre_fila: String, slot: int) -> bool:
	for n in get_tree().get_nodes_in_group("cliente_en_fila"):
		if n == self or not is_instance_valid(n):
			continue
		if n.get("_nombre_fila") == nombre_fila and int(n.get("_slot_fila")) == slot:
			return true
	for n in get_tree().get_nodes_in_group("cliente_esperando"):
		if n == self or not is_instance_valid(n):
			continue
		if n.get("_nombre_fila") == nombre_fila and int(n.get("_slot_fila")) == slot:
			return true
	return false


func _posicion_slot(escena: Node, nombre_fila: String, slot: int) -> Vector2:
	var fila = escena.get_node_or_null(nombre_fila)
	if fila == null:
		return global_position
	var slots := _hijos_marker_ordenados(fila)
	if slot < 0 or slot >= slots.size():
		return global_position
	return (slots[slot] as Node2D).global_position


# Índice del último slot de la fila actual (el frente en PJ2).
# Devuelve -1 si no hay fila.
func _max_slot_fila() -> int:
	var escena = get_tree().current_scene
	if escena == null or _nombre_fila == "":
		return -1
	var fila = escena.get_node_or_null(_nombre_fila)
	if fila == null:
		return -1
	return _hijos_marker_ordenados(fila).size() - 1


func _cargar_puntos(escena: Node, nombre_ruta: String) -> Array[Vector2]:
	var puntos: Array[Vector2] = []
	var ruta = escena.get_node_or_null(nombre_ruta)
	if ruta == null:
		return puntos
	for m in _hijos_marker_ordenados(ruta):
		puntos.append((m as Node2D).global_position)
	return puntos


func _hijos_marker_ordenados(nodo: Node) -> Array[Node]:
	var hijos: Array[Node] = []
	for h in nodo.get_children():
		if h is Marker2D:
			hijos.append(h)
	hijos.sort_custom(func(a: Node, b: Node) -> bool: return a.name < b.name)
	return hijos


func _actualizar_flip_ruta(dir: Vector2) -> void:
	_animar_movimiento(dir)


# Elige la animación según hacia dónde camina: WALK de costado,
# UP si va hacia arriba, DOWN si va hacia abajo. Así, si el cliente
# ya pasó el Punto1 y tiene que volver en contra, se lo ve caminar
# en la dirección correcta en vez de quedarse con la animación vieja.
func _animar_movimiento(dir: Vector2) -> void:
	var s = _get_sprite_activo()
	if s == null or dir == Vector2.ZERO:
		return
	if absf(dir.x) > absf(dir.y):
		if s.animation != &"WALK":
			s.play("WALK")
		s.flip_h = dir.x < 0
	else:
		if dir.y < 0.0:
			if s.animation != &"UP":
				s.play("UP")
		else:
			if s.animation != &"DOWN":
				s.play("DOWN")
		if absf(dir.x) > 5.0:
			s.flip_h = dir.x < 0


func configurar_direccion(dir: int) -> void:
	direccion_vertical = dir
	if is_inside_tree():
		_actualizar_animacion()

func _get_sprite_activo() -> AnimatedSprite2D:
	if _usar_segundo_sprite and has_node("AnimatedSprite2D2"):
		return $AnimatedSprite2D2
	if has_node("AnimatedSprite2D"):
		return $AnimatedSprite2D
	return null

func _actualizar_animacion() -> void:
	var sprite = _get_sprite_activo()
	if sprite == null:
		return
	if direccion_vertical > 0:
		sprite.play("DOWN")
	else:
		sprite.play("UP")
	if has_node("AnimatedSprite2D") and has_node("AnimatedSprite2D2"):
		if _usar_segundo_sprite:
			$AnimatedSprite2D.stop()
		else:
			$AnimatedSprite2D2.stop()
