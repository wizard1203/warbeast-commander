extends RefCounted
## Integer upkeep on automatic gold only. Rewards/refunds never call delivery.
const VERSION := "outposts-automatic-gold-upkeep-v2"
const WORKER_CAPACITY := {"FOOD":0,"MATERIAL":0,"ESSENCE":0}
static func worker_capacity(resource: String)->int:
	return int(WORKER_CAPACITY.get(resource,0))
static func upkeep(used_population: int)->Dictionary:
	var used:=maxi(0,used_population)
	return {"used_population":used,"tier":"NONE" if used<=50 else "LOW" if used<=80 else "HIGH","material_efficiency_percent":100 if used<=50 else 70 if used<=80 else 40}
static func delivery(resource: String,gross: int,efficiency_percent: int,remainder: int)->Dictionary:
	var amount:=maxi(0,gross)
	if resource!="MATERIAL":return {"gross":0,"net":0,"tax":0,"remainder_percent":0}
	var numerator:=amount*clampi(efficiency_percent,0,100)+clampi(remainder,0,99)
	var net:=numerator/100
	return {"gross":amount,"net":net,"tax":amount-net,"remainder_percent":numerator%100}
