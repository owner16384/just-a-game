class_name drawability
extends Node3D

# Custom Settings
@export var mouse_sensitivity: float = 2
@export var pen_sensitivity: float = 5
@export var max_pen_distance: float = 500
@export var pen_offset: Vector3 = Vector3(0.5, 0.5, -1)

@onready var pen: MeshInstance3D = $Pen
@onready var calculate_shape: Calculate_Shape = $calculate_shape

var stroke_points: Array[Vector2] = [] # Keeps 2d positions
var stroke_points_3d: Array[Vector3] = [] # Keeps 3d positions for the mesh

var current_mesh: MeshInstance3D
var deleting_meshes: Array[MeshInstance3D]

var mouse_pos: Vector2 = Vector2.ZERO
var mouse_pos_3d: Vector3 = Vector3.ZERO # 3D mouse position for the pen

func _ready() -> void:
	await get_tree().create_timer(0).timeout # wait for the world to be ready
	create_new_mesh()

func create_new_mesh():
	# emit a create mesh signal and bind a callable function
	EventBus.emit_signal("create_new_mesh", func(new_mesh): current_mesh = new_mesh)

func _process(delta: float) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): # call it every time when left mouse pressed
		left_clicked()
	elif EventBus.currentState & EventBus.state.DRAW: # Call it one time when mouse released
		left_released()
	
	pen.position = pen.position.lerp(mouse_pos_3d, pen_sensitivity * delta)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_pos += event.relative * mouse_sensitivity
		if mouse_pos.length() > max_pen_distance: # It applys limit for the mouse pos but in circle shape (Not Rectangle)
			mouse_pos = mouse_pos.normalized() * max_pen_distance
		
		mouse_pos_3d = Vector3(mouse_pos.x, -mouse_pos.y, 0)/800 + pen_offset

func left_clicked():
	EventBus.currentState |= EventBus.state.DRAW # Add draw state to the current state (It works on binary)
	
	if stroke_points.is_empty() or stroke_points.back().distance_to(mouse_pos) > 5:
		stroke_points.append(mouse_pos)
	
	stroke_points_3d.append(pen.global_position-pen.global_basis.z*0.4)
	if current_mesh:
		redraw_mesh(current_mesh.mesh, stroke_points_3d.duplicate())

func left_released():
	EventBus.currentState &= ~EventBus.state.DRAW # Remove the draw state from the current state (&= ~)
	
	if stroke_points.size() > 10:
		recognize_shape(stroke_points)
	stroke_points.clear()
	
	delete_mesh(current_mesh, stroke_points_3d.duplicate()) # be serious, we bind the duplicate
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
	# Simple, we draw the mesh in every frame
	mesh.clear_surfaces()
	if points.size() < 1: return
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in points:
		mesh.surface_add_vertex(i)
	mesh.surface_end()

func recognize_shape(points: Array[Vector2]):
	var processed_points = calculate_shape.process_stroke(points) # get the true point list
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

func compare_paths(path1: Array[Vector2], path2: Array[Vector2]) -> float: # Returns a ratio
	var total_distance = 0.0
	for i in range(min(path1.size(), path2.size())):
		total_distance += path1[i].distance_to(path2[i])
	return total_distance / path1.size()
