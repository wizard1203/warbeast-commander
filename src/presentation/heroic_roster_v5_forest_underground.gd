extends RefCounted
## V5 original pixel authoring only. No simulation, clocks, nodes or authority.
## Coordinates remain sprite-local. The consumer supplies truthful phases/events.
const P = preload("res://src/presentation/heroic_roster_v5_pixels.gd")
const AcceptedMyc = preload("res://src/presentation/heroic_r7_myc_spectacle.gd")
const VERSION := "v5-forest-underground-original-choreography-1"
const SIZE := 192
const FRAMES := 12
const ANCHOR := Vector2i(96,136)
const ROOT := ["#171f20","#344633","#6b7150","#afc27b","#f4e7b2","#d19760","#6aa99b"]
const SEED := ["#181e2b","#3d454f","#717a46","#abc475","#f4ecc9","#e697bd","#879fd8"]
const WIND := ["#17242b","#395d69","#73a8ae","#d39a7c","#fff1c9","#a6bb8c","#b39bc8"]
const WATER := ["#18232b","#3b6666","#78aea0","#d79cab","#fff0c9","#a3c4dc","#cfca8e"]
const THORN := ["#231d29","#514438","#89845b","#bd768b","#f4dcad","#92bda3","#c9a3dc"]
const GRAFT := ["#241c21","#514637","#8a7446","#c59d67","#fff0bd","#b9cc77","#cd718c"]
const ANTLER := ["#192522","#465849","#849479","#c3b18c","#f8ebc5","#ce8b70","#8eb7a0"]
const COMET := ["#1b2031","#49445c","#658a8a","#a9d681","#fff4be","#db99c0","#89b9dd"]
const SHELL := ["#1b202b","#3f4056","#777081","#a6a484","#f3e7be","#87bdab","#d99c79"]
const ECHO := ["#1c1c2b","#3d3658","#756a8d","#9ac6d0","#f7e8d0","#ba93d3","#87bb9a"]
const BOLT := ["#1e1e28","#443b4a","#7c6a7e","#bb8d9e","#f2d7a1","#94c78b","#78aca4"]
const FERMENT := ["#1e1d29","#46404d","#81725d","#c3af76","#fff0be","#a2c68b","#bd9ebc"]
const STRATA := ["#1c2028","#454750","#77747a","#b7a286","#f4e6bf","#81aabd","#bd92b7"]
const PRISM := ["#191e2c","#3a3c59","#666c8d","#8cbcd4","#fff1db","#c19de1","#87bfb1"]
const MOLT := ["#21212b","#474454","#82787a","#c0a882","#f3e8c4","#99c9b5","#ba9cc6"]
const MYC := ["#151622","#493650","#735574","#a6cb61","#fff5ce","#487f75","#a2dcc4"]

const PROFILES: Dictionary = {
 "VINE_SHOCK":{"hero":"VINE_WARDEN","faction":"FOREST","name":"根心复苏","material":"ROOT_EARTH","motif":"hive_root_stitch","form":"open_hive_ribs_gathering_inward","gesture":"两根重根臂合扣蜂箱","connection":"栗根内收、蜜液上行，非攻击光束","palette":ROOT,"story":"借根养蜂人修复借来的躯体，不把蜂群当弹药。","cast_notes":"肩边泥根反向抬起，胸前留空。","contact_notes":"厚根扣合伴琥珀液珠回体。","tail_notes":"泥块先落，花粉慢半拍消散。","passive":false},
 "VINE_WARD":{"hero":"VINE_WARDEN","faction":"FOREST","name":"老树皮","material":"BARK_HONEY","motif":"borrowed_bark_seams","form":"unequal_bark_shingles","gesture":"肩壳与根臂错层呼吸","connection":"低亮树液沿三处甲缝流转","palette":ROOT,"story":"老树保留离开的权利，护甲像借来的树皮而非密封罩。","cast_notes":"被动不制造主动起势。","contact_notes":"只在真实被动有效时低亮。","tail_notes":"树液在甲缝收回。","passive":true},
 "VINE_MEND":{"hero":"VINE_WARDEN","faction":"FOREST","name":"古根囚牢","material":"HIVE_ROOT_POLLEN","motif":"hive_route_root_clasp","form":"asymmetric_root_buttresses_open_crown","gesture":"高根臂拉开蜂路","connection":"低伏蜂路先串真实落点，根扣后合","palette":ROOT,"story":"守护出口的养蜂人以临时借根截住追击，不生成可碰撞树墙。","cast_notes":"两侧大根撑开，蜜色团向外迁移。","contact_notes":"不齐的根柱半环扣住实际受控者。","tail_notes":"亮蜜撤去后只留稀薄根影。","passive":false},
 "INNATE_VINE_WARDEN":{"hero":"VINE_WARDEN","faction":"FOREST","name":"扎根生息","material":"HONEY_DEW","motif":"stationary_hive_dew","form":"three_asymmetric_honeycomb_pores","gesture":"胸箱小孔呼吸","connection":"仅静止生息真实生效时有蜜点回流","palette":ROOT,"story":"借根不是囚根，驻足时才容许缓慢交换。","cast_notes":"不伪造施法。","contact_notes":"蜂孔里三点暖光依次亮。","tail_notes":"移动立即由消费者关闭。","passive":true},
 "LEAF_BIND":{"hero":"LEAF_SEER","faction":"FOREST","name":"织根缚","material":"SEED_ROOT_GLASS","motif":"experimental_graft_suture","form":"forked_seed_seams_and_root_catches","gesture":"种匣两片透叶翻开","connection":"种脉从叉杖分岔，不画额外命中","palette":SEED,"story":"未入册育种师将失败种子的叶脉缝回土缝。","cast_notes":"两张透叶如不齐的试验页。","contact_notes":"根节锁扣在目标足边合拢。","tail_notes":"粉色种粉被低根线收回。","passive":false},
 "LEAF_FLARE":{"hero":"LEAF_SEER","faction":"FOREST","name":"叶辉","material":"POLLEN_FACET","motif":"translucent_trial_leaf_fan","form":"staggered_translucent_leaf_blades","gesture":"双叉杖横扫，匣盖错开","connection":"不等长叶片按扇面先后展开","palette":SEED,"story":"失败植株的叶脉提供投递，而非神谕的统一光环。","cast_notes":"三张晶叶向一侧折叠。","contact_notes":"粉绿、雾紫叶脉依次扫过真实目标。","tail_notes":"叶片裂为细种粉，不再伤害。","passive":false},
 "LEAF_OATH":{"hero":"LEAF_SEER","faction":"FOREST","name":"古根囚印","material":"ROOT_KNOT_SEED","motif":"single_root_seed_vise","form":"single_inverted_seed_clamp","gesture":"种匣倒扣、叉杖相合","connection":"一条细根牵到唯一合法受控者","palette":SEED,"story":"她曾封住水渠，因此只夹一名目标，不再把一片土地封死。","cast_notes":"巨大空心种壳从两肩反向翻起。","contact_notes":"单个倒种荚夹合，中心持续留白。","tail_notes":"短根松开，不作范围爆炸。","passive":false},
 "INNATE_LEAF_SEER":{"hero":"LEAF_SEER","faction":"FOREST","name":"林律捕隙","material":"SEED_DIAGRAM","motif":"notched_seed_attention","form":"offcenter_seed_notch_ticks","gesture":"缺口叶脉微亮","connection":"真实捕隙触发才闪小刻痕","palette":SEED,"story":"从失败种植的缺口辨认机会。","cast_notes":"不生成大型法阵。","contact_notes":"叶脉三个不齐短刻亮起。","tail_notes":"向种匣内缩。","passive":true},
 "WIND_SHOT":{"hero":"WIND_COURIER","faction":"FOREST","name":"风弦","material":"FEATHER_WIND","motif":"frost_notice_feather_arrow","form":"long_feathered_arrow_and_split_wake","gesture":"轻骨弓反曲蓄弦","connection":"窄湖青尾迹与玫金实羽同向","palette":WIND,"story":"报霜的候鸟把难听的真消息先送到。","cast_notes":"羽梢与弓背共同后张。","contact_notes":"实体箭头刺入一个合法目标，羽丝延后散。","tail_notes":"尾羽逆风分离，不变成追踪分身。","passive":false},
 "WIND_FERVOR":{"hero":"WIND_COURIER","faction":"FOREST","name":"疾叶","material":"MOLT_AFTERIMAGE","motif":"two_staggered_molt_wings","form":"offset_feather_afterimages","gesture":"肩羽交错张开","connection":"残影跟随本体，不投向敌人","palette":WIND,"story":"换羽是时间残相，不是召唤候鸟作战。","cast_notes":"两簇长羽在背后错位。","contact_notes":"淡紫旧羽与湖青新羽交替。","tail_notes":"羽缘向后收束。","passive":false},
 "WIND_MEND":{"hero":"WIND_COURIER","faction":"FOREST","name":"风路横剪","material":"SEASON_FEATHER_SHEAR","motif":"migration_route_crosswind","form":"long_crosswind_feather_shear","gesture":"长弓横切、四尾羽分流","connection":"清晰直线风路连起真实命中，不是自身强化","palette":WIND,"story":"同一条季节消息穿过一列接力站。","cast_notes":"雾蓝尾羽折成断旗。","contact_notes":"长不等羽刃同向穿线，实羽与风带分离。","tail_notes":"由远至近卷成单尾迹。","passive":false},
 "INNATE_WIND_COURIER":{"hero":"WIND_COURIER","faction":"FOREST","name":"踏风蓄弦","material":"SEASON_QUILL","motif":"single_charged_quill","form":"offset_four_feather_ticks","gesture":"候鸟冠轻扬","connection":"一片蓄能羽只贴本体","palette":WIND,"story":"路程蓄下下一箭，而非不断凭空加速。","cast_notes":"不改移动位置。","contact_notes":"四枚羽刻从后向前亮。","tail_notes":"真实次数消耗后消散。","passive":true},
 "BLOOM_SPRING":{"hero":"BLOOM_GUIDE","faction":"FOREST","name":"花泉光环","material":"SALT_WATER_LEDGER","motif":"low_tidal_measure","form":"three_open_water_gauge_petals","gesture":"量水盘分段呼吸","connection":"浅低水位流，不画治疗十字","palette":WATER,"story":"盐沼量水师为活根外的生命也分春水。","cast_notes":"被动低亮，无主动爆点。","contact_notes":"盐白刻痕和青水错拍。","tail_notes":"随真实光环失效关闭。","passive":true},
 "BLOOM_TOUCH":{"hero":"BLOOM_GUIDE","faction":"FOREST","name":"新芽抚触","material":"SALT_RINSE_WATER","motif":"shell_cup_rinse_and_rise","form":"tilted_cup_spill_and_upward_dew","gesture":"贝壳叶杯向外倾","connection":"盐粒下落、水珠上行，连接真实受疗者","palette":WATER,"story":"她救人靠分水排盐，不靠通用绿色神光。","cast_notes":"大贝杯弧边从侧肩展开。","contact_notes":"桃粉水滴沿青流上抬。","tail_notes":"重盐先落、轻露后消。","passive":false},
 "BLOOM_SANCTUARY":{"hero":"BLOOM_GUIDE","faction":"FOREST","name":"长春庇护","material":"TIDAL_CANOPY","motif":"shared_reflow_channels","form":"open_water_canopy_with_return_channels","gesture":"量水盘抬高、叶杯分流","connection":"蓝量与行军窗口以回流表示，不伪造治疗","palette":WATER,"story":"撕席签后在堤口重画分水图。","cast_notes":"两侧湿地大瓣撑起空顶。","contact_notes":"蓝白回流从地面升到受益者，不是无敌罩。","tail_notes":"水位退潮，瓣片逐段闭合。","passive":false},
 "INNATE_BLOOM_GUIDE":{"hero":"BLOOM_GUIDE","faction":"FOREST","name":"新芽余韵","material":"SALT_DEW","motif":"remaining_dew_ledger","form":"four_dew_steps_and_salt_corners","gesture":"水尺末格滞留亮滴","connection":"只反映真实治疗余韵","palette":WATER,"story":"每份额外春水也记在水位表里。","cast_notes":"不重复播放主动杯爆发。","contact_notes":"四阶水滴低亮回旋。","tail_notes":"末滴回杯。","passive":true},
 "THORN_BREEZE":{"hero":"THORN_CHANTER","faction":"FOREST","name":"林风光环","material":"OPEN_THORN_HARP","motif":"missing_beat_harp","form":"unequal_open_harp_strings","gesture":"不齐枝袖微振","connection":"短谱线随风，不生成实体棘墙","palette":THORN,"story":"空园采声人故意保留失手的鼓点。","cast_notes":"常驻被动无强光。","contact_notes":"三根不等弦交替松紧。","tail_notes":"短弦归静。","passive":true},
 "THORN_LASH":{"hero":"THORN_CHANTER","faction":"FOREST","name":"缠枝","material":"THORN_SCORE_WHIP","motif":"unmetered_whip_score","form":"long_uneven_thorn_score_whip","gesture":"开口棘琴一侧拔弦","connection":"粗鞭主线带不等分支，服从实际直线","palette":THORN,"story":"棘谱像翻页，不把陌生声音抹平。","cast_notes":"荆刺压在一侧肩后。","contact_notes":"长鞭卷出有缺拍的刺节。","tail_notes":"鞭梢先松、主弦后落。","passive":false},
 "THORN_MAZE":{"hero":"THORN_CHANTER","faction":"FOREST","name":"荆棘迷庭","material":"THORN_PAPER_SCORE","motif":"broken_courtyard_staves","form":"broken_stave_arches_and_thorn_columns","gesture":"棘琴主弦向两边分开","connection":"不闭合枝谱串实际受控者，不生成障碍","palette":THORN,"story":"曾剪断疯长的胜利战歌，如今始终留一处缺口。","cast_notes":"三道不齐谱门向高处抽起。","contact_notes":"刺柱、粉谱与空白错拍落位。","tail_notes":"枝谱从断拍处逐根卸力。","passive":false},
 "INNATE_THORN_CHANTER":{"hero":"THORN_CHANTER","faction":"FOREST","name":"棘缠锋芒","material":"HOLLOW_SEED_SCORE","motif":"muted_thorn_notes","form":"three_muted_thorn_score_hooks","gesture":"空种壳耳饰短鸣","connection":"真实削弱中的棘结小标志","palette":THORN,"story":"采声不能强迫所有生命唱齐。","cast_notes":"不构造额外控制。","contact_notes":"三个缺笔音钩低亮。","tail_notes":"像松弦而非炸裂。","passive":true},
 "THORN_GRAFT_CATCH":{"hero":"THORN_REAVER","faction":"FOREST","name":"嫁枝缚切","material":"GRAFT_HOOK_SAP","motif":"forked_graft_sickle","form":"three_divergent_graft_hook_cuts","gesture":"嫁接镰横掠，短翼张开","connection":"近扇面三钩从同一嫁口分开","palette":GRAFT,"story":"间穗剪断压住水渠的耐旱藤。","cast_notes":"镰形粗枝向后折。","contact_notes":"开叉弧刃和鲜液依次向外切。","tail_notes":"树液下坠、刃影上扬。","passive":false},
 "THORN_SAP_BLADE":{"hero":"THORN_REAVER","faction":"FOREST","name":"流液芽刃","material":"SAP_THREAD_SICKLE","motif":"sap_edge_extension","form":"suspended_sap_sickle_and_buds","gesture":"树液沿镰背延展","connection":"贴武器的液丝，不是伤害投射","palette":GRAFT,"story":"给嫁口留出拒绝继续生长的空间。","cast_notes":"镰背两节芽轻开。","contact_notes":"粗黄液滴悬在细刃下方。","tail_notes":"液珠回落，刃光收短。","passive":false},
 "THORN_GRAFT_RUPTURE":{"hero":"THORN_REAVER","faction":"FOREST","name":"断枝新生","material":"GERMINATING_GRAFT","motif":"three_slow_rupture_buds","form":"three_lopsided_opening_graft_pods","gesture":"种匣破口向前托起","connection":"萌发作用于真实中毒者，不能画即刻爆炸伤害","palette":GRAFT,"story":"她替被遗忘者剪断记忆枝，萌发并非瞬间清场。","cast_notes":"三个重嫁接荚从低处抬起。","contact_notes":"荚缝慢开、绿紫汁丝分离。","tail_notes":"幼芽不等速弯下，不留下伤害地毯。","passive":false},
 "INNATE_THORN_REAVER":{"hero":"THORN_REAVER","faction":"FOREST","name":"嫁口顺势","material":"GRAFT_NOTCH","motif":"single_graft_opportunity","form":"forked_sickle_notch_glints","gesture":"眼罩枝刺与镰柄呼应","connection":"顺势命中时一短嫁口亮痕","palette":GRAFT,"story":"切断压迫关系也需要可辨认的缝。","cast_notes":"不额外束根。","contact_notes":"两叉不对称短刃亮起。","tail_notes":"鲜液沿旧嫁口收回。","passive":true},
 "ANTLER_BRANCH_SWEEP":{"hero":"ANTLER_WARRIOR","faction":"FOREST","name":"空角挑枝","material":"HOLLOW_ANTLER","motif":"shed_antler_prong_sweep","form":"broad_hollow_antler_prong_fan","gesture":"短矛与空角盾并扫","connection":"不同长度角尖同扇展开，非满圆旋斩","palette":ANTLER,"story":"巡苔用自然脱落的鹿角开季节通路。","cast_notes":"两根空角交叠蓄势。","contact_notes":"角叉剥出甲缝亮木屑。","tail_notes":"空角虚影向侧后抽走。","passive":false},
 "ANTLER_BARK_FOLD":{"hero":"ANTLER_WARRIOR","faction":"FOREST","name":"折枝轻甲","material":"RUNNING_BRANCH","motif":"long_branch_running_gait","form":"long_running_branch_spurs","gesture":"枝盾折窄、矛梢延长","connection":"沿本体两侧后掠，非突进位移","palette":ANTLER,"story":"每年重走林界，不信永远固定的工事。","cast_notes":"弧枝向肩后折。","contact_notes":"不等长枝轨随轻步延伸。","tail_notes":"枝轨逐节缩回。","passive":false},
 "ANTLER_RUT_SEASON":{"hero":"ANTLER_WARRIOR","faction":"FOREST","name":"迁林猎季","material":"ANTLER_ROOT_CORRIDOR","motif":"empty_antler_route_gate","form":"tall_empty_antler_corridor","gesture":"双空角向上开门","connection":"根线只连已受禁足者，不画伤害波","palette":ANTLER,"story":"烧去旧路以引开追兵，留下可重新打开的回廊。","cast_notes":"空角高举如不完整通路门。","contact_notes":"两排高矮角枝夹出空走廊。","tail_notes":"角枝由远向近熄灭。","passive":false},
 "INNATE_ANTLER_WARRIOR":{"hero":"ANTLER_WARRIOR","faction":"FOREST","name":"迁林蓄势","material":"TRAVEL_KNOT","motif":"single_travel_knot","form":"three_travel_knots_on_branch","gesture":"尾披绳结依次短亮","connection":"蓄一次，不以光线冒充额外普攻","palette":ANTLER,"story":"每一步旧路都可能成为新路的借力点。","cast_notes":"不伪造冲刺。","contact_notes":"沿枝三个绳结顺序点亮。","tail_notes":"真实次数用掉后灭。","passive":true},
 "POLLEN_FIREFLY_FAN":{"hero":"POLLEN_COMET","faction":"FOREST","name":"萤尾散弧","material":"FIREFLY_PETAL","motif":"independent_firefly_tail_fan","form":"five_unequal_firefly_parabolas","gesture":"花萼斗篷撑开，萤须前探","connection":"萤群各走不齐弧线，仍服从扇面真实命中","palette":COMET,"story":"流穗让会改变航迹的生命离开固定星图。","cast_notes":"萤须聚五点不同亮度。","contact_notes":"五束长短不同彗尾分拍落。","tail_notes":"大彗籽暗下后微萤才散。","passive":false},
 "POLLEN_LONE_COMET":{"hero":"POLLEN_COMET","faction":"FOREST","name":"独行彗籽","material":"LONE_POLLEN_STAR","motif":"one_wandering_seed_comet","form":"single_large_seed_comet_with_corkscrew_tail","gesture":"彗籽杖托一颗厚种星","connection":"一颗实种星带多彩螺尾，不画群攻爆圈","palette":COMET,"story":"为未记录的未来保留一条不合群的路。","cast_notes":"偏心种星先收后亮。","contact_notes":"单彗核削开两道亮裂。","tail_notes":"螺尾展开为三片叶状余影。","passive":false},
 "POLLEN_COMET_PROCESSION":{"hero":"POLLEN_COMET","faction":"FOREST","name":"万点离巢","material":"MIGRATING_COMET_SWARM","motif":"unfixed_migration_procession","form":"branching_migration_ribbons_and_seed_stars","gesture":"整件花萼披风上翻离巢","connection":"仅沿实际连锁次序迁飞，不凭空增加跳数","palette":COMET,"story":"迁林不需要唯一答案，萤群在多个真实节点接力。","cast_notes":"巨大开花萼上涌多色萤潮。","contact_notes":"大种星与细萤带交错穿过节点。","tail_notes":"最后一处尾光先停，旧轨后淡。","passive":false},
 "INNATE_POLLEN_COMET":{"hero":"POLLEN_COMET","faction":"FOREST","name":"萤路回认","material":"REMEMBERED_FIREFLY","motif":"returning_known_firefly","form":"one_hooked_firefly_return","gesture":"弯萤须回应一次旧光","connection":"只对真实回认触发作小尾迹","palette":COMET,"story":"萤认得刚走过的路，但不拥有全知星图。","cast_notes":"不新增目标指示。","contact_notes":"一颗偏心萤点拐回杖侧。","tail_notes":"余尾分成细短光屑。","passive":true},
 "TUNNEL_SHOCK":{"hero":"TUNNEL_SENTINEL","faction":"UNDERGROUND","name":"孢壳重整","material":"STATION_SHELL_MIST","motif":"mobile_shell_station_repair","form":"open_station_roof_and_warm_spore_lifts","gesture":"公共背甲两端抬起","connection":"暖孢回身体并串最近真实伤员，不作冲击波","palette":SHELL,"story":"背着育幼车站继续走，而非让祖门成为牢笼。","cast_notes":"暗背甲像临时站棚掀开。","contact_notes":"大壳板归位、孢灯向上提。","tail_notes":"厚雾低伏，暖点留在受疗处。","passive":false},
 "TUNNEL_WARD":{"hero":"TUNNEL_SENTINEL","faction":"UNDERGROUND","name":"穴甲外壳","material":"SHELL_RAIL","motif":"station_balustrade_braces","form":"three_short_station_balustrades","gesture":"孢灯护栏低亮呼吸","connection":"不满屏封壳，条件支援由消费者开关","palette":SHELL,"story":"幼群需要能自行离开的护栏。","cast_notes":"被动不施放。","contact_notes":"三段护栏与甲缝错层。","tail_notes":"松开不破裂。","passive":true},
 "TUNNEL_MEND":{"hero":"TUNNEL_SENTINEL","faction":"UNDERGROUND","name":"穴鸣禁足","material":"FLEXIBLE_SPORE_GATE","motif":"opening_vent_fan_lock","form":"broad_vent_gates_and_low_spore_hooks","gesture":"站台护栏向两侧扇开","connection":"扇面真实受控者才有壳钩，非全图孢闸","palette":SHELL,"story":"带着门走的壳车只临时拦住追击。","cast_notes":"大壳翼和低孢囊反向起势。","contact_notes":"厚雾边框内短节钩分拍扣住。","tail_notes":"壳钩先退、雾压后散。","passive":false},
 "INNATE_TUNNEL_SENTINEL":{"hero":"TUNNEL_SENTINEL","faction":"UNDERGROUND","name":"穴甲合阵","material":"SHELL_STATION_JOINT","motif":"allied_shell_station_seams","form":"three_linked_railing_joints","gesture":"站台三接榫短亮","connection":"有真实合阵条件才亮，不画假护盾","palette":SHELL,"story":"共同迁居依靠邻近伙伴而不是无条件厚甲。","cast_notes":"不伪造受益人数。","contact_notes":"三接榫自两端向中间闭合。","tail_notes":"队形解除由消费者关闭。","passive":true},
 "ECHO_BIND":{"hero":"ECHO_BINDER","faction":"UNDERGROUND","name":"声纹缚","material":"REFRACTED_SOUND","motif":"returning_echo_tethers","form":"broken_zigzag_echo_spindles","gesture":"偏心晶耳倾向地层","connection":"折回声带按真实连锁节点串接","palette":ECHO,"story":"借震测绘者把杂乱回声折回一条可理解的路。","cast_notes":"两只偏心晶耳错拍响应。","contact_notes":"纺锤声纹交错夹住目标足边。","tail_notes":"长声带拆为留白短节。","passive":false},
 "ECHO_FLARE":{"hero":"ECHO_BINDER","faction":"UNDERGROUND","name":"晶鸣","material":"CHIPPED_RESONANCE","motif":"split_resonance_spine","form":"long_jagged_crystal_sound_spine","gesture":"裂杖短压再伸","connection":"狭长晶脊与空声带沿实际直线同行","palette":ECHO,"story":"她不把不整齐震动误作不存在的生命。","cast_notes":"三片薄晶错位积声。","contact_notes":"长晶刃与两条空心余波分拍。","tail_notes":"大碎晶先止、小晶尘后退。","passive":false},
 "ECHO_OATH":{"hero":"ECHO_BINDER","faction":"UNDERGROUND","name":"晶核坍缩","material":"COLLAPSING_SOUND_CORE","motif":"one_inward_echo_crystal","form":"single_inward_collapsing_crystal_drum","gesture":"晶耳与裂杖向一个缺口收音","connection":"向唯一目标内吸的光瓣，不画群体冲击圈","palette":ECHO,"story":"烧掉完美空洞图后，她只为真正听见的目标作证。","cast_notes":"高晶笼反向内折。","contact_notes":"不对称晶瓣内坍，中心留暗核。","tail_notes":"最后一粒晶尘向中心熄灭。","passive":false},
 "INNATE_ECHO_BINDER":{"hero":"ECHO_BINDER","faction":"UNDERGROUND","name":"孢音渗透","material":"ECHO_DUST","motif":"poison_echo_seep","form":"offset_ear_seep_notches","gesture":"偏心晶耳底部细声颤","connection":"真实中毒技能联动才点亮细晶孔","palette":ECHO,"story":"让低声的证据透过岩层。","cast_notes":"不新增中毒。","contact_notes":"细紫孔与青晶三短痕。","tail_notes":"声孔归静。","passive":true},
 "SPORE_SEAL":{"hero":"SPORE_STALKER","faction":"UNDERGROUND","name":"闭孔钉刺","material":"BIOBOLT_STOPPER","motif":"vent_stopper_bolt","form":"heavy_barbed_bolt_with_closing_vents","gesture":"背负双槽弩一边闭孔","connection":"一个粗钉刺向真实受控者投递","palette":BOLT,"story":"验脉弩手隔裂隙射击，钉刺不是扇形近战刀。","cast_notes":"双槽中单一弩轨后拉。","contact_notes":"倒钩钉刺与短闭孔锁夹。","tail_notes":"钉杆暗下，钩影收进。","passive":false},
 "SPORE_SWEEP":{"hero":"SPORE_STALKER","faction":"UNDERGROUND","name":"验脉穿刺","material":"VEIN_TEST_BOLT","motif":"single_split_probe","form":"long_probe_with_two_sampling_barbs","gesture":"另一弩轨薄探针前推","connection":"细长采样刺仅指向单体，不画穿人直线","palette":BOLT,"story":"探查裂隙里的矿毒之后才敢判断伤处。","cast_notes":"窄探针从弩口缓出。","contact_notes":"双采样倒刺剥出不对称亮屑。","tail_notes":"采样丝反向回弩。","passive":false},
 "SPORE_MEND":{"hero":"SPORE_STALKER","faction":"UNDERGROUND","name":"裂隙追猎","material":"BIOBOLT_READY_RACK","motif":"double_vent_predator_rack","form":"open_double_bolt_racks_and_sight_spines","gesture":"双槽弩背全开，节足压低","connection":"强化贴持有者，不伪造回血或射出额外箭矢","palette":BOLT,"story":"多足稳住试剂囊，为有限追猎窗口准备真正两条弩轨。","cast_notes":"巨大双槽架在背后斜开。","contact_notes":"两色探针火与瞄脊持续交替。","tail_notes":"弩孔从外至内闭合。","passive":false},
 "INNATE_SPORE_STALKER":{"hero":"SPORE_STALKER","faction":"UNDERGROUND","name":"穴群夹击","material":"ALLY_PROBE_NOTCH","motif":"paired_probe_signal","form":"two_offset_probe_brackets","gesture":"弩背两侧短刻响应","connection":"需要实际夹击伙伴才由消费者亮起","palette":BOLT,"story":"安全距离本身不能代替伙伴的近身风险。","cast_notes":"不显示隐藏友敌。","contact_notes":"双钩之间一条短采样脉。","tail_notes":"伙伴条件失效即停。","passive":true},
 "SPORE_GLOW":{"hero":"SPORE_GUIDE","faction":"UNDERGROUND","name":"菌光光环","material":"FERMENTATION_LANTERN","motif":"separate_culture_chambers","form":"three_different_culture_lights","gesture":"分格菌罐三仓不齐呼吸","connection":"不把所有菌丝连接成一个思想","palette":FERMENT,"story":"分菌酿师给共同体余粮，也给不共享的味道留位置。","cast_notes":"低亮菌褶不是爆炸。","contact_notes":"三种菌光不同相位。","tail_notes":"各自收束，不并成大环。","passive":true},
 "SPORE_REMEDY":{"hero":"SPORE_GUIDE","faction":"UNDERGROUND","name":"孢疗","material":"CULTURE_STEAM","motif":"ladled_three_culture_remedy","form":"ladle_steam_and_three_healing_caps","gesture":"筛勺从分格菌罐舀出","connection":"蒸气上行、重菌粒下落，连接真实伤员","palette":FERMENT,"story":"撤回高产配方后，用不同旧菌重新救人。","cast_notes":"大筛勺与三色菌帽起势。","contact_notes":"奶金、青灰、淡紫菌蒸气分束。","tail_notes":"蒸气散开而药粒下沉。","passive":false},
 "SPORE_HAVEN":{"hero":"SPORE_GUIDE","faction":"UNDERGROUND","name":"菌丝庇所","material":"FERMENTED_MYCELIUM","motif":"separate_slow_culture_lanes","form":"low_braided_culture_ribbons","gesture":"长柄筛勺平放、菌罐开三仓","connection":"低伏菌带只标真实减速，绝不伪造治疗或毒伤","palette":FERMENT,"story":"共生地放慢追兵，让彼此保留退出的可能。","cast_notes":"三种发酵气带先分开。","contact_notes":"厚薄不齐菌带横向交织。","tail_notes":"气带由地隙吸回，不留伤害池。","passive":false},
 "INNATE_SPORE_GUIDE":{"hero":"SPORE_GUIDE","faction":"UNDERGROUND","name":"菌丝分润","material":"CULTURE_SHARING","motif":"one_shared_ladle_drop","form":"two_unequal_culture_cups","gesture":"菌罐侧仓送出小滴","connection":"真实分润后才有一次低亮渡滴","palette":FERMENT,"story":"分粮不是强迫所有家户吃同一配方。","cast_notes":"不递归表现治疗。","contact_notes":"大小菌杯之间一滴渡流。","tail_notes":"小杯先暗。","passive":true},
 "QUAKE_RHYTHM":{"hero":"QUAKE_PRIEST","faction":"UNDERGROUND","name":"穴音光环","material":"STRATA_SCRIPT","motif":"low_strata_footfalls","form":"three_staggered_strata_bars","gesture":"层页石册错页呼吸","connection":"低频步幅短线，不画持续震荡伤害","palette":STRATA,"story":"旧契约应给活人提供路，而不是封路。","cast_notes":"被动低亮。","contact_notes":"三层不齐石页交替短亮。","tail_notes":"沉入石页。","passive":true},
 "QUAKE_SNARE":{"hero":"QUAKE_PRIEST","faction":"UNDERGROUND","name":"地层解理","material":"SPLIT_STRATA","motif":"armor_load_seam","form":"offset_strata_separation_plates","gesture":"钝镐敲开层页接缝","connection":"层理裂痕指向真实破甲者，不画冲击伤害","palette":STRATA,"story":"亲手敲碎压住水脉的古边石。","cast_notes":"石页先错层再张开。","contact_notes":"三块承压板在目标边缘分离。","tail_notes":"粉尘低坠，细裂线留白。","passive":false},
 "QUAKE_SEAL":{"hero":"QUAKE_PRIEST","faction":"UNDERGROUND","name":"断层封印","material":"FAULT_TESTIMONY","motif":"broken_contract_fault_gate","form":"tall_asymmetric_fault_book_clasp","gesture":"整册断层书页高举翻开","connection":"真实群控者的脚边受层页扣，不改地形","palette":STRATA,"story":"保存通行权的证据并不意味着让历史永远压住未来。","cast_notes":"巨大不对称石页反向举起。","contact_notes":"高低断层与白缝依序咬合。","tail_notes":"厚板先退、细白缝后灭。","passive":false},
 "INNATE_QUAKE_PRIEST":{"hero":"QUAKE_PRIEST","faction":"UNDERGROUND","name":"地鸣余震","material":"FAULT_AFTERTREMOR","motif":"ending_strata_pause","form":"two_offset_aftertremor_steps","gesture":"断层印余拍轻颤","connection":"只在实际自然结束事件后出现短余纹","palette":STRATA,"story":"后来者的路也应记录在旧石册页脚。","cast_notes":"净化不可触发假余震。","contact_notes":"两级短台错时降下。","tail_notes":"下层先暗。","passive":true},
 "PRISM_FACET_PIN":{"hero":"PRISM_MANTIS","faction":"UNDERGROUND","name":"棱足锁切","material":"FACET_PIN","motif":"two_anchored_facet_pins","form":"two_tall_offset_crystal_pins","gesture":"六足压低、双棱刃分折","connection":"两枚棱针沿实际窄线落位，无爆炸伤害","palette":PRISM,"story":"刻师保住不能互译的声音，锁住的是切面不是生命思想。","cast_notes":"细长棱针在肩外错开。","contact_notes":"双针和短折面足锁扣合。","tail_notes":"玻璃细屑向两侧轻退。","passive":false},
 "PRISM_DOUBLE_EDGE":{"hero":"PRISM_MANTIS","faction":"UNDERGROUND","name":"双折镜锋","material":"REFRACTION_EDGE","motif":"two_counted_refraction_edges","form":"two_unequal_suspended_crystal_edges","gesture":"双刃延展，前后错位","connection":"两次有限强化贴武器，不作额外攻击","palette":PRISM,"story":"两个切面可同时锋利，但不因此获得无限连斩。","cast_notes":"两片长棱从短刃内旋出。","contact_notes":"一高一低透明棱锋。","tail_notes":"随实际次数耗尽收回。","passive":false},
 "PRISM_REFRACTION_CUT":{"hero":"PRISM_MANTIS","faction":"UNDERGROUND","name":"三证折界","material":"SETTLED_REFRACTION","motif":"four_settled_prism_hops","form":"broken_mirror_gates_and_refraction_slashes","gesture":"偏心晶冠裂为三方向","connection":"折面逐真实连锁目标接力，不让一人重复弹射","palette":PRISM,"story":"最贵母晶被分开，只为不同证词共享出口。","cast_notes":"三道大错位折面撑开。","contact_notes":"亮切面连续折返并断开。","tail_notes":"不完整镜门化作方向不同的晶尘。","passive":false},
 "INNATE_PRISM_MANTIS":{"hero":"PRISM_MANTIS","faction":"UNDERGROUND","name":"折面捕音","material":"FACET_ECHO","motif":"controlled_echo_facet","form":"three_offaxis_facet_ears","gesture":"晶冠偏心短亮","connection":"真实受控捕隙触发才亮，不新增控制","palette":PRISM,"story":"圆钝证词也需一个能被听见的切面。","cast_notes":"不显示隐藏状态。","contact_notes":"三短棱耳围着留白错开。","tail_notes":"最后一面后暗。","passive":true},
 "CARAPACE_SHELL_SPLIT":{"hero":"CARAPACE_WARRIOR","faction":"UNDERGROUND","name":"铲角裂壳","material":"SPADE_CARAPACE","motif":"closing_spade_pincers","form":"two_heavy_asymmetric_spade_jaws","gesture":"宽壳前伸，两铲角合拢","connection":"只夹真实单体，不画范围地震","palette":MOLT,"story":"不同巢温的幼体可由同一位斗卫庇护。","cast_notes":"一大一小铲角后摆。","contact_notes":"双铲角夹击加重壳碎屑。","tail_notes":"壳影向外卸力。","passive":false},
 "CARAPACE_NEST_GUARD":{"hero":"CARAPACE_WARRIOR","faction":"UNDERGROUND","name":"通气护壳","material":"VENTED_SHELL","motif":"clean_air_vent_repair","form":"six_vent_shutters_and_clean_air_plumes","gesture":"双层通气扇盖翻起","connection":"污雾排出、清气内回，不伪造临时护甲","palette":MOLT,"story":"共居不必统一巢温，通气孔让每层仍能呼吸。","cast_notes":"两排不齐扇孔张开。","contact_notes":"清气由两侧回体、旧污点向外落。","tail_notes":"风停但壳盖不炸裂。","passive":false},
 "CARAPACE_LAYERED_MOLT":{"hero":"CARAPACE_WARRIOR","faction":"UNDERGROUND","name":"共巢蜕甲","material":"SHARED_MOLT_SHELTER","motif":"four_shared_vent_shelters","form":"four_offset_molt_roofs_with_open_vents","gesture":"整片背壳层层举起","connection":"旧甲只给实际受益者，不画全军无敌罩","palette":MOLT,"story":"她把血缘通行权改为轮值照料。","cast_notes":"巨大四层旧甲从背后反向翻出。","contact_notes":"不等壳顶与清气分散到实际受益者。","tail_notes":"空旧壳软化下落、清气后散。","passive":false},
 "INNATE_CARAPACE_WARRIOR":{"hero":"CARAPACE_WARRIOR","faction":"UNDERGROUND","name":"透壳气隙","material":"VENT_BREATH","motif":"one_clean_vent_path","form":"three_vent_slits_and_offset_air_threads","gesture":"侧壳三孔错时透气","connection":"仅抵抗状态的小通气纹，不额外净化","palette":MOLT,"story":"仍保留自己呼吸节拍的共同体才值得守。","cast_notes":"不改实际控制时长。","contact_notes":"三缝外侧青白气丝。","tail_notes":"由宽缝先收。","passive":true},
 "MYCELIAL_ACID_VEIN":{"hero":"MYCELIAL_CATALYST","faction":"UNDERGROUND","name":"酸脉分流","material":"ACID_GLASS","motif":"accepted_v4_branching_acid_vein","form":"accepted_v4_three_acid_nodes","gesture":"保留V4四足支撑与举囊","connection":"保留V4真实分支投递","palette":MYC,"story":"菌酸清理弃矿毒盐，不能把矿工变成劳力。","cast_notes":"保留已经接受的V4原帧。","contact_notes":"不叠加V5第二层爆炸。","tail_notes":"保留原真实状态约束。","passive":false,"preserve_v4":true,"v4_handler":"myc_w"},
 "MYCELIAL_ACID_KERNEL":{"hero":"MYCELIAL_CATALYST","faction":"UNDERGROUND","name":"浓酸核珠","material":"CERAMIC_ACID","motif":"accepted_v4_single_acid_capsule","form":"accepted_v4_single_axial_acid_peel","gesture":"保留V4压身与投囊","connection":"保留V4单核投递","palette":MYC,"story":"她打开被污染支洞的出口，而非制造无差别酸海。","cast_notes":"保留V4双囊蓄压。","contact_notes":"保留轴向核珠剥落。","tail_notes":"不增加伤害地毯。","passive":false,"preserve_v4":true,"v4_handler":"myc_q"},
 "MYCELIAL_SPORE_DOWNPOUR":{"hero":"MYCELIAL_CATALYST","faction":"UNDERGROUND","name":"蚀穹孢雨","material":"ACID_SPORE_CANOPY","motif":"accepted_v4_single_canopy_rain","form":"accepted_v4_single_large_canopy","gesture":"保留V4大穹起势与四足举投","connection":"只在真实目标中心一次倾雨","palette":MYC,"story":"缓慢分解让被耗尽的土地有停止被索取的权利。","cast_notes":"保留三层悬穹。","contact_notes":"无初始伤害，不给每个受害者重复大伞。","tail_notes":"保留真实状态有效期。","passive":false,"preserve_v4":true,"v4_handler":"myc_r"},
 "INNATE_MYCELIAL_CATALYST":{"hero":"MYCELIAL_CATALYST","faction":"UNDERGROUND","name":"三岔回收","material":"FERMENTATION_RETURN","motif":"accepted_v4_three_return_seeds","form":"accepted_v4_three_curved_return_seeds","gesture":"保留V4酸囊回收","connection":"仅真实返蓝事件出回收动画","palette":MYC,"story":"三处真实接触的回收，不是无条件常亮回蓝光环。","cast_notes":"不凭空产生RETURN。","contact_notes":"保留三种发酵籽逆流。","tail_notes":"回囊即止。","passive":true,"preserve_v4":true,"v4_handler":"myc_p"}
}

static func paint(image: Image, skill_id: String, phase: String, frame: int) -> void:
 if not PROFILES.has(skill_id) or frame < 0 or frame >= FRAMES or phase not in ["CAST","CONTACT","TAIL","AURA"]: return
 var row: Dictionary = PROFILES[skill_id]
 if bool(row.get("preserve_v4",false)):
  var old_phase := "RETURN" if skill_id.begins_with("INNATE_") else phase
  if AcceptedMyc.clips().has(str(row.v4_handler)+":"+old_phase):
   var original: Image = AcceptedMyc.image(str(row.v4_handler),old_phase,frame)
   image.blit_rect(original,Rect2i(0,0,SIZE,SIZE),Vector2i.ZERO)
  _finish(image)
  return
 var f := frame
 var mode := 0 if phase == "CAST" else 1 if phase == "CONTACT" else 2 if phase == "TAIL" else 3
 if bool(row.passive) or phase == "AURA": _passive(image,skill_id,f,row)
 else:
  match str(row.hero):
   "VINE_WARDEN": _vine(image,skill_id,mode,f,row)
   "LEAF_SEER": _leaf(image,skill_id,mode,f,row)
   "WIND_COURIER": _wind(image,skill_id,mode,f,row)
   "BLOOM_GUIDE": _bloom(image,skill_id,mode,f,row)
   "THORN_CHANTER": _thorn(image,skill_id,mode,f,row)
   "THORN_REAVER": _graft(image,skill_id,mode,f,row)
   "ANTLER_WARRIOR": _antler(image,skill_id,mode,f,row)
   "POLLEN_COMET": _comet(image,skill_id,mode,f,row)
   "TUNNEL_SENTINEL": _tunnel(image,skill_id,mode,f,row)
   "ECHO_BINDER": _echo(image,skill_id,mode,f,row)
   "SPORE_STALKER": _stalker(image,skill_id,mode,f,row)
   "SPORE_GUIDE": _ferment(image,skill_id,mode,f,row)
   "QUAKE_PRIEST": _quake(image,skill_id,mode,f,row)
   "PRISM_MANTIS": _prism(image,skill_id,mode,f,row)
   "CARAPACE_WARRIOR": _carapace(image,skill_id,mode,f,row)
 _finish(image)

static func _c(row: Dictionary, i: int, alpha: float = 1.0) -> Color: return P.color(row,i,alpha)
static func _poly(image: Image, points: Array, color: Color) -> void:
 var typed: Array[Vector2] = []
 for point: Variant in points: typed.append(Vector2(point).round())
 P.poly(image,typed,color)
static func _line(image: Image, a: Vector2, b: Vector2, row: Dictionary, width: int = 7, light: int = 3, alpha: float = 1.0) -> void:
 P.line(image,a.round(),b.round(),_c(row,0,alpha),width+4)
 P.line(image,a.round(),b.round(),_c(row,2,alpha),width)
 P.line(image,(a+Vector2(-1,-1)).round(),(b+Vector2(-1,-1)).round(),_c(row,light,alpha),maxi(1,width-3))
static func _path(image: Image, points: Array, row: Dictionary, width: int = 7, light: int = 3, alpha: float = 1.0) -> void:
 for i: int in range(points.size()-1): _line(image,Vector2(points[i]),Vector2(points[i+1]),row,width,light,alpha)
static func _oval(image: Image, p: Vector2, radius: Vector2, row: Dictionary, index: int, alpha: float = 1.0) -> void:
 P.ellipse(image,p.round(),radius.round(),_c(row,0,alpha),true)
 P.ellipse(image,(p+Vector2(-1,-1)).round(),(radius-Vector2(3,3)).max(Vector2.ONE).round(),_c(row,index,alpha),true)
static func _leaflet(image: Image, p: Vector2, size: float, tilt: float, row: Dictionary, tint: int = 3, alpha: float = 1.0) -> void:
 var stem := Vector2(sin(tilt),-cos(tilt))*size
 var side := Vector2(cos(tilt),sin(tilt))*size*0.42
 _poly(image,[p,p+stem*.45-side,p+stem,p+stem*.62+side,p+side*.4],_c(row,0,alpha))
 _poly(image,[p+stem*.13,p+stem*.49-side*.65,p+stem*.88,p+stem*.62+side*.65],_c(row,tint,alpha))
 P.line(image,(p+stem*.15).round(),(p+stem*.82).round(),_c(row,4,alpha),2)
static func _crystal(image: Image, p: Vector2, height: float, width: float, row: Dictionary, tint: int = 3, alpha: float = 1.0) -> void:
 _poly(image,[p+Vector2(-width,0),p+Vector2(-width*.65,-height*.72),p+Vector2(0,-height),p+Vector2(width,-height*.42),p+Vector2(width*.7,5)],_c(row,0,alpha))
 _poly(image,[p+Vector2(-width+3,-2),p+Vector2(-width*.4,-height*.67),p+Vector2(-1,-height+5),p+Vector2(width-3,-height*.4),p+Vector2(width*.55,1)],_c(row,2,alpha))
 _poly(image,[p+Vector2(-1,-height+5),p+Vector2(width-3,-height*.4),p+Vector2(1,-height*.32),p+Vector2(-width*.4,-height*.67)],_c(row,tint,alpha))
 P.line(image,(p+Vector2(0,-height+6)).round(),(p+Vector2(1,-height*.34)).round(),_c(row,4,alpha),2)
static func _shell(image: Image, p: Vector2, w: float, h: float, row: Dictionary, tint: int = 3, alpha: float = 1.0) -> void:
 _poly(image,[p+Vector2(-w,0),p+Vector2(-w*.8,-h*.6),p+Vector2(-w*.24,-h),p+Vector2(w*.4,-h*.85),p+Vector2(w,-h*.27),p+Vector2(w*.84,5)],_c(row,0,alpha))
 _poly(image,[p+Vector2(-w+4,-3),p+Vector2(-w*.62,-h*.58),p+Vector2(-w*.16,-h+4),p+Vector2(w*.32,-h*.7),p+Vector2(w-4,-h*.22),p+Vector2(w*.72,1)],_c(row,tint,alpha))
 _path(image,[p+Vector2(-w*.62,-3),p+Vector2(-w*.4,-h*.45),p+Vector2(-w*.12,-h*.75)],row,3,4,alpha)
 for i: int in range(3):
  P.line(image,(p+Vector2(-w*.25+i*w*.3,-h*.45+i%2*3)).round(),(p+Vector2(-w*.2+i*w*.3,-h*.2)).round(),_c(row,0,alpha),3)
static func _drop(image: Image, p: Vector2, r: int, row: Dictionary, tint: int = 4, alpha: float = 1.0) -> void:
 _poly(image,[p+Vector2(0,-r*2),p+Vector2(r,0),p+Vector2(r-1,r),p+Vector2(-r+1,r),p+Vector2(-r,-1)],_c(row,0,alpha))
 _poly(image,[p+Vector2(0,-r*2+4),p+Vector2(r-3,0),p+Vector2(r-3,r-3),p+Vector2(-r+3,r-3)],_c(row,tint,alpha))
static func _specks(image: Image, row: Dictionary, f: int, start: Vector2, count: int, spread: float, rising: bool, tint: int = 4, alpha: float = 1.0) -> void:
 for i: int in range(count):
  var t := (f+i*3)%12
  var x := start.x+sin(float(i)*2.17)*spread+float(t-6)*(0.6 if i%2==0 else -0.4)
  var y := start.y+cos(float(i)*1.73)*spread*.45+float(-t*3 if rising else t*2)
  var s := 2+i%3
  P.rect(image,roundi(x),roundi(y),s+2,s+2,_c(row,0,alpha))
  P.rect(image,roundi(x),roundi(y),s,s,_c(row,tint if i%2==0 else 5,alpha))
static func _shadow(image: Image, row: Dictionary, f: int, wide: int = 60) -> void:
 P.ellipse(image,Vector2(97+f%2,144),Vector2(wide,13),_c(row,0,0.13),true)
 P.ellipse(image,Vector2(91,145),Vector2(wide*.7,7),_c(row,1,0.19),true)
static func _alpha(mode: int, f: int) -> float:
 return 1.0 if mode<2 else float(12-f)/16.0
static func _finish(image: Image) -> void:
 # Keep the fixed hero-body corridor and transparent outer two pixels.
 for y: int in range(84,137):
  for x: int in range(82,111):
   var pixel := image.get_pixel(x,y)
   if pixel.a>48.0/255.0: pixel.a=48.0/255.0;image.set_pixel(x,y,pixel)
 for i: int in range(SIZE):
  for edge: int in [0,1,SIZE-2,SIZE-1]:
   image.set_pixel(i,edge,Color.TRANSPARENT);image.set_pixel(edge,i,Color.TRANSPARENT)

static func _vine(image: Image, id: String, mode: int, f: int, row: Dictionary) -> void:
 var a := _alpha(mode,f)
 var rise := mini(f,8)
 _shadow(image,row,f,69 if id=="VINE_MEND" else 51)
 if id=="VINE_SHOCK":
  for side: int in [-1,1]:
   var inward := float(f*2 if mode==1 else rise)
   var x := 96+side*(53-inward)
   _path(image,[Vector2(96+side*69,151),Vector2(x+side*7,128),Vector2(x,101-rise),Vector2(96+side*19,77+rise)],row,11,3,a)
   _shell(image,Vector2(x+side*9,112-rise),15,22,row,2,a)
   _drop(image,Vector2(x-side*6,84-f*2),5,row,5,a)
  for i: int in range(4): _oval(image,Vector2(49+i*31,150-f-i%2*9),Vector2(7,5),row,5,a)
  _specks(image,row,f,Vector2(97,116),8,58,true,4,a)
 else:
  # Heavy unequal buttresses; the gap makes this a root clasp, not a dome.
  for i: int in range(5):
   var x := 28+i*33
   var h := 44+(i*19)%32+rise*2
   var sway := sin(float(f+i)*0.24)*4
   var alpha := a*(0.55 if mode==2 else 1.0)
   _path(image,[Vector2(x,160),Vector2(x+sway-7,136),Vector2(x+sway+3,119-h*.3),Vector2(x+12,157-h)],row,11,3,alpha)
   _leaflet(image,Vector2(x+6,145-h*.55),20+i%2*7,-.8+i*.31,row,6,alpha)
   if i%2==0: _drop(image,Vector2(x+14,122-h*.25-f),5,row,5,alpha)
  _path(image,[Vector2(31,155),Vector2(48,163),Vector2(70,150),Vector2(79,154)],row,5,5,a)
  _path(image,[Vector2(119,151),Vector2(139,157),Vector2(164,147)],row,6,6,a)
  _specks(image,row,f,Vector2(98,95),13,72,mode!=2,5,a)

static func _leaf(image: Image, id: String, mode: int, f: int, row: Dictionary) -> void:
 var a := _alpha(mode,f)
 var spread := float(18+mini(f,8)*4)
 _shadow(image,row,f,56)
 match id:
  "LEAF_BIND":
   for side: int in [-1,1]:
    var x: float = 96+side*(spread if mode==0 else 40-f)
    _leaflet(image,Vector2(x,111),35+f*.9,side*.7,row,6,a)
    _path(image,[Vector2(x-side*4,104),Vector2(x+side*14,127),Vector2(96+side*18,148),Vector2(96+side*35,156)],row,7,3,a)
    _leaflet(image,Vector2(x+side*13,129),19,-side*.8,row,5,a)
   _specks(image,row,f,Vector2(97,139),9,62,false,5,a)
  "LEAF_FLARE":
   for i: int in range(5):
    var angle := -.95+i*.39+f*.026
    var origin := Vector2(81,137) if mode==0 else Vector2(50,143)
    var p := origin+Vector2(cos(angle),sin(angle))*float(31+i*12+f*2)
    _leaflet(image,p,34+i%3*13,angle+PI*.5,row,3 if i%2 else 6,a)
    _line(image,origin+Vector2(0,-8),p+Vector2(0,-16),row,3,5,a*.65)
   _specks(image,row,f,Vector2(117,83),10,58,false,5,a)
  "LEAF_OATH":
   for side: int in [-1,1]:
    var x := 96+side*(56-f*2 if mode==1 else 35+mini(f,8)*2)
    _leaflet(image,Vector2(x,156),86+f,side*.37,row,3,a)
    _path(image,[Vector2(x,154),Vector2(x-side*18,146),Vector2(96+side*16,143)],row,9,2,a)
    _crystal(image,Vector2(x-side*10,81+f*.6),27,11,row,5,a)
   _oval(image,Vector2(96,62-f*.5),Vector2(19,13),row,6,a)
   _specks(image,row,f,Vector2(95,93),12,60,true,4,a)

static func _arrow(image: Image, a: Vector2, b: Vector2, row: Dictionary, width: int, alpha: float = 1.0, feather: bool = true) -> void:
 var direction := (b-a).normalized()
 var side := direction.orthogonal()
 _line(image,a,b,row,width,3,alpha)
 _poly(image,[b+direction*12,b-direction*16+side*12,b-direction*10,b-direction*16-side*12],_c(row,0,alpha))
 _poly(image,[b+direction*7,b-direction*12+side*7,b-direction*8,b-direction*12-side*7],_c(row,4,alpha))
 if feather:
  for i: int in range(3):
   var p := a+direction*float(7+i*7)
   _poly(image,[p-side*3,p-direction*12-side*15,p-direction*18-side*12,p-direction*9+side*2],_c(row,5 if i%2 else 6,alpha))

static func _wind(image: Image, id: String, mode: int, f: int, row: Dictionary) -> void:
 var a := _alpha(mode,f)
 _shadow(image,row,f,60)
 if id=="WIND_SHOT":
  var y := 91-f*.8 if mode==0 else 94+sin(float(f)*.45)*5
  var x := 40+mini(f,8)*2 if mode==0 else 31+f*4
  _arrow(image,Vector2(x,y+19),Vector2(minf(168,x+83),y-7),row,6,a)
  for i: int in range(3): _path(image,[Vector2(x-10-i*4,y+28+i*4),Vector2(x+9,y+20+i*4),Vector2(x+38,y+20+i*4)],row,2,2+i,a*.45)
  _specks(image,row,f,Vector2(126,99),6,42,false,4,a)
 elif id=="WIND_FERVOR":
  for side: int in [-1,1]:
   for i: int in range(3):
    var x := 96+side*(32+i*12+f%3)
    var y := 124+i*5-f*.8
    _leaflet(image,Vector2(x,y),45+i*11,side*(.4+i*.16),row,6 if i%2==0 else 2,a*(.6 if i==2 else 1.0))
  _specks(image,row,f,Vector2(94,76),8,61,true,3,a)
 else:
  # A directional open wing, not a radial wind explosion or self-buff shell.
  for i: int in range(4):
   var y := 70+i*19
   var dx := f*3+i*6
   _arrow(image,Vector2(24+dx*.25,y+15),Vector2(157+dx*.2,y-7),row,4+i%2*2,a*.86,i%2==0)
   _leaflet(image,Vector2(47+dx*.4,y+17),35+i*5,-.85,row,5 if i%2==0 else 6,a)
  _specks(image,row,f,Vector2(107,91),14,74,false,4,a)

static func _bloom(image: Image, id: String, mode: int, f: int, row: Dictionary) -> void:
 var a := _alpha(mode,f)
 _shadow(image,row,f,67)
 if id=="BLOOM_TOUCH":
  var lift := float(f*2 if mode==1 else mini(f,8))
  # A very large tilted shell cup; the gap is not a shield.
  _path(image,[Vector2(28,87-lift),Vector2(33,110-lift),Vector2(48,121-lift),Vector2(68,117-lift),Vector2(80,104-lift)],row,10,5,a)
  for i: int in range(4):
   var start := Vector2(51,114-lift)
   var end := Vector2(104+i*18,139-f*3-i*9)
   _path(image,[start,Vector2(81+i*7,126-lift),end],row,4,2,a*.8)
   _drop(image,end,5+i%2,row,3 if i%2 else 5,a)
   P.rect(image,37+i*16,122+f*2-i%2*4,4,4,_c(row,6,a))
  _leaflet(image,Vector2(38,116-lift),29,-.8,row,3,a)
 else:
  # A divided wetland canopy with open channels, not a hemisphere.
  for i: int in range(5):
   var x := 28+i*33
   var y := 76+(i%3)*11-f*.7
   _leaflet(image,Vector2(x,119),50+i%2*21,(i-2)*.38,row,3 if i%2 else 5,a)
   _path(image,[Vector2(x,143),Vector2(x-7,121),Vector2(x+8,y)],row,4,2,a*.8)
   _drop(image,Vector2(x+11,135-((f+i*2)%12)*5),5,row,5,a)
  _path(image,[Vector2(24,150),Vector2(49,157),Vector2(72,151)],row,4,5,a*.75)
  _path(image,[Vector2(124,153),Vector2(148,145),Vector2(169,151)],row,5,3,a*.75)
  _specks(image,row,f,Vector2(98,90),10,71,true,6,a)

static func _thorn(image: Image, id: String, mode: int, f: int, row: Dictionary) -> void:
 var a := _alpha(mode,f)
 _shadow(image,row,f,69)
 if id=="THORN_LASH":
  var wave := sin(float(f)*.43)*13
  var points := [Vector2(25,134),Vector2(48,102+wave),Vector2(79,77-wave*.3),Vector2(115,83+wave),Vector2(145,54+wave*.6),Vector2(172,66-wave*.3)]
  _path(image,points,row,9,3,a)
  for i: int in range(1,5):
   var p := Vector2(points[i])
   _leaflet(image,p,20+i%2*9,-.8+i*.28,row,2 if i%2 else 5,a)
  _specks(image,row,f,Vector2(119,88),8,57,false,6,a)
 else:
  for i: int in range(6):
   var x := 21+i*29
   var height := 52+(i*17)%37+mini(f,7)
   _path(image,[Vector2(x,154),Vector2(x+8,128),Vector2(x-3,157-height),Vector2(x+12,142-height)],row,8,2,a)
   _leaflet(image,Vector2(x+3,119),20+i%3*7,-.75+i*.22,row,3 if i%2 else 5,a)
   if i<5 and i!=2:
    _path(image,[Vector2(x+7,120-height*.35),Vector2(x+15,101-height*.35),Vector2(x+33,119-height*.35)],row,4,6,a*.8)
  for i: int in range(4): P.rect(image,31+i*35,67+(i%2)*13-f,8,3,_c(row,4,a))
  _specks(image,row,f,Vector2(101,115),12,71,false,5,a)

static func _graft(image: Image, id: String, mode: int, f: int, row: Dictionary) -> void:
 var a := _alpha(mode,f)
 _shadow(image,row,f,66)
 match id:
  "THORN_GRAFT_CATCH":
   for i: int in range(3):
    var y := 66+i*32
    var offset := f*2 if mode==1 else -f
    _path(image,[Vector2(35,140),Vector2(60+i*7,105),Vector2(95+offset,y),Vector2(145+i*12,y-9),Vector2(134+i*12,y+15)],row,8-i,3+i%2,a)
    _leaflet(image,Vector2(128+i*10,y+9),19,.8,row,5,a)
   _specks(image,row,f,Vector2(111,110),9,60,false,6,a)
  "THORN_SAP_BLADE":
   for side: int in [-1,1]:
    _path(image,[Vector2(96+side*28,151),Vector2(96+side*42,111),Vector2(96+side*58,71),Vector2(96+side*46,49-f*.6),Vector2(96+side*26,58)],row,8,3,a)
    _drop(image,Vector2(96+side*52,97+f),7,row,5,a)
    _leaflet(image,Vector2(96+side*30,122),26,side*.9,row,5,a)
   _specks(image,row,f,Vector2(98,80),7,60,true,6,a)
  "THORN_GRAFT_RUPTURE":
   for i: int in range(3):
    var x := 41+i*55
    var y := 122+(i%2)*25
    var opening := mini(f,9)*2
    _shell(image,Vector2(x-opening*.3,y),18,30+opening,row,2,a)
    _leaflet(image,Vector2(x+9,y-18),34+f,(-.5+i*.4),row,5,a)
    _drop(image,Vector2(x-12,y-35-f*.8),6,row,6,a)
    _path(image,[Vector2(x,y+3),Vector2(x+8,y+13),Vector2(x+23,y+7)],row,4,3,a*.7)
   _specks(image,row,f,Vector2(96,108),12,69,true,5,a)

static func _antler(image: Image, id: String, mode: int, f: int, row: Dictionary) -> void:
 var a := _alpha(mode,f)
 _shadow(image,row,f,69)
 match id:
  "ANTLER_BRANCH_SWEEP":
   for i: int in range(4):
    var dx := mini(f,9)*3
    var end := Vector2(99+i*23+dx*.2,49+i*25)
    _path(image,[Vector2(33,141),Vector2(56+i*7,118),end],row,8-i,3,a)
    _path(image,[end-Vector2(13,-4),end+Vector2(-16,-20),end+Vector2(-3,-28)],row,5,4,a)
    _leaflet(image,end+Vector2(-12,5),23,.7,row,5,a)
   _specks(image,row,f,Vector2(129,114),10,53,false,4,a)
  "ANTLER_BARK_FOLD":
   for side: int in [-1,1]:
    _path(image,[Vector2(96+side*22,155),Vector2(96+side*51,122-f*.5),Vector2(96+side*65,82-f)],row,7,3,a)
    _path(image,[Vector2(96+side*47,132),Vector2(96+side*65,146),Vector2(96+side*76,136)],row,5,5,a)
    _leaflet(image,Vector2(96+side*41,107),40+f*.6,side*.7,row,6,a)
   _specks(image,row,f,Vector2(93,143),8,64,false,4,a)
  "ANTLER_RUT_SEASON":
   for side: int in [-1,1]:
    for depth: int in range(2):
     var x := 96+side*(42+depth*25)
     var top := 46+depth*23-mini(f,7)
     _path(image,[Vector2(x,156),Vector2(x-side*5,114),Vector2(x+side*9,top+20),Vector2(x-side*10,top)],row,9-depth*2,3,a)
     _path(image,[Vector2(x+side*2,top+47),Vector2(x+side*18,top+28),Vector2(x+side*11,top+10)],row,5,4,a)
   _path(image,[Vector2(24,153),Vector2(48,145),Vector2(72,156)],row,5,6,a*.7)
   _path(image,[Vector2(120,156),Vector2(145,145),Vector2(169,151)],row,5,6,a*.7)
   _specks(image,row,f,Vector2(96,83),13,69,true,5,a)

static func _comet(image: Image, id: String, mode: int, f: int, row: Dictionary) -> void:
 var a := _alpha(mode,f)
 _shadow(image,row,f,65)
 match id:
  "POLLEN_FIREFLY_FAN":
   for i: int in range(5):
    var angle := -.9+i*.42
    var p := Vector2(40,134)+Vector2(cos(angle),sin(angle))*float(65+f*4+i*6)
    _path(image,[Vector2(29+i*4,145),Vector2(61+i*8,91+i*7),p],row,3,3+i%3,a*.7)
    _oval(image,p,Vector2(8+i%3,6+i%2),row,3 if i%2 else 5,a)
    _leaflet(image,p+Vector2(-9,4),17,-.7,row,6,a)
   _specks(image,row,f,Vector2(101,89),13,74,true,4,a)
  "POLLEN_LONE_COMET":
   var p := Vector2(107+f*2.5,64+sin(float(f)*.45)*8)
   for i: int in range(5):
    var t := float(i)/4.0
    var q := p-Vector2(90*t,0)+Vector2(0,sin(t*8.0-f*.6)*float(9+i*3)+t*50)
    _oval(image,q,Vector2(12-i,6-i*.5),row,3 if i%2 else 6,a*.65)
    if i>0: _line(image,q,p-Vector2(50*t,-12*t),row,3,5,a*.6)
   _crystal(image,p+Vector2(0,17),42,18,row,3,a)
   _leaflet(image,p+Vector2(-12,10),33,-1.1,row,5,a)
   _leaflet(image,p+Vector2(11,10),25,.9,row,6,a)
   _specks(image,row,f,Vector2(94,109),9,61,true,4,a)
  "POLLEN_COMET_PROCESSION":
   for i: int in range(4):
    var x := 31+i*39
    var y := 65+(i%2)*47
    var p := Vector2(x+sin(float(f+i)*.35)*9,y-f*.5)
    _path(image,[Vector2(32,154),Vector2(54+i*13,127),p,Vector2(minf(176,p.x+24),p.y+17)],row,5-i%2,3+i%3,a*.75)
    _crystal(image,p+Vector2(0,12),30+i%2*11,10+i%2*3,row,3+i%3,a)
    _leaflet(image,p+Vector2(-5,9),24,-.7+i*.35,row,6,a)
   _specks(image,row,f,Vector2(99,109),20,76,true,4,a)

static func _tunnel(image: Image, id: String, mode: int, f: int, row: Dictionary) -> void:
 var a := _alpha(mode,f)
 _shadow(image,row,f,70)
 if id=="TUNNEL_SHOCK":
  # Station roof lifts in two unequal halves; healing air is inward/upward.
  for side: int in [-1,1]:
   var x := 96+side*(44+f*.7)
   _shell(image,Vector2(x,118-f*.8),28,39+mini(f,7),row,2,a)
   _path(image,[Vector2(x+side*7,129),Vector2(x-side*12,144),Vector2(96+side*20,139-f)],row,5,5,a)
   _oval(image,Vector2(x-side*11,82-f),Vector2(8,10),row,4,a)
  _specks(image,row,f,Vector2(94,135),11,67,true,5,a)
 else:
  # A wide vent-fan with heavy ribs, never a bubble around the entire army.
  for i: int in range(5):
   var x := 27+i*35
   var high := 38+(i*13)%24+mini(f,8)*2
   _shell(image,Vector2(x,127+i%2*13),20,high,row,2 if i%2 else 3,a)
   _path(image,[Vector2(x+6,131),Vector2(x+14,151),Vector2(x+23,141)],row,7,5,a)
   _oval(image,Vector2(x,96-high*.4-f*.6),Vector2(7,8),row,6,a)
  for i: int in range(3): P.ellipse(image,Vector2(47+i*46+f*.7,148-i%2*7),Vector2(25,9),_c(row,1,a*.19),true)
  _specks(image,row,f,Vector2(95,119),13,76,false,5,a)

static func _echo(image: Image, id: String, mode: int, f: int, row: Dictionary) -> void:
 var a := _alpha(mode,f)
 _shadow(image,row,f,65)
 match id:
  "ECHO_BIND":
   var wav := sin(float(f)*.55)*9
   _path(image,[Vector2(29,129),Vector2(53,96+wav),Vector2(77,110),Vector2(107,70-wav),Vector2(136,91),Vector2(166,51+wav)],row,5,3,a)
   for i: int in range(3):
    var x := 43+i*48
    _crystal(image,Vector2(x,146-f*.3),36+i*10,10,row,5,a)
    _path(image,[Vector2(x-10,124),Vector2(x-18,115-f),Vector2(x-10,104),Vector2(x+10,109+f*.3)],row,3,6,a)
   _specks(image,row,f,Vector2(97,101),10,67,true,4,a)
  "ECHO_FLARE":
   var slide := f*2
   for i: int in range(5):
    var x := 29+i*29+slide*.25
    var y := 115-i*9
    _crystal(image,Vector2(x,y),24+i%3*13,8+i%2*4,row,3 if i%2 else 5,a)
   _path(image,[Vector2(21,137),Vector2(59,110),Vector2(101,91),Vector2(171,58)],row,5,3,a)
   _path(image,[Vector2(25,147),Vector2(64,121),Vector2(107,104),Vector2(178,70)],row,2,5,a*.65)
   _specks(image,row,f,Vector2(111,91),12,70,false,4,a)
  "ECHO_OATH":
   var collapse := f*2 if mode==1 else mini(f,7)
   for i: int in range(5):
    var theta := float(i)*TAU/5.0-.7
    var p := Vector2(96,113)+Vector2(cos(theta)*float(65-collapse),sin(theta)*float(45-collapse*.4))
    _crystal(image,p,39+i%2*20,13+i%3,row,3 if i%2 else 5,a)
    _line(image,p-Vector2(0,17),Vector2(96,113),row,4,6,a*.65)
   _oval(image,Vector2(96,112),Vector2(12+f%3,17),row,1,a)
   _specks(image,row,f,Vector2(96,109),12,67,mode==0,4,a)

static func _stalker(image: Image, id: String, mode: int, f: int, row: Dictionary) -> void:
 var a := _alpha(mode,f)
 _shadow(image,row,f,67)
 match id:
  "SPORE_SEAL":
   var y := 87+f*.5
   _arrow(image,Vector2(30+f,y+25),Vector2(145+f,y-6),row,10,a,false)
   _path(image,[Vector2(113+f,y-16),Vector2(135+f,y-22),Vector2(127+f,y-2)],row,6,5,a)
   _path(image,[Vector2(126+f,y+17),Vector2(149+f,y+18),Vector2(140+f,y-1)],row,6,3,a)
   for i: int in range(3): _oval(image,Vector2(47+i*17,112+f*.5),Vector2(6,8),row,2,a)
   _specks(image,row,f,Vector2(123,94),7,39,false,4,a)
  "SPORE_SWEEP":
   var p := Vector2(148+f*1.4,70+sin(float(f)*.3)*5)
   _arrow(image,Vector2(25,121-f*.8),p,row,4,a,false)
   for side: int in [-1,1]:
    _path(image,[p-Vector2(25,0),p+Vector2(-31,side*16),p+Vector2(-16,side*7)],row,4,5,a)
   _path(image,[Vector2(31,133),Vector2(63,128-f*.5),Vector2(109,101-f*.7)],row,2,6,a*.65)
   _specks(image,row,f,Vector2(141,80),8,35,false,4,a)
  "SPORE_MEND":
   for side: int in [-1,1]:
    var x := 96+side*(39+sin(float(f)*.28)*3)
    _path(image,[Vector2(x,156),Vector2(x+side*14,120),Vector2(x+side*21,69),Vector2(x+side*8,44)],row,12,2,a)
    _arrow(image,Vector2(x,128),Vector2(x+side*13,56-f*.5),row,5,a,false)
    _oval(image,Vector2(x+side*9,80),Vector2(7,12),row,3 if side<0 else 5,a)
    for i: int in range(3): P.rect(image,roundi(x+side*(8+i*5)),106+i*11-f%3,7,4,_c(row,4 if i%2==0 else 6,a))
   _specks(image,row,f,Vector2(94,70),11,69,true,5,a)

static func _ferment(image: Image, id: String, mode: int, f: int, row: Dictionary) -> void:
 var a := _alpha(mode,f)
 _shadow(image,row,f,70)
 if id=="SPORE_REMEDY":
  # Ladle shape is deliberate: a pouring implement, not a poison bomb.
  _path(image,[Vector2(28,132),Vector2(49,102-f*.7),Vector2(67,67-f*.5)],row,7,3,a)
  _oval(image,Vector2(69,59-f*.5),Vector2(21,12),row,2,a)
  _oval(image,Vector2(69,56-f*.5),Vector2(14,6),row,4,a)
  for i: int in range(3):
   var x := 78+i*37
   var y := 135-((f+i*2)%12)*4
   _path(image,[Vector2(x,147),Vector2(x-9,124),Vector2(x+6,105-f)],row,4,3+i,a*.75)
   _oval(image,Vector2(x,y),Vector2(11+i%2*3,6),row,3 if i==0 else 5 if i==1 else 6,a)
   _drop(image,Vector2(x-13,118+f*2),4,row,4,a)
  _specks(image,row,f,Vector2(105,119),11,64,true,5,a)
 else:
  # Three independent cultures braid sideways, without a damaging pool.
  for i: int in range(3):
   var y := 109+i*20
   var phase := float(f)*.36+i*1.1
   _path(image,[Vector2(20,y+sin(phase)*7),Vector2(53,y-15+sin(phase+1)*8),Vector2(94,y+8),Vector2(137,y-11+cos(phase)*9),Vector2(174,y+sin(phase+2)*5)],row,10-i*2,3+i,a*.75)
   for k: int in range(3):
    var p := Vector2(40+k*50+i*7,y-13-f*.65)
    _oval(image,p,Vector2(9,5),row,3+i,a)
    P.line(image,p.round()+Vector2(0,4),p.round()+Vector2(1,13),_c(row,2,a),3)
  _specks(image,row,f,Vector2(98,102),15,74,true,4,a)

static func _quake(image: Image, id: String, mode: int, f: int, row: Dictionary) -> void:
 var a := _alpha(mode,f)
 _shadow(image,row,f,72)
 if id=="QUAKE_SNARE":
  for i: int in range(4):
   var x := 30+i*40
   var y := 145-i%2*24
   var spread := mini(f,9)
   _poly(image,[Vector2(x-15-spread,y),Vector2(x-22-spread,y-29),Vector2(x+5-spread,y-40),Vector2(x+12-spread,y-9)],_c(row,0,a))
   _poly(image,[Vector2(x-12-spread,y-4),Vector2(x-18-spread,y-26),Vector2(x+3-spread,y-34),Vector2(x+8-spread,y-11)],_c(row,2+i%2,a))
   _path(image,[Vector2(x+8+spread,y-6),Vector2(x+3+spread,y-24),Vector2(x+15+spread,y-38)],row,3,4,a)
  _specks(image,row,f,Vector2(100,131),14,74,false,5,a)
 else:
  # Contract pages are massive irregular slabs, not homogenous mountain spikes.
  for i: int in range(4):
   var x := 29+i*44
   var y := 151-i%2*7
   var high := 65+i%3*17+mini(f,8)
   _poly(image,[Vector2(x-17,y),Vector2(x-25,y-high+12),Vector2(x+5,y-high),Vector2(x+20,y-high+23),Vector2(x+14,y-5)],_c(row,0,a))
   _poly(image,[Vector2(x-13,y-5),Vector2(x-20,y-high+16),Vector2(x+3,y-high+5),Vector2(x+14,y-high+25),Vector2(x+9,y-8)],_c(row,2 if i%2 else 3,a))
   _path(image,[Vector2(x-12,y-high+27),Vector2(x+6,y-high+24),Vector2(x+10,y-high+32)],row,3,4,a)
   _path(image,[Vector2(x-9,y-19),Vector2(x+2,y-33),Vector2(x-2,y-48)],row,2,5,a)
  _specks(image,row,f,Vector2(98,123),18,75,false,4,a)

static func _prism(image: Image, id: String, mode: int, f: int, row: Dictionary) -> void:
 var a := _alpha(mode,f)
 _shadow(image,row,f,67)
 match id:
  "PRISM_FACET_PIN":
   for i: int in range(2):
    var p := Vector2(53+i*87,140-i*29)
    _crystal(image,p,64+f*.8-i*12,14,row,3 if i==0 else 5,a)
    _path(image,[p+Vector2(-18,7),p+Vector2(-5,-5),p+Vector2(17,1),p+Vector2(22,-11)],row,6,6,a)
   _path(image,[Vector2(36,151),Vector2(62,128),Vector2(109,117),Vector2(150,96)],row,3,5,a*.65)
   _specks(image,row,f,Vector2(99,111),10,70,true,4,a)
  "PRISM_DOUBLE_EDGE":
   for side: int in [-1,1]:
    var p := Vector2(96+side*(39+sin(float(f)*.3)*3),139+side*9)
    _crystal(image,p,75-side*12+f*.4,14+side*3,row,3 if side<0 else 5,a)
    _path(image,[p+Vector2(-side*4,0),p+Vector2(side*22,-29),p+Vector2(side*20,-61)],row,4,6,a*.75)
   _specks(image,row,f,Vector2(92,84),8,66,true,4,a)
  "PRISM_REFRACTION_CUT":
   for i: int in range(4):
    var p := Vector2(31+i*43,138-(i%2)*35)
    var skew := float(i%2*2-1)*(12-f*.7)
    _crystal(image,p,49+i%3*12,15,row,3 if i%2 else 5,a)
    _path(image,[p+Vector2(-18,6),p+Vector2(skew,-29),p+Vector2(20,-49)],row,5,4,a)
    if i<3: _path(image,[p+Vector2(7,-19),p+Vector2(25,-31),p+Vector2(45,-14)],row,3,6,a*.65)
   _specks(image,row,f,Vector2(98,101),17,74,mode==0,4,a)

static func _carapace(image: Image, id: String, mode: int, f: int, row: Dictionary) -> void:
 var a := _alpha(mode,f)
 _shadow(image,row,f,73)
 match id:
  "CARAPACE_SHELL_SPLIT":
   var close := mini(f,9)*2 if mode==1 else -mini(f,9)
   for side: int in [-1,1]:
    var x := 96+side*(56-close)
    _shell(image,Vector2(x,135),27+side*4,55-side*9,row,3,a)
    _path(image,[Vector2(x,132),Vector2(x-side*8,105),Vector2(x-side*23,93)],row,11,2,a)
    _crystal(image,Vector2(x-side*19,92),23,10,row,4,a)
   _specks(image,row,f,Vector2(95,126),12,67,false,6,a)
  "CARAPACE_NEST_GUARD":
   for side: int in [-1,1]:
    var x := 96+side*47
    _shell(image,Vector2(x,136-f*.4),26,65+mini(f,7),row,2,a)
    for i: int in range(3):
     var y := 94+i*16
     P.rect(image,roundi(x-side*8),y,12,5,_c(row,0,a))
     _path(image,[Vector2(x+side*9,y),Vector2(x+side*22,y-8-f*.5),Vector2(x+side*32,y-6-f*.8)],row,3,5,a*.7)
     _drop(image,Vector2(x-side*17,y+f),4,row,4,a)
   _specks(image,row,f,Vector2(96,118),9,74,true,5,a)
  "CARAPACE_LAYERED_MOLT":
   for i: int in range(4):
    var x := 29+i*44
    var y := 142-(i%2)*26
    var h := 47+i%3*14+mini(f,8)
    _shell(image,Vector2(x,y),24,h,row,2 if i%2 else 3,a)
    _shell(image,Vector2(x-5,y-14-f*.4),20,h*.66,row,6 if i%2 else 5,a*.7)
    _path(image,[Vector2(x-15,y+3),Vector2(x-5,y-9),Vector2(x+12,y-6)],row,4,5,a)
   _specks(image,row,f,Vector2(98,104),17,75,true,4,a)

static func _passive(image: Image, id: String, f: int, row: Dictionary) -> void:
 # Holder glyphs, not world-range rings. Root alone supplies eligibility.
 var y := 145+sin(float(f)*.48)*2
 var a := .5+float(f%4)*.08
 match id:
  "VINE_WARD":
   for i: int in range(3): _shell(image,Vector2(60+i*35,y+i%2*7),13,17+i%2*5,row,2,a)
  "INNATE_VINE_WARDEN":
   for i: int in range(3):
    var x := 67+i*28
    _poly(image,[Vector2(x-7,y),Vector2(x-4,y-8),Vector2(x+5,y-8),Vector2(x+9,y),Vector2(x+4,y+7),Vector2(x-5,y+7)],_c(row,0,a))
    P.rect(image,x-2,roundi(y)-3,4,5,_c(row,5 if (f/2+i)%3==0 else 2,a))
  "INNATE_LEAF_SEER":
   for i: int in range(3): _leaflet(image,Vector2(62+i*31,y+5),14+i*3,-.7+i*.5,row,6 if i%2 else 3,a)
  "INNATE_WIND_COURIER":
   for i: int in range(4): _leaflet(image,Vector2(57+i*25,y-i%2*5),15+i%2*7,.9,row,3 if i==(f/3)%4 else 5,a)
  "BLOOM_SPRING":
   for i: int in range(3):
    _leaflet(image,Vector2(60+i*36,y+5),17,.7-f*.02,row,3,a)
    P.rect(image,55+i*36,roundi(y)+8-f%3,9,2,_c(row,5,a))
  "INNATE_BLOOM_GUIDE":
   for i: int in range(4): _drop(image,Vector2(56+i*25,y-((f+i*2)%7)),3,row,5 if i%2 else 3,a)
  "THORN_BREEZE":
   _path(image,[Vector2(51,y+8),Vector2(58,y-14),Vector2(71,y+1),Vector2(77,y-9)],row,3,2,a)
   for i: int in range(3): P.line(image,Vector2(78+i*10,y-7-i%2*4),Vector2(84+i*10,y+4),_c(row,6,a),2)
   _leaflet(image,Vector2(130,y+6),18,-.6,row,3,a)
  "INNATE_THORN_CHANTER":
   for i: int in range(3): _path(image,[Vector2(57+i*33,y+6),Vector2(62+i*33,y-6),Vector2(72+i*33,y-2)],row,3,3+i%2,a)
  "INNATE_THORN_REAVER":
   for side: int in [-1,1]: _path(image,[Vector2(96+side*27,y+6),Vector2(96+side*35,y-8),Vector2(96+side*16,y-13)],row,4,5,a)
  "INNATE_ANTLER_WARRIOR":
   _path(image,[Vector2(52,y+7),Vector2(76,y-2),Vector2(110,y+2),Vector2(140,y-7)],row,3,2,a)
   for i: int in range(3): _oval(image,Vector2(68+i*29,y+3-i*4),Vector2(5,4),row,4 if (f/3)%3==i else 3,a)
  "INNATE_POLLEN_COMET":
   var p := Vector2(96+cos(float(f)*.42)*31,y-8+sin(float(f)*.42)*8)
   _path(image,[Vector2(55,y+6),Vector2(72,y-8),p],row,2,6,a)
   _oval(image,p,Vector2(5,4),row,4,a)
  "TUNNEL_WARD":
   for i: int in range(3):
    _shell(image,Vector2(59+i*36,y+5),11,15,row,2,a)
    P.rect(image,54+i*36,roundi(y)-7,8,3,_c(row,5,a))
  "INNATE_TUNNEL_SENTINEL":
   _path(image,[Vector2(52,y+4),Vector2(70,y-5),Vector2(88,y+1)],row,4,2,a)
   _path(image,[Vector2(105,y+1),Vector2(124,y-5),Vector2(143,y+4)],row,4,2,a)
   for i: int in range(3): P.rect(image,64+i*29,roundi(y)-f%3,6,4,_c(row,5,a))
  "INNATE_ECHO_BINDER":
   for i: int in range(3):
    _crystal(image,Vector2(62+i*33,y+7),14+i%2*8,5,row,5,a)
    P.rect(image,58+i*33,roundi(y)-4,5,2,_c(row,6,a))
  "INNATE_SPORE_STALKER":
   _path(image,[Vector2(52,y+7),Vector2(52,y-5),Vector2(73,y-5)],row,3,5,a)
   _path(image,[Vector2(141,y+7),Vector2(141,y-5),Vector2(121,y-5)],row,3,3,a)
   P.line(image,Vector2(78+f,y),Vector2(100+f,y),_c(row,4,a),2)
  "SPORE_GLOW":
   for i: int in range(3):
    var p := Vector2(60+i*35,y-float((f+i*3)%6)*.5)
    _oval(image,p,Vector2(9,6),row,3+i,a)
    P.line(image,p+Vector2(0,5),p+Vector2(1,11),_c(row,2,a),3)
  "INNATE_SPORE_GUIDE":
   _oval(image,Vector2(62,y+2),Vector2(12,7),row,3,a)
   _oval(image,Vector2(132,y+4),Vector2(8,5),row,5,a)
   _drop(image,Vector2(78+f*3,y-8+sin(float(f)*.4)*4),3,row,4,a)
  "QUAKE_RHYTHM":
   for i: int in range(3):
    var x := 56+i*33
    P.rect(image,x,roundi(y)+i%2*5,21,6,_c(row,0,a))
    P.rect(image,x+2,roundi(y)+i%2*5,15,2,_c(row,5 if (f/2+i)%3==0 else 3,a))
  "INNATE_QUAKE_PRIEST":
   _path(image,[Vector2(49,y+6),Vector2(61,y+6),Vector2(65,y-2),Vector2(81,y-2)],row,3,3,a)
   _path(image,[Vector2(110,y+3),Vector2(126,y+3),Vector2(129,y-7),Vector2(144,y-7)],row,3,5,a)
  "INNATE_PRISM_MANTIS":
   for i: int in range(3): _crystal(image,Vector2(59+i*36,y+5-i%2*7),18+i%2*8,6,row,3+i%3,a)
  "INNATE_CARAPACE_WARRIOR":
   for i: int in range(3):
    var x := 57+i*34
    P.rect(image,x,roundi(y),16,5,_c(row,0,a))
    _path(image,[Vector2(x+4,y-1),Vector2(x+10,y-9-f*.3),Vector2(x+19,y-8)],row,2,5,a)
  _:
   # Authoring-only AURA request for an active has no fictional active field.
   # Show a tiny material specimen; runtime must not call it as a real aura.
   var seed := posmod(id.hash(),17)
   _leaflet(image,Vector2(63+seed,y+6),12+seed%7,-.6,row,3,a)
   _crystal(image,Vector2(127-seed*.4,y+4),12+seed%6,4,row,5,a)
