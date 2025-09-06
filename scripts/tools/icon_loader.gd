class_name IconLoader extends RefCounted

const PLACEHOLDER: Texture2D = preload("res://assets/textures/ui/skill_slot/skill_placeholder.png")

static func load_skill_icon(skill_id: String) -> Texture2D:
	if skill_id == "":
		return PLACEHOLDER
	var path := "res://assets/textures/skills/%s.png" % skill_id
	if ResourceLoader.exists(path, "Texture2D"):
		return load(path) as Texture2D
	return PLACEHOLDER
