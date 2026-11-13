extends RefCounted
## The closed four participant identities are independent of faction materials.
const COLORS := {"PLAYER":Color("e9c447"), "AI":Color("dc4d76"), "AI_2":Color("b493e4"), "AI_3":Color("91c66c")}
static func side_color(id: String) -> Color:
	return COLORS.get(id, Color("a9b29c"))
static func side_label(id: String) -> String:
	return str({"PLAYER":"玩家 1", "AI":"玩家 2", "AI_2":"玩家 3", "AI_3":"玩家 4"}.get(id, "中立"))
