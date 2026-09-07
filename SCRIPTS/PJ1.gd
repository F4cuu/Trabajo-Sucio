extends CharacterBody2D


const SPEED = 400.0
const BASURA_VELOCIDAD: float = 700.0

var _b_presionada := false
var _c_presionada := false
var _v_presionada := false
var basura_sostenida: Node = null
var ultima_direccion: Vector2 = Vector2.RIGHT
var esta_revoleando: bool = false
var _revolear_tiempo: float = 0.0


func _ready() -> void:
	$AnimatedSprite2D.animation_finished.connect(_on_anim_finished)

func _physics_process(delta: float) -> void:
	if esta_revoleando:
		_revolear_tiempo += delta
		if $AnimatedSprite2D.animation != &"REVOLEAR BASURA" or not $AnimatedSprite2D.is_playing() or _revolear_tiempo > 0.5:
			esta_revoleando = false
			_revolear_tiempo = 0.0
		else:
			velocity = Vector2.ZERO
			move_and_slide()
			return

	# Input manual sin InputMap/deadzone para evitar que get_vector caiga a 0 por deadzone 0.5
	var raw := Vector2(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	)
	var direction := Vector2.ZERO
	if raw != Vector2.ZERO:
		direction = raw.normalized()
		ultima_direccion = direction
	if direction != Vector2.ZERO:
		velocity = direction * SPEED
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED * delta * 8.0)
		if velocity.length() < 5.0:
			velocity = Vector2.ZERO

	if direction.x != 0:
		$AnimatedSprite2D.flip_h = direction.x < 0
	elif ultima_direccion.x != 0:
		$AnimatedSprite2D.flip_h = ultima_direccion.x < 0

	move_and_slide()

	var limpiando := Input.is_physical_key_pressed(KEY_B)
	if limpiando and not _b_presionada:
		var v = _get_ventana_sucia_cercana()
		if v:
			v.limpiar()
			get_tree().call_group("puntuacion", "agregar_puntos", 20)
		else:
			get_tree().call_group("puntuacion", "agregar_puntos", 10)
	_b_presionada = limpiando

	var v_ahora := Input.is_physical_key_pressed(KEY_V)
	if v_ahora and not _v_presionada:
		if basura_sostenida == null:
			var b = _get_basura_cercana()
			if b:
				_sostener_basura(b)
		else:
			_soltar_basura()
	_v_presionada = v_ahora

	var c_ahora := Input.is_physical_key_pressed(KEY_C)
	if c_ahora and not _c_presionada:
		if basura_sostenida != null and not esta_revoleando:
			esta_revoleando = true
			_revolear_tiempo = 0.0
			$AnimatedSprite2D.play("REVOLEAR BASURA")
			if has_node("SonidoRevolear"):
				$SonidoRevolear.play()
			_arrojar_basura()
	_c_presionada = c_ahora

	# if esta_revoleando:
	# 	return
	var anim := ""
	if basura_sostenida != null:
		anim = "CORRER BASURA" if direction != Vector2.ZERO else "IDLE BASURA"
	elif limpiando:
		anim = "LIMPIAR"
	elif direction != Vector2.ZERO:
		anim = "CORRER"
	else:
		anim = "IDLE"
	if $AnimatedSprite2D.animation != StringName(anim):
		$AnimatedSprite2D.play(anim)


func _get_basura_cercana() -> Node:
	var mejor: Node = null
	var mejor_dist := 80.0
	for b in get_tree().get_nodes_in_group("basura"):
		if not is_instance_valid(b):
			continue
		if b.is_ancestor_of(self) or is_ancestor_of(b):
			continue
		if b.has_method("es_proyectil") and b.es_proyectil():
			continue
		var d = global_position.distance_to(b.global_position)
		if d < mejor_dist:
			mejor = b
			mejor_dist = d
	return mejor

func _get_ventana_sucia_cercana() -> Node:
	var mejor: Node = null
	var mejor_dist := 100.0
	for w in get_tree().get_nodes_in_group("ventana1"):
		if not is_instance_valid(w):
			continue
		if not w.get("esta_sucia"):
			continue
		var d = global_position.distance_to(w.global_position)
		if d < mejor_dist:
			mejor = w
			mejor_dist = d
	return mejor


func _sostener_basura(b: Node) -> void:
	basura_sostenida = b
	var parent = b.get_parent()
	if parent:
		parent.remove_child(b)
	add_child(b)
	b.position = Vector2(-18, -45)
	if b.has_node("CollisionShape2D"):
		b.get_node("CollisionShape2D").set_deferred("disabled", true)
	if b is Area2D:
		b.monitoring = false
		b.monitorable = false
	if b.has_method("set_sostenida"):
		b.set_sostenida(true)


func _soltar_basura() -> void:
	if basura_sostenida == null:
		return
	var b = basura_sostenida
	remove_child(b)
	get_parent().add_child(b)
	var offset := Vector2(40, 20)
	if $AnimatedSprite2D.flip_h:
		offset.x *= -1
	b.global_position = global_position + offset
	if b.has_node("CollisionShape2D"):
		b.get_node("CollisionShape2D").set_deferred("disabled", false)
	if b is Area2D:
		b.monitoring = true
		b.monitorable = true
	if b.has_method("set_sostenida"):
		b.set_sostenida(false)
	basura_sostenida = null


func _arrojar_basura() -> void:
	if basura_sostenida == null:
		esta_revoleando = false
		return
	var b = basura_sostenida
	remove_child(b)
	get_parent().add_child(b)
	b.global_position = global_position + Vector2(-18, -45)
	if b.has_node("CollisionShape2D"):
		b.get_node("CollisionShape2D").set_deferred("disabled", false)
	if b is Area2D:
		b.monitoring = true
		b.monitorable = true
	if b.has_method("lanzar"):
		var dir = ultima_direccion
		if dir == Vector2.ZERO:
			dir = Vector2.RIGHT if not $AnimatedSprite2D.flip_h else Vector2.LEFT
		b.jugador_dueno = 1
		b.lanzar(dir * BASURA_VELOCIDAD)
	elif b.has_method("set_sostenida"):
		b.set_sostenida(false)
	basura_sostenida = null


func _on_anim_finished() -> void:
	if $AnimatedSprite2D.animation == &"REVOLEAR BASURA":
		esta_revoleando = false
		_revolear_tiempo = 0.0
