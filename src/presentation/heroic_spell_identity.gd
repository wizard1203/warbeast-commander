extends RefCounted
## M56 authored color/material scores. These are presentation data only.
## Ink / shadow / body / contrasting material / hot core / afterglow / metal
## are deliberately separate roles; no faction ramp or random hue fallback.
const VERSION := "m56-72-multimaterial-scores-v1"
const Materials = preload("res://src/presentation/heroic_spell_materials.gd")
const ExpansionAV=preload("res://src/presentation/heroic_expansion_av_m66.gd")
const ROLES := ["pixel_ink","material_shadow","primary_body","secondary_material","luminous_core","afterglow","physical_fragment"]
# story, choreography, emblem, rhythm, seven color roles
const SPELLS := {
	"RECOVER":["金线缝合与青瓷回声","stitch","banner","rising","14191d","655039","c59450","60c9bf","fff3cb","e79c94","a7bfc1"],
	"RALLY":["朱红誓旗与碧金契页","standard","banner","reprise","19151d","563040","c85660","62bdba","fff0b2","d9a44b","b4c5be"],
	"SHIELD_SHOCK":["靛钢盾震与橙铜裂火","retort","shield","snap","13191e","354b66","6e9fc0","f0a55b","fff2c6","c2a2da","939a8a"],
	"BULWARK_RECOVER":["砂金壁垒与紫曜支柱","bastion","shield","draw","19171d","695242","c4a56e","a18bde","fff0c8","e17c76","a8bdb7"],
	"STARFIRE":["紫晶星屑与橙金彗羽","fan","crystal","snap","181725","57416d","a77ed4","edb75e","fff7da","7dd0bf","bd8b86"],
	"FROST_BIND":["冰青棱片与绯紫契丝","ice","crystal","draw","141b25","37596e","76bfd6","d18ab7","f3ffeb","ecbc76","9aa5bd"],
	"ARCANE_BURST":["靛紫星核与金白贯星","astral_execution","crystal","double","171426","4b3677","9e75de","edc35f","fff9da","73d2d1","d599bc"],
	"PIERCING_SHOT":["青钢贯羽与玫金弦光","lance","blade","snap","141b1c","395851","81b4a1","dfa274","fff4cc","ab8bd4","b8c7c0"],
	"ARROW_RAIN":["雨蓝羽簇与琥珀落星","volley","blade","stagger","161c24","3d526b","80b6d5","e8b15d","ffedbf","c78aa4","a5b3aa"],
	"QUICKDRAW":["绯羽翼展与冰蓝弦线","wings","banner","reprise","21151e","71374b","d8777e","83bfdd","fff2bd","d8ad64","b1c1b3"],
	"WHIRLWIND":["月银刃带与赤金断契","crosscut","blade","snap","161c22","435467","a1b7ca","dc7e68","fff4d2","90c3b4","c6ad75"],
	"BLOOD_PACT":["血玉双锋与冷白判印","verdict","blade","double","21151f","743544","cc647b","87c6d4","fff0c3","ad95da","bd9d70"],
	"ASH_STITCH":["铜烬灰缝与碧绿灯芯","stitch","lantern","rising","1c171c","6c493f","d88b58","7bc9af","fff0c4","bd7eaf","a6aaa0"],
	"ASH_REQUIEM":["象牙归灯与青碧魂帆","choir","lantern","reprise","191a21","63604f","cbbb87","79c7bc","fff5dc","cb8b9e","8d9eaa"],
	"ASH_SHOCK":["骨金裂肋与幽蓝骨火","retort","bone","snap","1b171f","695244","bea070","6baac9","fff0c1","bd82a6","97a7a0"],
	"ASH_MEND":["紫绛镇魂与翡翠烬潮","fan","bone","draw","211621","694067","bd81b5","83cfac","fff1c7","e0b16b","969db0"],
	"MOURN_BIND":["幽蓝锁魂与锈金链结","chain","bone","stagger","151b25","344b72","74a6db","ce976a","f4f5d9","bd8bb9","92acaa"],
	"MOURN_FLARE":["兰紫游魂与薄荷冥焰","soulflare","lantern","rising","1b1727","574274","ad87d8","80d6bb","fff2d1","dc9b7e","92abb7"],
	"MOURN_OATH":["翠魂抽线与朱铜归烬","soul_extraction","lantern","double","152120","365e5a","76c6b3","d98872","fff3c7","b28ddd","8da8c0"],
	"CINDER_SHOT":["赤铜骨箭与幽蓝火羽","lance","bone","snap","21191d","704534","d3834f","72b2cf","fff0b1","ba8da9","b6baa3"],
	"CINDER_FERVOR":["夜紫箭架与金黄烬羽","quiver","bone","reprise","1b1726","4c3e73","9c83cf","e6be68","fff3d7","75c9b5","bda495"],
	"CINDER_MEND":["霜碧狩箭与赤烬钉印","bone_pin","bone","double","172120","38645d","83cdb9","da7866","fff3c8","c29ade","adae8c"],
	"GRAVE_CHAIN":["古铜墓钩与青魂节链","hook","bone","draw","191e20","655145","c18f61","77bcb7","fff1d1","b58fc9","93a7b8"],
	"GRAVE_TOLL":["紫铜巨钟与金青魂纹","bell","lantern","double","1d1727","5f4171","af7ac1","d5b761","fff4d6","78bdc7","bc8b7f"],
	"COIL_MEND":["暖铜焊星与薄荷冷却","satellites","gear","rising","191b1c","664d3e","c98c5a","76d0b8","fff5cb","aa92cf","a8b9b7"],
	"COIL_OVERHAUL":["军绿检修坞与珊瑚焊流","dock","gear","reprise","191e1b","4a5b44","8db077","db8c77","fff2bd","80bcd0","c4b995"],
	"COIL_SHOCK":["铜黄压阀与紫电反冲","retort","gear","snap","1d1a20","725438","cf9e4f","aa8ad5","fff5c5","75c5bc","afb8ad"],
	"COIL_REPAIR":["海蓝电磁闸与橙红栓齿","gate","shield","draw","141d24","31546d","6badd0","e49b65","f2f7d4","bb8bcd","a8baac"],
	"VOLT_BIND":["明黄特斯拉线与紫铜端子","tesla","bolt","snap","1d1b20","726437","dbc15c","aa86d4","fff9da","6dbecb","c79275"],
	"VOLT_ARC":["青白叉电与珊瑚线圈","discharge","bolt","stagger","131f24","2d5c70","6ac3d9","e68b83","f3fff0","c5a257","ad9bcb"],
	"VOLT_NETWORK":["紫曜风暴与薄荷高压枝","switchyard","bolt","double","1b1729","4f3b7e","9b7bd6","79d2b1","fff3d0","e1aa69","8faac3"],
	"GEAR_SHOT":["锈红破片与钴蓝火花","shell","gear","snap","21191c","704236","ca7456","73aace","fff1bc","b39ad3","b8baa3"],
	"GEAR_FERVOR":["橄榄转轮与品红超频","rotor","gear","reprise","1b201a","59663d","a3b95e","ce86bd","fff0c4","80bed3","bba382"],
	"GEAR_REPAIR":["铁蓝锁弹与橙焰破甲","missile_lock","gear","double","161d25","3e516d","7aa0c8","efaa62","fff5cb","bc87ae","a7c4b3"],
	"SIGNAL_LOCK":["珊瑚断路与青金信号","circuit","bolt","snap","23191e","7a4351","d88891","82c9bd","fff0bf","ba9ad7","bcad89"],
	"SIGNAL_BLACKOUT":["深紫天线与琥珀熄电","antenna","gear","double","1b1723","514368","a28ac4","ddb568","fff4d1","6bbbc3","c49a88"],
	"BLOOM_TOUCH":["桃粉花泉与青碧叶杯","lily","bloom","rising","201b22","76536b","d79fbb","81cbb6","fff3d3","d7bc68","b4c1a0"],
	"BLOOM_SANCTUARY":["白金繁花与淡紫枝庭","arbor","bloom","reprise","1d201b","657048","c4d484","b59ad7","fff7d6","d98e91","8bbcaf"],
	"VINE_SHOCK":["苔翠根心与朱红树液","rootheart","rootclaw","snap","15221c","37694d","7bbb7e","dd8c77","fff2c5","9ca4d5","c4b57e"],
	"VINE_MEND":["栗褐古根与冰青冠叶","rootcrown","rootclaw","draw","211c19","715040","ba8867","8dcfc6","fff2cd","b3a1d7","a6bf8c"],
	"LEAF_BIND":["紫藤织根与金橙花蕊","woven","rootclaw","draw","201927","604674","ae8cc5","e1b360","fff5d8","82c5b0","aaa992"],
	"LEAF_FLARE":["珊瑚花叶与碧蓝风扇","fan","leaf","stagger","221b20","784b5e","dc9caa","78c8c5","fff1c8","cfb967","a4b58d"],
	"LEAF_OATH":["翡翠古根与琥珀囚花","root_prison","bloom","double","15231e","396e54","7cc697","dfa458","fff6cf","b09bdc","bfb18b"],
	"WIND_SHOT":["湖青风羽与玫金弦刃","windlance","leaf","snap","152024","395d71","8ac0d5","d89a9b","fff3cb","b6cb78","a996c7"],
	"WIND_FERVOR":["嫩金疾叶与兰紫风脉","swiftleaf","leaf","reprise","201f19","6e6b3e","c6cb6a","aa95d8","fff5d1","7dc4b5","c99681"],
	"WIND_MEND":["雾蓝猎翼与焰橙羽冠","canopy","leaf","double","162022","3b6266","82bdc5","e4a36a","fff4cd","bd9acf","a2b783"],
	"THORN_LASH":["酒红棘鞭与嫩玉倒刺","whip","rootclaw","snap","21181d","6e3d51","bc748c","9aca90","fff2c8","8bb9ce","c2aa77"],
	"THORN_MAZE":["墨青棘网与蔷薇锋花","labyrinth","rootclaw","double","132220","32675f","75b9a7","d789af","fff1ce","c4b870","99a3d2"],
	"HEARTH_MEND":["炭橙炉心与淡蓝暖烟","hearth","flame","rising","231b18","7a4b36","e59a60","8ebfd1","fff1bd","ba8aa9","b3bd93"],
	"HEARTH_REFUGE":["金红营火与紫霜棚影","campfire","flame","reprise","261c1c","85483e","ec8d62","ac96ce","fff4be","81c4b2","bca77b"],
	"RIDGE_SHOCK":["玄青锤纹与赤铜熔血","temper","mountain","snap","191e23","40586a","85abbf","de8862","fff2bd","b7a2d0","c0b080"],
	"RIDGE_MEND":["冰蓝崖壁与金紫符震","avalanche","mountain","draw","1d1e25","626775","8baed3","c89ed5","fff0bd","e4a36d","85b7ac"],
	"RUNE_BIND":["紫铜炉符与碧玉刻槽","runelock","mountain","draw","231b24","72456b","c184b9","84cbaa","fff3cc","d8b362","94abc3"],
	"RUNE_FLARE":["橙红喷焰与湖蓝炉石","eruption","flame","stagger","261a1c","853f35","e77c4f","78bcc9","fff2af","c494c4","baa98b"],
	"RUNE_OATH":["苍蓝炉焰与金橙喷锋","fan","flame","double","171e28","3d567d","82a9df","f0b15c","fff7cb","cf91bb","92c2aa"],
	"EMBER_SEAL":["熔金断刃与靛蓝淬火","execution","blade","snap","231c1e","775436","ddb15c","8d9cd3","fff2bd","d18f91","a4bfa9"],
	"EMBER_SWEEP":["珊瑚热刃与霜青回锋","sweep","blade","stagger","26191e","84434e","e5848a","7dc9c1","fff3c8","c8aa60","a49dcb"],
	"EMBER_MEND":["朱金熔锋与苍白断层","molten_verdict","blade","double","271b1c","88432f","eb8f45","9cbfda","fff8c8","bb8dca","bdaf83"],
	"STORM_HAMMER":["钴蓝雷锤与橙铜电钉","thunder","mountain","snap","171d29","3e537d","80a3db","dda264","fff4c4","b78ac9","94b9ad"],
	"STORM_VERDICT":["紫白峰雷与金红旌裂","summit","bolt","double","211a29","62477e","bd9adc","e8ac66","fff9dc","79bfd0","a0b991"],
	"SPORE_REMEDY":["青莹菌伞与橘粉孢星","sporecaps","mushroom","rising","152322","356c63","7ecdb2","e5a18c","fff4d0","bca0d7","b6bd86"],
	"SPORE_HAVEN":["葡紫菌丝与金绿灯蕈","mycelium","mushroom","reprise","23192a","6b457d","b486d0","c7d274","fff4d5","82c8cc","dca18b"],
	"TUNNEL_SHOCK":["铁褐甲壳与天青裂隙","shell","jaw","snap","211e1b","665640","b39c6d","74bccc","fff3c6","c78db3","9dbb8a"],
	"TUNNEL_MEND":["靛蓝穴颚与金红震波","fan","jaw","draw","191d2a","434d7f","8d99d6","dfa265","fff3c8","82c8ab","c590b1"],
	"ECHO_BIND":["粉晶声纹与碧青裂音","resonance","crystal","stagger","221b28","744f7c","ca91cf","80c9bd","fff4d4","dfb069","98aecb"],
	"ECHO_FLARE":["绿晶声钻与紫红余音","drill","crystal","snap","172420","3e715a","8dcc9c","c28cbd","fff5cc","e3b369","96b4cd"],
	"ECHO_OATH":["紫晶内爆与金青共鸣","crystal_implosion","crystal","double","21182b","63417f","b183df","e5bb67","fff8d7","77ccc4","d38eaa"],
	"SPORE_SEAL":["湖蓝隙刺与赤橙毒晶","stinger","crystal","snap","162126","3b6275","7bbacf","e29b70","fff2c8","bca0d3","adc58d"],
	"SPORE_SWEEP":["玫紫螳刃与薄荷毒丝","mantis","blade","stagger","241b26","754c78","c58cc2","89cdb2","fff5d0","dcaf65","9cacc9"],
	"SPORE_MEND":["玉绿裂隙翼与朱红猎纹","rift","jaw","double","18241f","436e53","91c390","de8c83","fff2c5","9da5d8","c5b277"],
	"QUAKE_SNARE":["铜金断层夹与紫蓝裂辉","fault","slab","draw","231e1a","765f3b","c9aa69","9c94d2","fff2ca","80bfb6","ca8e9c"],
	"QUAKE_SEAL":["暮紫地脊与琥珀封印","tectonic","slab","double","231b2c","634c7d","a78bc8","dfb767","fff4d1","87c7c1","cf8e99"],
}

static func profile(id: String, hero: String="") -> Dictionary:
	if ExpansionAV.Data.SKILLS.has(id):
		var owner:=ExpansionAV.Data.owner(id);var row:Dictionary=ExpansionAV.Data.SKILLS[id]
		return {"id":id,"story":ExpansionAV.Data.STORIES[owner].origin,"choreography":row.motif,"emblem":row.emblem,"rhythm":"double" if id in ExpansionAV.Data.ULTIMATES else "snap","palette":ExpansionAV.PALETTES[owner].duplicate(),"roles":ROLES.duplicate(),"material":{"mode":row.material,"choreography":row.motif,"signature":row.motif,"prompt":ExpansionAV.Data.STORIES[owner].silhouette+"；"+str(row.name)}}
	if not SPELLS.has(id): return {}
	var score: Array=SPELLS[id]
	var result:={"id":id,"story":score[0],"choreography":score[1],"emblem":score[2],"rhythm":score[3],"palette":score.slice(4),"roles":ROLES.duplicate()}
	if not hero.is_empty(): result["material"]=Materials.profile(hero,id)
	return result

static func phase_for(phase: float, rhythm: String) -> float:
	# Monotonic time warps, not RNG. A held wind-up and a snap have visibly
	# different anticipation/impact timing, but never change gameplay timing.
	match rhythm:
		"snap": return pow(phase,0.79)
		"draw": return pow(phase,1.23)
		"rising": return phase*0.86+phase*phase*0.14
		"stagger": return phase*0.94+sin(phase*TAU)*0.025
		"double": return phase*0.9+phase*phase*0.1
		_: return phase
