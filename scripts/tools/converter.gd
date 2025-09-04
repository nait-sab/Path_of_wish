class_name Converter extends Node

static func convert_value_to_vector2i(value: Variant, default: Vector2i) -> Vector2i:
	if typeof(value) == TYPE_VECTOR2I:
		return value
	
	if typeof(value) == TYPE_ARRAY and value.size() == 2:
		return Vector2i(int(value[0]), int(value[1]))
	
	if typeof(value) == TYPE_STRING:
		var string := (value as String).strip_edges()
		string = string.replace("(", "").replace(")", "").replace(" ", "")
		var parts := string.split(",", false)
		if parts.size() == 2 and parts[0].is_valid_int() and parts[1].is_valid_int():
			return Vector2i(int(parts[0]), int(parts[1]))
		parts = string.split("x", false)
		if parts.size() == 2 and parts[0].is_valid_int() and parts[1].is_valid_int():
			return Vector2i(int(parts[0]), int(parts[1]))
	
	return default
