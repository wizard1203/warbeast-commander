extends RefCounted
## M70 reviewed literal reductions after the historical M69 projection.
## Offline comparison owns no combat state, RNG, prices or damage settlement.
const VERSION := "m70-ordinary-ultimate-relative-budgets-v1"
const ROWS := {
	"ANTLER_BARK_FOLD": {
		"move_speed_percent": [
			4.55,
			6.18,
			7.8
		],
		"range_bonus": [
			7.8,
			9.75,
			11.7
		]
	},
	"ARCANE_BURST": {
		"damage": [
			190.4,
			214.2
		]
	},
	"ASH_WARD": {
		"passive_armor": [
			0.5,
			0.75,
			1
		]
	},
	"BASALT_LOAD_TEST": {
		"passive_armor": [
			0.25,
			0.5,
			0.75
		]
	},
	"BRIDGE_LOCK_BRACE": {
		"attack_speed_percent": [
			3.25,
			4.88,
			6.5
		],
		"ally_guard": [
			0.65,
			0.98,
			1.3
		]
	},
	"BULWARK_WARD": {
		"passive_armor": [
			0.25,
			0.5,
			0.75
		]
	},
	"CARAPACE_LAYERED_MOLT": {
		"heal": [
			108,
			121.5
		],
		"ally_heal": [
			54,
			60.75
		]
	},
	"CINDER_FERVOR": {
		"damage_percent": [
			11.38,
			14.63,
			17.88
		],
		"damage_bonus": [
			0.65,
			0.65,
			0.65
		],
		"attack_speed_percent": [
			4.88,
			6.5,
			8.13
		],
		"drain_percent_buff": [
			8.13,
			8.13,
			8.13
		]
	},
	"CINDER_MEND": {
		"damage": [
			276.8,
			311.4
		]
	},
	"CINDER_LINGERING_CLAUSE": {
		"damage": [
			43.12,
			60.37,
			77.62
		],
		"status_total_damage": [
			76.67,
			107.33,
			138
		],
		"status_power": [
			12.778333333333334,
			13.41625,
			13.8
		]
	},
	"CINDER_FINAL_CODICIL": {
		"damage": [
			344.99,
			388.11
		]
	},
	"COIL_MEND": {
		"heal": [
			84.53,
			118.26,
			151.98
		],
		"ally_heal": [
			61.48,
			86.24,
			110.57
		]
	},
	"COIL_OVERHAUL": {
		"heal": [
			302.99,
			340.81
		],
		"ally_heal": [
			147,
			165.4
		]
	},
	"COIL_WARD": {
		"passive_armor": [
			0.5,
			0.75,
			1
		]
	},
	"BLOOD_PACT": {
		"control_duration_ticks": [
			32,
			36
		]
	},
	"ECHO_OATH": {
		"damage": [
			170.64,
			194.4
		],
		"status_total_damage": [
			19.44,
			19.44
		],
		"status_power": [
			2.43,
			2.43
		],
		"status_duration_ticks": [
			160,
			160
		]
	},
	"EMBER_MEND": {
		"damage": [
			208.8,
			234.9
		]
	},
	"FLUX_BORE_LANCE": {
		"damage": [
			67.07,
			93.9,
			120.73
		]
	},
	"FLUX_RELAY_FORK": {
		"damage": [
			59.03,
			82.64,
			106.25
		]
	},
	"FLUX_SATURATION_CORE": {
		"damage": [
			170,
			191.25
		]
	},
	"GEAR_FERVOR": {
		"damage_percent": [
			11.38,
			14.63,
			17.88
		],
		"damage_bonus": [
			0.65,
			0.65,
			0.65
		],
		"attack_speed_percent": [
			4.88,
			6.5,
			8.13
		],
		"range_bonus": [
			9.75,
			9.75,
			9.75
		]
	},
	"GEAR_REPAIR": {
		"status_total_damage": [
			83.46,
			93.89
		],
		"status_power": [
			10.4325,
			11.73625
		],
		"status_duration_ticks": [
			160,
			160
		]
	},
	"GRAVE_TOLL": {
		"control_duration_ticks": [
			48,
			53
		]
	},
	"LEAF_OATH": {
		"control_duration_ticks": [
			48,
			54
		]
	},
	"MOURN_OATH": {
		"damage": [
			198.4,
			223.2
		]
	},
	"MYCELIAL_ACID_VEIN": {
		"damage": [
			44.23,
			61.92,
			79.61
		],
		"status_total_damage": [
			34.62,
			48.46,
			62.31
		],
		"status_power": [
			5.77,
			6.0575,
			6.231
		]
	},
	"MYCELIAL_SPORE_DOWNPOUR": {
		"status_total_damage": [
			201.59,
			226.79
		],
		"status_power": [
			25.19875,
			28.348750000000003
		],
		"status_duration_ticks": [
			160,
			160
		]
	},
	"OATH_EDGE_PLEDGE": {
		"damage_percent": [
			28,
			38,
			48
		]
	},
	"OBSIDIAN_GLASS_POOL": {
		"damage": [
			72.11,
			100.96,
			129.8
		]
	},
	"OBSIDIAN_CINDER_SEAM": {
		"status_total_damage": [
			62.5,
			87.5,
			112.5
		],
		"status_power": [
			10.416666666666666,
			10.9375,
			11.25
		]
	},
	"OBSIDIAN_NIGHT_FAN": {
		"damage": [
			225,
			253.12
		]
	},
	"PISTON_FLYWHEEL": {
		"damage_percent": [
			4.8,
			7.2,
			9.6
		],
		"attack_speed_percent": [
			14,
			18,
			22
		]
	},
	"POLLEN_FIREFLY_FAN": {
		"damage": [
			55,
			77,
			99
		]
	},
	"POLLEN_LONE_COMET": {
		"damage": [
			137.5,
			192.5,
			247.5
		]
	},
	"POLLEN_COMET_PROCESSION": {
		"damage": [
			165,
			185.62
		]
	},
	"PRISM_DOUBLE_EDGE": {
		"damage_percent": [
			18,
			24,
			30
		],
		"range_bonus": [
			9.6,
			12,
			14.4
		]
	},
	"QUAKE_SEAL": {
		"status_total_damage": [
			5.4,
			8.1
		],
		"status_power": [
			0.675,
			0.675
		]
	},
	"RELIC_COLD_EDGE": {
		"damage_percent": [
			11.38,
			16.25,
			21.13
		],
		"mana_per_second": [
			0.33,
			0.49,
			0.65
		]
	},
	"RELIC_UNFINISHED_DUEL": {
		"damage": [
			172.8,
			194.4
		]
	},
	"RIDGE_WARD": {
		"passive_armor": [
			0.25,
			0.5,
			0.75
		]
	},
	"RIVET_LOAD_PLATE": {
		"armor_bonus": [
			0.8,
			1.2,
			1.6
		],
		"skill_damage_percent": [
			4.8,
			7.2,
			9.6
		]
	},
	"RUNE_FLARE": {
		"damage": [
			50.58,
			70.99,
			90.95
		],
		"status_total_damage": [
			6.39,
			8.94,
			11.5
		],
		"status_power": [
			1.065,
			1.1175,
			1.15
		]
	},
	"RUNE_OATH": {
		"damage": [
			149.99,
			171.97
		],
		"status_total_damage": [
			19.82,
			19.82
		],
		"status_power": [
			2.4775,
			2.4775
		],
		"status_duration_ticks": [
			160,
			160
		]
	},
	"SIGNAL_LOCK": {
		"control_duration_ticks": [
			22,
			30,
			37
		]
	},
	"SIGNAL_BLACKOUT": {
		"control_duration_ticks": [
			59,
			66
		]
	},
	"SLAG_WHITE_HEAT": {
		"damage_percent": [
			38,
			50,
			62
		]
	},
	"SLAG_QUENCH_VERDICT": {
		"damage": [
			143.8,
			164.5
		],
		"status_total_damage": [
			65,
			70.4
		],
		"status_duration_ticks": [
			160,
			160
		]
	},
	"STORM_HAMMER": {
		"control_duration_ticks": [
			13,
			17,
			21
		]
	},
	"STORM_VERDICT": {
		"control_duration_ticks": [
			33,
			37
		]
	},
	"SUNGLASS_LIGHT_SHEAR": {
		"damage": [
			58.3,
			81.62,
			104.94
		]
	},
	"SUNGLASS_FALLING_INDEX": {
		"damage": [
			154.98,
			174.36
		]
	},
	"THORN_MAZE": {
		"control_duration_ticks": [
			48,
			53
		]
	},
	"THORN_SAP_BLADE": {
		"damage_percent": [
			13.65,
			18.53,
			23.4
		],
		"move_speed_percent": [
			1.63,
			2.6,
			3.58
		]
	},
	"THORN_GRAFT_RUPTURE": {
		"status_total_damage": [
			126.96,
			142.82
		],
		"status_power": [
			15.87,
			17.8525
		],
		"status_duration_ticks": [
			160,
			160
		]
	},
	"TUNNEL_WARD": {
		"passive_armor": [
			0.5,
			0.75,
			1
		]
	},
	"VINE_WARD": {
		"passive_armor": [
			0.5,
			0.75,
			1
		]
	},
	"VOLT_ARC": {
		"damage": [
			56.79,
			79.59,
			102.39
		]
	},
	"VOLT_NETWORK": {
		"damage": [
			156.99,
			176.62
		]
	},
	"WIND_FERVOR": {
		"damage_percent": [
			11.38,
			14.63,
			17.88
		],
		"damage_bonus": [
			0.65,
			0.65,
			0.65
		],
		"attack_speed_percent": [
			4.88,
			6.5,
			8.13
		],
		"move_speed_percent": [
			3.9,
			5.2,
			6.5
		]
	},
	"WIND_MEND": {
		"damage": [
			123.42,
			138.85
		]
	}
}

static func apply(skill:Dictionary)->Dictionary:
	if skill.is_empty():return {}
	var out:=skill.duplicate(true)
	if out.get("relative_budget_version","")==VERSION:return out
	var rank:=maxi(1,int(out.get("level",1)))
	var edits:Dictionary=ROWS.get(str(out.get("id","")),{})
	for field:String in edits:out[field]=edits[field][mini(rank-1,edits[field].size()-1)]
	if out.has("budget_primary_raw"):
		out["budget_primary_raw"]=float(out.get("damage",out.get("heal",out.get("damage_percent",0))))
	if out.has("budget_per_cast_raw"):
		var count:=int(out.get("max_targets",1))
		out["budget_per_cast_raw"]=float(out.get("damage",0))*(1.0+float(maxi(0,count-1))*float(out.get("secondary_damage_percent",100))/100.0)+float(out.get("status_total_damage",0))*count if out.has("damage") else float(out.get("heal",0))+float(out.get("ally_heal",0))*count
	out["relative_budget_version"]=VERSION
	out["relative_budget_scope"]="M70：普通3阶与大招1/2阶在英雄5/8级比较；可比较主预算以1.6/1.8倍为目标，仅下调。不同机制、几何、CD/MP与副属性不机械乘同一倍数。"
	if out.has("calibration_reason"):
		out["m69_calibration_reason"]=out.calibration_reason
		out["calibration_reason"]=out.relative_budget_scope+" M69历史半幅结果是本轮只降校准前的上界；同类大招二阶有限窗口可收敛至一阶同长，保留实际幅度成长。"
	return out





