extends Node3D

@onready var sprite: Sprite2D = $Sprite2D
@onready var pen: MeshInstance3D = $Pen
@onready var brushPath: Texture2D = preload("res://Assets/Brush.png")

var image: Image
var texture: ImageTexture
var brushImage: Image

var stroke_points: Array[Vector2i] = []

func _ready() -> void:
	image = Image.create(1280, 720, false, Image.FORMAT_RGBA8)
	texture = ImageTexture.create_from_image(image)
	sprite.texture = texture
	
	brushImage = brushPath.get_image()

var last_mouse_pos: Vector2i
var timer_has_started: bool = false
var mouse_pos: Vector2 = Vector2.ZERO
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_pos += event.relative
		
		#region clamp mouse pos
		var before_clamp: Vector2 = mouse_pos
		mouse_pos.x = fposmod(mouse_pos.x, 1280)
		mouse_pos.y = fposmod(mouse_pos.y, 720)
		#endregion
		
		if event.button_mask == MOUSE_BUTTON_LEFT:
			EventBus.currentState |= EventBus.state.DRAW
			
			pen.position = pen.position.lerp(Vector3(mouse_pos.x/750, -mouse_pos.y/750, -0.3) - Vector3(0.3, -0.7, 0.0), 0.1)
			
			var interpolation = last_mouse_pos.distance_squared_to(before_clamp)
			if interpolation > 8:
				paint_line(last_mouse_pos, before_clamp)
			else:
				paint(before_clamp)
			
			if stroke_points.is_empty() or stroke_points.back().distance_to(mouse_pos) > 5:
				stroke_points.append(Vector2i(mouse_pos))
		elif EventBus.currentState & EventBus.state.DRAW:
			EventBus.currentState &= ~EventBus.state.DRAW
			
			if stroke_points.size() > 10:
				recognize_shape(stroke_points)
			stroke_points.clear()
		
		last_mouse_pos = Vector2((1280 if mouse_pos.x > before_clamp.x else 0) if mouse_pos.x != before_clamp.x else mouse_pos.x, (720 if mouse_pos.y > before_clamp.y else 0) if mouse_pos.y != before_clamp.y else mouse_pos.y)

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

func scale_to_square(points: Array[Vector2i], size: float) -> Array[Vector2i]:
	var min_x = INF; var max_x = -INF
	var min_y = INF; var max_y = -INF
	
	for p in points:
		min_x = min(min_x, p.x); max_x = max(max_x, p.x)
		min_y = min(min_y, p.y); max_y = max(max_y, p.y)
	
	var width = max_x - min_x
	var height = max_y - min_y
	
	var new_points: Array[Vector2i] = []
	for p in points:
		var qx = p.x * (size / width) if width != 0 else p.x
		var qy = p.y * (size / height) if height != 0 else p.y
		new_points.append(Vector2i(qx, qy))
	return new_points

func recognize_shape(points: Array[Vector2i]):
	var processed_points = process_stroke(points)
	var best_match: SpellManager = null
	var best_score = INF
	
	for template in Templates.spells:
		var score = compare_paths(processed_points, template.coords)
		if score < best_score:
			best_score = score
			best_match = template
	
	if best_match:
		$"../UI -- For Just Test/Last_Spell_Label".text = best_match.get_spell().name
	
	stroke_points.clear()
	image.fill(Color(0, 0, 0, 0))
	texture.update(image)

func compare_paths(path1: Array[Vector2i], path2: Array) -> float:
	var total_distance = 0.0
	for i in range(min(path1.size(), path2.size())):
		total_distance += path1[i].distance_to(path2[i])
	return total_distance / path1.size()
