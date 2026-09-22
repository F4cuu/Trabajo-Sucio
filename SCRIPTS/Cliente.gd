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

var _en_pausa: bool = false
var _tiempo_pausa: float = 0.0
var _tiempo_chequeo: float = 0.0
var _muerto: bool = false
var _usar_segundo_sprite: bool = false
# Cliente que va a pedir comida: sigue la ruta de su vereda y espera en la fila
var _va_al_mostrador: bool = false
var _esperando_pedido: bool = false
var _destino_mostrador: Vector2 = Vector2.ZERO
# Ruta preestablecida (markers Punto1, Punto2... dentro de RutaPJ1/RutaPJ2)
var _ruta: Array[Vector2] = []
var _indice_ruta: int = 0
# Fila (slots Fila0, Fila1... dentro de FilaPJ1/FilaPJ2, Fila0 = frente)
var _nombre_fila: String = ""
var _slot_fila: int = -1
var _moviendose_en_fila: bool = false
var _tiempo_chequeo_fila: float = 0.0
# Destino fijado por el spawner que lo creó (0 = automático por lado, 1 = PJ1, 2 = PJ2)
var destino_forzado: int = 0
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
				_entrar_en_fila()
				move_and_slide()
				return
			if _bloqueado_cerca((_destino_mostrador - global_position).length()):
				_va_al_mostrador = false
				_entrar_en_fila()
				move_and_slide()
			return
		# Con ruta: seguir Punto1, Punto2... en orden, de a un punto por vez.
		# Al Punto2 solo se va cuando se llegó al Punto1, y así sucesivamente.
		if _indice_ruta >= _ruta.size():
			_va_al_mostrador = false
			_ruta.clear()
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
	if _muerto:
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

func es_cliente_esperando() -> bool:
	if not _esperando_pedido:
		return false
	# Con fila: solo el primero (slot 0) puede ser alimentado
	if _nombre_fila != "":
		return _slot_fila <= 0
	return true


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
	# Si no existen, se usa el Mostrador directo como antes.
	_ruta = _cargar_puntos(escena, nombre_ruta)
	_indice_ruta = 0
	if _ruta.is_empty():
		var nombre_mostrador = "MostradorPJ1" if es_pj1 else "MostradorPJ2"
		var mostrador = escena.get_node_or_null(nombre_mostrador)
		if mostrador == null:
			return
		_destino_mostrador = (mostrador as Node2D).global_position
	# Sin entrada en L: el cliente va DIRECTO al Punto1 fijo de su ruta
	# (Spawner2/3 -> Punto1 de RutaPJ1, Spawner/4 -> Punto1 de RutaPJ2)
	# y de ahí sigue Punto2, Punto3... en orden, esté donde esté.
	_asignar_pedido()
	_va_al_mostrador = true
	_en_pausa = false
	if DEBUG_RUTA:
		print("[Cliente ", get_instance_id(), "] a ", nombre_ruta, " puntos=", _ruta, " fila=", _nombre_fila, " desde=", global_position)


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
	_mostrar_globo(true)
	var s_fila = _get_sprite_activo()
	if s_fila:
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


func _entrar_en_fila() -> void:
	var escena = get_tree().current_scene
	var slot := _pedir_slot_libre()
	if slot < 0:
		# Fila llena o sin nodo de fila: esperar donde está (comportamiento viejo)
		_nombre_fila = ""
		_slot_fila = -1
		_esperando_pedido = true
		velocity = Vector2.ZERO
		add_to_group("cliente_esperando")
		_mostrar_globo(true)
		var s = _get_sprite_activo()
		if s:
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
	if _nombre_fila == "" or _slot_fila <= 0 or _moviendose_en_fila:
		return
	_tiempo_chequeo_fila -= delta
	if _tiempo_chequeo_fila > 0.0:
		return
	_tiempo_chequeo_fila = 0.3
	if _slot_ocupado(_nombre_fila, _slot_fila - 1):
		return
	# Avanzar un puesto
	_slot_fila -= 1
	var escena = get_tree().current_scene
	_destino_mostrador = _posicion_slot(escena, _nombre_fila, _slot_fila)
	_moviendose_en_fila = true
	_esperando_pedido = false
	remove_from_group("cliente_esperando")
	_mostrar_globo(false)


# El cliente entra por el FONDO (slot más alto = Fila3) y de ahí avanza
# puesto por puesto (Fila3 -> Fila2 -> Fila1 -> Fila0) a medida que se liberan.
# En Fila0 espera a ser atendido. Devuelve -1 si la fila está llena.
func _pedir_slot_libre() -> int:
	var escena = get_tree().current_scene
	if escena == null or _nombre_fila == "":
		return -1
	var fila = escena.get_node_or_null(_nombre_fila)
	if fila == null:
		return -1
	var slots := _hijos_marker_ordenados(fila)
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
