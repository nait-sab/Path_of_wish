class_name ToolTipHelper extends RefCounted

static func rarity_color(rarity: Item.Rarity) -> Color:
	match rarity:
		Item.Rarity.NORMAL: return Color.WHITE
		Item.Rarity.MAGIC: 	return Color(.3, .5, 1)
		Item.Rarity.RARE: 	return Color(1, 1, .3)
		Item.Rarity.UNIQUE: return Color(1, .5, .1)
		_: 					return Color.WHITE

static func tags_to_strings(tags: Array, tags_ignored: Array = []) -> String:
	var list = []
	for tag in tags:
		if tags_ignored.has(tag):
			continue
		if typeof(tag) == TYPE_STRING:
			list.append(tag.capitalize())
		elif typeof(tag) == TYPE_INT:
			list.append(str(Item.Tag.keys()[tag]).capitalize())
	return " / ".join(list)

static func convert_comma_decimal(value: float) -> String:
	return "%s" % String.num(value, 2).replace(".", ",") 
