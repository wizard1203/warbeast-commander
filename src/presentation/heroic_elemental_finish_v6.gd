extends RefCounted
## V6 deterministic material finish over the accepted V5 silhouette.
## Geometry is authored decoration, never damage/range/lifetime authority.
## No Nodes, randomness, image allocation, global image scans or texture cache.
const VERSION := "roster-v6-materials-rev1-20261103"
const SIZE := 192
const FRAMES := 12
const PHASES := ["CAST", "CONTACT", "TAIL", "AURA"]
const BODY := Rect2i(82,84,29,53)

# Every current material is assigned explicitly. Unknown future materials are
# intentionally untouched rather than silently rendered as generic magic.
const MATERIALS := {
	"fire":["VENTED_HEAT","KILN_PLUME","GLASS_MELT","FURNACE_SAND_SPEAR","HOT_SAND_RIBBON","WHITE_HOT_JAVELIN","TWO_WHITE_EDGES","KILN_SEAM_EMBER","HEAT_GAUGE","SAND_CHARGE_TICKS"],
	"lightning":["WOVEN_CURRENT","COPPER_ARC","LOOM_LIGHTNING","THREE_PHASE_COPPER","MAGNETIC_RAIL","RELAY_FORK","PAIRED_RELAY","GROUNDED_THUNDER","FLAG_CHAIN_LIGHTNING"],
	"water":["RAIN_KITE","SALT_WATER_LEDGER","SALT_RINSE_WATER","TIDAL_CANOPY","SALT_DEW","ICE_COPPER_BACKFLOW"],
	"detonation":["GUNPOWDER_SCRAP","IRON_BLOSSOM"],
	"prism":["BROKEN_PRISM","STAR_GLASS","SUN_MIRROR","GLASS_BOOKMARK","GLASS_ARCHIVE","POLLEN_FACET","FACET_PIN","REFRACTION_EDGE","SETTLED_REFRACTION","FACET_ECHO"],
	"frost":["FROST_GLASS","COLD_QUENCH_BLADES","HOT_COLD_CROSS_SCAR","TEMPER_GAUGE"],
	"black_glass":["BLACK_GLASS","OBSIDIAN_FAN","COOLING_SONG_SLITS"],
	"ink":["INK_MEASURE","INK_BINDING","INK_BANNERS"],
	"paper":["COPPER_CLOTH","COPPER_SEAL","PAPER_RAIN","COPPER_PAPER","SIGNED_PAGES","WITNESS_PAPER","THEATRE_PAPER","GHOST_FILES"],
	"wood":["IRON_WOOD","SLUICE_IRON","TIMBER_IRON","JOINERY_COPPER","COUNTERWEIGHT_TIMBER","ROOT_EARTH","BARK_HONEY","HIVE_ROOT_POLLEN","SEED_ROOT_GLASS","ROOT_KNOT_SEED","GRAFT_HOOK_SAP","GERMINATING_GRAFT","GRAFT_NOTCH","HOLLOW_ANTLER","RUNNING_BRANCH","ANTLER_ROOT_CORRIDOR","TRAVEL_KNOT","SEED_DIAGRAM"],
	"bone":["BONE_CABINET","BONE_WIRE","BONE_ARROW","ASH_BONE","BONE_SAIL"],
	"ghost":["LANTERN_SHADOW","MEMORY_FLAME","GHOST_MIRROR","THEATRE_SHADOW"],
	"silk":["PORCELAIN_THREAD","KITE_STRING","CINDER_STRING","WARM_STITCH","WARM_THREAD","SILK_BONE","COLD_SILK","OLD_SAIL_SUTURE","ASH_SAIL","SAP_THREAD_SICKLE"],
	"bronze":["BLACK_BRONZE","BRONZE_LINKS","NEGATIVE_BRONZE"],
	"machine":["RIVET_PLATE","GROUND_BOLTS","ECCENTRIC_ROTORS","CALIPER_TEETH","PISTON_STEEL","OPEN_FLYWHEEL","SHEAR_RAIL","GAUGE_MARKS","SHEARED_RIVET","CHARGED_LOAD_PLATES","COOPERATIVE_MANIFOLD","WORKBENCH_ANCHOR","MAGNETIC_CLAMP","DAM_RIVETS","KILN_GAUGE"],
	"steam":["PRESSURE_SMOKE","BREAD_HEARTH","WARM_CLOTH_SMOKE","MOBILE_CAMP_BRAZIER","BREAD_CRUST_GUARD"],
	"resin":["WARM_COPPER_PIPE","RESIN_STITCH","HEATED_RESIN_CANOPY","RESIN_INSULATION","HONEY_DEW"],
	"signal":["FLAG_CODE","RETURN_RECEIPT","SHUTTERED_STATIC","BEACON_CAPACITOR","GROUNDING_CLOTH","REPLY_KNOT_MARK"],
	"pollen":["FIREFLY_PETAL","LONE_POLLEN_STAR","MIGRATING_COMET_SWARM","REMEMBERED_FIREFLY"],
	"spore":["STATION_SHELL_MIST","FLEXIBLE_SPORE_GATE","FERMENTATION_LANTERN","CULTURE_STEAM","FERMENTED_MYCELIUM","CULTURE_SHARING","VENT_BREATH"],
	"feather":["FEATHER_WIND","MOLT_AFTERIMAGE","SEASON_FEATHER_SHEAR","SEASON_QUILL"],
	"stone":["STRATIFIED_DAM","FRACTURE_PERCUSSION","STRATA_FRACTURE","SHOULDER_STONES","COUNTERWEIGHT_STRATA","REAR_LOAD_STONES","STRATA_SCRIPT","SPLIT_STRATA","FAULT_TESTIMONY","FAULT_AFTERTREMOR"],
	"chitin":["SHELL_RAIL","SHELL_STATION_JOINT","BIOBOLT_STOPPER","VEIN_TEST_BOLT","BIOBOLT_READY_RACK","ALLY_PROBE_NOTCH","SPADE_CARAPACE","VENTED_SHELL","SHARED_MOLT_SHELTER"],
	"sound":["OPEN_THORN_HARP","THORN_SCORE_WHIP","THORN_PAPER_SCORE","HOLLOW_SEED_SCORE","REFRACTED_SOUND","CHIPPED_RESONANCE","COLLAPSING_SOUND_CORE","ECHO_DUST"]
}
const IDENTITY_FAMILY := {
	"COMMANDER":"silk","BULWARK":"machine","ARCANIST":"prism","RANGER":"water","DUELIST":"ink","OATH_REAVER":"paper","BRIDGE_VANGUARD":"wood","SUNGLASS_SCRIBE":"prism",
	"ASH_MARSHAL":"bone","MOURN_ORACLE":"ghost","CINDER_STALKER":"bone","ASH_CHANTER":"silk","GRAVE_BELL":"bronze","RELIC_REAVER":"silk","OSSUARY_KNIGHT":"bone"
}
# Seven authored color roles: dark outline, low material, body, lit face,
# white core, cool/secondary accent, warm/opposed accent. No blurred light.
const PALETTES := {
	"fire":["241725","652b39","ca5141","fa9753","fff0bb","aa756a","ffce68"],
	"lightning":["131a30","34486c","5f8fc5","a0e8ee","fffbd7","bc8bdf","e5ad64"],
	"water":["152634","27546e","3d94b1","8ad7de","e2fff0","b68da6","66bbc0"],
	"detonation":["241d2c","574454","ab7255","f0ad65","fff1bf","86b5bf","c8b287"],
	"prism":["211b37","4c416f","8c78b8","b4d9e8","fff5dc","e29dc4","78d4c8"],
	"frost":["172436","3d5974","7da3bb","b9e3e7","f2ffed","c58b9a","dda36c"],
	"black_glass":["171726","303146","675071","b39fbf","f7d7e4","62c2c1","f1ac74"],
	"ink":["171d26","30434b","688a8c","bbd0c0","fff4d5","b9798c","77b8c1"],
	"paper":["251d2b","6a4749","ae7a66","e5c194","fff1cf","70b5b1","d99190"],
	"wood":["20231f","4d5840","859354","c2c17a","f2e9b9","5da99a","b78355"],
	"bone":["241e2b","61515d","a39391","ddd2b6","fff2d4","7baeb2","c38777"],
	"ghost":["171c2c","3c475f","7184a3","adc8c4","eff9d8","bd8dc0","dbad6d"],
	"silk":["251c2b","5d485e","9b8191","d5c2b4","fff1d3","72bbb9","d9948e"],
	"bronze":["231d2d","514052","9a7777","d6b68c","fff0c4","bda0d0","6ba7aa"],
	"machine":["1e2430","48505e","8b8f8e","c6ba98","fff1cd","78b9bd","e2a569"],
	"steam":["271f2a","57484d","957e78","cbb7a2","fff0ce","a0c6c1","e5aa76"],
	"resin":["28222b","6d5449","b58459","e3b77c","fff1b8","8acac0","d99992"],
	"signal":["1d1e32","4d4261","94778f","cebda0","fff5cc","78c9cc","d697b7"],
	"pollen":["21252b","4b625b","8ea876","d9db8e","fff8c9","90d9ca","e29aaf"],
	"spore":["202530","465e69","7a9ca3","b7d5bd","f4f4cf","c3a0c5","d1ad75"],
	"feather":["1d2930","3e6872","7eaaa6","b8d6bd","faf2c8","b897bc","dfad78"],
	"stone":["24232d","52515c","91858a","cbb8a0","f6e7bd","86aaa8","d28a66"],
	"chitin":["22232e","4d5261","818ca0","b9c6be","f3efc9","ba97b0","9ab875"],
	"sound":["221d34","4b426c","8a7ead","c1b9dc","fff1d8","79c9cd","dfa3a0"]
}
const SHAPES := {
	"fire":"curled-tongues/updraft-coals","lightning":"segmented-forks/short-flash-afterglow","water":"crest/drop/returning-curl","detonation":"asymmetric-pressure-blades/ballistic-scrap",
	"prism":"staggered-facets/chromatic-refraction","frost":"unequal-crystal-spines/falling-rime","black_glass":"dark-face/specular-sliver/amber-seam","ink":"broken-brush/dry-pigment/notches",
	"paper":"creased-leaf/edge-fleck","wood":"bifurcating-root/sap-node/bark-grain","bone":"irregular-rib/chalk/ashen-chip","ghost":"offset-wisp/hollow-shadow/eye-glint",
	"silk":"tensioned-thread/separate-stitch/soft-fold","bronze":"offset-bell-beat/metallic-dust","machine":"countermoving-teeth/rivet/copper-spark","steam":"open-steam-scroll/warm-vents",
	"resin":"viscous-drop/amber-suture","signal":"unequal-flag-code/short-dash","pollen":"curved-firefly-wake/petal/star-seed","spore":"gill/mist-lobe/ascending-spore",
	"feather":"quill/barb/two-speed-wind","stone":"offset-strata/mineral-seam/falling-grit","chitin":"segmented-shell/vent-light","sound":"broken-wavelets/phase-comb/resonance-fragment"
}

static func _family(row:Dictionary)->String:
	var material:=str(row.get("material",""))
	if material=="LOW_KEY_IDENTITY":return str(IDENTITY_FAMILY.get(str(row.get("hero","")),"unmapped"))
	for family:String in MATERIALS:
		if material in MATERIALS[family]:return family
	return "unmapped"

static func profile(id:String,row:Dictionary)->Dictionary:
	if bool(row.get("preserve_v4",false)):
		return {"id":id,"family":"preserve_v4","material":str(row.get("material","")),"palette":[],"shape":"accepted-v4-unchanged","layers":0,"budget":0,"semantic":"V4 route unchanged","preserve_v4":true}
	var family:=_family(row)
	var passive:=bool(row.get("passive",false)) or id.begins_with("INNATE_")
	return {"id":id,"family":family,"material":str(row.get("material","")),"palette":Array(PALETTES.get(family,[])).duplicate(),"shape":str(SHAPES.get(family,"untouched-unknown")),"layers":2 if passive else 4,"budget":12 if passive else 48,"budget_unit":"bounded logical motifs including edge candidates; not GPU calls","edge_candidates":6 if passive else 20,"semantic":("low-amplitude identity only; no fabricated proc or recipient" if passive else str(row.get("connection","existing actual-event route"))),"preserve_v4":false,"passive":passive}

static func enhance(image:Image,id:String,row:Dictionary,phase:String,frame:int)->void:
	if image==null or image.get_width()!=SIZE or image.get_height()!=SIZE:return
	if phase not in PHASES or frame<0 or frame>=FRAMES or bool(row.get("preserve_v4",false)):return
	var family:=_family(row)
	if not PALETTES.has(family):return
	var seed:=_seed(id)
	var t:=float(frame)/11.0
	var identity:=bool(row.get("passive",false)) or id.begins_with("INNATE_") or phase=="AURA"
	var alpha:=0.30+0.10*sin(t*TAU+float(seed%9)) if identity else 0.74+0.15*sin(t*PI)
	if phase=="TAIL" and not identity:alpha*=0.82-0.56*t
	if phase=="CONTACT" and not identity:alpha=minf(1.0,alpha+(0.18 if frame<3 else 0.0))
	# Fixed bounded candidate points on the original silhouette; no full-image
	# neighbor traversal. Called before extra geometry to avoid self-sampling.
	_facet_glints(image,family,seed,frame,alpha,6 if identity else 20)
	if identity:
		_identity(image,family,seed,frame,alpha)
		return
	match family:
		"fire":_fire(image,family,seed,frame,phase,alpha)
		"lightning":_lightning(image,family,seed,frame,phase,alpha)
		"water":_water(image,family,seed,frame,phase,alpha)
		"detonation":_detonation(image,family,seed,frame,phase,alpha)
		"prism","black_glass","frost":_facets(image,family,seed,frame,phase,alpha)
		"ink","paper":_documents(image,family,seed,frame,phase,alpha)
		"wood":_wood(image,family,seed,frame,phase,alpha)
		"bone","ghost":_relic(image,family,seed,frame,phase,alpha)
		"silk","resin":_threads(image,family,seed,frame,phase,alpha)
		"machine","signal":_metal(image,family,seed,frame,phase,alpha)
		"steam","spore":_vapour(image,family,seed,frame,phase,alpha)
		"pollen","feather":_migration(image,family,seed,frame,phase,alpha)
		"stone","chitin":_strata(image,family,seed,frame,phase,alpha)
		"bronze","sound":_resonance(image,family,seed,frame,phase,alpha)

static func _seed(id:String)->int:
	var result:=17
	for n:int in range(id.length()):result=posmod(result*31+id.unicode_at(n),65521)
	return result
static func _c(family:String,index:int,alpha:float=1.0)->Color:
	var color:=Color(str(PALETTES[family][posmod(index,7)]))
	color.a=clampf(alpha,0.0,1.0)
	return color
static func _pixel(im:Image,x:int,y:int,color:Color)->void:
	if x<2 or y<2 or x>=190 or y>=190 or BODY.has_point(Vector2i(x,y)):return
	var old:=im.get_pixel(x,y)
	var alpha:=color.a+old.a*(1.0-color.a)
	if alpha<=0.0:return
	var out:=Color((color.r*color.a+old.r*old.a*(1.0-color.a))/alpha,(color.g*color.a+old.g*old.a*(1.0-color.a))/alpha,(color.b*color.a+old.b*old.a*(1.0-color.a))/alpha,alpha)
	im.set_pixel(x,y,out)
static func _rect(im:Image,p:Vector2,w:int,h:int,color:Color)->void:
	var x0:=maxi(2,roundi(p.x));var x1:=mini(190,x0+maxi(w,0))
	var y0:=maxi(2,roundi(p.y));var y1:=mini(190,y0+maxi(h,0))
	for y:int in range(y0,y1):
		for x:int in range(x0,x1):_pixel(im,x,y,color)
static func _line(im:Image,a:Vector2,b:Vector2,color:Color,width:int=2)->void:
	var steps:=maxi(1,ceili(a.distance_to(b)))
	for n:int in range(steps+1):_rect(im,a.lerp(b,float(n)/steps)-Vector2.ONE*float(width/2),width,width,color)
static func _stroke(im:Image,family:String,a:Vector2,b:Vector2,alpha:float,width:int=3,index:int=3)->void:
	_line(im,a+Vector2(1,2),b+Vector2(1,2),_c(family,0,alpha*.58),width+3)
	_line(im,a,b,_c(family,index,alpha),width)
	_line(im,a+Vector2(0,-1),b+Vector2(0,-1),_c(family,4,alpha*.90),maxi(1,width/2))
static func _path(im:Image,family:String,points:Array,alpha:float,width:int=3,index:int=3)->void:
	for n:int in range(1,points.size()):_stroke(im,family,points[n-1],points[n],alpha,width,index)
static func _chip(im:Image,family:String,p:Vector2,alpha:float,length:int=5,index:int=3,lean:int=1)->void:
	_stroke(im,family,p+Vector2(-2,3),p+Vector2(lean*3,-length),alpha,3,index)
static func _spark(im:Image,family:String,p:Vector2,alpha:float,size:int=4,index:int=4)->void:
	_rect(im,p-Vector2(size/2+1,1),size+2,3,_c(family,0,alpha*.65))
	_rect(im,p-Vector2(1,size/2+1),3,size+2,_c(family,0,alpha*.65))
	_rect(im,p-Vector2(size/2,0),size,1,_c(family,index,alpha))
	_rect(im,p-Vector2(0,size/2),1,size,_c(family,index,alpha))
	_rect(im,p-Vector2.ONE,2,2,_c(family,4,alpha))
static func _facet_glints(im:Image,family:String,seed:int,frame:int,alpha:float,count:int)->void:
	for n:int in range(count):
		var x:=22+posmod(seed+n*41+frame*3,145)
		var y:=31+posmod(seed/7+n*29+frame*2,124)
		if BODY.grow(3).has_point(Vector2i(x,y)):continue
		var current:=im.get_pixel(x,y)
		if current.a<.28:continue
		var adjacent:=im.get_pixel(mini(189,x+3),maxi(2,y-2))
		if adjacent.a<.20:
			_line(im,Vector2(x-1,y),Vector2(x+2,y-2),_c(family,4,alpha*.8),2)
		elif n%3==0:_rect(im,Vector2(x,y),2,2,_c(family,5,alpha*.65))

static func _identity(im:Image,family:String,seed:int,frame:int,alpha:float)->void:
	# Three local accents, never an aura perimeter or a proc/hit animation.
	for n:int in range(3):
		var p:=Vector2(65+n*31,70+posmod(seed+n*17,15)+sin(float(frame+n*3)*TAU/12.0)*2)
		match family:
			"lightning","signal":_path(im,family,[p+Vector2(-4,2),p,p+Vector2(2,-4)],alpha,2,5)
			"water","resin":_path(im,family,[p+Vector2(0,-5),p+Vector2(-2,1),p+Vector2(1,3)],alpha,2,3)
			"wood","feather","pollen":
				_stroke(im,family,p+Vector2(-3,3),p+Vector2(3,-3),alpha,2,5)
				_line(im,p,p+Vector2(4,0),_c(family,3,alpha),2)
			"stone","chitin","machine","bone":_path(im,family,[p+Vector2(-4,1),p+Vector2(1,-3),p+Vector2(4,-1)],alpha,2,3)
			_:
				_rect(im,p,3,2,_c(family,3,alpha))
				_rect(im,p+Vector2(3,-2),2,2,_c(family,5,alpha*.85))

static func _fire(im:Image,family:String,seed:int,f:int,phase:String,a:float)->void:
	var count:=7 if phase=="CAST" else 10
	for n:int in range(count):
		var rise:=float(posmod(f*5+n*11+seed,48))
		var p:=Vector2(42+posmod(n*31+seed,115),146-rise)
		var curl:=sin(float(n+f)*.7)*5.0
		var height:=10.0+float((n+seed)%4)*3.0
		_path(im,family,[p+Vector2(-3,3),p+Vector2(3,-3),p+Vector2(curl,-height),p+Vector2(curl-3,-height-5)],a*.78,4,2)
		_path(im,family,[p,p+Vector2(2,-5),p+Vector2(curl*.5,-height+3)],a,2,6)
		if n%2==0:_rect(im,p+Vector2(curl-2,-height-11),3,4,_c(family,3,a*.65))
	# A separated coal after the upward tongue, not repeated white explosions.
	_spark(im,family,Vector2(131+seed%17,47-posmod(f*3,16)),a*.70,5,6)

static func _lightning(im:Image,family:String,seed:int,f:int,phase:String,a:float)->void:
	var flash:=1.0 if f%4 in [0,1] else .45
	for n:int in range(3):
		var p:=Vector2(36+n*46,62+posmod(seed+n*17,38))
		var bend:=float(5+posmod(seed+n*7+f*3,13))
		var points:Array=[p,p+Vector2(12,-bend),p+Vector2(19,4),p+Vector2(31,-bend*.5),p+Vector2(41,2)]
		_path(im,family,points,a*flash,3,5 if n%2 else 3)
		_path(im,family,[points[1],points[1]+Vector2(-5,-10),points[1]+Vector2(2,-17)],a*flash*.7,2,3)
		var knot:Vector2=points[1+posmod(f+n,3)]
		_spark(im,family,knot,a*flash,5+(n%2),4)
	if phase=="TAIL":_line(im,Vector2(43,151),Vector2(70+f*3,148),_c(family,5,a*.4),2)

static func _water(im:Image,family:String,seed:int,f:int,phase:String,a:float)->void:
	var time:=float(f)/11.0
	# Two asymmetrical open crests: no full disk, no harmful blast for healing.
	for side:int in [-1,1]:
		var p:=Vector2(96+side*(37+sin(time*PI)*8),135)
		var h:=34.0+float((seed+side)%9)
		var points:Array=[p+Vector2(side*12,5),p+Vector2(side*19,-10),p+Vector2(side*20,-h),p+Vector2(side*9,-h-10),p+Vector2(side*2,-h-6),p+Vector2(side*6,-h)]
		_path(im,family,points,a*.7,5,2)
		_path(im,family,[points[1]+Vector2(0,-2),points[2]+Vector2(-side*2,-2),points[3],points[4]],a,2,3)
	for n:int in range(7):
		var drop:=Vector2(38+posmod(seed+n*23,121),62+posmod(n*19+f*(2+n%2),73))
		var length:=4+n%3
		_path(im,family,[drop+Vector2(0,-length),drop+Vector2(-2,2),drop+Vector2(1,4),drop+Vector2(3,1)],a*.8,2,3)
		_rect(im,drop+Vector2(-1,0),2,2,_c(family,4,a))
	# Horizontal foam is an open shoreline, not a rule radius.
	for n:int in range(4):_stroke(im,family,Vector2(44+n*28,149+n%2*3),Vector2(54+n*28+f%3,148+n%2*3),a*.55,2,5)

static func _detonation(im:Image,family:String,seed:int,f:int,phase:String,a:float)->void:
	var expand:=minf(1.0,float(f+2)/7.0)
	if phase=="CAST":expand*=.6
	for n:int in range(8):
		var angle:=float(n)*TAU/8.0+float(seed%11)*.08
		var axis:=Vector2(cos(angle),sin(angle)*.68)
		var p:=Vector2(96,111)+axis*(24+expand*(19+n%3*8))+Vector2(0,f*f*.10)
		_stroke(im,family,p-axis*float(7+n%4),p+axis*float(3+n%3),a*(1.0-float(f)*.04),4,2 if n%3 else 5)
		if n%2==0:_spark(im,family,p,a*(1.0-float(f)*.05),5,6)
	# White core is short and offset above the body. Impact, not steady beacon.
	if phase=="CONTACT" and f<4:
		_spark(im,family,Vector2(114,72),a,12-f*2,4)
		_spark(im,family,Vector2(72,89),a*.8,7,6)

static func _facets(im:Image,family:String,seed:int,f:int,phase:String,a:float)->void:
	for n:int in range(7):
		var p:=Vector2(35+posmod(seed+n*29,125),50+posmod(seed/3+n*19+f*(1+n%2),96))
		var height:=6+n%4*2
		var lean:float=sin(float(f+n)*.55)*4
		var points:Array=[p+Vector2(0,height),p+Vector2(lean-3,0),p+Vector2(lean,-height),p+Vector2(lean+4,0),p+Vector2(0,height)]
		_path(im,family,points,a*.75,3,2 if family=="black_glass" else 3)
		_line(im,p+Vector2(lean,-height+2),p+Vector2(lean+3,-1),_c(family,4,a),2)
		_line(im,p+Vector2(lean+1,1),p+Vector2(0,height-2),_c(family,6 if n%2 else 5,a*.85),2)
		if family=="frost":_line(im,p,p+Vector2(-7,3),_c(family,3,a*.7),2)
		elif n%2==0:_spark(im,family,p+Vector2(6,-height-3),a*.75,4,5)
	if family=="black_glass":
		for n:int in range(3):_line(im,Vector2(40+n*40,149),Vector2(54+n*40+f%3,145),_c(family,6,a*.7),2)

static func _documents(im:Image,family:String,seed:int,f:int,phase:String,a:float)->void:
	for n:int in range(6):
		var p:=Vector2(38+posmod(seed+n*31+f*2,121),53+posmod(n*23+seed/5-f*2,95))
		if family=="ink":
			_path(im,family,[p+Vector2(-5,4),p,p+Vector2(2,-7)],a*.72,4,1)
			_line(im,p+Vector2(-2,3),p+Vector2(2,-5),_c(family,4,a*.9),2)
			_rect(im,p+Vector2(5,-3),3,2,_c(family,5,a*.7))
		else:
			var flutter:=float((f+n)%3)-1
			_path(im,family,[p+Vector2(-4,-5),p+Vector2(4,-3+flutter),p+Vector2(5,5),p+Vector2(-3,3),p+Vector2(-4,-5)],a*.75,2,3)
			_line(im,p+Vector2(-1,-1),p+Vector2(3,-1+flutter),_c(family,1,a),2)
			_line(im,p+Vector2(2,-4),p+Vector2(4,-2),_c(family,4,a),2)
	# Short dry-brush footmarks are not new circles or target boxes.
	for n:int in range(3):_stroke(im,family,Vector2(51+n*34,148+n%2*3),Vector2(62+n*34,147),a*.5,2,5)

static func _wood(im:Image,family:String,seed:int,f:int,phase:String,a:float)->void:
	for side:int in [-1,1]:
		var p:=Vector2(96+side*43,146)
		var q:=p+Vector2(side*10,-25-sin(float(f)*.35)*4)
		_path(im,family,[p,p+Vector2(side*9,-10),q,q+Vector2(-side*3,-16)],a*.7,4,2)
		_path(im,family,[q,q+Vector2(side*12,-9),q+Vector2(side*17,-11)],a*.7,2,5)
		for n:int in range(2):_line(im,p+Vector2(side*(5+n*2),-8-n*9),p+Vector2(side*(9+n*2),-11-n*9),_c(family,4,a*.7),2)
	for n:int in range(5):
		var p:=Vector2(41+posmod(seed+n*29,112),62+posmod(n*13-f*2+seed,50))
		_chip(im,family,p,a*.75,4,5 if n%2 else 3,1 if n%2 else -1)
		_rect(im,p+Vector2(2,2),2,3,_c(family,6,a*.6))

static func _relic(im:Image,family:String,seed:int,f:int,phase:String,a:float)->void:
	for n:int in range(6):
		var p:=Vector2(38+posmod(seed+n*27,120),58+posmod(n*23-f*2+seed/5,85))
		if family=="bone":
			_chip(im,family,p,a*.8,6+n%3,3,1 if n%2 else -1)
			_rect(im,p+Vector2(-3,2),4,3,_c(family,4,a*.75))
		else:
			var drift:=sin(float(f+n)*.6)*5
			_path(im,family,[p+Vector2(-6,7),p+Vector2(drift,-1),p+Vector2(drift+4,-10)],a*.5,4,2)
			_line(im,p+Vector2(drift,-1),p+Vector2(drift+2,-8),_c(family,5,a*.85),2)
			if n%2==0:_rect(im,p+Vector2(drift-2,-4),3,2,_c(family,4,a*.8))
	if family=="bone":
		for n:int in range(3):_rect(im,Vector2(47+n*45+f%4,150+n%2*3),3,3,_c(family,5,a*.6))

static func _threads(im:Image,family:String,seed:int,f:int,phase:String,a:float)->void:
	for side:int in [-1,1]:
		var x:=96+side*(39+seed%7)
		var sway:=sin(float(f)*.5+side)*7.0
		var points:Array=[Vector2(x+side*13,141),Vector2(x+side*18,112),Vector2(x+sway,85),Vector2(x-side*7,64)]
		_path(im,family,points,a*.6,3,5 if family=="silk" else 2)
		var segment:=posmod(f/3,3)
		var bead:Vector2=Vector2(points[segment]).lerp(points[segment+1],float(f%3)/3)
		if family=="resin":
			_path(im,family,[bead+Vector2(0,-5),bead+Vector2(-3,2),bead+Vector2(1,5),bead+Vector2(3,0)],a,3,3)
		else:_spark(im,family,bead,a,5,4)
	for n:int in range(4):
		var p:=Vector2(41+posmod(seed+n*31,115),151-posmod(f*3+n*17,73))
		_line(im,p+Vector2(-3,2),p+Vector2(3,-2),_c(family,3,a*.8),2)
		if n%2==0:_rect(im,p,2,2,_c(family,4,a))

static func _metal(im:Image,family:String,seed:int,f:int,phase:String,a:float)->void:
	for n:int in range(6):
		var p:=Vector2(38+posmod(seed+n*31,121),58+posmod(seed/3+n*19,87))
		var offset:=float(posmod(f+n,4)-2)
		if family=="signal":
			_path(im,family,[p+Vector2(-5,offset),p+Vector2(-5,-7),p+Vector2(4,-5),p+Vector2(1,-1)],a*.65,2,5 if n%2 else 3)
			_rect(im,p+Vector2(6,-4+offset),4,2,_c(family,4,a*.75))
		else:
			_stroke(im,family,p+Vector2(-4,offset),p+Vector2(5,-2+offset),a*.75,3,2)
			_line(im,p+Vector2(1,-4+offset),p+Vector2(1,3+offset),_c(family,6,a*.9),2)
			_rect(im,p+Vector2(-1,-2+offset),2,2,_c(family,4,a))
	for n:int in range(3):
		var p:=Vector2(43+posmod(seed+n*39+f*5,115),75+posmod(n*17+f*3,67))
		_chip(im,family,p,a*.6,4,6,-1)

static func _vapour(im:Image,family:String,seed:int,f:int,phase:String,a:float)->void:
	for n:int in range(5):
		var rise:=float(posmod(f*3+n*17+seed,59))
		var p:=Vector2(43+posmod(seed+n*31,114),147-rise)
		var curl:=sin(float(f+n)*.6)*6.0
		_path(im,family,[p+Vector2(-4,4),p+Vector2(-8,-2),p+Vector2(-3,-10),p+Vector2(curl+4,-12),p+Vector2(curl+6,-7)],a*.40,4,2)
		_line(im,p+Vector2(-5,-6),p+Vector2(0,-10),_c(family,3,a*.55),2)
		if family=="spore":
			_rect(im,p+Vector2(7,-17),3,4,_c(family,5,a*.75))
			_line(im,p+Vector2(7,-11),p+Vector2(7,-8),_c(family,4,a*.65),1)
		else:_rect(im,p+Vector2(-4,-17),3,2,_c(family,6,a*.7))

static func _migration(im:Image,family:String,seed:int,f:int,phase:String,a:float)->void:
	for n:int in range(8):
		var p:=Vector2(35+posmod(seed+n*23+f*(2+n%2),126),61+posmod(seed/7+n*17-f*2,85))
		if family=="pollen":
			_line(im,p+Vector2(-9,5),p+Vector2(-4,2),_c(family,5,a*.5),2)
			_spark(im,family,p,a*(.65+.25*sin(float(f+n))),5+n%2,3 if n%2 else 4)
			_line(im,p+Vector2(-3,-2),p+Vector2(-6,-4),_c(family,6,a*.8),2)
		else:
			_stroke(im,family,p+Vector2(-5,5),p+Vector2(6,-6),a*.7,2,3)
			for barb:int in range(3):_line(im,p+Vector2(-3+barb*3,3-barb*3),p+Vector2(2+barb*3,3-barb*3),_c(family,5 if barb%2 else 4,a*.7),2)

static func _strata(im:Image,family:String,seed:int,f:int,phase:String,a:float)->void:
	for n:int in range(6):
		var p:=Vector2(35+posmod(seed+n*27,124),80+posmod(n*19+seed/5,66)+float(f*f)*.06)
		var width:=5+n%3*2
		_path(im,family,[p+Vector2(-width,0),p+Vector2(-width+2,-5),p+Vector2(width,-3),p+Vector2(width-2,3)],a*.75,3,2)
		_line(im,p+Vector2(-width+2,-5),p+Vector2(width-1,-3),_c(family,3,a),2)
		if family=="chitin":_line(im,p+Vector2(-2,-4),p+Vector2(0,2),_c(family,5,a*.85),2)
		else:_line(im,p+Vector2(-3,0),p+Vector2(2,-2),_c(family,6,a*.8),2)
	for n:int in range(5):_rect(im,Vector2(38+posmod(seed+n*29+f*2,121),146+posmod(n*7+f,15)),2+n%2,3,_c(family,3,a*.6))

static func _resonance(im:Image,family:String,seed:int,f:int,phase:String,a:float)->void:
	for side:int in [-1,1]:
		for n:int in range(3):
			var spread:=33.0+float(n)*13.0+float(f%4)*1.5
			var p:=Vector2(96+side*spread,112+sin(float(f+n)*.5)*3)
			# Open, asymmetric beat combs: never an all-around aura boundary.
			_path(im,family,[p+Vector2(-side*3,-17-n*2),p+Vector2(side*3,-6),p+Vector2(side*5,7),p+Vector2(side*2,15+n*2)],a*(.75-float(n)*.10),2,3 if family=="bronze" else 5)
			if (n+f)%3==0:_spark(im,family,p+Vector2(side*3,-7),a*.8,4,4)
	for n:int in range(3):
		var p:=Vector2(57+n*39,59+posmod(seed+n*13-f*3,25))
		_line(im,p,p+Vector2(5,3),_c(family,6,a*.7),2)
