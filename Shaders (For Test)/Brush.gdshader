shader_type canvas_item;

void vertex() {
	float x = sin(VERTEX.x * TIME);
	float y = sin(VERTEX.y * TIME);
	
	VERTEX.x += x;
	VERTEX.y += y;
}

void fragment() {
	vec4 sd = COLOR;
	float ds = (sin(TIME*0.7)+8.0)/10.0;
	COLOR = vec4(sd.x * ds, sd.y * ds, sd.z * ds, sd.a * ds);
}
