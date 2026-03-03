extends Control

@onready var drawing: Line2D = $Drawing

var stroke_points: Array[Vector2]
var last_mouse_pos: Vector2
var current_draw: int = 0

func _process(_delta: float) -> void:
	var mouse_pos = Vector2(get_viewport().get_mouse_position()-drawing.position/2.35)
	if is_on_drawing(Vector2(350, 350), Vector2(400, 400), mouse_pos):
		var is_drawing = EventBus.currentState & EventBus.state.DRAW
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if !is_drawing:
				EventBus.currentState |= EventBus.state.DRAW
				stroke_points.clear()
				drawing.clear_points()
			
			if last_mouse_pos.distance_squared_to(mouse_pos) > 8:
				add_line(last_mouse_pos, mouse_pos)
			else:
				add_point(mouse_pos)
			
			last_mouse_pos = mouse_pos
			
			if stroke_points.is_empty() or stroke_points.back().distance_to(mouse_pos) > 4:
				stroke_points.append(mouse_pos)
		elif is_drawing:
			EventBus.currentState &= ~EventBus.state.DRAW
			
			if stroke_points.size() > 10:
				stroke_points = process_stroke(stroke_points)
		else:
			last_mouse_pos = mouse_pos

func is_on_drawing(drawing_pos: Vector2, drawing_size: Vector2, mouse_pos: Vector2) -> bool:
	var left_up_pos = drawing_pos - drawing_size/2
	var right_down_pos = drawing_pos + drawing_size/2
	
	var inleftup = true if mouse_pos.x > left_up_pos.x and mouse_pos.y > left_up_pos.y else false
	var inrightdown = true if mouse_pos.x < right_down_pos.x and mouse_pos.y < right_down_pos.y else false
	
	return true if inleftup and inrightdown else false

func add_point(where: Vector2):
	drawing.add_point(where)

func add_line(from: Vector2, to: Vector2):
	add_point(from)
	while from != to:
		from = from.move_toward(to, 6)
		add_point(from)

const NUM_POINTS = 64
const SQUARE_SIZE = 250.0

func process_stroke(points: Array[Vector2]) -> Array[Vector2]:
	var resampled = resample(points, NUM_POINTS)
	var translated = translate_to_origin(resampled)
	var scaled = scale_to_square(translated, SQUARE_SIZE)
	return scaled

func resample(points: Array[Vector2], n: int) -> Array[Vector2]:
	if points.size() < 2:
		return points.duplicate()
	
	var interval_length = path_length(points) / (n - 1)
	
	if interval_length <= 0.001: 
		var tiny_arr: Array[Vector2] = []
		for j in range(n):
			tiny_arr.append(points[0])
		return tiny_arr
	
	var D = 0.0
	var new_points: Array[Vector2] = [points[0]]
	var i = 1
	
	var working_points = points.duplicate()
	
	while i < working_points.size():
		var d = working_points[i-1].distance_to(working_points[i])
		if D + d >= interval_length:
			var ratio = (interval_length - D) / d if d > 0 else 0.0
			var qx = round(working_points[i-1].x + ratio * (working_points[i].x - working_points[i-1].x))
			var qy = round(working_points[i-1].y + ratio * (working_points[i].y - working_points[i-1].y))
			var q = Vector2(qx, qy)
			
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

func path_length(points: Array[Vector2]) -> float:
	var d = 0.0
	for i in range(1, points.size()):
		d += points[i-1].distance_to(points[i])
	return d

func translate_to_origin(points: Array[Vector2]) -> Array[Vector2]:
	var centroid = Vector2.ZERO
	for p in points:
		centroid += p
	centroid /= points.size()
	
	var new_points: Array[Vector2] = []
	for p in points:
		new_points.append(p - centroid)
	return new_points

func scale_to_square(points: Array[Vector2], _size: float) -> Array[Vector2]:
	var min_x = INF; var max_x = -INF
	var min_y = INF; var max_y = -INF
	
	for p in points:
		min_x = min(min_x, p.x); max_x = max(max_x, p.x)
		min_y = min(min_y, p.y); max_y = max(max_y, p.y)
	
	var width = max_x - min_x
	var height = max_y - min_y
	
	var new_points: Array[Vector2] = []
	for p in points:
		var qx = p.x * (_size / width) if width != 0 else p.x
		var qy = p.y * (_size / height) if height != 0 else p.y
		new_points.append(Vector2(qx, qy))
	return new_points

func _on_finish_button_pressed() -> void:
	if stroke_points.size() <= 10: return
	
	var current_spell_name = Templates.add_new_spell(current_draw, stroke_points.duplicate())
	stroke_points.clear()
	drawing.clear_points()
	
	current_draw += 1
	if !current_spell_name:
		get_tree().change_scene_to_file("res://Scenes/world.tscn")
		return
	
	get_parent().get_node("Label").text = current_spell_name
