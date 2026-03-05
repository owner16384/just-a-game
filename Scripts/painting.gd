extends Control

@onready var drawing: Line2D = $Drawing
@onready var calculate_shape: Calculate_Shape = $calculate_shape

var stroke_points: Array[Vector2]
var current_draw: int = 0

func _process(_delta: float) -> void:
	# a formula of the finding mouse position
	var mouse_pos = Vector2(get_viewport().get_mouse_position()-drawing.position/2.35)
	
	if is_on_drawing(Vector2(350, 350), Vector2(400, 400), mouse_pos):
		var is_drawing = EventBus.currentState & EventBus.state.DRAW
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if !is_drawing:
				EventBus.currentState |= EventBus.state.DRAW
				stroke_points.clear()
				drawing.clear_points()
			
			add_point(mouse_pos)
			
			if stroke_points.is_empty() or stroke_points.back().distance_to(mouse_pos) > 4:
				stroke_points.append(mouse_pos)
		elif is_drawing:
			EventBus.currentState &= ~EventBus.state.DRAW
			
			if stroke_points.size() > 10:
				stroke_points = calculate_shape.process_stroke(stroke_points)

func is_on_drawing(drawing_pos: Vector2, drawing_size: Vector2, mouse_pos: Vector2) -> bool:
	# checks if mouse is on drawing
	
	var left_up_pos = drawing_pos - drawing_size/2
	var right_down_pos = drawing_pos + drawing_size/2
	
	var inleftup = true if mouse_pos.x > left_up_pos.x and mouse_pos.y > left_up_pos.y else false
	var inrightdown = true if mouse_pos.x < right_down_pos.x and mouse_pos.y < right_down_pos.y else false
	
	return true if inleftup and inrightdown else false

func add_point(where: Vector2): # adds a point
	drawing.add_point(where)

func _on_finish_button_pressed() -> void:
	if stroke_points.size() <= 10: return
	# if finish button pressed attach the coordinates to the new spellmanager resource
	
	var current_spell_name = Templates.add_new_spell(current_draw, stroke_points.duplicate())
	stroke_points.clear()
	drawing.clear_points()
	
	current_draw += 1
	if !current_spell_name:
		get_tree().change_scene_to_file("res://Scenes/world.tscn")
		return
	
	get_parent().get_node("Label").text = current_spell_name
