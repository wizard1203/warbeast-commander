extends RefCounted
## Static obstacle material and bounded complete sprite compositions. The
## observed circular union is the only footprint; no inferred collision.
const Collection = preload("res://src/presentation/heroic_collection.gd")
const Groves = preload("res://src/presentation/m66_terrain_art.gd")
const Mountains = preload("res://src/presentation/heroic_mountain_art.gd")
const VERSION := "heroic-physical-biome-art-m75-v2"
const INK := Color("171820")
const COLORS := {
	"TREE":["1d3028","294332","344b35","3f5838","5d7046"],
	"MOUNTAIN":["292b34","3d3e47","54515a","69626a","8c7f82"],
	"GLACIER":["263644","426775","699eae","a4cbd2","e0ede8"],
	"LAVA":["251d28","392630","62402f","ba522e","eda74d"],
}
static var _textures: Dictionary = {}
static var _bakes := 0
static var _painted_pixels := 0

static func handles(body: Dictionary) -> bool:
	return not str(body.get("cluster_id","")).is_empty() and str(body.get("kind","")) in COLORS

static func draw(canvas: Object,point: Vector2,body: Dictionary,faction: String,factor: float) -> bool:
	if not handles(body) or not point.is_finite() or not is_finite(factor) or factor<=0: return false
	var radius := float(body.get("radius",0))
	if not is_finite(radius) or radius<=0 or radius>160: return false
	var kind := str(body.kind)
	var key := str(body.get("id","")).sha256_text().substr(0,8).hex_to_int()
	if kind=="TREE":
		if not Collection.active(): return Groves.draw_tree(canvas,point,body,faction,factor)
		var offsets := [Vector2(-0.58,-0.17),Vector2(-0.12,-0.39),Vector2(0.38,-0.33),Vector2(0.66,0.08),Vector2(-0.60,0.30),Vector2(-0.17,0.14),Vector2(0.27,0.30),Vector2(-0.13,0.57)]
		var drawn := false
		for index: int in range(offsets.size()):
			var source := Groves.isolated_source(faction,key+index*7)
			var scale := radius/float(source.size.y)*(0.54+float((key+index)%3)*0.045)
			drawn=Collection.draw_region(canvas,"overworld",Groves.FILE,source,point+Vector2(offsets[index])*radius*factor,Vector2(source.size.x*0.5,source.size.y-1),scale*factor) or drawn
		return drawn
	if kind=="MOUNTAIN": return Mountains.draw(canvas,point,body,faction,factor)
	if kind=="GLACIER" and Collection.active():
		# Existing full isolated ice peaks, sampled at their original pixel
		# density. A cold stratified base below is baked from the real union.
		var parts := [Vector2(-0.40,0.08),Vector2(0.19,-0.14),Vector2(0.38,0.35),Vector2(-0.20,0.53)]
		var drawn := false
		for index: int in range(parts.size()):
			var source := Rect2i(624,400,32,32) if index<2 else Rect2i(640,352,16,16)
			var scale := radius/float(source.size.y)*(1.0 if index<2 else 0.72)
			var texture := _ice_peak(source)
			if texture==null: continue
			var foot := point+Vector2(parts[index])*radius*factor
			canvas.draw_texture_rect(texture,Rect2((foot-Vector2(source.size.x*0.5,source.size.y-1)*scale*factor).round(),Vector2(source.size)*scale*factor),false,Color.WHITE)
			drawn=true
		return drawn
	# The active collection ground already contains one continuous world-space
	# lava fissure across the union. Per-circle raised disks would disclose the
	# collision decomposition as three artificial octagonal stepping stones.
	if kind=="LAVA" and Collection.active(): return true
	# Lava has no selected licensed complete basin. These are original coarse
	# rock/flow pixels, generated once per four variants, never illustrations.
	var texture := _texture(kind,key%(2 if kind=="GLACIER" else 4))
	var size := Vector2(radius*1.7,radius*1.7)*factor
	canvas.draw_texture_rect(texture,Rect2((point-size*0.5).round(),size.round()),false,Color.WHITE)
	return true

static func paint(image: Image,snapshot: Dictionary,bounds: Rect2,pixel: float) -> Dictionary:
	var report := {"version":VERSION,"groups":0,"pixels":0,"per_kind":{},"geometry":"observed-circle-union","per_frame_pixel_work":0,"failures":[]}
	if image==null or image.is_empty() or not is_finite(pixel) or pixel<=0 or image.get_width()>2048 or image.get_height()>2048: return report
	var groups := {}
	for body: Dictionary in snapshot.get("terrain",[]):
		if not handles(body): continue
		var id := str(body.cluster_id)
		if not groups.has(id): groups[id]=[]
		if groups[id].size()<3: groups[id].append(body)
	if groups.size()>4: report.failures.append("Physical biome group budget exceeded");return report
	for id: String in groups:
		var members: Array=groups[id]
		var kind := str(members[0].kind)
		var area := Rect2(Vector2(members[0].position),Vector2.ZERO).grow(float(members[0].radius))
		for member: Dictionary in members: area=area.merge(Rect2(Vector2(member.position),Vector2.ZERO).grow(float(member.radius)))
		var first := Vector2i(((area.position-bounds.position)/pixel).floor()).clamp(Vector2i.ZERO,image.get_size())
		var end := Vector2i(((area.end-bounds.position)/pixel).ceil()).clamp(Vector2i.ZERO,image.get_size())
		var colors: Array=COLORS[kind]
		var centers: Array[Vector2]=[]
		for member: Dictionary in members: centers.append(Vector2(member.position))
		var count := 0
		for y: int in range(first.y,end.y):
			for x: int in range(first.x,end.x):
				var point := bounds.position+(Vector2(x,y)+Vector2.ONE*0.5)*pixel
				if not _inside(point,members): continue
				var inset := _inset(point,members)
				var cell := Vector2i((point/4.0).floor())
				var key := posmod(cell.x*13+cell.y*29+cell.x*cell.y*3,127)
				var level := 1 if key<56 else 2 if key<106 else 3
				if kind=="LAVA":
					# A shared winding main flow joins physical members, with
					# tributaries in stable coarse world pixels, not sprite tiles.
					var flow := _flow_distance(point,centers)
					var width := 13.0+float(posmod(int(cell.x/3)+int(cell.y/4),5))*2.0
					var fissure := posmod(cell.x+int(cell.y/3),17)<=1 or posmod(cell.y+int(cell.x/5),23)==0
					level=4 if flow<width and key>34 else 3 if flow<width+7.0 or fissure else 1 if key<99 else 2
				elif kind=="GLACIER": level=1 if posmod(cell.x+cell.y*3,21)<2 else 4 if key>116 else 2 if key<70 else 3
				var under := image.get_pixel(x,y)
				var material := Color(str(colors[level]))
				# A bounded in-footprint fringe blends with the existing soil.
				# Its jagged pixel-width varies but never paints outside physics;
				# no full black circular plate is imposed around every grove.
				var fringe := 14.0+float(posmod(int(cell.x/2)+int(cell.y/3),4))*3.0
				var coverage := clampf(inset/fringe,0.0,1.0)
				coverage=0.23+coverage*0.77
				if kind=="TREE": coverage*=0.58
				if inset<pixel*1.5 and key%5==0: material=material.lerp(INK,0.6)
				image.set_pixel(x,y,under.lerp(material,coverage))
				count+=1
		report.groups+=1
		report.pixels+=count
		report.per_kind[kind]=int(report.per_kind.get(kind,0))+count
	_bakes+=1
	_painted_pixels+=int(report.pixels)
	return report

static func _inside(point: Vector2,members: Array) -> bool:
	for member: Dictionary in members:
		if point.distance_squared_to(Vector2(member.position))<=pow(float(member.radius),2): return true
	return false

static func _inset(point: Vector2,members: Array) -> float:
	var depth := 0.0
	for member: Dictionary in members: depth=maxf(depth,float(member.radius)-point.distance_to(Vector2(member.position)))
	return depth

static func _flow_distance(point: Vector2,centers: Array[Vector2]) -> float:
	var result := INF
	for index: int in range(maxi(centers.size()-1,1)):
		var start: Vector2=centers[index]
		var finish: Vector2=centers[mini(index+1,centers.size()-1)]
		var delta := finish-start
		var progress := clampf((point-start).dot(delta)/maxf(delta.length_squared(),1.0),0.0,1.0)
		var middle := start+delta*progress
		var wave := sin(progress*PI*3.0+float(index))*9.0
		middle+=delta.orthogonal().normalized()*snappedf(wave,4.0)
		result=minf(result,point.distance_to(middle))
	return result

static func _ice_peak(rect: Rect2i) -> Texture2D:
	var key := "ICE_PEAK:"+str(rect.size.x)
	if _textures.has(key): return _textures[key]
	var sheet := Collection.image("overworld",Groves.FILE)
	if sheet==null: return null
	var pixels := sheet.get_region(rect)
	# Retain the author's silhouette, alpha, darkest coarse contour and
	# facet/shadow order; only grey rock midtones become blue glacial ice.
	var ramp := [Color("243442"),Color("477c96"),Color("7eb4ca"),Color("c2e2e6"),Color("edf7ef")]
	for y: int in range(pixels.get_height()):
		for x: int in range(pixels.get_width()):
			var old := pixels.get_pixel(x,y)
			if old.a<=0.0 or maxf(old.r,maxf(old.g,old.b))<0.16: continue
			var brightness := old.get_luminance()
			var index := 0 if brightness<0.25 else 1 if brightness<0.39 else 2 if brightness<0.58 else 3 if brightness<0.78 else 4
			var tint: Color=ramp[index]
			tint.a=old.a
			pixels.set_pixel(x,y,tint)
	_textures[key]=ImageTexture.create_from_image(pixels)
	return _textures[key]

static func _texture(kind: String,variant: int) -> Texture2D:
	var id := kind+":"+str(variant)
	if _textures.has(id): return _textures[id]
	var image := Image.create(64,64,false,Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var colors: Array=COLORS[kind]
	for y: int in range(5,59):
		for x: int in range(5,59):
			var point := Vector2(x-32,y-32)
			var octagon := maxf(absf(point.x),absf(point.y))+minf(absf(point.x),absf(point.y))*0.43
			if octagon>25.0: continue
			var stepped := float(posmod(int(x/3)+variant*5,7))
			var crack := posmod(x+int(y/3)+variant*5,17)<=1 or posmod(y+int(x/7)+variant*3,19)==0
			var rock := posmod(x*7+y*13+int(x*y/17)+variant*11,43)
			var level := 4 if crack and rock>26 else 3 if crack else 2 if rock>31 else 1
			if kind=="GLACIER": level=4 if posmod(x+y,13)==0 else 3 if rock>23 else 2
			if octagon>22.0 or (y>24+stepped and y<27+stepped and x%13<9): image.set_pixel(x,y,INK)
			else: image.set_pixel(x,y,Color(str(colors[level])))
	_textures[id]=ImageTexture.create_from_image(image)
	return _textures[id]

static func debug_stats() -> Dictionary:
	var bytes := 0
	for texture: Texture2D in _textures.values(): bytes+=texture.get_width()*texture.get_height()*4
	return {"version":VERSION,"texture_count":_textures.size(),"maximum_texture_count":8,"generated_texture_bytes":bytes,"bakes":_bakes,"painted_pixels":_painted_pixels,"per_instance_textures":0,"per_frame_pixel_work":0,"max_draw_calls_per_body":8}
