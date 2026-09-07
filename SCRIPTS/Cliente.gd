extends CharacterBody2D

@export var velocidad: float = 120.0
@export var direccion_vertical: int = 1

var _en_pausa: bool = false
var _tiempo_pausa: float = 0.0
var _tiempo_chequeo: float = 0.0
var _muerto: bool = false
var _usar_segundo_sprite: bool = false

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
