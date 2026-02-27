extends Control

var current_draw: int = 0

@onready var drawing: Sprite2D = $Drawing
@onready var brushPath = preload("res://Assets/Brush.png")

var image: Image
var texture: ImageTexture
var brushImage: Image

var is_drawing: bool = false

var stroke_points: Array[Vector2i]

func _ready() -> void:
	image = Image.create(400, 400, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	texture = ImageTexture.create_from_image(image)
	drawing.texture = texture
	
	brushImage = brushPath.get_image()

var last_mouse_pos: Vector2i
func _process(_delta: float) -> void:
	var mouse_pos = Vector2i(round(get_viewport().get_mouse_position()-drawing.position/2.35))
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		is_drawing = true
		
		if last_mouse_pos.distance_squared_to(mouse_pos) > 8:
			paint_line(last_mouse_pos, mouse_pos)
		else:
			paint(mouse_pos)
		
		last_mouse_pos = mouse_pos
		
		if stroke_points.is_empty() or stroke_points.back().distance_to(mouse_pos) > 5:
			stroke_points.append(mouse_pos)
	elif is_drawing:
		is_drawing = false
		
		if stroke_points.size() > 10:
			recognize_and_save_shape(stroke_points)
		stroke_points.clear()
		image.fill(Color.WHITE)
	else:
		last_mouse_pos = mouse_pos

func paint(where: Vector2i):
	image.blend_rect(brushImage, brushImage.get_used_rect(), Vector2i(where)-brushImage.get_used_rect().size/2)
	texture.update(image)

func paint_line(from: Vector2, to: Vector2):
	paint(from)
	while from != to:
		from = from.move_toward(to, 6)
		paint(Vector2i(from))

const NUM_POINTS = 64
const SQUARE_SIZE = 250.0

func process_stroke(points: Array[Vector2i]) -> Array[Vector2i]:
	var resampled = resample(points, NUM_POINTS)
	var translated = translate_to_origin(resampled)
	var scaled = scale_to_square(translated, SQUARE_SIZE)
	return scaled

func resample(points: Array[Vector2i], n: int) -> Array[Vector2i]:
	if points.size() < 2:
		return points.duplicate()
		
	var interval_length = path_length(points) / (n - 1)
	
	if interval_length <= 0.001: 
		var tiny_arr: Array[Vector2i] = []
		for j in range(n):
			tiny_arr.append(points[0])
		return tiny_arr
	
	var D = 0.0
	var new_points: Array[Vector2i] = [points[0]]
	var i = 1
	
	var working_points = points.duplicate()
	
	while i < working_points.size():
		var d = working_points[i-1].distance_to(working_points[i])
		if D + d >= interval_length:
			var ratio = (interval_length - D) / d if d > 0 else 0.0
			var qx = round(working_points[i-1].x + ratio * (working_points[i].x - working_points[i-1].x))
			var qy = round(working_points[i-1].y + ratio * (working_points[i].y - working_points[i-1].y))
			var q = Vector2i(qx, qy)
			
			new_points.append(q)
			working_points.insert(i, q)
			D = 0.0
			i += 1
		else:
			D += d
			i += 1
	while new_points.size() < n:
		new_points.append(working_points.back())
		
	return new_points

func path_length(points: Array[Vector2i]) -> float:
	var d = 0.0
	for i in range(1, points.size()):
		d += points[i-1].distance_to(points[i])
	return d

func translate_to_origin(points: Array[Vector2i]) -> Array[Vector2i]:
	var centroid = Vector2i.ZERO
	for p in points:
		centroid += p
	centroid /= points.size()
	
	var new_points: Array[Vector2i] = []
	for p in points:
		new_points.append(p - centroid)
	return new_points

func scale_to_square(points: Array[Vector2i], _size: float) -> Array[Vector2i]:
	var min_x = INF; var max_x = -INF
	var min_y = INF; var max_y = -INF
	
	for p in points:
		min_x = min(min_x, p.x); max_x = max(max_x, p.x)
		min_y = min(min_y, p.y); max_y = max(max_y, p.y)
	
	var width = max_x - min_x
	var height = max_y - min_y
	
	var new_points: Array[Vector2i] = []
	for p in points:
		var qx = p.x * (_size / width) if width != 0 else p.x
		var qy = p.y * (_size / height) if height != 0 else p.y
		new_points.append(Vector2i(qx, qy))
	return new_points

var last_points: Array
func recognize_and_save_shape(points: Array[Vector2i]):
	var processed_points = process_stroke(points)
	last_points = processed_points

func _on_finish_button_pressed() -> void:
	if last_points.size() < 1: return
	
	Templates.add_new_spell(current_draw, last_points)
	
	current_draw += 1
	if Templates.spell_resources.size() <= current_draw:
		get_tree().change_scene_to_file("res://Scenes/world.tscn")
