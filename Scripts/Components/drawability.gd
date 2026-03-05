class_name drawability
extends Node3D

@export var mouse_sensitivity: float = 2
@export var pen_sensitivity: float = 5
@export var max_pen_distance: float = 500
@export var pen_offset: Vector3 = Vector3(0.5, 0.5, -1)

@onready var pen: MeshInstance3D = $Pen

var stroke_points: Array[Vector2] = []
var stroke_points_3d: Array[Vector3] = []

var current_mesh: MeshInstance3D
var deleting_meshes: Array[MeshInstance3D]

var mouse_pos: Vector2 = Vector2.ZERO
var mouse_pos_3d: Vector3 = Vector3.ZERO

func _ready() -> void:
	await get_tree().create_timer(0).timeout
	create_new_mesh()

func create_new_mesh():
	EventBus.emit_signal("create_new_mesh", get_mesh as Callable)

func get_mesh(new_mesh):
	current_mesh = new_mesh

func _process(delta: float) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		left_clicked()
	elif EventBus.currentState & EventBus.state.DRAW:
		left_released()
	
	pen.position = pen.position.lerp(mouse_pos_3d, pen_sensitivity * delta)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_pos += event.relative * mouse_sensitivity
		if mouse_pos.length() > max_pen_distance:
			mouse_pos = mouse_pos.normalized() * max_pen_distance
		
		mouse_pos_3d = Vector3(mouse_pos.x, -mouse_pos.y, 0)/800 + pen_offset

func left_clicked():
	EventBus.currentState |= EventBus.state.DRAW
	
	if stroke_points.is_empty() or stroke_points.back().distance_to(mouse_pos) > 5:
		stroke_points.append(mouse_pos)
	
	stroke_points_3d.append(pen.global_position-pen.global_basis.z*0.4)
	if current_mesh:
		redraw_mesh(current_mesh.mesh, stroke_points_3d.duplicate())

func left_released():
	EventBus.currentState &= ~EventBus.state.DRAW
	
	if stroke_points.size() > 10:
		recognize_shape(stroke_points)
	stroke_points.clear()
	
	delete_mesh(current_mesh, stroke_points_3d.duplicate())
	current_mesh = null
	create_new_mesh()
	stroke_points_3d.clear()

func delete_mesh(meshins, points):
	if deleting_meshes.has(meshins): return # checks if it isn't deleting currently
	deleting_meshes.append(meshins)
	
	var mesh: ImmediateMesh = meshins.mesh
	
	# this gives a simple tail animation
	for i in points.size():
		points.pop_front()
		
		redraw_mesh(mesh, points.duplicate())
		
		await get_tree().create_timer(0.0).timeout
	
	deleting_meshes.erase(meshins) # delete from list (if this is not, it keeps be in list like "<Freed Object>")
	meshins.queue_free() # delete from scene simply

func redraw_mesh(mesh, points):
	
	mesh.clear_surfaces()
	if points.size() < 1: return
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in points:
		mesh.surface_add_vertex(i)
	mesh.surface_end()

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

func scale_to_square(points: Array[Vector2], size: float) -> Array[Vector2]:
	var min_x = INF; var max_x = -INF
	var min_y = INF; var max_y = -INF
	
	for p in points:
		min_x = min(min_x, p.x); max_x = max(max_x, p.x)
		min_y = min(min_y, p.y); max_y = max(max_y, p.y)
	
	var width = max_x - min_x
	var height = max_y - min_y
	
	var new_points: Array[Vector2] = []
	for p in points:
		var qx = p.x * (size / width) if width != 0 else p.x
		var qy = p.y * (size / height) if height != 0 else p.y
		new_points.append(Vector2(qx, qy))
	return new_points

func recognize_shape(points: Array[Vector2]):
	var processed_points = process_stroke(points)
	var best_match: SpellManager = null
	var best_score = INF
	
	for template in Templates.spells:
		var score = compare_paths(processed_points, template.get_coords())
		
		if score < best_score:
			best_score = score
			best_match = template
	
	if best_match:
		$"../UI -- For Just Test/Last_Spell_Label".text = best_match.get_spell().name
	
	stroke_points.clear()

func compare_paths(path1: Array[Vector2], path2: Array[Vector2]) -> float:
	var total_distance = 0.0
	for i in range(min(path1.size(), path2.size())):
		total_distance += path1[i].distance_to(path2[i])
	return total_distance / path1.size()
