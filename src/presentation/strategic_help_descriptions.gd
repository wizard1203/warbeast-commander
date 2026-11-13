extends RefCounted
## Read-only purpose text. Live costs, availability and entity facts belong to
## the arena's current catalog/snapshot resolver, not this static vocabulary.

const OPERATIONS := {
	"EconomyButton":"查看各据点的金币收入、金矿余量和停产原因。",
	"RecruitButton":"选择出兵建筑、兵种和接收部队，招募新兵。",
	"BuildButton":"在已占领据点的空位建造建筑。确认后支付金币，完整控制据点时自动施工。",
	"ArmyButton":"创建或合并部队，按兵种调配成员。",
	"TechnologyButton":"科技：查看科技树、前置和当前进度；选择可用节点进行研究。",
	"MenuButton":"调整镜头、音效与指挥选项。打开菜单时战斗继续。",
	"AttackMoveButton":"选点攻移：先单击此键，再单击战场目的地；部队沿途交战后继续前进。高亮表示等待选点，小地图只移动镜头。",
	"RetreatButton":"命令所选部队撤退，优先脱离战斗。",
	"EngageButton":"自动进攻：单击立即命令当前部队集中攻击最近的敌方部队，不再等待地图选点；没有敌军部队时尝试进攻敌方基地。",
	"DefendButton":"命令所选部队返回己方根据地。",
	"FormationMenuButton":"选择部队阵型。阵型改变站位，不提供属性加成。",
	"FormationSTEADY":"方阵：围绕部队中心紧凑排列。",
	"FormationLOOSE":"散阵：拉开成员间距。",
	"FormationCOLUMN":"纵队：以两列纵深队形行军。",
	"FormationSPEAR":"突阵：沿前进方向排出纵深队形。",
	"CancelTargetButton":"取消当前选点：退出攻移或建筑落点模式，不对地图发令。已提交的订单不会因此撤销。",
	"CloseManagementButton":"关闭面板，返回战场。",
	"ConfirmRecruitButton":"招募一名：在所选建筑加入当前单位的订单，按显示费用和人口要求办理；完成后进入所选接收部队或预备池。",
	"CancelRecruitButton":"撤销队首：取消所选出兵建筑最前面的生产订单，原额退还该订单实付金币。",
	"CancelRecruitTailButton":"撤销队末：取消所选出兵建筑最后面的生产订单，原额退还该订单实付金币。",
	"CancelConstructionHeadButton":"取消施工队列中的第一座未完工建筑，全额退还已付金币。",
	"CancelConstructionTailButton":"取消施工队列中的最后一座未完工建筑，全额退还已付金币。",
	"RecruitWorkerButton":"金币由已占领据点中的完工基地或采矿场自动开采。",
	"CreateArmyButton":"建立新编队，再从其他部队或预备池调入成员。",
	"SwapArmiesButton":"交换方向：互换调配界面的来源和接收部队；仅交换选择，不立即调兵。",
	"ArmyMoreButton":"合并或解散所选部队。",
	"TransferUnitsButton":"将选定成员转入接收部队。调配后保持当前位置。",
	"MergeArmiesButton":"将来源部队的全部成员并入另一支部队。成员保持当前位置。",
	"DeleteArmyButton":"解散来源部队，成员进入预备池。英雄的经验和装备保留。",
	"BackToArmyButton":"返回人数调配：继续选择来源、接收部队和兵种人数，不提交调兵。",
	"UpgradeBaseButton":"升级所选基地：支付显示费用后进行升级，解锁相应英雄名额、建筑、兵种与科技；不直接增加人口上限。",
	"BaseRecruitEntry":"查看建筑空位：在已占领据点确认建造出兵建筑；士兵和英雄仍需在各自完工的对应建筑排队招募。",
	"BaseTechnologyEntry":"打开科技树，查看当前基地等级允许的研究与前置。",
	"TechnologyBaseEntry":"查看基地升级与解锁；高级科技仍需相应基地等级和完工兵工坊。",
	"FoundryPrerequisite":"查看科技兵工坊的建造状态。完工后可以研究科技。",
	"InventoryButton":"独立行囊：2种消耗品各最多2份，4个装备槽共容纳初级和高级装备。需英雄靠近己方完整控制据点内的完工商店；购买和缺件合成只支付金币，已有组件抵扣。",
	"HeroAutomationButton":"成长：查看当前英雄经验、技能点，调整独立的自动攻击和自动技能开关。",
	"HeroAutoAttackToggle":"自动攻击：单击切换当前英雄的普通自动攻击。与自动技能独立；行军和撤退命令优先，手动攻击仍可用。",
	"HeroAutoSkillsToggle":"自动技能：单击切换当前英雄的自动施法。与普通自动攻击独立；仍需满足实际耗蓝、冷却和目标条件。",
	"UnitInformationButton":"查看所选单位的属性、特性和技能。",
	"RecruitInformationButton":"查看待招募单位的定位、属性和技能。",
	"HeroRosterButton":"查阅各族兵种与英雄。",
	"InformationSelectHero":"选中本方已有的这名英雄。",
	"InformationRecruitHero":"招募或复活本类型英雄：第二／第三英雄需二／三级基地；已拥有的死亡英雄复活不重新要求基地等级。仍需支付报价、预留人口并拥有完工祭庭。",
	"ForceCompositionButton":"查看本方存活兵力、兵种构成和人口占用。",
	"SiteCaptureButton":"查看据点归属、驻军与占领进度。",
	"EnterSiteCircleButton":"命令所选单位前往占领圈。清除守军并取得兵力优势后开始占领。",
	"ComputerActivityButton":"查看电脑的经营、扩张和作战动向。",
	"AIDifficultySelector":"设置电脑难度。难度影响经营和战斗决策的频率。",
	"DifficultyRestartButton":"重新开局：返回配置流程后选择电脑难度；会结束当前这一局。",
	"StartBattleButton":"结束筹备，开始采金、生产与战斗。",
	"BattleStartQuickButton":"结束筹备，开始交战。",
	"RestartStrategicButton":"重新开局：结束当前对局并回到开局配置；当前战局不会因此保存。",
	"HomeCameraButton":"将镜头移到己方根据地。",
	"OverviewCameraButton":"缩放镜头，查看完整地图。",
	"ZoomInButton":"放大战场。",
	"ZoomOutButton":"缩小战场，查看更大区域。",
	"LegacyModeButton":"历史演练版：切换到保留的历史玩法入口，并非升级或继续当前战局。",
	"SoundMuteButton":"开启或关闭游戏音效。",
	"SoundVolumeSlider":"调整游戏音效音量。",
	"HeroicArtCreditsButton":"查看美术作者与素材署名。",
	"FrontierAppearanceSeedButton":"更换地景外观种子：调整表现层装饰，不重置资源、经济或地形规则。",
	"MovementJoystick":"拖动摇杆，移动所选单位。",
	"AttackJoystick":"攻击：轻触或拖动后释放，瞄准附近敌兵、野怪或可攻击建筑；长按只查看。远征请使用部队进攻式移动。",
	"WorkSiteOption":"查看据点金矿。完整占领并建成基地或采矿场后自动产出金币。",
	"RecruitBuildingOption":"选择出兵建筑。每座建筑独立训练士兵。",
	"ReceivingArmyOption":"选择新兵加入的部队，或留在预备池。",
	"RecruitHeroArchetype":"英雄类型：选择准备招募或召回的英雄身份；不同类型拥有各自属性与技能。",
	"SourceArmyOption":"来源部队：从这里选择将被调出的成员；预备池内成员也可分派到普通部队。",
	"TargetArmyOption":"接收部队：选择调配后成员的新归属；必须与来源不同，选择本身不提交调兵。",
	"BaseUpgradeOption":"升级目标：选择本次查看或升级的具体营所；每座营所具有自己的升级进度。",
	"FoundryOption":"选择承接研究的完工兵工坊。",
	"ComputerSideOption":"选择要查看的电脑阵营。",
	"InformationUnitType":"选择要查阅的兵种。",
	"InformationHeroType":"选择要查阅的英雄。",
	"LobbyMapOption":"选择下一局地图。",
	"LobbyParticipantCount":"参战方数：选择地图允许的参与方数量；每一方独立经营与作战。",
	"LobbyStartBattleButton":"开始对局：按当前生效配置建立地图与参战方，启动经济、生产、占领与战斗。"
}

const BUILDING_ROLES := {
	"BASE":"开采根据地金矿，升级后解锁高级兵种、英雄名额和科技。每个资源根据地限1座；需完整占领才能产金。",
	"BARRACKS":"训练本族的3种物理兵。每个根据地限1座；人口据点的军营位须在物理营与魔法营中二选一。",
	"RANGE":"训练本族的2种法师与支援兵。每个根据地限1座；人口据点与物理营共用军营位。各兵种的基地等级要求见招募卡。",
	"TOWER":"自动攻击射程内的敌人。根据地最多建5座，人口据点和纯资源点各2座；二级基地可强化。各族防御塔的攻击方式不同。",
	"SITE_TOWER":"守卫据点。己方占领点数清零前继续攻击，清零后停止；夺占过程中保持休眠。",
	"ESSENCE_MINE":"自动开采纯资源点与富矿的金币。每点限1座，需完整占领；纯资源点还可建2座防御塔，不提供人口。",
	"FOUNDRY":"研究通用攻防与本族科技。每个根据地限1座，需要二级基地。",
	"ALTAR":"招募或复活英雄，每个根据地限1座。整局最多拥有3种英雄；第二、第三英雄分别需要二级、三级基地。已拥有英雄可在幸存祭庭按等级费用复活。",
	"WORKSHOP":"训练机械与支援单位。",
	"SHOP":"为附近己方英雄购买装备、消耗品或合成装备。每个根据地和人口据点限1座，需完整占领。每位英雄有4格装备、2类消耗品槽，同类消耗品最多2份。",
	"DRAGON_ROOST":"训练本族的2种专属兵。需要三级基地，仅可在资源根据地建造，每点限1座。"
}


static func operation(node_name: String, caption: String) -> String:
	var lowered := node_name.to_lower()
	if lowered.contains("contexthelp") or lowered.contains("tooltip") or lowered.begins_with("hint"):
		return ""
	if OPERATIONS.has(node_name):
		return str(OPERATIONS[node_name])
	if node_name.begins_with("EconomyPlus") or node_name.begins_with("EconomyMinus"):
		return "清除守军、完整占领并建成基地或采矿场后，自动开采金币。"
	if node_name.begins_with("HeroSkillUpgrade"):
		return "消耗技能点提升技能。普通技能最高3级；大招在英雄5级、8级时可提升。"
	if node_name.begins_with("HeroSkillRankIcon") or node_name.begins_with("HeroSkillRankInfo"):
		return "查看技能效果、法力消耗、冷却时间和升级效果。"
	if node_name.begins_with("BuyItem"):
		return "购买一件当前物品：存活英雄靠近己方完整控制据点内的完工商店后，支付金币；装备取得后立即装备，消耗品不自动饮用。合成抵扣已有组件，也可直接付费补齐缺件。"
	if node_name == "ItemPOTION":
		return "饮用药水：消耗一瓶已持有药水恢复缺失生命；满血或英雄倒下时不能使用。"
	if node_name.begins_with("Item"):
		return "为当前英雄装备这件物品。"
	if node_name.begins_with("TransferMinus_"):
		return "调配选择减一：只减少此兵种准备调出的数量，最低为零；确认调配前不改变归属。"
	if node_name.begins_with("TransferPlus_"):
		return "调配选择加一：最多选择来源现有的该兵种存活人数；确认调配前不改变归属。"
	if node_name.begins_with("TransferHalf_"):
		return "选择来源中此兵种当前存活成员的半数，向上取整；尚未执行调配。"
	if node_name.begins_with("TransferAll_"):
		return "选择来源中此兵种当前全部存活成员；不包含其他兵种，尚未执行调配。"
	if node_name.begins_with("TechnologyNode_"):
		return "科技节点：查看此项研究的效果、费用与前置；只有当前可用节点才能加入正常研究。"
	if node_name.begins_with("LobbyFaction_"):
		return "选择这一方的种族，决定可用兵种、英雄和科技。"
	if node_name.begins_with("LobbyController_"):
		return "玩家1可选择亲自指挥或电脑观战；其余参战方由电脑控制。"
	if node_name.begins_with("LobbyDifficulty_"):
		return "电脑难度：设置这一方电脑的运营与进攻节奏；本机操控方不使用电脑难度。"
	if node_name.begins_with("ArmySelect_"):
		return "选中这支部队，查看成员并下达指令。"
	if caption.contains("悬浮或长按查看说明"):
		return caption
	return caption + "：单击操作；悬浮或长按查看说明。"


static func building(building_type: String) -> String:
	return str(BUILDING_ROLES.get(building_type, "在已占领据点的对应空位建造。完工后可使用。"))


static func skill_overview_role(skill: Dictionary) -> String:
	# Purpose only, from effective catalog fields. Exact values, conditions,
	# cooldowns and target rules remain in the unchanged full skill handbook.
	match str(skill.get("effect", "")):
		"AURA":
			var roles: Array[String] = []
			for pair: Array in [["aura_damage", "攻击光环"], ["aura_armor", "护甲光环"], ["aura_heal", "回复光环"], ["aura_speed", "移速光环"]]:
				if int(skill.get(pair[0], 0)) > 0: roles.append(str(pair[1]))
			return "复合光环" if roles.size() > 1 else roles[0] if not roles.is_empty() else "友军光环"
		"PASSIVE_GUARD": return "被动护甲"
		"HEAL":
			if int(skill.get("ally_heal", 0)) > 0:
				return "机械群体回复" if skill.get("ally_required_tag", "") == "MACHINE" else "群体回复"
			return "自我回复"
		"STUN": return "伤害/眩晕" if int(skill.get("damage", 0)) > 0 else "眩晕"
		"ROOT": return "伤害/定身" if int(skill.get("damage", 0)) > 0 else "定身"
		"DAMAGE":
			return "贯穿伤害" if skill.get("delivery") == "LINE" else "连锁伤害" if skill.get("delivery") == "CHAIN" else "单体伤害" if skill.get("delivery") == "SINGLE" else "范围伤害"
		"RALLY": return "友军普攻强化"
		"ARMOR_BUFF": return "自身护甲"
		"DAMAGE_BUFF": return "普攻/吸血" if int(skill.get("drain_percent_buff", 0)) > 0 else "普攻强化"
	return "详见手册"
