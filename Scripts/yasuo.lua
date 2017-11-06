--[[

Reference link https://github.com/Cloudhax23/GoS/blob/master/Common/Yasuo.lua

Thanks Celtech team

]]

IncludeFile("Lib\\Callbacks.lua")

function UpdateHeroInfo()
    return GetMyChamp()
end

if GetChampName(UpdateHeroInfo()) ~= "Yasuo" then return end

__PrintTextGame("Yasuo v1.0 loaded")

local Q = 0
local W = 1
local E = 2
local R = 3

local _Q = 0
local _W = 1
local _E = 2
local _R = 3

local SpaceKeyCode = 32
local CKeyCode = 67
local VKeyCode = 86

local config_AutoUlt = true
local config_AutoW = true

config_AutoUlt  = AddMenuCustom(1, config_AutoUlt, "Auto Ultil")

local SpellQW = {Range = 425, Speed = 1500, Delay = 0.25, Width = 90}
local SpellQ3 = {Range = 1000, Speed = 1500, Delay = 0.25, Width = 90}

WALL_SPELLS = { -- Yea boiz and grillz its all right here.......
    ["FizzMarinerDoom"]                      = {Spellname ="FizzMarinerDoom",Name = "Fizz", Spellslot =_R},
    ["AatroxE"]                      = {Spellname ="AatroxE",Name= "Aatrox", Spellslot =_E},
    ["AhriOrbofDeception"]                      = {Spellname ="AhriOrbofDeception",Name = "Ahri", Spellslot =_Q},
    ["AhriFoxFire"]                      = {Spellname ="AhriFoxFire",Name = "Ahri", Spellslot =_W},
    ["AhriSeduce"]                      = {Spellname ="AhriSeduce",Name = "Ahri", Spellslot =_E},
    ["AhriTumble"]                      = {Spellname ="AhriTumble",Name = "Ahri", Spellslot =_R},
    ["FlashFrost"]                      = {Spellname ="FlashFrost",Name = "Anivia", Spellslot =_Q},
    ["Anivia2"]                      = {Spellname ="Frostbite",Name = "Anivia", Spellslot =_E},
    ["Disintegrate"]                      = {Spellname ="Disintegrate",Name = "Annie", Spellslot =_Q},
    ["Volley"]                      = {Spellname ="Volley",Name ="Ashe", Spellslot =_W},
    ["EnchantedCrystalArrow"]                      = {Spellname ="EnchantedCrystalArrow",Name ="Ashe", Spellslot =_R},
    ["BandageToss"]                      = {Spellname ="BandageToss",Name ="Amumu",Spellslot =_Q},
    ["RocketGrabMissile"]                      = {Spellname ="RocketGrabMissile",Name ="Blitzcrank",Spellslot =_Q},
    ["BrandBlaze"]                      = {Spellname ="BrandBlaze",Name ="Brand", Spellslot =_Q},
    ["BrandWildfire"]                      = {Spellname ="BrandWildfire",Name ="Brand", Spellslot =_R},
    ["BraumQ"]                      = {Spellname ="BraumQ",Name ="Braum",Spellslot =_Q},
    ["BraumRWapper"]                      = {Spellname ="BraumRWapper",Name ="Braum",Spellslot =_R},
    ["CaitlynPiltoverPeacemaker"]                      = {Spellname ="CaitlynPiltoverPeacemaker",Name ="Caitlyn",Spellslot =_Q},
    ["CaitlynEntrapment"]                      = {Spellname ="CaitlynEntrapment",Name ="Caitlyn",Spellslot =_E},
    ["CaitlynAceintheHole"]                      = {Spellname ="CaitlynAceintheHole",Name ="Caitlyn",Spellslot =_R},
    ["CassiopeiaMiasma"]                      = {Spellname ="CassiopeiaMiasma",Name ="Cassiopiea",Spellslot =_W},
    ["CassiopeiaTwinFang"]                      = {Spellname ="CassiopeiaTwinFang",Name ="Cassiopiea",Spellslot =_E},
    ["PhosphorusBomb"]                      = {Spellname ="PhosphorusBomb",Name ="Corki",Spellslot =_Q},
    ["MissileBarrage"]                      = {Spellname ="MissileBarrage",Name ="Corki",Spellslot =_R},
    ["DianaArc"]                      = {Spellname ="DianaArc",Name ="Diana",Spellslot =_Q},
    ["InfectedCleaverMissileCast"]                      = {Spellname ="InfectedCleaverMissileCast",Name ="DrMundo",Spellslot =_Q},
    ["dravenspinning"]                      = {Spellname ="dravenspinning",Name ="Draven",Spellslot =_Q},
    ["DravenDoubleShot"]                      = {Spellname ="DravenDoubleShot",Name ="Draven",Spellslot =_E},
    ["DravenRCast"]                      = {Spellname ="DravenRCast",Name ="Draven",Spellslot =_R},
    ["EliseHumanQ"]                      = {Spellname ="EliseHumanQ",Name ="Elise",Spellslot =_Q},
    ["EliseHumanE"]                      = {Spellname ="EliseHumanE",Name ="Elise",Spellslot =_E},
    ["EvelynnQ"]                      = {Spellname ="EvelynnQ",Name ="Evelynn",Spellslot =_Q},
    ["EzrealMysticShot"]                      = {Spellname ="EzrealMysticShot",Name ="Ezreal",Spellslot =_Q,},
    ["EzrealEssenceFlux"]                      = {Spellname ="EzrealEssenceFlux",Name ="Ezreal",Spellslot =_W},
    ["EzrealArcaneShift"]                      = {Spellname ="EzrealArcaneShift",Name ="Ezreal",Spellslot =_R},
    ["GalioRighteousGust"]                      = {Spellname ="GalioRighteousGust",Name ="Galio",Spellslot =_E},
    ["GalioResoluteSmite"]                      = {Spellname ="GalioResoluteSmite",Name ="Galio",Spellslot =_Q},
    ["Parley"]                      = {Spellname ="Parley",Name ="Gangplank",Spellslot =_Q},
    ["GnarQ"]                      = {Spellname ="GnarQ",Name ="Gnar",Spellslot =_Q},
    ["GravesClusterShot"]                      = {Spellname ="GravesClusterShot",Name ="Graves",Spellslot =_Q},
    ["GravesChargeShot"]                      = {Spellname ="GravesChargeShot",Name ="Graves",Spellslot =_R},
    ["HeimerdingerW"]                      = {Spellname ="HeimerdingerW",Name ="Heimerdinger",Spellslot =_W},
    ["IreliaTranscendentBlades"]                      = {Spellname ="IreliaTranscendentBlades",Name ="Irelia",Spellslot =_R},
    ["HowlingGale"]                      = {Spellname ="HowlingGale",Name ="Janna",Spellslot =_Q},
    ["JayceToTheSkies"]                      = {Spellname ="JayceToTheSkies" or "jayceshockblast",Name ="Jayce",Spellslot =_Q},
    ["jayceshockblast"]                      = {Spellname ="JayceToTheSkies" or "jayceshockblast",Name ="Jayce",Spellslot =_Q},
    ["JinxW"]                      = {Spellname ="JinxW",Name ="Jinx",Spellslot =_W},
    ["JinxR"]                      = {Spellname ="JinxR",Name ="Jinx",Spellslot =_R},
    ["KalistaMysticShot"]                      = {Spellname ="KalistaMysticShot",Name ="Kalista",Spellslot =_Q},
    ["KarmaQ"]                      = {Spellname ="KarmaQ",Name ="Karma",Spellslot =_Q},
    ["NullLance"]                      = {Spellname ="NullLance",Name ="Kassidan",Spellslot =_Q},
    ["KatarinaR"]                      = {Spellname ="KatarinaR",Name ="Katarina",Spellslot =_R},
    ["LeblancChaosOrb"]                      = {Spellname ="LeblancChaosOrb",Name ="Leblanc",Spellslot =_Q},
    ["LeblancSoulShackle"]                      = {Spellname ="LeblancSoulShackle" or "LeblancSoulShackleM",Name ="Leblanc",Spellslot =_E},
    ["LeblancSoulShackleM"]                      = {Spellname ="LeblancSoulShackle" or "LeblancSoulShackleM",Name ="Leblanc",Spellslot =_E},
    ["BlindMonkQOne"]                      = {Spellname ="BlindMonkQOne",Name ="Leesin",Spellslot =_Q},
    ["LeonaZenithBladeMissle"]                      = {Spellname ="LeonaZenithBladeMissle",Name ="Leona",Spellslot =_E},
    ["LissandraE"]                      = {Spellname ="LissandraE",Name ="Lissandra",Spellslot =_E},
    ["LucianR"]                      = {Spellname ="LucianR",Name ="Lucian",Spellslot =_R},
    ["LuxLightBinding"]                      = {Spellname ="LuxLightBinding",Name ="Lux",Spellslot =_Q},
    ["LuxLightStrikeKugel"]                      = {Spellname ="LuxLightStrikeKugel",Name ="Lux",Spellslot =_E},
    ["MissFortuneBulletTime"]                      = {Spellname ="MissFortuneBulletTime",Name ="Missfortune",Spellslot =_R},
    ["DarkBindingMissile"]                      = {Spellname ="DarkBindingMissile",Name ="Morgana",Spellslot =_Q},
    ["NamiR"]                      = {Spellname ="NamiR",Name ="Nami",Spellslot =_R},
    ["JavelinToss"]                      = {Spellname ="JavelinToss",Name ="Nidalee",Spellslot =_Q},
    ["NocturneDuskbringer"]                      = {Spellname ="NocturneDuskbringer",Name ="Nocturne",Spellslot =_Q},
    ["Pantheon_Throw"]                      = {Spellname ="Pantheon_Throw",Name ="Pantheon",Spellslot =_Q},
    ["QuinnQ"]                      = {Spellname ="QuinnQ",Name ="Quinn",Spellslot =_Q},
    ["RengarE"]                      = {Spellname ="RengarE",Name ="Rengar",Spellslot =_E},
    ["rivenizunablade"]                      = {Spellname ="rivenizunablade",Name ="Riven",Spellslot =_R},
    ["Overload"]                      = {Spellname ="Overload",Name ="Ryze",Spellslot =_Q},
    ["SpellFlux"]                      = {Spellname ="SpellFlux",Name ="Ryze",Spellslot =_E},
    ["SejuaniGlacialPrisonStart"]                      = {Spellname ="SejuaniGlacialPrisonStart",Name ="Sejuani",Spellslot =_R},
    ["SivirQ"]                      = {Spellname ="SivirQ",Name ="Sivir",Spellslot =_Q},
    ["SivirE"]                      = {Spellname ="SivirE",Name ="Sivir",Spellslot =_E},
    ["SkarnerFractureMissileSpell"]                      = {Spellname ="SkarnerFractureMissileSpell",Name ="Skarner",Spellslot =_E},
    ["SonaCrescendo"]                      = {Spellname ="SonaCrescendo",Name ="Sona",Spellslot =_R},
    ["SwainDecrepify"]                      = {Spellname ="SwainDecrepify",Name ="Swain",Spellslot =_Q},
    ["SwainMetamorphism"]                      = {Spellname ="SwainMetamorphism",Name ="Swain",Spellslot =_R},
    ["SyndraE"]                      = {Spellname ="SyndraE",Name ="Syndra",Spellslot =_E},
    ["SyndraR"]                      = {Spellname ="SyndraR",Name ="Syndra",Spellslot =_R},
    ["TalonRake"]                      = {Spellname ="TalonRake",Name ="Talon",Spellslot =_W},
    ["TalonShadowAssault"]                      = {Spellname ="TalonShadowAssault",Name ="Talon",Spellslot =_R},
    ["BlindingDart"]                      = {Spellname ="BlindingDart",Name ="Teemo",Spellslot =_Q},
    ["Thresh"]                      = {Spellname ="ThreshQ",Name ="Thresh",Spellslot =_Q},
    ["BusterShot"]                      = {Spellname ="BusterShot",Name ="Tristana",Spellslot =_R},
    ["VarusQ"]                      = {Spellname ="VarusQ",Name ="Varus",Spellslot =_Q},
    ["VarusR"]                      = {Spellname ="VarusR",Name ="Varus",Spellslot =_R},
    ["VayneCondemm"]                      = {Spellname ="VayneCondemm",Name ="Vayne",Spellslot =_E},
    ["VeigarPrimordialBurst"]                      = {Spellname ="VeigarPrimordialBurst",Name ="Veigar",Spellslot =_R},
    ["WildCards"]                      = {Spellname ="WildCards",Name ="Twistedfate",Spellslot =_Q},
    ["VelkozQ"]                      = {Spellname ="VelkozQ",Name ="Velkoz",Spellslot =_Q},
    ["VelkozW"]                      = {Spellname ="VelkozW",Name ="Velkoz",Spellslot =_W},
    ["ViktorDeathRay"]                      = {Spellname ="ViktorDeathRay",Name ="Viktor",Spellslot =_E},
    ["XerathArcanoPulseChargeUp"]                      = {Spellname ="XerathArcanoPulseChargeUp",Name ="Xerath",Spellslot =_Q},
    ["ZedShuriken"]                      = {Spellname ="ZedShuriken",Name ="Zed",Spellslot =_Q},
    ["ZiggsR"]                      = {Spellname ="ZiggsR",Name ="Ziggs",Spellslot =_R},
    ["ZiggsQ"]                      = {Spellname ="ZiggsQ",Name ="Ziggs",Spellslot =_Q},
    ["ZyraGraspingRoots"]                      = {Spellname ="ZyraGraspingRoots",Name ="Zyra",Spellslot =_E}

}

function QReady()
	return CanCast(Q)
end

function WReady()
	return CanCast(W)
end

function EReady()
	return CanCast(E)
end

function RReady()
	return CanCast(R)
end

function GetTarget()
	return GetEnemyChampCanKillFastest(1000)
end

Callback.Add("Update", function()
	if IsDead(UpdateHeroInfo()) then return end

	AutoW()

	local nKeyCode = GetKeyCode()

	if nKeyCode == SpaceKeyCode then
		SetLuaCombo(true)
		Combo()
	end

	if nKeyCode == VKeyCode then
		LaneClear()
	end

	KillSteal()

	if config_AutoUlt then
		AutoUlt()
	end

	--YasuoDash2minion()

end)

function AutoW()
	SearchAllChamp()
	local Enemies = pObjChamp
	for i, enemy in ipairs(Enemies) do
		if enemy ~= 0 then
			if WReady() and ValidTargetRange(enemy, 1500) and GetDistance(enemy) >= 475 and config_AutoW then
				local spell = GetSpellCasting(enemy)
				if spell ~= 0 then
					--__PrintDebug(GetName_Casting(spell))
					if WALL_SPELLS[GetName_Casting(spell)] then
						CastSpellToPredictionPos(enemy, W, GetDistance(enemy))
						--__PrintDebug("Cast W")
					end
				end
			end
		end
	end
end


function VPGetLineCastPosition(Target, Delay, Width, Range, Speed)
	local x1 = GetPosX(UpdateHeroInfo())
	local z1 = GetPosZ(UpdateHeroInfo())

	local x2 = GetPosX(Target)
	local z2 = GetPosZ(Target)

	local distance = GetDistance2D(x1,z1,x2,z2)

	TimeMissile = Delay + distance/Speed
	local real_distance = (TimeMissile * GetMoveSpeed(Target))

	if real_distance == 0 then return distance end
	return real_distance

end

function ValidTarget(Target)
	if Target ~= 0 then
		if not IsDead(Target) and not IsInFog(Target) and GetTargetableToTeam(Target) == 4 and IsEnemy(Target) then
			return true
		end
	end
	return false
end

function GetDistance(Target)
	x1 = GetPosX(UpdateHeroInfo())
	z1 = GetPosZ(UpdateHeroInfo())

	x2 = GetPosX(Target)
	z2 = GetPosZ(Target)

	return GetDistance2D(x1,z1,x2,z2)
end

function ValidTargetRange(Target, Range)
	if ValidTarget(Target) and GetDistance(Target) < Range then
		return true
	end
	return false
end

function Combo()

	local Target = GetTarget()

	if Target ~= 0 then
		if ValidTarget(Target) then
			if Setting_IsComboUseQ() then
				if QReady() then
					CastQ(Target)
				end
			end
		end
	end


	Target = GetTarget()
	if Target ~= 0 then
		if ValidTarget(Target) then
			if Setting_IsComboUseE() then
				if EReady() then
					CastE(Target)
				end
			end
		end
	end


end

function CastQ(Target)
	if Target ~= 0 and ValidTargetRange(Target, SpellQW.Range) and QReady() and GetBuffCount(UpdateHeroInfo(), "yasuoq3w") == 0 and CanMove() then
		local vp_distance = VPGetLineCastPosition(Target, SpellQW.Delay, SpellQW.Width, SpellQW.Range, SpellQW.Speed)
		if vp_distance > 0 and vp_distance < SpellQW.Range then
			CastSpellToPredictionPos(Target, Q, vp_distance)
		end
	end
	if Target ~= 0 and ValidTargetRange(Target, SpellQ3.Range) and QReady() and GetBuffCount(UpdateHeroInfo(), "yasuoq3w") > 0 and CanMove() then
		local vp_distance = VPGetLineCastPosition(Target, SpellQ3.Delay, SpellQ3.Width, SpellQ3.Range, SpellQ3.Speed)
		if vp_distance > 0 and vp_distance < SpellQ3.Range then
			CastSpellToPredictionPos(Target, Q, vp_distance)
		end
	end
end

function CastE(Target)
	if Target ~= 0 and EReady() and ValidTargetRange(Target, 475) and CanMove() then
		CastSpellTarget(Target, E)
	end
end

function AutoUlt()
	SearchAllChamp()
	local Enemies = pObjChamp
	for i, enemy in ipairs(Enemies) do
		if enemy ~= 0 then
			if RReady() and ValidTargetRange(enemy, 1200) and GetDistance(enemy) < 1200 and CanMove() then
				CastSpellTarget(UpdateHeroInfo(),R)
			end
		end
	end
end

function ClosestMinion()
	GetAllUnitAroundAnObject(UpdateHeroInfo(), 1000)

	local closest_distance = 475
	local last_minion = 0

	local Enemies = pUnit
	for i, enemy in pairs(Enemies) do
		if enemy ~= 0 then
			if IsMinion(enemy) and IsEnemy(enemy) and not IsDead(enemy) and not IsInFog(enemy) and GetTargetableToTeam(enemy) == 4 then
				local distance = GetDistance(enemy)
				if distance > 0 and distance < closest_distance and distance < 1000 and GetBuffCount(UpdateHeroInfo(), "YasuoDashWrapper") == 0 then
					closest_distance = distance
					last_minion = enemy
				end
			end
		end
	end
	return last_minion
end

--[[
function YasuoDash2minion()
	GetAllObjectAroundAnObject(UpdateHeroInfo(), 1000)

	local Enemies = pObject
	for i, enemy in pairs(Enemies) do
		if enemy ~= 0 then
			if IsMinion(enemy) and IsEnemy(enemy) and not IsDead(enemy) and not IsInFog(enemy) and GetTargetableToTeam(enemy) == 4 then
				if GetDistance(enemy) < 375 then
					if GetBuffCount(enemy, "YasuoDashWrapper") > 0 and EReady() and not GetDistance(enemy) < 475 then
						local Q = ClosestMinion()
						if GetDistance(Q) < 375 then
							if EReady() then
								CastSpellTarget(Q, E)
							end
						end
					end
				end
			end
		end
	end
end
]]

function ValidTargetJungle(Target)
	if Target ~= 0 then
		if not IsDead(Target) and not IsInFog(Target) and GetTargetableToTeam(Target) == 4 and IsJungleMonster(Target) then
			return true
		end
	end
	return false
end

function GetMinion()
	GetAllUnitAroundAnObject(UpdateHeroInfo(), 1000)

	local Enemies = pUnit
	for i, minion in pairs(Enemies) do
		if minion ~= 0 then
			if IsMinion(minion) and IsEnemy(minion) and not IsDead(minion) and not IsInFog(minion) and GetTargetableToTeam(minion) == 4 then
				return minion
			end
		end
	end

	return 0
end

function LaneClear()
	local jungle = GetJungleMonster(1000)
	if jungle ~= 0 then

		if QReady() and CanMove() then
			if ValidTargetJungle(jungle) and GetDistance(jungle) < SpellQW.Range then
				local vp_distance = VPGetLineCastPosition(jungle, SpellQW.Delay, SpellQW.Width, SpellQW.Range, SpellQW.Speed)
				if vp_distance > 0 and vp_distance < SpellQW.Range then
					CastSpellToPredictionPos(jungle, Q, vp_distance)
				end
			end
		end

		jungle = GetJungleMonster(1000)
		if jungle ~= 0 then
			if EReady() and CanMove() then
				if ValidTargetJungle(jungle) and GetDistance(jungle) < 475 and GetBuffCount(jungle, "YasuoDashWrapper") == 0 then
					CastSpellTarget(jungle, E)
				end
			end
		end

	else
		local minion = GetMinion()
		if minion ~= 0 then
			if EReady() and CanMove() and Setting_IsLaneClearUseE() and GetDistance(minion) < 475 and not UnderTower() then
				CastSpellTarget(minion, E)
			end
		end

		minion = GetMinion()
		if minion ~= 0 then
			if QReady() and CanMove() and Setting_IsLaneClearUseQ() and GetDistance(minion) < SpellQW.Range and GetBuffCount(minion, "YasuoDashWrapper") == 0 then
				local vp_distance = VPGetLineCastPosition(minion, SpellQW.Delay, SpellQW.Width, SpellQW.Range, SpellQW.Speed)
				if vp_distance > 0 and vp_distance < SpellQW.Range then
					CastSpellToPredictionPos(minion, Q, vp_distance)
				end
			end
		end
	end

end

function UnderTower()
	GetAllUnitAroundAnObject(UpdateHeroInfo(), 1400)
	for i, obj in pairs(pUnit) do
		if obj ~= 0 then
			if IsEnemy(obj) and IsTurret(obj) and GetTargetableToTeam(obj) == 4 and GetDistance(obj) < 1400 then
				return true
			end
		end
	end

	return false
end


function KillSteal()
	SearchAllChamp()
	local Enemies = pObjChamp
	for i, Target in pairs(Enemies) do
		if Target ~= 0 then
			if ValidTarget(Target) then
				--__PrintDebug("Q1")
				if ValidTargetRange(Target, SpellQW.Range) and QReady() and GetBuffCount(UpdateHeroInfo(), "yasuoq3w") == 0 and getDmg(Q, Target) > GetHealthPoint(Target) then
					local vp_distance = VPGetLineCastPosition(Target, SpellQW.Delay, SpellQW.Width, SpellQW.Range, SpellQW.Speed)
					if vp_distance > 0 and vp_distance < SpellQW.Range and CanMove() then
						CastSpellToPredictionPos(Target, Q, vp_distance)
					end
				end
				--__PrintDebug("Q2")
				if ValidTargetRange(Target, SpellQ3.Range) and QReady() and GetBuffCount(UpdateHeroInfo(), "yasuoq3w") > 0 and getDmg(Q, Target) > GetHealthPoint(Target) then
					local vp_distance = VPGetLineCastPosition(Target, SpellQ3.Delay, SpellQ3.Width, SpellQ3.Range, SpellQ3.Speed)
					if vp_distance > 0 and vp_distance < SpellQ3.Range and CanMove() then
						CastSpellToPredictionPos(Target, Q, vp_distance)
					end
				end
				--__PrintDebug("E")
				if ValidTargetRange(Target, 425) and EReady() and GetBuffCount(Target, "YasuoDashWrapper") == 0 and getDmg(E, Target) > GetHealthPoint(Target) and CanMove() then
					CastSpellTarget(Target, E)
				end
				--__PrintDebug("R")
				if ValidTargetRange(Target, 1200) and RReady() and getDmg(R, Target) > GetHealthPoint(Target) and CanMove() then
					CastSpellTarget(UpdateHeroInfo(),R)
				end

			end
		end
	end
end

function getDmg(Spell, Enemy)
	local Damage = 0

	if Spell == Q then
		if GetSpellLevel(UpdateHeroInfo(),Q) == 0 then return 0 end

		local DamageSpellQTable = {20, 40, 60, 80, 100}

		local Percent_AD = 1

		local Damage_AD = GetFlatPhysicalDamage(UpdateHeroInfo()) + GetBaseAttackDamage(UpdateHeroInfo())

		local DamageSpellQ = DamageSpellQTable[GetSpellLevel(UpdateHeroInfo(),Q)]

		local Enemy_Armor = GetArmor(Enemy)

		local Dominik_ID = 3036--Lord Dominik's Regards
		local Mortal_Reminder_ID = 3033--Mortal Reminder

		if GetItemByID(Dominik_ID) > 0 or GetItemByID(Mortal_Reminder_ID) > 0 then
			Enemy_Armor = Enemy_Armor - GetBonusArmor(Enemy) * 45/100
		end

		local ArmorPenetration = 60 * GetArmorPenetration(UpdateHeroInfo()) / 100 + (1 - 60/100) * GetArmorPenetration(UpdateHeroInfo()) * GetLevel(Enemy) / 18

		Enemy_Armor = Enemy_Armor - ArmorPenetration

		if Enemy_Armor >= 0 then
			Damage = (DamageSpellQ + Percent_AD * Damage_AD) * (100/(100 + Enemy_Armor))
		else
			Damage = (DamageSpellQ + Percent_AD * Damage_AD) * (2 - 100/(100 - Enemy_Armor))
		end


		return Damage
	end

	if Spell == E then
		if GetSpellLevel(UpdateHeroInfo(),E) == 0 then return 0 end

		local DamageSpellETable = {60, 70, 80, 90, 100}

		local Percent_Bonus_AD = 0.2

		local Damage_Bonus_AD = GetFlatPhysicalDamage(UpdateHeroInfo())

		local Percent_AP = 0.6

		local Damage_AP = GetFlatMagicDamage(UpdateHeroInfo()) + GetFlatMagicDamage(UpdateHeroInfo()) * GetPercentMagicDamage(UpdateHeroInfo())

		local DamageSpellE = DamageSpellETable[GetSpellLevel(UpdateHeroInfo(),E)]

		local Enemy_Armor = GetArmor(Enemy)

		local Dominik_ID = 3036--Lord Dominik's Regards
		local Mortal_Reminder_ID = 3033--Mortal Reminder

		if GetItemByID(Dominik_ID) > 0 or GetItemByID(Mortal_Reminder_ID) > 0 then
			Enemy_Armor = Enemy_Armor - GetBonusArmor(Enemy) * 45/100
		end

		local ArmorPenetration = 60 * GetArmorPenetration(UpdateHeroInfo()) / 100 + (1 - 60/100) * GetArmorPenetration(UpdateHeroInfo()) * GetLevel(Enemy) / 18

		Enemy_Armor = Enemy_Armor - ArmorPenetration

		if Enemy_Armor >= 0 then
			Damage = (DamageSpellE + Percent_Bonus_AD * Damage_Bonus_AD + Percent_AP * Damage_AP) * (100/(100 + Enemy_Armor))
		else
			Damage = (DamageSpellE + Percent_Bonus_AD * Damage_Bonus_AD + Percent_AP * Damage_AP) * (2 - 100/(100 - Enemy_Armor))
		end

		return Damage
	end

	if Spell == R then
		if GetSpellLevel(UpdateHeroInfo(),R) == 0 then return 0 end

		local DamageSpellRTable = {200, 300, 400}

		local Percent_Bonus_AD = 1.5

		local Damage_Bonus_AD = GetFlatPhysicalDamage(UpdateHeroInfo())

		local DamageSpellR = DamageSpellRTable[GetSpellLevel(UpdateHeroInfo(),R)]

		local Enemy_Armor = GetArmor(Enemy)

		local Dominik_ID = 3036--Lord Dominik's Regards
		local Mortal_Reminder_ID = 3033--Mortal Reminder

		if GetItemByID(Dominik_ID) > 0 or GetItemByID(Mortal_Reminder_ID) > 0 then
			Enemy_Armor = Enemy_Armor - GetBonusArmor(Enemy) * 45/100
		end

		local ArmorPenetration = 60 * GetArmorPenetration(UpdateHeroInfo()) / 100 + (1 - 60/100) * GetArmorPenetration(UpdateHeroInfo()) * GetLevel(Enemy) / 18

		Enemy_Armor = Enemy_Armor - ArmorPenetration

		if Enemy_Armor >= 0 then
			Damage = (DamageSpellR + Percent_Bonus_AD * Damage_Bonus_AD) * (100/(100 + Enemy_Armor))
		else
			Damage = (DamageSpellR + Percent_Bonus_AD * Damage_Bonus_AD) * (2 - 100/(100 - Enemy_Armor))
		end

		return Damage
	end

end
