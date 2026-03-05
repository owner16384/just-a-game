class_name Calculate_Shape
extends Node

const NUM_POINTS: int = 64
const SQUARE_SIZE: int = 250

func process_stroke(points: Array[Vector2]) -> Array[Vector2]: # Core Of The Calculating
	var resampled = resample(points, NUM_POINTS)
	var translated = translate_to_origin(resampled)
	var scaled = scale_to_square(translated, SQUARE_SIZE)
	return scaled

func resample(points: Array[Vector2], numpoints: int) -> Array[Vector2]: # Returns a 64 point list
	if points.size() < 2:
		return points.duplicate() # Duplicate() bcs we don't want to change original one
	
	var interval_length = path_length(points) / (numpoints - 1)
	
	if interval_length <= 0.001:
		# if distance between points is small return the first 64 point
		var tiny_arr: Array[Vector2] = []
		for i in range(numpoints):
			tiny_arr.append(points[0])
		return tiny_arr
	
	var D = 0.0
	var new_points: Array[Vector2] = [points[0]]
	var i = 1
	
	var working_points = points.duplicate()
	
	while i < working_points.size():
		var d = working_points[i-1].distance_to(working_points[i])
		if D + d >= interval_length:
			# If distance from the last edit to the point i bigger than the interval_length, 
			var ratio = (interval_length - D) / d if d > 0 else 0.0
			var qx = working_points[i-1].x + ratio * (working_points[i].x - working_points[i-1].x) # x + ratio * difference between x 
			var qy = working_points[i-1].y + ratio * (working_points[i].y - working_points[i-1].y) # y + ratio * difference between y 
			var q = Vector2(qx, qy)
			
			new_points.append(q)
			working_points.insert(i, q)
			D = 0.0
			i += 1
		else:
			D += d
			i += 1
	while new_points.size() < numpoints: # if size of the list bigger than 64 then get the first 64 point of the list
		new_points.append(working_points.back())
	
	return new_points

func path_length(points: Array[Vector2]) -> float: # Returns the length of the path
	var d = 0.0
	for i in range(1, points.size()):
		d += points[i-1].distance_to(points[i])
	return d

func translate_to_origin(points: Array[Vector2]) -> Array[Vector2]: # Lock position to the center
	var centroid = Vector2.ZERO
	for p in points:
		centroid += p
	centroid /= points.size()
	
	var new_points: Array[Vector2] = []
	for p in points:
		new_points.append(p - centroid)
	return new_points

func scale_to_square(points: Array[Vector2], size: float) -> Array[Vector2]:
	# Makes shape scale to 250 static value
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
