extends Node
## Peglord rule tables (autoload "D"). Every balance number lives here, ported 1:1 from the web version.

const LEVEL_COST := 99
const LEVEL_CAP := 60
const SOFT_CAP_1 := 25
const SOFT_CAP_2 := 40
const STAGE_HEAL := 0.30
const MAX_JOKERS := 5
const BASE_BALLS := 3
const REVEAL_HOLD := 3.0
const ANIM_STEP := 0.68

static func payout(stage: int) -> int:
	return 3 + int((stage - 1) / 3)

const PHYS := {
	"W": 480.0, "H": 640.0, "dt": 1.0 / 240.0, "gravity": 900.0, "ballR": 7.0, "launchSpeed": 560.0, "speedCap": 820.0,
	"pegBounce": 0.6, "wallBounce": 0.72, "ceilBounce": 0.5, "bumperBounce": 1.05, "bumperKick": 140.0,
	"nudge": 18.0, "aimClamp": 0.3, "stallSpeed": 28.0, "stallTime": 0.5, "maxBallLife": 22.0,
	"pegR": 8.0, "launcherX": 240.0, "launcherY": 34.0,
	"rows": 10, "cols": 9, "dx": 51.0, "dy": 43.0, "jitterX": 5.0, "jitterY": 4.0, "top": 118.0,
	"pocketTop": 596.0, "pocketCount": 6, "keep": 0.58, "keepPerExtra": 0.01, "keepMax": 0.82,
	"bombRadius": 72.0, "bombSquadRadius": 96.0, "boltRange": 150.0, "roverAmp": 38.0, "portalCooldown": 0.5,
}

const PEGS := {
	"brass": {"name": "Brass", "pts": 1, "shape": "circle", "color": "#c9a24a", "rule": "Scores 1 once; vanishes when the ball lands."},
	"gold": {"name": "Gold", "pts": 3, "shape": "diamond", "color": "#ffd23f", "rule": "Scores 3 once; vanishes when the ball lands."},
	"crate": {"name": "Crate", "pts": 1, "shape": "square", "color": "#a0703c", "hits": 3, "rule": "1 per hit. Breaks in 3 hits into loot: bomb, free ball, potion, whetstone or coins."},
	"bomb": {"name": "Bomb", "pts": 2, "shape": "bomb", "color": "#e0503c", "rule": "Explodes in a 72 px radius, hits neighbours, chains, kicks the ball."},
	"bumper": {"name": "Bumper", "pts": 2, "shape": "ring", "color": "#4fc3f7", "rule": "Hard kick. Re-arms every ball."},
	"glass": {"name": "Glass", "pts": 2, "shape": "hex", "color": "#bfe8ff", "rule": "Shatters on first touch."},
	"heart": {"name": "Heart", "pts": 1, "shape": "heart", "color": "#ff6b8a", "rule": "Heals the weakest hero 3; vanishes when the ball lands."},
	"star": {"name": "Star", "pts": 2, "shape": "star", "color": "#fff176", "rule": "Adds 3 to the combo counter."},
	"bolt": {"name": "Bolt", "pts": 1, "shape": "bolt", "color": "#b388ff", "rule": "Arcs to the 3 nearest unlit pegs within 150 px."},
	"portal": {"name": "Portal", "pts": 2, "shape": "donut", "color": "#7c4dff", "rule": "2 on first use. Teleports the ball to its twin. Re-arms."},
	"rover": {"name": "Rover", "pts": 2, "shape": "pill", "color": "#4db6ac", "rule": "Slides 38 px each side. Re-arms."},
	"chest": {"name": "Chest", "pts": 2, "shape": "chest", "color": "#d4a017", "hits": 2, "rule": "2 per hit. Breaks in 2 hits and drops a gear piece."},
}
const REARM := {"bumper": true, "portal": true, "rover": true}
const BASE_PEG_MIX := {"gold": 4, "crate": 3, "bomb": 2, "bumper": 2, "glass": 2, "heart": 1}
const RANDOM_SPECIALS := ["glass", "star", "bolt", "rover", "heart", "gold"]
const RANDOM_SPECIAL_COUNT := 2
const CRATE_LOOT := ["bomb", "ball", "potion", "whetstone", "coins"]

const POCKETS := {
	"jackpot": {"name": "Jackpot", "kind": "perk", "text": "+(6 + 2 × stage) XP"},
	"double": {"name": "Double", "kind": "perk", "text": "Adds this ball's XP a second time"},
	"freeball": {"name": "Free Ball", "kind": "perk", "text": "+1 ball"},
	"patch": {"name": "Patch Up", "kind": "perk", "text": "Heals the weakest hero 5"},
	"guard": {"name": "Guard", "kind": "perk", "text": "Foes deal 3 less per hit this round"},
	"treasure": {"name": "Treasure", "kind": "perk", "text": "Drops one gear piece"},
	"rally": {"name": "Rally", "kind": "perk", "text": "+2 damage on every hero hit this round"},
	"hotball": {"name": "Hot Ball", "kind": "perk", "text": "The next ball starts at combo 8 (×2)"},
	"taxman": {"name": "Taxman", "kind": "bad", "text": "Lose 6 XP (never below 0)"},
	"leaky": {"name": "Leaky", "kind": "bad", "text": "Lose half of this ball's XP"},
	"curse": {"name": "Curse", "kind": "bad", "text": "Foes get +3 attack this round"},
	"rust": {"name": "Rust", "kind": "bad", "text": "Heroes deal 1 less damage per hit this round"},
	"plague": {"name": "Plague", "kind": "bad", "text": "Every hero loses 2 HP (never kills)"},
	"jam": {"name": "Jam", "kind": "bad", "text": "Lose 1 ball"},
}
const POCKET_SPLIT := [{"upTo": 3, "perks": 4}, {"upTo": 99, "perks": 3}]

const ATTRS := ["vig", "str", "dex", "int", "fai", "arc"]
const ATTR_NAMES := {"vig": "Vigor", "str": "Strength", "dex": "Dexterity", "int": "Intelligence", "fai": "Faith", "arc": "Arcane"}
const ATTR_HELP := {
	"vig": "Max HP = 10 + 2.5 × Vigor. +1 Defense and Resist per 6.",
	"str": "Scales heavy weapons. Meets heavy armour requirements.",
	"dex": "Scales light weapons. +1% crit per point.",
	"int": "Scales magic weapons. Meets robe and tome requirements.",
	"fai": "Scales holy weapons. Mend heals 6 + 1.5 × Faith. Powers Blessing.",
	"arc": "+0.5% crit and +1% gear drop chance per point.",
}

const GRADES := {"S": 1.40, "A": 1.00, "B": 0.75, "C": 0.50, "D": 0.30, "E": 0.15}
const REQ_PENALTY := 0.40
const UPGRADE_STEP := 0.08
const FAVOURED_AFFINITY := 0.10
const CRIT_BASE := 3
const CRIT_CAP := 75

const HEROES := {
	"knight": {
		"name": "Knight", "title": "Bulwark", "color": "#8fb3d9",
		"attrs": {"vig": 12, "str": 12, "dex": 8, "int": 4, "fai": 6, "arc": 4},
		"favoured": ["sword", "axe", "hammer", "shield"], "start": ["sword", "shield"],
		"passive": "Iron Hide: +1 Defense per 4 Vigor. Guarding draws foe attacks.",
		"skill": {"name": "Cleave", "text": "0.7 × AR to every foe", "cd": 2},
		"perks": {8: "Riposte: while Guarding, counters each attacker for 0.5 × AR",
			16: "Cleave cooldown is one turn shorter",
			24: "Bastion: +3 Defense, draws attacks even when not Guarding",
			36: "Last Stand: once per stage, survives a lethal hit at 1 HP"},
	},
	"mage": {
		"name": "Hex Mage", "title": "Glass cannon", "color": "#c39bff",
		"attrs": {"vig": 7, "str": 4, "dex": 8, "int": 14, "fai": 6, "arc": 7},
		"favoured": ["staff", "wand", "tome", "orb"], "start": ["staff"],
		"passive": "Spell Surge: all magic attack rating × 1.15.",
		"skill": {"name": "Firebolt", "text": "2.2 × AR magic to one foe", "cd": 2},
		"perks": {8: "Chain Lightning: Attack also arcs for 40% to a second foe",
			16: "Firebolt crits burn the foe: 3 a turn for 3 turns",
			24: "Overcast: once per stage, Firebolt ignores its cooldown",
			36: "Meteor: Firebolt also hits every other foe for 50%"},
	},
	"priest": {
		"name": "Pint Priest", "title": "Support", "color": "#ffcc80",
		"attrs": {"vig": 9, "str": 7, "dex": 6, "int": 5, "fai": 13, "arc": 6},
		"favoured": ["mace", "flail", "symbol", "seal"], "start": ["mace"],
		"passive": "Blessing: while alive, every ally attack deals +1 per 5 Faith.",
		"skill": {"name": "Mend", "text": "Heals the weakest ally 6 + 1.5 × Faith", "cd": 2},
		"perks": {8: "Cleansing Mend: Mend removes burns and hexes",
			16: "Smite Mark: Attack marks a foe to take +20% damage this round",
			24: "Blessed Shield: overhealing becomes a shield",
			36: "Resurrect: once per stage, revive a fallen ally at 40% HP"},
	},
	"rogue": {
		"name": "Rogue", "title": "Cutpurse", "color": "#9ccc65", "unlock": true,
		"attrs": {"vig": 9, "str": 6, "dex": 14, "int": 5, "fai": 4, "arc": 8},
		"favoured": ["dagger", "flail"], "start": ["dagger"],
		"passive": "Pickpocket: +10% crit chance.",
		"skill": {"name": "Twin Stab", "text": "Two hits of 1.1 × AR on one foe", "cd": 2},
		"perks": {8: "Bleed: crits deal 3 a turn for 3 turns", 16: "Twin Stab cooldown one turn shorter",
			24: "Shadowstep: Guard also dodges the first hit", 36: "Assassin: hits on foes under 30% HP deal double"},
	},
	"ranger": {
		"name": "Ranger", "title": "Marksman", "color": "#4dd0e1", "unlock": true,
		"attrs": {"vig": 10, "str": 7, "dex": 12, "int": 5, "fai": 4, "arc": 8},
		"favoured": ["bow", "dagger"], "start": ["bow"],
		"passive": "Keen Eye: ignores 2 foe armor.",
		"skill": {"name": "Volley", "text": "0.6 × AR to every foe", "cd": 2},
		"perks": {8: "Pinning Shot: Attack lowers the foe attack by 1 this round", 16: "Volley cooldown one turn shorter",
			24: "Hunter: +25% damage to the foe with most HP", 36: "Rain of Arrows: Volley hits twice"},
	},
}
const DEFAULT_PARTY := ["knight", "mage", "priest"]
const PERK_LEVELS := [8, 16, 24, 36]

## Attribute the Auto button buys next for a hero.
static func auto_attr(h: Dictionary) -> String:
	var lv: int = h.level + 1
	match h.cls:
		"knight": return "vig" if h.bought.vig <= h.bought.str else "str"
		"mage": return "vig" if lv % 4 == 0 else "int"
		"priest": return "vig" if lv % 3 == 0 else "fai"
		"rogue": return "vig" if lv % 4 == 0 else "dex"
		"ranger": return "vig" if lv % 3 == 0 else "dex"
	return "vig"

const ENEMIES := {
	"brute": {"name": "Brute", "hp": 14, "atk": 4, "armor": 0, "moves": ["smash"]},
	"sneak": {"name": "Sneak", "hp": 10, "atk": 5, "armor": 0, "moves": ["backstab"]},
	"bomber": {"name": "Bomber", "hp": 12, "atk": 5, "armor": 0, "moves": ["blast"]},
	"shaman": {"name": "Shaman", "hp": 11, "atk": 3, "armor": 0, "moves": ["mend", "hex"]},
	"bulwark": {"name": "Bulwark", "hp": 18, "atk": 3, "armor": 2, "moves": ["shove"]},
	"leech": {"name": "Leech", "hp": 12, "atk": 4, "armor": 0, "moves": ["drain"]},
	"drunk": {"name": "Drunkard", "hp": 16, "atk": 6, "armor": 0, "moves": ["flail"]},
	"hound": {"name": "Debt Hound", "hp": 9, "atk": 4, "armor": 0, "moves": ["pounce"]},
}
const MOVES := {
	"smash": {"name": "Smash", "mult": 1.0, "target": "one", "text": "Full attack on one hero"},
	"backstab": {"name": "Backstab", "mult": 0.9, "target": "lowest", "text": "0.9 × attack on the lowest-HP hero, ignores taunt"},
	"blast": {"name": "Blast", "mult": 0.5, "target": "all", "text": "0.5 × attack on every hero"},
	"mend": {"name": "Mend", "mult": 1.5, "target": "ally", "text": "Heals the weakest foe 1.5 × attack + 3"},
	"hex": {"name": "Hex", "mult": 0.7, "target": "one", "magic": true, "hex": true, "text": "0.7 × attack magic and a hex (2 a turn for 2 turns)"},
	"shove": {"name": "Shove", "mult": 0.9, "target": "one", "text": "0.9 × attack on one hero"},
	"drain": {"name": "Drain", "mult": 0.8, "target": "one", "drain": true, "text": "0.8 × attack, heals itself that much"},
	"flail": {"name": "Wild Swing", "mult": 1.3, "target": "one", "miss": 0.3, "text": "1.3 × attack, 30% chance to miss"},
	"pounce": {"name": "Pounce", "mult": 0.6, "target": "one", "hits": 2, "text": "Two hits of 0.6 × attack"},
	"eviction": {"name": "Eviction", "mult": 1.7, "target": "one", "text": "1.7 × attack on one hero"},
	"renthike": {"name": "Rent Hike", "mult": 0.5, "target": "all", "rentHike": true, "text": "+2 attack forever, 0.5 × attack on every hero"},
	"latefees": {"name": "Late Fees", "mult": 0.7, "target": "all", "magic": true, "text": "0.7 × attack magic on every hero"},
	"foreclose": {"name": "Foreclosure", "mult": 1.1, "target": "all", "text": "1.1 × attack on every hero"},
}
const ENEMY_HP_SCALE := 0.6
const ENEMY_ATK_SCALE := 0.6
const RENT_HIKE_PER_ROUND := 1
const CURSE_ATK := 3
const GLASS_CANNON_FOE := 1.25
const GUARD_POCKET := 3

const STAGES := [
	{"name": "The Cellar", "themes": [["brute", "sneak", "bulwark"], ["brute", "hound", "sneak"], ["bulwark", "drunk", "brute"]]},
	{"name": "Back Alley", "themes": [["brute", "sneak", "bulwark"], ["hound", "sneak", "drunk"], ["bulwark", "hound", "brute"]]},
	{"name": "Market Row", "themes": [["brute", "sneak", "bomber", "shaman", "bulwark"], ["leech", "drunk", "sneak"], ["bomber", "hound", "brute"]]},
	{"name": "Dockside", "themes": [["brute", "sneak", "bomber", "shaman", "bulwark"], ["drunk", "bomber", "leech"], ["hound", "shaman", "bulwark"]]},
	{"name": "Rooftops", "themes": [["brute", "sneak", "bomber", "shaman", "bulwark"], ["sneak", "hound", "bomber"], ["leech", "shaman", "drunk"]]},
	{"name": "Tax Office", "themes": [["brute", "sneak", "bomber", "shaman", "bulwark"], ["bulwark", "shaman", "leech"], ["drunk", "hound", "bomber"]]},
	{"name": "Counting House", "themes": [["brute", "sneak", "bomber", "shaman", "bulwark"], ["leech", "sneak", "bulwark"], ["bomber", "drunk", "shaman"]]},
	{"name": "Debtors' Court", "themes": [["brute", "sneak", "bomber", "shaman", "bulwark", "leech", "drunk", "hound"], ["hound", "hound", "shaman"], ["bulwark", "bomber", "leech"]]},
	{"name": "The Vault", "themes": [["brute", "sneak", "bomber", "shaman", "bulwark", "leech", "drunk", "hound"], ["bulwark", "bulwark", "shaman"], ["drunk", "sneak", "bomber"]]},
	{"name": "Penthouse Stairs", "themes": [["brute", "sneak", "bomber", "shaman", "bulwark", "leech", "drunk", "hound"], ["leech", "bomber", "hound"], ["sneak", "drunk", "shaman"]]},
	{"name": "The Landlord", "boss": true},
]
const BOSS := {"name": "The Landlord", "hp": 750, "atk": 22, "armor": 1, "moves": ["eviction", "renthike", "latefees"],
	"phase2Moves": ["eviction", "foreclose", "latefees"], "phase2Armor": 2, "phase2Atk": 3,
	"minions": [{"type": "sneak", "name": "Bailiff", "stage": 9}, {"type": "bulwark", "name": "Heavy", "stage": 9}]}

const SLOTS := ["weapon", "offhand", "helm", "chest", "gloves", "legs", "boots", "amulet", "ring"]
const SLOT_NAMES := {"weapon": "Weapon", "offhand": "Off-hand", "helm": "Helm", "chest": "Chest", "gloves": "Gloves", "legs": "Legs", "boots": "Boots", "amulet": "Amulet", "ring": "Ring"}
const ARMOR_WEIGHT := {"helm": 2, "chest": 3, "gloves": 1, "legs": 2, "boots": 1, "shield": 3}
const ARMOR_CLASS := {
	"heavy": {"name": "Heavy", "def": 1.0, "res": 0.5, "req": "str", "words": {"helm": "Greathelm", "chest": "Plate", "gloves": "Gauntlets", "legs": "Greaves", "boots": "Sabatons"}},
	"medium": {"name": "Medium", "def": 0.75, "res": 0.75, "req": "", "words": {"helm": "Hood", "chest": "Jerkin", "gloves": "Gloves", "legs": "Breeches", "boots": "Boots"}},
	"light": {"name": "Light", "def": 0.5, "res": 1.0, "req": "intfai", "words": {"helm": "Hat", "chest": "Robe", "gloves": "Wraps", "legs": "Trousers", "boots": "Slippers"}},
}
const RARITIES := [
	{"id": "common", "name": "Common", "color": "#a8a8a8", "prefix": "Worn", "mult": 1.00, "lines": 0, "salvage": 20},
	{"id": "fine", "name": "Fine", "color": "#6fdc7c", "prefix": "Sturdy", "mult": 1.15, "lines": 1, "salvage": 40},
	{"id": "rare", "name": "Rare", "color": "#6cb4ff", "prefix": "Gilded", "mult": 1.30, "lines": 2, "salvage": 80},
	{"id": "epic", "name": "Epic", "color": "#c98bff", "prefix": "Landlord's", "mult": 1.50, "lines": 3, "salvage": 160},
	{"id": "legendary", "name": "Legendary", "color": "#ffa04a", "prefix": "", "mult": 1.75, "lines": 3, "salvage": 300},
]
const RARITY_WEIGHTS := [
	{"upTo": 3, "w": [60, 35, 5, 0, 0]},
	{"upTo": 7, "w": [20, 45, 30, 5, 0]},
	{"upTo": 11, "w": [0, 25, 45, 25, 5]},
]
const WEAPONS := {
	"sword": {"name": "Sword", "type": "phys", "grades": {"str": "B", "dex": "C"}, "req": {"str": 10}},
	"axe": {"name": "Axe", "type": "phys", "grades": {"str": "A"}, "req": {"str": 12}},
	"hammer": {"name": "Hammer", "type": "phys", "grades": {"str": "A", "vig": "E"}, "req": {"str": 14}},
	"mace": {"name": "Mace", "type": "holy", "grades": {"fai": "B", "str": "D"}, "req": {"fai": 9}},
	"flail": {"name": "Flail", "type": "phys", "grades": {"dex": "B", "fai": "C"}, "req": {"dex": 8}},
	"dagger": {"name": "Dagger", "type": "phys", "grades": {"dex": "A", "arc": "D"}, "req": {"dex": 9}},
	"staff": {"name": "Staff", "type": "magic", "grades": {"int": "A"}, "req": {"int": 10}},
	"wand": {"name": "Wand", "type": "magic", "grades": {"int": "B", "dex": "C"}, "req": {"int": 8}},
	"tome": {"name": "Tome", "type": "magic", "grades": {"int": "B", "arc": "C"}, "req": {"int": 9}},
	"symbol": {"name": "Holy Symbol", "type": "holy", "grades": {"fai": "A"}, "req": {"fai": 10}},
	"bow": {"name": "Bow", "type": "phys", "grades": {"dex": "A", "str": "E"}, "req": {"dex": 10}},
	"sickle": {"name": "Moon Sickle", "type": "magic", "grades": {"arc": "B", "dex": "C"}, "req": {"arc": 8}},
}
const WEAPON_WORDS := ["Pint", "Tankard", "Barrel", "Cask", "Brewer", "Taproom", "Alehouse", "Cellar", "Rent", "Ledger", "Hearth", "Cobble"]
const OFFHANDS := {
	"shield": {"name": "Shield", "text": "Defense; Guarding blocks an extra 25%"},
	"orb": {"name": "Orb", "text": "+12% magic AR"},
	"seal": {"name": "Seal", "text": "+15% healing"},
}
const ORB_BONUS := 0.12
const SEAL_BONUS := 0.15
const SHIELD_BLOCK := 0.25
const AFFIXES := {
	"attr": {"name": "Attribute", "size": [1, 2, 4], "slots": "any"},
	"hp": {"name": "Max HP", "size": [4, 9, 14], "slots": ["helm", "chest", "gloves", "legs", "boots", "amulet", "ring"]},
	"atk": {"name": "Attack", "size": [4, 8, 12], "slots": ["weapon", "gloves", "ring"]},
	"crit": {"name": "Crit chance", "size": [3, 6, 9], "slots": ["weapon", "gloves", "amulet", "ring"]},
	"def": {"name": "Defense", "size": [2, 5, 8], "slots": ["helm", "chest", "gloves", "legs", "boots", "offhand"]},
	"res": {"name": "Resist", "size": [2, 5, 8], "slots": ["helm", "chest", "gloves", "legs", "boots", "offhand"]},
	"heal": {"name": "Heal power", "size": [8, 16, 24], "slots": ["helm", "offhand", "amulet"]},
	"leech": {"name": "Life on hit", "size": [1, 2, 3], "slots": ["weapon", "gloves", "ring"]},
	"thorns": {"name": "Thorns", "size": [2, 4, 6], "slots": ["chest", "legs", "offhand"]},
	"xp": {"name": "XP gain", "size": [3, 6, 9], "slots": ["amulet", "ring", "boots"]},
	"luck": {"name": "Loot luck", "size": [4, 8, 12], "slots": ["amulet", "ring", "boots"]},
	"bounty": {"name": "Bounty hunter", "size": [10, 17, 25], "slots": ["weapon", "gloves"]},
	"quick": {"name": "Quick skill", "size": [0, 0, 1], "slots": ["gloves", "amulet"], "epicOnly": true},
}

static func affix_text(x: Dictionary) -> String:
	var v = x.value
	match x.type:
		"attr": return "+%d %s" % [v, ATTR_NAMES[x.attr]]
		"hp": return "+%d max HP" % v
		"atk": return "+%d%% AR" % v
		"crit": return "+%d%% crit" % v
		"def": return "+%d Defense" % v
		"res": return "+%d Resist" % v
		"heal": return "+%d%% healing" % v
		"leech": return "Heal %d per hit landed" % v
		"thorns": return "Reflect %d when hit" % v
		"xp": return "+%d%% XP (party)" % v
		"luck": return "+%d%% gear drops" % v
		"bounty": return "+%d%% vs foe with most HP" % v
		"quick": return "Skill cooldown −1"
	return str(x)

const XP_GAIN_CAP := 50
const SETS := {
	"bouncer": {"name": "Bouncer's Garb", "cls": "heavy", "two": "+6 Defense", "four": "Guarding heals 4 HP and counters like Riposte"},
	"spiller": {"name": "Spiller's Robes", "cls": "light", "two": "+10% magic AR", "four": "Skill cooldown −1"},
	"choir": {"name": "Choirboy's Vestments", "cls": "light", "two": "+20% heal power", "four": "Mend also gives its target +3 Defense this round"},
}
const SET_SLOTS := ["helm", "chest", "gloves", "legs", "boots"]
const SET_CHANCE := 0.25
const SET_FROM_STAGE := 4
const LEGENDARIES := [
	{"id": "gavel", "name": "The Landlord's Gavel", "slot": "weapon", "family": "hammer", "grades": {"str": "S"}, "text": "Every hit also deals 3 to every other foe"},
	{"id": "lastcall", "name": "Last Call", "slot": "weapon", "family": "staff", "grades": {"int": "S"}, "text": "A Firebolt that kills ignores its cooldown"},
	{"id": "tapmaster", "name": "Tapmaster's Mace", "slot": "weapon", "family": "mace", "grades": {"fai": "A", "str": "D"}, "text": "Each hit heals the weakest ally 10% of the damage"},
	{"id": "bastion", "name": "Bouncer's Bastion", "slot": "offhand", "family": "shield", "text": "Damage blocked while Guarding is dealt back"},
	{"id": "horseshoe", "name": "Lucky Horseshoe", "slot": "ring", "text": "The first ball of each round scores ×2"},
	{"id": "pinthelm", "name": "Cracked Pint Helm", "slot": "helm", "cls": "medium", "text": "Gold pegs pay +1 and +5 max HP"},
	{"id": "rentboots", "name": "Rent Collector's Boots", "slot": "boots", "cls": "medium", "text": "Every level bought heals this hero 5"},
	{"id": "pawnshark", "name": "Pawn Shark Amulet", "slot": "amulet", "text": "Salvaging items returns double XP"},
	{"id": "lastorder", "name": "Last Orders Bell", "slot": "amulet", "text": "The last ball of each round starts at combo 8"},
	{"id": "nightcap", "name": "Nightcap Dagger", "slot": "weapon", "family": "dagger", "grades": {"dex": "S", "arc": "C"}, "text": "Crits deal ×2.5 instead of ×2"},
]
const DROP_CHANCE := 0.12
const MINION_DROP := 0.25

static func legendary(id: String) -> Dictionary:
	for l in LEGENDARIES:
		if l.id == id:
			return l
	return {}

const JOKERS := {
	"goldtooth": {"name": "Gold Tooth", "rarity": "common", "text": "Gold pegs pay +2"},
	"pintglass": {"name": "Pint Glass", "rarity": "common", "text": "Brass pegs pay +1"},
	"penny": {"name": "Lucky Penny", "rarity": "common", "text": "First scoring hit of each ball pays ×3"},
	"bombsquad": {"name": "Bomb Squad", "rarity": "common", "text": "Bombs pay +4 and blast wider"},
	"horseshoe": {"name": "Horseshoe", "rarity": "common", "text": "The ball is pulled toward gold pegs"},
	"secondwind": {"name": "Second Wind", "rarity": "common", "text": "Heal everyone 3 at the start of each round"},
	"crowbar": {"name": "Crowbar", "rarity": "common", "text": "Crates break in 2 hits"},
	"tipjar": {"name": "Tip Jar", "rarity": "common", "text": "A ball landing in a perk pocket pays +3"},
	"bartab": {"name": "Bar Tab", "rarity": "common", "text": "+10 XP at the start of each round"},
	"lastorders": {"name": "Last Orders", "rarity": "common", "text": "The last ball of each round scores ×2"},
	"comboking": {"name": "Combo King", "rarity": "rare", "text": "Multiplier rises every 6 hits"},
	"debt": {"name": "Debt Collector", "rarity": "rare", "text": "Bad pockets pay 6 XP"},
	"sparekey": {"name": "Spare Key", "rarity": "rare", "text": "One extra ball every round"},
	"glasscannon": {"name": "Glass Cannon", "rarity": "rare", "text": "+1 to each hero's main damage stat, foes hit 25% harder"},
	"fever": {"name": "Jackpot Fever", "rarity": "rare", "text": "Jackpot pays double"},
	"chalk": {"name": "Chalk Dust", "rarity": "rare", "text": "The first bad pocket each round does nothing"},
	"peephole": {"name": "Peephole", "rarity": "rare", "text": "At each launch, one perk pocket glints"},
	"luckyseven": {"name": "Lucky Seven", "rarity": "rare", "text": "Every 7th scoring hit pays +7"},
	"overclock": {"name": "Overclock", "rarity": "epic", "text": "Each hero's highest stat gets +2"},
	"echo": {"name": "Echo Chamber", "rarity": "epic", "text": "Every 4th scoring hit pays double"},
	"happyhour": {"name": "Happy Hour", "rarity": "epic", "text": "First round of each stage: +2 balls"},
}
const JOKER_RARITY_WEIGHT := {"common": 6, "rare": 3, "epic": 1}
const JOKER_RARITY_COLOR := {"common": "#b9a27a", "rare": "#6cb4ff", "epic": "#c98bff"}

const PEG_PACKS := {
	"gilded": {"name": "Gilded Row", "add": {"gold": 4}, "text": "+4 gold pegs"},
	"keg": {"name": "Powder Keg", "add": {"bomb": 3}, "text": "+3 bombs"},
	"crates": {"name": "Crate Stack", "add": {"crate": 3}, "text": "+3 crates"},
	"bumpers": {"name": "Bumper Bank", "add": {"bumper": 3}, "text": "+3 bumpers"},
	"glass": {"name": "Glass Case", "add": {"glass": 4}, "text": "+4 glass"},
	"hearts": {"name": "Pub Hearts", "add": {"heart": 2}, "text": "+2 hearts"},
	"stars": {"name": "Star Pegs", "add": {"star": 2}, "text": "+2 stars"},
	"storm": {"name": "Storm Pegs", "add": {"bolt": 2}, "text": "+2 bolts"},
	"portal": {"name": "Portal Pair", "add": {"portal": 2}, "text": "+1 portal pair"},
	"rovers": {"name": "Rovers", "add": {"rover": 2}, "text": "+2 rovers"},
	"chest": {"name": "Treasure Chest", "add": {"chest": 1}, "text": "+1 chest"},
}
const TANKARD_CHANCE := 0.15
const WARM_BED_HEAL := 0.40
