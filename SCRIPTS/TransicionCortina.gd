class_name TransicionCortina
extends RefCounted

## Cortina de teatro para cambios de escena: dos paños rojos con pliegues
## que se cierran hacia el medio hasta juntar sus filos dorados al centro.
## La capa vive en root (sobrevive al cambio de escena) para poder abrirse
## del otro lado. Si no hay cortina, abrir() no hace nada.

const NOMBRE := "CortinaTransicion"
const COLOR_TELON := Color(0.48, 0.06, 0.11)
const COLOR_PLIEGUE := Color(0.29, 0.03, 0.07)
const COLOR_SOMBRA := Color(0.12, 0.01, 0.03, 0.6)
const COLOR_FILO := Color(0.88, 0.64, 0.26)
const COLOR_CENEFA := Color(0.36, 0.04, 0.08)
const PLIEGUES := 8


static func cerrar(tree: SceneTree, duracion: float = 1.1) -> void:
	if tree == null or tree.root.get_node_or_null(NOMBRE) != null:
		return
	var layer := CanvasLayer.new()
	layer.name = NOMBRE
	layer.layer = 128
	tree.root.add_child(layer)
	# Paños recogidos en los bordes (ancho cero) que crecen hacia el medio
	var izq := _pano(layer, "Izq", 0.0, 0.0, true)
	var der := _pano(layer, "Der", 1.0, 1.0, false)
	var tw := layer.create_tween().set_parallel(true)
	tw.tween_property(izq, "anchor_right", 0.5, duracion).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(der, "anchor_left", 0.5, duracion).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished


static func abrir(tree: SceneTree, duracion: float = 1.1) -> void:
	if tree == null:
		return
	var layer := tree.root.get_node_or_null(NOMBRE) as CanvasLayer
	if layer == null:
		return
	var izq := layer.get_node_or_null("Izq")
	var der := layer.get_node_or_null("Der")
	if izq == null or der == null:
		layer.queue_free()
		return
	var tw := layer.create_tween().set_parallel(true)
	tw.tween_property(izq, "anchor_right", 0.0, duracion).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(der, "anchor_left", 1.0, duracion).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	if is_instance_valid(layer):
		layer.queue_free()


# Un paño: contenedor transparente con franjas verticales alternadas
# (pliegues de tela), filo dorado en el borde interior, cenefa superior
# y sombra inferior para dar volumen.
static func _pano(layer: CanvasLayer, nombre: String, a_izq: float, a_der: float, filo_derecha: bool) -> Control:
	var p := Control.new()
	p.name = nombre
	# Bloquea clicks mientras la cortina está en pantalla
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(p)
	p.anchor_left = a_izq
	p.anchor_right = a_der
	p.anchor_top = 0.0
	p.anchor_bottom = 1.0
	p.offset_left = 0.0
	p.offset_right = 0.0
	p.offset_top = 0.0
	p.offset_bottom = 0.0
	# Pliegues: franjas verticales que alternan luz y sombra de la tela
	for i in PLIEGUES:
		var f := ColorRect.new()
		f.color = COLOR_TELON if i % 2 == 0 else COLOR_PLIEGUE
		f.mouse_filter = Control.MOUSE_FILTER_IGNORE
		f.anchor_left = float(i) / float(PLIEGUES)
		f.anchor_right = float(i + 1) / float(PLIEGUES)
		f.anchor_top = 0.0
		f.anchor_bottom = 1.0
		p.add_child(f)
	# Cenefa superior: franja con ribete dorado abajo
	var cenefa := ColorRect.new()
	cenefa.color = COLOR_CENEFA
	cenefa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cenefa.anchor_left = 0.0
	cenefa.anchor_right = 1.0
	cenefa.anchor_top = 0.0
	cenefa.anchor_bottom = 0.0
	cenefa.offset_bottom = 46.0
	p.add_child(cenefa)
	var ribete := ColorRect.new()
	ribete.color = COLOR_FILO
	ribete.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ribete.anchor_left = 0.0
	ribete.anchor_right = 1.0
	ribete.anchor_top = 0.0
	ribete.anchor_bottom = 0.0
	ribete.offset_top = 46.0
	ribete.offset_bottom = 52.0
	p.add_child(ribete)
	# Sombra inferior para dar caída a la tela
	var sombra := ColorRect.new()
	sombra.color = COLOR_SOMBRA
	sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sombra.anchor_left = 0.0
	sombra.anchor_right = 1.0
	sombra.anchor_top = 0.86
	sombra.anchor_bottom = 1.0
	p.add_child(sombra)
	# Filo dorado en el borde interior: al cerrarse se juntan al centro
	var filo := ColorRect.new()
	filo.color = COLOR_FILO
	filo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	filo.anchor_top = 0.0
	filo.anchor_bottom = 1.0
	if filo_derecha:
		filo.anchor_left = 1.0
		filo.anchor_right = 1.0
		filo.offset_left = -12.0
		filo.offset_right = 0.0
	else:
		filo.anchor_left = 0.0
		filo.anchor_right = 0.0
		filo.offset_left = 0.0
		filo.offset_right = 12.0
	p.add_child(filo)
	return p
