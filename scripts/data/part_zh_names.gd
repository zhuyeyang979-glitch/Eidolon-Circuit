extends RefCounted

const EXACT_NAMES := {
	"自定义": "自定义",
	"SOUL ANCHOR": "英魂锚",
	"SOUL: FIRST EDGE ECHO": "始锋回响英魂",
	"CODE: LINE": "源代码：直线队列",
	"ETHER: ORIGIN PIN": "以太：始点星钉",
	"STARTER SOCKET JOINT": "初始插口关节",
	"BOT LEFT": "底左",
	"BOT MID": "底中",
	"BOT RIGHT": "底右",
	"LEFT MID": "左中",
	"RIGHT MID": "右中",
	"TOP LEFT": "顶左",
	"TOP MID": "顶中",
	"TOP RIGHT": "顶右",
	"AUTO AIM": "自动瞄准",
	"MANUAL AIM": "手动瞄准",
	"SWING AIM": "摆击瞄准",
	"SWING ASSAULT": "摆击突袭",
	"DIRECT ASSAULT": "直接突袭",
	"三肢轮切 / TRIPLE-LIMB CROSS CUT": "三肢轮切",
	"伸旋突斩 / EXTEND-SLASH DRIVER": "伸旋突斩",
	"刃弧切返 / BLADE ARC RETURN": "刃弧切返",
	"双段正锋折返 / TWO-LINK FORWARD SNAP": "双段正锋折返",
	"大锤蓄砸 / HAMMER WINDUP-SLAM": "大锤蓄砸",
	"巨剑压斩 / GREATSWORD COMMIT CLEAVE": "巨剑压斩",
	"拳套伸摆 / GAUNTLET EXTEND-SWING": "拳套伸摆",
	"来复枪点射启动 / RIFLE BURST ACTIVATE": "来复枪点射启动",
	"枪械启动 / GUN ACTIVATE": "枪械启动",
	"标准动量拳套 / STANDARD MOMENTUM GAUNTLET": "标准动量拳套",
	"标准化学喷射器 / STANDARD CAUSTIC SPRAYER": "标准化学喷射器",
	"标准子弹狙击枪 / STANDARD BULLET SNIPER": "标准子弹狙击枪",
	"标准捕缚蛛丝枪 / STANDARD WEB TETHER GUN": "标准捕缚蛛丝枪",
	"棱镜照射启动 / PRISM BEAM ACTIVATE": "棱镜照射启动",
	"榴弹弧射启动 / GRENADE ARC ACTIVATE": "榴弹弧射启动",
	"武士刀瞬斩 / KATANA QUICKDRAW": "武士刀瞬斩",
	"猎隼锁射启动 / KESTREL MISSILE LOCK": "猎隼锁射启动",
	"盾牌架撞 / SHIELD GUARD-BASH": "盾牌架撞",
	"红线猎隼导弹架 / REDLINE KESTREL MISSILE POD": "红线猎隼导弹架",
	"红线跳爆榴弹枪 / REDLINE HOPPER GRENADE LAUNCHER": "红线跳爆榴弹枪",
	"蛛丝牵引 / WEB TETHER ACTIVATE": "蛛丝牵引",
	"轻型动量拳套 / LIGHT MOMENTUM GAUNTLET": "轻型动量拳套",
	"重型动量拳套 / HEAVY MOMENTUM GAUNTLET": "重型动量拳套",
	"镰月钩返 / SCYTHE HOOK RETURN": "镰月钩返",
	"长视制式来复枪 / LONGSIGHT PATTERN RIFLE": "长视制式来复枪",
	"长视棱镜激光枪 / LONGSIGHT PRISM LASER": "长视棱镜激光枪",
}

const TOKEN_NAMES := {
	"1": "一", "2": "二", "4": "四", "5": "五", "90": "九十", "180": "百八十", "360": "三百六十",
	"1M": "一米", "2M": "二米", "3M": "三米", "A": "甲", "B": "乙", "C": "丙", "D": "丁", "E": "戊", "F": "己", "G": "庚", "H": "辛",
	"II": "二型", "XI": "十一", "XS": "微型", "S": "小型", "M": "中型", "L": "大型", "XL": "巨型", "QE": "双键", "U": "马蹄",
	"ACCELERATOR": "加速器", "ACID": "酸蚀", "ACTION": "动作", "ACTIVATE": "启动", "ACTUATOR": "作动器", "ADVANCE": "预支", "AEGIS": "圣盾",
	"AI": "智脑", "AIM": "瞄准", "AIR": "隔离", "ALL": "全谱", "ALPHA": "甲型", "AMMO": "弹药", "ANCHOR": "锚定", "AND": "与",
	"ANTENNA": "天线", "ANTI": "反制", "API": "接口", "APOGEE": "远地点", "ARC": "弧形", "AREA": "区域", "ARENA": "竞技场",
	"ARMOR": "护甲", "ARRAY": "阵列", "ARSENAL": "武库", "ASCENT": "升格", "ASSAULT": "突击", "AUGER": "螺旋钻", "AURA": "光环",
	"AURORA": "极光", "AUTO": "自动", "AUTOCANNON": "机炮", "AUTOSWING": "自摆", "AUX": "副装", "AXE": "斧", "AXLE": "轴心",
	"BACKLASH": "回抽", "BAFFLE": "挡板", "BALANCE": "均衡", "BALL": "球形", "BANK": "组列", "BANKED": "倾斜", "BARB": "倒钩",
	"BARRAGE": "弹幕", "BARRIER": "结界", "BASH": "撞击", "BASTION": "堡垒", "BATTERY": "炮组", "BAY": "舱", "BEACON": "信标",
	"BEAM": "光束", "BEARING": "承重", "BECOME": "化身", "BEND": "弯折", "BETA": "乙型", "BIRD": "飞鸟", "BIT": "浮游炮",
	"BITE": "咬合", "BLACK": "黑洞", "BLACKBOX": "黑匣", "BLACKOUT": "断讯", "BLADE": "刀刃", "BLOCK": "块", "BLOOM": "花簇",
	"BLUE": "蓝焰", "BODY": "机体", "BODYGUARD": "护卫", "BODYGUARDS": "护卫队", "BOMBARD": "轰击", "BOOMERANG": "回旋镖",
	"BOOST": "推进", "BOOSTED": "增压", "BOOSTER": "推进器", "BOOT": "启动", "BOOTLEG": "盗版", "BOT": "底", "BOXING": "拳击",
	"BRACE": "支架", "BRACED": "支撑", "BRAKE": "制动", "BRAWLER": "斗士", "BREACH": "破门", "BREACHBURST": "破阵爆",
	"BROAD": "宽幅", "BROOD": "巢群", "BUCKLER": "小圆盾", "BULKHEAD": "舱壁", "BULL": "公牛", "BULLET": "弹丸",
	"BULWARK": "壁垒", "BUNKER": "碉堡", "BURST": "爆发", "BUS": "总线", "BUSTER": "破城", "CABLE": "缆索", "CACHE": "缓存",
	"CACTUS": "棘簇", "CAGE": "笼", "CALIBRATION": "校准", "CANNON": "炮", "CAPACITOR": "电容", "CAPITAL": "资本",
	"CAPTAIN": "队长", "CAPTURE": "捕获", "CARAPACE": "甲壳", "CARGO": "货舱", "CARRIER": "载体", "CAST": "施放",
	"CASTLE": "城", "CATAPULT": "弹射器", "CATCH": "捕捉", "CATHEDRAL": "大教堂", "CAUSTIC": "腐蚀", "CELL": "电池",
	"CENTIPEDE": "蜈蚣", "CERAMIC": "陶瓷", "CHAIN": "链条", "CHAINED": "链式", "CHAOS": "混沌", "CHARGE": "炸药",
	"CHASSIS": "底盘", "CHEM": "化学", "CHEST": "胸腔", "CHILLER": "冷机", "CIPHER": "密钥", "CLAIM": "索赔",
	"CLAMP": "夹钳", "CLAW": "爪", "CLEAVE": "压斩", "CLOSE": "闭合", "CLOUD": "云群", "CLUSTER": "集簇", "CODE": "源代码",
	"COIL": "线圈", "COIN": "铸币", "COINRUN": "投币", "COLLECTORS": "收集队", "COLOSSUS": "巨像", "COMBINE": "合体",
	"COMBO": "连段", "COMMIT": "蓄力", "COMPACT": "紧凑", "CONDUCTOR": "导体", "CONNECTOR": "连接器", "CONSTELLATION": "星座",
	"CONTROL": "控制", "COOLANT": "冷却液", "COOLER": "冷却器", "CORE": "核心", "CORNER": "转角", "COUNTER": "反制",
	"COURSE": "赛道", "COVER": "掩护", "CRAB": "蟹式", "CRATER": "弹坑", "CRESCENT": "月弧", "CREW": "班组",
	"CROSS": "交叉", "CROWN": "王冠", "CRUISE": "巡航", "CRUSH": "粉碎", "CRUSTA": "甲壳", "CRYO": "寒冰",
	"CURVED": "弯曲", "CUT": "斩", "CYCLER": "轮换器", "DANCE": "舞步", "DART": "飞镖", "DASH": "冲刺",
	"DEADLOCK": "死锁", "DEFLECT": "偏转", "DENIAL": "封锁", "DINO": "恐龙", "DIRECT": "直接", "DIRECTIONAL": "定向",
	"DISC": "圆盘", "DISTRICT": "区块", "DIVIDEND": "分红", "DOCK": "船坞", "DOCKING": "对接", "DOME": "穹盾",
	"DOWN": "下行", "DRAG": "拖拽", "DRILL": "钻头", "DRIVER": "驱动器", "DRONE": "浮游机", "DRUM": "弹鼓",
	"DRYDOCK": "干船坞", "DUAL": "双联", "DUEL": "决斗", "DUELING": "决斗", "DUELIST": "决斗者", "DUMP": "倾泻",
	"DUNGEON": "地牢", "ECHO": "回响", "ECLIPSE": "蚀光", "EDGE": "边锋", "EJECT": "弹射", "ELBOW": "弯肘",
	"ELECTROMAG": "电磁", "EMITTER": "发射器", "ENGINE": "引擎", "ENTANGLE": "缠绕", "ENTRY": "入口", "ESCAPE": "逃生",
	"ESTOC": "重刺剑", "ETHER": "以太", "EXECUTION": "处刑", "EXPLOSIVE": "爆裂", "EXPOSED": "裸露", "EXTEND": "伸展",
	"FAN": "扇面", "FARADAY": "法拉第", "FEATHER": "羽翼", "FEELER": "触须", "FEINT": "佯攻", "FIBER": "纤维",
	"FIELD": "场", "FIN": "鳍片", "FIRE": "火控", "FIREWALL": "防火墙", "FIRING": "射击", "FIRST": "初始",
	"FIST": "拳", "FIXED": "固定", "FLANK": "侧袭", "FLARE": "耀斑", "FLEX": "柔性", "FLOATING": "浮游",
	"FLOOR": "地台", "FLOW": "流量", "FOCUS": "聚焦", "FOIL": "花剑", "FOLD": "折叠", "FOREARM": "前臂",
	"FORECLOSURE": "没收", "FORELIMB": "前肢", "FORM": "形态", "FORMATION": "阵型", "FORTRESS": "堡垒", "FORWARD": "正锋",
	"FOUNTAIN": "喷泉", "FRACTURE": "裂解", "FRAME": "框架", "FUR": "绒毛", "FURNACE": "熔炉", "GALAXY": "星河",
	"GALLERY": "射击廊", "GAPPED": "隔离", "GATE": "门", "GAUNTLET": "臂铠", "GECKO": "壁虎", "GENE": "基因",
	"GIMBAL": "万向", "GIRDER": "梁", "GLACIER": "冰川", "GLAND": "腺体", "GLINT": "闪光", "GLOVE": "拳套",
	"GRAFT": "嫁接", "GRAPPLE": "抓取", "GRAVITY": "重力", "GREATSWORD": "巨剑", "GRENADE": "榴弹", "GRID": "格栅",
	"GRIP": "抓附", "GROUP": "组", "GUARD": "护卫", "GUIDANCE": "制导", "GUN": "枪", "GUNNER": "枪手",
	"GUTTER": "沟槽", "GYMNASIUM": "道场", "GYRO": "陀螺", "HACK": "骇入", "HACKING": "骇雾", "HALO": "光环",
	"HAMMER": "锤", "HANGAR": "机库", "HARDENED": "硬化", "HARDLIGHT": "硬光", "HARPOON": "鱼叉", "HATCHERY": "孵化舱",
	"HEAD": "头", "HEART": "心脏", "HEAT": "热力", "HEAVY": "重型", "HEEL": "足跟", "HERO": "英雄",
	"HIJACK": "劫持", "HINGE": "铰链", "HIP": "髋部", "HIVE": "蜂巢", "HOLE": "黑洞", "HOOF": "蹄",
	"HOOK": "钩返", "HOPPER": "跳爆", "HORN": "角", "HOUND": "猎犬", "HULL": "船壳", "HUMANOID": "人形",
	"HUMANOVA": "人形", "HUNT": "猎袭", "HYDRAULIC": "液压", "IFF": "敌我识别", "IMPACT": "冲击", "IMPULSE": "冲量",
	"INDEX": "索引", "INSERT": "插入", "INTERFACE": "接口", "INWARD": "内收", "IRON": "铁", "JACK": "千斤顶",
	"JACKPOT": "头奖", "JAILBREAK": "越狱", "JAMMER": "干扰器", "JAW": "颚", "JOINT": "关节", "JOUSTING": "骑枪",
	"KAIJU": "怪兽", "KATANA": "武士刀", "KEEL": "龙骨", "KEEPER": "守持器", "KESTREL": "猎隼", "KINETIC": "动能",
	"KIOSK": "亭站", "KNEE": "膝", "KNIGHT": "骑士", "KNUCKLE": "指节", "LABYRINTH": "迷宫", "LANCE": "枪矛",
	"LASER": "激光", "LATTICE": "格阵", "LAUNCH": "发射", "LAUNCHER": "发射器", "LEDGE": "台阶", "LEFT": "左",
	"LEG": "腿", "LEGION": "军团", "LEMNISCATE": "双环", "LEVIATHAN": "利维坦", "LIGHT": "轻型", "LIGHTSINK": "吞光",
	"LIMB": "肢体", "LINE": "线列", "LINEAR": "直线", "LINED": "衬毛", "LINK": "连杆", "LITE": "轻量",
	"LIZARD": "蜥蜴", "LOAD": "负载", "LOADOUT": "装配", "LOAN": "借贷", "LOCK": "锁", "LOCKSTEP": "齐步",
	"LONG": "长", "LONGEVITY": "长生", "LONGSIGHT": "长视", "LOOP": "回环", "LOW": "低", "LUG": "耳轴",
	"LUNG": "热肺", "MACHETE": "砍刀", "MAG": "磁轨", "MANTLE": "披甲", "MANUAL": "手动", "MARATHON": "长程",
	"MARKER": "标记", "MARKSMAN": "射手", "MASS": "质量", "MAUL": "大槌", "MAZE": "迷宫", "MECH": "机甲",
	"MEDIUM": "中型", "MEMORY": "记忆", "METAL": "金属", "METEOR": "流星", "MICRO": "微型", "MID": "中",
	"MIDFIELD": "中场", "MIDFLIGHT": "中途", "MINE": "地雷", "MINT": "铸币", "MIRROR": "镜", "MIRV": "分裂弹",
	"MISSILE": "导弹", "MIST": "雾", "MOMENTUM": "动量", "MONO": "单分子", "MONOCHROME": "单色", "MONSTER": "怪物",
	"MORPH": "变形", "MORTAR": "迫击炮", "MOSAIC": "镶嵌", "MULTI": "多形态", "MUSCLE": "肌肉", "MYOMER": "肌束",
	"NANO": "纳米", "NEEDLE": "针", "NEEDLER": "针枪", "NET": "网", "NODE": "节点", "NOZZLE": "喷嘴",
	"NTR": "神经索", "NUDGE": "微调", "OCTOPUS": "章鱼", "ODACHI": "大太刀", "OMNI": "全向", "ONE": "单向",
	"OPEN": "开放", "ORBIT": "环卫", "ORBITAL": "轨道", "ORIGIN": "始点", "OVERBURN": "过燃", "OVERDRIVE": "超驱",
	"OVERWATCH": "监视", "PACK": "小队", "PAD": "垫", "PADDED": "软垫", "PAGE": "页面", "PAIR": "双联",
	"PANEL": "板", "PARACHUTE": "降落伞", "PARADE": "巡游", "PART": "零件", "PATCH": "修补", "PATTERN": "制式",
	"PAW": "爪垫", "PHASE": "相位", "PICKUP": "拾取", "PIERCE": "穿刺", "PIERCING": "穿刺", "PIKE": "长矛",
	"PILGRIM": "朝圣者", "PILOT": "驾驶", "PIN": "星钉", "PINCER": "钳击", "PISTOL": "手枪", "PISTON": "活塞",
	"PIT": "维修坑", "PLATE": "板", "PLATFORM": "平台", "PLATING": "镀层", "POD": "舱", "POLARITY": "极性",
	"POPPER": "破弹", "PORT": "端口", "PRACTICE": "练习", "PRESS": "压迫", "PRESSURE": "压力", "PREY": "猎物",
	"PRISM": "棱镜", "PRISON": "牢笼", "PUBLIC": "公共", "PUPPET": "傀儡", "QUARTET": "四重队", "QUESTION": "问题",
	"QUICK": "速攻", "QUICKDRAW": "瞬斩", "QUIET": "静默", "RACKET": "球拍", "RADIATOR": "散热器", "RAID": "突袭",
	"RAIL": "轨", "RAIN": "雨", "RAKE": "耙", "RAM": "冲锤", "RANGE": "靶场", "RANGER": "游骑",
	"RAPID": "快速", "RAPIER": "刺剑", "RAZOR": "剃刀", "REACTION": "反应", "REACTIVE": "反应", "REACTOR": "反应炉",
	"REAR": "后方", "RECALL": "回收", "RECEIVER": "接收器", "RECOIL": "后坐", "RED": "红线", "REDLINE": "红线",
	"REEL": "卷收", "REFLECTOR": "反射器", "REMORAS": "吸附队", "RENTIER": "食利者", "REPAIR": "维修", "REPULSOR": "斥力",
	"RESOURCE": "资源", "RETINUE": "侍队", "RETREAT": "撤退", "RETURN": "折返", "REV": "转速", "RIB": "肋骨",
	"RICOCHET": "跳弹", "RIFLE": "来复枪", "RIGHT": "右", "RIGID": "刚性", "RING": "环", "RIPOSTE": "还击",
	"RITE": "仪式", "ROACH": "蟑甲", "ROD": "杆", "ROLE": "角色", "ROOM": "房间", "ROTARY": "旋转",
	"ROTATION": "旋转", "ROUTE": "路线", "ROUTER": "路由", "ROYAL": "王室", "SABER": "军刀", "SALVO": "齐射",
	"SANCTUM": "圣域", "SATURATION": "饱和", "SCAR": "疤痕", "SCOUT": "侦察", "SCREEN": "屏障", "SCRIPT": "脚本",
	"SCYTHE": "镰刀", "SEALED": "封存", "SEED": "种子", "SEEKER": "猎隼", "SEGMENT": "分段", "SELF": "自身",
	"SEND": "发送", "SENTINEL": "哨卫", "SENTRIES": "哨兵", "SERPENT": "蛇形", "SERVE": "发球", "SHALLOW": "浅弯",
	"SHEET": "薄片", "SHELL": "炮弹", "SHIELD": "盾", "SHIFT": "换位", "SHIN": "胫骨", "SHOCK": "震荡",
	"SHORT": "短", "SHOT": "射击", "SHOVE": "推斥", "SHRIMP": "虾式", "SIEGE": "攻城", "SIGNAL": "信号",
	"SIGNING": "签约", "SILENT": "静默", "SILK": "蛛丝", "SINEW": "筋腱", "SINK": "吸收", "SIPHON": "虹吸",
	"SKATE": "滑行", "SLAM": "蓄砸", "SLASH": "斩击", "SLEEVE": "套管", "SMASH": "扣杀", "SNAKE": "蛇形",
	"SNAP": "折返", "SNARE": "捕网", "SNIPER": "狙击", "SOCKET": "插口", "SOUL": "英魂", "SPACE": "太空",
	"SPAR": "支杆", "SPARK": "火花", "SPECTRUM": "光谱", "SPEED": "速度", "SPIKE": "尖刺", "SPIKEBALL": "刺球",
	"SPIN": "旋转", "SPINE": "脊柱", "SPIRE": "尖塔", "SPLASH": "溅射", "SPOOL": "线轴", "SPOTTERS": "观测队",
	"SPRAY": "喷射", "SPRAYER": "喷射器", "SPRING": "弹簧", "SPRINGBOARD": "跳板", "SPRINKLER": "喷洒器", "SQUAD": "小队",
	"STABILIZED": "稳定", "STACK": "堆栈", "STAGE": "舞台", "STAKE": "桩", "STANDARD": "标准", "STARBURST": "星爆",
	"STARTER": "初始", "STATIC": "固定", "STEEL": "钢", "STILETTO": "短刺", "STINGER": "刺蜂", "STOP": "止动",
	"STORM": "风暴", "STRAIGHT": "直线", "STRAND": "束", "STRIDER": "疾行者", "STRING": "连锁", "STRIP": "轨条",
	"STRUT": "撑杆", "SUICIDE": "自爆", "SUSTAIN": "续航", "SWAP": "替换", "SWARM": "蜂群", "SWEEP": "扫射",
	"SWING": "摆击", "SWIVEL": "旋轴", "SYNTAX": "句法", "TACTICAL": "战术", "TAIL": "尾", "TAKEOVER": "接管",
	"TALON": "爪枪", "TANK": "坦克", "TANKER": "油罐", "TAX": "税务", "TEAR": "撕裂", "TELESCOPIC": "伸缩",
	"TEMPO": "节奏", "TENDER": "补给", "TENDON": "腱梁", "TENSION": "张力", "TENTACLE": "触手", "TERMINAL": "末端",
	"TETHER": "牵索", "THERMAL": "热力", "THIGH": "大腿", "THREAT": "威胁", "THROW": "投掷", "THRUST": "突刺",
	"THRUSTER": "推进器", "TILE": "地块", "TIMBER": "木质", "TITAN": "泰坦", "TO": "转", "TOP": "顶",
	"TOPOLOGY": "拓扑", "TORSION": "扭转", "TORSO": "躯干", "TOWER": "塔", "TRACKING": "追踪", "TRAINING": "训练",
	"TRAP": "陷阱", "TRAVERSE": "横移", "TRIAD": "三联", "TRIAGE": "急救", "TRIGGER": "触发", "TRIPLE": "三肢",
	"TURBINE": "涡轮", "TURRET": "炮塔", "TWIN": "双子", "TWO": "双段", "UMBRA": "影伞", "UP": "上行",
	"VANGUARD": "前卫", "VANTA": "暗网", "VARIANCE": "变化", "VAULT": "金库", "VECTOR": "矢量", "VEIL": "帷幕",
	"VEIN": "脉络", "VENT": "排热", "VERTEBRA": "椎骨", "VIOLENT": "暴烈", "VISE": "虎钳", "WAKE": "尾迹",
	"WAKIZASHI": "胁差", "WALL": "墙", "WARD": "防火墙", "WARRANT": "凭证", "WAY": "单向", "WEB": "蛛丝",
	"WELL": "井", "WHIP": "鞭", "WHITEOUT": "白盲", "WINDUP": "蓄力", "WING": "翼", "WOOD": "木质",
	"WOUNDED": "伤者", "WRAP": "缠带", "WRIST": "腕", "YELLOW": "黄焰", "YOKE": "轭",
}


static func zh_name_for(part_name: String) -> String:
	var cleaned := part_name.strip_edges()
	if cleaned == "":
		return ""
	if EXACT_NAMES.has(cleaned):
		return String(EXACT_NAMES[cleaned])
	var slash_index := cleaned.find(" / ")
	if slash_index > 0:
		var prefix := cleaned.substr(0, slash_index).strip_edges()
		if _has_cjk(prefix):
			return prefix
	if _has_cjk(cleaned) and cleaned.find("/") < 0:
		return cleaned
	return _tokenized_name(cleaned)


static func _tokenized_name(part_name: String) -> String:
	var normalized := part_name.to_upper()
	for pair in [["：", " : "], [":", " : "], ["-", " "], ["/", " "], ["_", " "], [".", " "], ["+", " "]]:
		normalized = normalized.replace(String(pair[0]), String(pair[1]))
	var pieces: Array = []
	for token in normalized.split(" ", false):
		var cleaned_token := _clean_token(String(token))
		if cleaned_token == "":
			continue
		if cleaned_token == ":":
			pieces.append("：")
		else:
			pieces.append(String(TOKEN_NAMES.get(cleaned_token, cleaned_token)))
	var joined := "".join(pieces)
	for pair in [
		["肌肉", ""],
		["动作驱动器", "动作驱动"],
		["盾盾", "盾"],
		["枪枪", "枪"],
		["炮炮", "炮"],
		["躯干躯干", "躯干"],
		["核心核心", "核心"],
		["结界结界", "结界"],
		["源代码源代码", "源代码"],
		["来复枪来复枪", "来复枪"],
	]:
		if String(pair[0]) == "肌肉" and not joined.ends_with("肌肉"):
			continue
		if String(pair[0]) == "肌肉":
			joined = joined.substr(0, joined.length() - 2)
		else:
			joined = joined.replace(String(pair[0]), String(pair[1]))
	return joined


static func _clean_token(token: String) -> String:
	var result := ""
	for i in range(token.length()):
		var code := token.unicode_at(i)
		var is_digit := code >= 48 and code <= 57
		var is_upper := code >= 65 and code <= 90
		var ch := token.substr(i, 1)
		if is_digit or is_upper or ch == ":":
			result += ch
	return result


static func _has_cjk(value: String) -> bool:
	for i in range(value.length()):
		var code := value.unicode_at(i)
		if code >= 0x2e80:
			return true
	return false
