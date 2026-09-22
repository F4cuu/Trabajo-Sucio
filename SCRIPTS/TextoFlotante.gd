class_name TextoFlotante
extends Node2D

## Muestra un "+N" o "-N" amarillo que flota hacia arriba y se desvanece.
## Llamar con: TextoFlotante.mostrar(escena, posicion_mundo, cantidad)
static func mostrar(en_escena: Node, pos_mundo: Vector2, cantidad: int) -> void:
	if cantidad == 0:
		return
	if en_escena == null:
		return

	var contenedor := Node2D.new()
	contenedor.z_index = 200
	contenedor.z_as_relative = false
	# Pequeño desplazamiento aleatorio para que varios textos no se apilen
	contenedor.position = pos_mundo + Vector2(randf_range(-12.0, 12.0), 0.0)
	en_escena.add_child(contenedor)

	var etiqueta := Label.new()
	if cantidad > 0:
		etiqueta.text = "+%d" % cantidad
	else:
		etiqueta.text = "%d" % cantidad # ya incluye el signo "-"
	etiqueta.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	etiqueta.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	etiqueta.add_theme_constant_override("outline_size", 6)
	etiqueta.add_theme_font_size_override("font_size", 20)
	var fuente = load("res://FONTS/PressStart2P-Regular.ttf")
	if fuente is Font:
		etiqueta.add_theme_font_override("font", fuente)
	# Centrar el texto sobre el punto de aparición
	etiqueta.position = Vector2(-40.0, -20.0)
	etiqueta.size = Vector2(80.0, 40.0)
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiqueta.z_index = 200
	etiqueta.z_as_relative = false
	contenedor.add_child(etiqueta)

	# Flota hacia arriba y se desvanece en 1 segundo
	var tween := contenedor.create_tween()
	tween.set_parallel(true)
	tween.tween_property(contenedor, "position:y", contenedor.position.y - 70.0, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(etiqueta, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_LINEAR).set_delay(0.25)
	tween.chain().tween_callback(contenedor.queue_free)
