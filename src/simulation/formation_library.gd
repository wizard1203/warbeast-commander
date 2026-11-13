class_name FormationLibrary
extends RefCounted

const MEMBER_COUNT := 8

const STEADY := "STEADY"
const MARCH_COLUMN := "MARCH_COLUMN"
const WIDE_LINE := "WIDE_LINE"
const DISPERSED := "DISPERSED"
const ALL := [STEADY, MARCH_COLUMN, WIDE_LINE, DISPERSED]

const FACING_NORTH := "NORTH"
const FACING_EAST := "EAST"
const FACING_SOUTH := "SOUTH"
const FACING_WEST := "WEST"
const CARDINAL_FACINGS := [FACING_NORTH, FACING_EAST, FACING_SOUTH, FACING_WEST]


static func is_valid(formation: String) -> bool:
	return formation in ALL


static func is_valid_facing(facing: String) -> bool:
	return facing in CARDINAL_FACINGS


static func get_local_slots(formation: String) -> Array[Vector2i]:
	var slots: Array[Vector2i] = []
	match formation:
		STEADY:
			slots.assign([
				Vector2i(-24, -24), Vector2i(0, -24), Vector2i(24, -24), Vector2i(48, -24),
				Vector2i(-24, 24), Vector2i(0, 24), Vector2i(24, 24), Vector2i(48, 24),
			])
		MARCH_COLUMN:
			slots.assign([
				Vector2i(-54, -12), Vector2i(-54, 12),
				Vector2i(-18, -12), Vector2i(-18, 12),
				Vector2i(18, -12), Vector2i(18, 12),
				Vector2i(54, -12), Vector2i(54, 12),
			])
		WIDE_LINE:
			slots.assign([
				Vector2i(0, -84), Vector2i(0, -60), Vector2i(0, -36), Vector2i(0, -12),
				Vector2i(0, 12), Vector2i(0, 36), Vector2i(0, 60), Vector2i(0, 84),
			])
		DISPERSED:
			slots.assign([
				Vector2i(-48, -48), Vector2i(0, -60), Vector2i(48, -42), Vector2i(66, 0),
				Vector2i(42, 54), Vector2i(-6, 66), Vector2i(-60, 42), Vector2i(-66, -6),
			])
	return slots


static func transform_offset(offset: Vector2i, facing: String) -> Vector2i:
	match facing:
		FACING_NORTH:
			return Vector2i(offset.y, -offset.x)
		FACING_SOUTH:
			return Vector2i(-offset.y, offset.x)
		FACING_WEST:
			return Vector2i(-offset.x, -offset.y)
		_:
			return offset


static func get_world_slots(formation: String, anchor: Vector2i, facing: String) -> Array[Vector2i]:
	var world_slots: Array[Vector2i] = []
	for offset: Vector2i in get_local_slots(formation):
		world_slots.append(anchor + transform_offset(offset, facing))
	return world_slots
