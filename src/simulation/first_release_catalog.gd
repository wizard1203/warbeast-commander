extends RefCounted
## Edition policy only. Shared content definitions remain unchanged internally.
## No command-line or request field can expand the playable faction list.
const VERSION := "first-release-roster-v1"
const FACTION_IDS := ["HUMAN","MACHINE","FOREST"]
const DEFAULT_PLAYER_FACTION := "HUMAN"
const DEFAULT_OPPONENT_FACTION := "MACHINE"
const EXPECTED_TROOPS := 21
const EXPECTED_HEROES := 24
const EXPECTED_TECHNOLOGIES := 12

static func is_playable_faction(id: String) -> bool:
	return id in FACTION_IDS
