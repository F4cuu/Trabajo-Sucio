extends CharacterBody2D


const SPEED = 400.0
const BASURA_VELOCIDAD: float = 700.0

var _b_presionada := false
var _o_presionada := false
var _p_presionada := false
var basura_sostenida: Node = null
var ultima_direccion: Vector2 = Vector2.RIGHT
var esta_revoleando: bool = false


func _ready() -> void:
	$AnimatedSprite2D.animation_finished.connect(_on_anim_finished)


func _physics_process(delta: float) -> void:
	if esta_revoleando:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direction := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_UP):
		direction.y -= 1
	if Input.is_physical_key_pressed(KEY_DOWN):
		direction.y += 1
	if Input.is_physical_key_pressed(KEY_LEFT):
		direction.x -= 1
	if Input.is_physical_key_pressed(KEY_RIGHT):
		direction.x += 1
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		ultima_direccion = direction
	if direction != Vector2.ZERO:
		velocity = direction * SPEED
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED)

	if direction.x != 0:
		$AnimatedSprite2D.flip_h = direction.x < 0
	elif ultima_direccion.x != 0:
		$AnimatedSprite2D.flip_h = ultima_direccion.x < 0

	move_and_slide()

	var limpiando := Input.is_physical_key_pressed(KEY_I)
	if limpiando and not _b_presionada:
		get_tree().call_group("puntuacion_pj2", "agregar_puntos", 10)
	_b_presionada = limpiando

	var o_ahora := Input.is_physical_key_pressed(KEY_O)
	if o_ahora and not _o_presionada:
		if basura_sostenida == null:
			var b = _get_basura_cercana()
			if b:
				_sostener_basura(b)
		else:
			_soltar_basura()
	_o_presionada = o_ahora

	var p_ahora := Input.is_physical_key_pressed(KEY_P)
	if p_ahora and not _p_presionada:
		if basura_sostenida != null and not esta_revoleando:
			esta_revoleando = true
			$AnimatedSprite2D.play("REVOLEAR BASURA")
			if has_node("SonidoRevolear"):
				$SonidoRevolear.play()
			_arrojar_basura()
	_p_presionada = p_ahora

	if esta_revoleando:
		return
	if basura_sostenida != null:
		if direction:
			$AnimatedSprite2D.play("CORRER BASURA")
		else:
			$AnimatedSprite2D.play("IDLE BASURA")
	elif limpiando:
		$AnimatedSprite2D.play("LIMPIAR")
	elif direction:
		$AnimatedSprite2D.play("CORRER")
	else:
		$AnimatedSprite2D.play("IDLE")


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


func _sostener_basura(b: Node) -> void:
	basura_sostenida = b
	var parent = b.get_parent()
	if parent:
		parent.remove_child(b)
	add_child(b)
	b.position = Vector2(15, -20)
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
	b.global_position = global_position + Vector2(15, -20)
	if b.has_node("CollisionShape2D"):
		b.get_node("CollisionShape2D").set_deferred("disabled", false)
	if b is Area2D:
		b.monitoring = true
		b.monitorable = true
	if b.has_method("lanzar"):
		var dir = ultima_direccion
		if dir == Vector2.ZERO:
			dir = Vector2.RIGHT if not $AnimatedSprite2D.flip_h else Vector2.LEFT
		b.jugador_dueno = 2
		b.lanzar(dir * BASURA_VELOCIDAD)
	elif b.has_method("set_sostenida"):
		b.set_sostenida(false)
	basura_sostenida = null


func _on_anim_finished() -> void:
	if $AnimatedSprite2D.animation == &"REVOLEAR BASURA":
		esta_revoleando = false
