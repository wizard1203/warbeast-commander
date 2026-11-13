extends RefCounted
## Detached source/upkeep projection. Never assigns workers or settles income.
const Economy = preload("res://src/simulation/strategic_economy_catalog.gd")

static func read(snapshot: Dictionary, id: String, side: String = "PLAYER") -> Dictionary:
	for source: Dictionary in snapshot.get("resource_sources",[]):
		if str(source.get("id","")) != id or not bool(source.get("visible",true)): continue
		var resource := str(source.get("resource",source.get("kind","")))
		var capacity := int(source.get("worker_capacity",3 if resource == "ESSENCE" else 5))
		var assigned := int(source.get("assigned_workers",0))
		var remaining := int(source.get("remaining",source.get("remaining_amount",0)))
		var initial := int(source.get("initial",source.get("initial_amount",0)))
		if bool(snapshot.get("outpost_mode",false)):
			return _automatic_readout(snapshot,source,resource,remaining,initial,side)
		var active := bool(source.get("active",false))
		var efficiency := int(source.get("efficiency_percent_by_side",{}).get(side,100)) if resource == "MATERIAL" else 100
		var label := str(Economy.RESOURCE_LABELS.get(resource,resource))+"采集点"
		var state := "已耗尽" if remaining <= 0 else "等待经营" if not active else "已满员" if assigned >= capacity else "可派工"
		var description := "%s · 储量 %d / %d\n工人 %d / %d（每个来源共享上限，不按建筑重复计算）\n%s" % [label,remaining,initial,assigned,capacity,state]
		description += "\n矿材交付效率 %d%%；按交付当时已用人口计算。%s" % [efficiency,upkeep_text(snapshot,side)] if resource == "MATERIAL" else "\n此资源不受人口维护费影响。"
		description += "\n单击仅查阅；经营界面统一分派，满员后工人寻找其他合法来源或等待。有限储量不会因重建而恢复。"
		return {"id":id,"collection":"resource_sources","label":label,"description":description,"body":source.duplicate(true),"remaining":remaining,"initial":initial,"worker_capacity":capacity,"assigned_workers":assigned,"efficiency_percent":efficiency,"state_caption":state,"resource":resource,"read_only":true}
	return {}

static func _automatic_readout(snapshot: Dictionary, source: Dictionary, resource: String, remaining: int, initial: int, side: String) -> Dictionary:
	var site: Dictionary = {}
	for candidate: Dictionary in snapshot.get("sites",[]):
		if str(candidate.get("id","")) == str(source.get("site_id","")):
			site = candidate
			break
	var owner := str(source.get("owner",site.get("owner",side)))
	var efficiency := int(upkeep(snapshot,owner).material_efficiency_percent)
	# Rates come from the detached authority observation, not a second income
	# calculation. Enemy inspection must describe the owner's maintenance.
	var net_rate := float(source.get("income_per_second",source.get("net_rates",{}).get(resource,0.0)))
	var active := bool(source.get("income_active",source.get("active",false)))
	var state := "已耗尽" if remaining <= 0 else "自动产出" if active else "未启用 / 暂停"
	var required := "采矿场" if str(site.get("kind","")) == "SATELLITE" else "资源基地"
	var label := "金币矿点"
	var description := "%s · 储量 %d / %d\n%s · 当前净收入 %.1f金币/秒\n%s" % [label,remaining,initial,str(site.get("label","资源据点")),net_rate,state]
	description += "\n完全占领且本点%s存活完工后自动产出，无需工人。失去完整控制、经济建筑被毁或矿脉耗尽时停止。" % required
	description += "\n当前占领方维护费后保留%d%%金币收入。%s" % [efficiency,upkeep_text(snapshot,owner)]
	description += "\n单击仅查阅；有限储量不会因重建或重新占领而恢复。"
	return {"id":str(source.get("id","")),"collection":"resource_sources","label":label,"description":description,"body":source.duplicate(true),"remaining":remaining,"initial":initial,"worker_capacity":0,"assigned_workers":0,"efficiency_percent":efficiency,"state_caption":state,"resource":resource,"automatic_income":true,"net_per_second":net_rate,"required_building":required,"read_only":true}

static func upkeep(snapshot: Dictionary, side: String = "PLAYER") -> Dictionary:
	var data: Dictionary = snapshot.get("population_upkeep",{}).get(side,{})
	var used := int(snapshot.get("population",{}).get(side,{}).get("used",0))
	return {"used_population":int(data.get("used_population",used)),"material_efficiency_percent":int(data.get("material_efficiency_percent",100 if used <= 50 else 70 if used <= 80 else 40)),"tier":str(data.get("tier","NONE" if used <= 50 else "LOW" if used <= 80 else "HIGH"))}

static func upkeep_text(snapshot: Dictionary, side: String = "PLAYER") -> String:
	var data := upkeep(snapshot,side)
	return "已用人口%d；≤50人口100%%，51–80人口70%%，81+人口40%%。只影响自动金币收入；击杀赏金、出售和退款不扣维护费，预留人口不计入。" % int(data.used_population)
