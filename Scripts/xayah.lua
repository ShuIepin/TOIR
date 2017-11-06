--[[

Reference link https://raw.githubusercontent.com/Celtech/BOL/master/UnitedUnderBrokenWings/UnitedUnderBrokenWings.lua

Thanks Celtech team

]]

IncludeFile("Lib\\Callbacks.lua")
IncludeFile("Lib\\Vector.lua")

function UpdateHeroInfo()
    return GetMyChamp()
end

if GetChampName(UpdateHeroInfo()) ~= "Xayah" then return end

__PrintTextGame("Xayah v1.0 loaded")

local Q = 0
local W = 1
local E = 2
local R = 3

local SpaceKeyCode = 32
local CKeyCode = 67
local VKeyCode = 86


local HarassUseMana = 60
local LaneClearUseMana = 60

local SpellQ = {Range = 1075, Speed = 2000, Delay = 0.25, Width = 75, Collision = false}
local SpellW = {Range = 1000, Delay = 0.25}
local SpellE = {Range = 1075, Speed = 2000, Delay = 0.00, Width = 75, Collision = false}
local SpellR = {Range = 1040, Speed = 2000, Delay = 0.50, Angle = 150, Collision = false,}

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
	return GetEnemyChampCanKillFastest(1100)
end

Callback.Add("Update", function()
	if IsDead(UpdateHeroInfo()) then return end

	local nKeyCode = GetKeyCode()

	if nKeyCode == SpaceKeyCode then
		SetLuaCombo(true)
		Combo()
	end

	if nKeyCode == CKeyCode then
		SetLuaHarass(true)
		Harass()
	end

	if nKeyCode == VKeyCode then
		LaneClear()
	end

	KillSteal()

end)

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
			if Setting_IsComboUseW() then
				if WReady() and CanMove() then
					CastW(Target)
				end
			end
		end
	end

	Target = GetTarget()
	if Target ~= 0 then
		if ValidTarget(Target) then
			if Setting_IsComboUseE() then
				if EReady() and CanMove() then
					CastE(Target)
				end
			end
		end
	end

	Target = GetTarget()

	if Target ~= 0 then
		if ValidTarget(Target) then
			if Setting_IsComboUseR() then
				if RReady() and CanMove() then
					CastR(Target)
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

function CastQ(Target)
	if Target ~= 0 and ValidTarget(Target, SpellQ.Range) and QReady() then
		local vp_distance = VPGetLineCastPosition(Target, SpellQ.Delay, SpellQ.Width, SpellQ.Range, SpellQ.Speed)
		if vp_distance > 0 and vp_distance < SpellQ.Range then
			CastSpellToPredictionPos(Target, Q, vp_distance)
		end
	end
end

function CastW(Target)
	if Target ~= 0 and WReady() and ValidTarget(Target, SpellW.Range) then
		CastSpellTarget(UpdateHeroInfo(), W)
	end
end


function VectorPointProjectionOnLineSegment(v1, v2, v)
    local cx, cy, ax, ay, bx, by = v.x, (v.z or v.y), v1.x, (v1.z or v1.y), v2.x, (v2.z or v2.y)
    local rL = ((cx - ax) * (bx - ax) + (cy - ay) * (by - ay)) / ((bx - ax) ^ 2 + (by - ay) ^ 2)
    local pointLine = { x = ax + rL * (bx - ax), z = ay + rL * (by - ay) }
    local rS = rL < 0 and 0 or (rL > 1 and 1 or rL)
    local isOnSegment = rS == rL
    local pointSegment = isOnSegment and pointLine or { x = ax + rS * (bx - ax), z = ay + rS * (by - ay) }
    return pointSegment, pointLine, isOnSegment
end

function rootLogic(target, obj)
    local myHeroPos = { GetPosX(UpdateHeroInfo()), GetPosY(UpdateHeroInfo()), GetPosZ(UpdateHeroInfo()) }
    local targetPos = { GetPosX(target), GetPosY(target), GetPosZ(target) }
    local objPos = { GetPosX(obj), GetPosY(obj), GetPosZ(obj) }

    local myHeroVector = Vector(myHeroPos)
    local targetVector = Vector(targetPos)
    local objVector = Vector(objPos)

    local distanceToObj = myHeroVector:DistanceTo(objVector)
    local endPos = myHeroVector:Extend(objVector, distanceToObj)
    local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(myHeroVector, endPos, targetVector)

    local pointSegmentVector = Vector(pointSegment.x, targetVector.y, pointSegment.z)
    if isOnSegment and targetVector:DistanceTo(pointSegmentVector) <= 85 * 1.5 then
        return true
    end
    return false
end

function feathersHitCount(target)
    GetAllUnitAroundAnObject(UpdateHeroInfo(), SpellE.Range * 2)
    local count = 0
    local fObjects = pUnit
    for i, object in pairs(fObjects) do
        if object ~= 0 then
            if GetTargetableToTeam(object) ~= 4 and GetObjName(object) == "Feather" and GetChampName(object) == "TestCubeRender" and rootLogic(target, object) then
                count = count + 1
            end
        end
    end
    return count
end

function CastE(Target)
    if EReady() and CanMove() then
        if ValidTarget(Target, SpellE.Range) and feathersHitCount(Target) > 2 then
            CastSpellTarget(UpdateHeroInfo(), E)
        end
    end
end

function CastR(Target)
	if Target ~= 0 and RReady() and CanMove() and ValidTargetRange(Target, SpellR.Range) then
		local vp_distance = VPGetLineCastPosition(Target, SpellR.Delay, SpellR.Width, SpellR.Range, SpellR.Speed)
		if vp_distance > 0 and vp_distance < SpellR.Range then
			CastSpellToPredictionPos(Target, R, vp_distance)
		end
	end
end

function IsMyManaLowHarass()
    if GetManaPoint(UpdateHeroInfo()) < (GetManaPointMax(UpdateHeroInfo()) * ( HarassUseMana / 100)) then
        return true
    else
        return false
    end
end

function IsMyManaLowLaneClear()
    if GetManaPoint(UpdateHeroInfo()) < (GetManaPointMax(UpdateHeroInfo()) * ( LaneClearUseMana / 100)) then
        return true
    else
        return false
    end
end

function Harass()
	local Target = GetTarget()
	if Target ~= 0 then
		if ValidTarget(Target) then
			if QReady() and Setting_IsHarassUseQ() and not IsMyManaLowHarass() then
				CastQ(Target)
			end
		end
	end

	Target = GetTarget()
	if Target ~= 0 then
		if ValidTarget(Target) then
			if WReady() and CanMove() and Setting_IsHarassUseW() and not IsMyManaLowHarass() then
				CastW(Target)
			end
		end
	end

	Target = GetTarget()
	if Target ~= 0 then
		if ValidTarget(Target) then
			if EReady() and CanMove() and Setting_IsHarassUseE() and not IsMyManaLowHarass() then
				CastE(Target)
			end
		end
	end

	Target = GetTarget()
	if Target ~= 0 then
		if ValidTarget(Target) then
			if RReady() and CanMove() and Setting_IsHarassUseR() and not IsMyManaLowHarass() then
				CastR(Target)
			end
		end
	end
end

function ValidTargetJungle(Target)
	if Target ~= 0 then
		if not IsDead(Target) and not IsInFog(Target) and GetTargetableToTeam(Target) == 4 and IsJungleMonster(Target) then
			return true
		end
	end
	return false
end

function GetMinion()
	GetAllUnitAroundAnObject(UpdateHeroInfo(), SpellE.Range)

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
	local jungle = GetJungleMonster(1100)
	if jungle ~= 0 then
		if QReady() and not IsMyManaLowLaneClear() then
			if ValidTargetJungle(jungle) and GetDistance(jungle) < SpellQ.Range then
				local vp_distance = VPGetLineCastPosition(jungle, SpellQ.Delay, SpellQ.Width, SpellQ.Range, SpellQ.Speed)
				if vp_distance > 0 and vp_distance < SpellQ.Range then
					CastSpellToPredictionPos(jungle, Q, vp_distance)
				end
			end
		end

		jungle = GetJungleMonster(1100)
		if jungle ~= 0 then
			if WReady() and CanMove() and not IsMyManaLowLaneClear() then
				if ValidTargetJungle(jungle) and GetDistance(jungle) < SpellQ.Range then
					CastSpellTarget(UpdateHeroInfo(), W)

				end
			end
		end

		jungle = GetJungleMonster(1100)
		if jungle ~= 0 then

			if EReady() and CanMove() and not IsMyManaLowLaneClear() then
				if ValidTargetJungle(jungle) and GetDistance(jungle) < SpellQ.Range then
					CastSpellTarget(UpdateHeroInfo(), E)
				end
			end
		end

	else
		local minion = GetMinion()
		if minion ~= 0 then
			if QReady() and Setting_IsLaneClearUseQ() and not IsMyManaLowLaneClear() and GetDistance(minion) < SpellE.Range then
				local vp_distance = VPGetLineCastPosition(minion, SpellQ.Delay, SpellQ.Width, SpellQ.Range, SpellQ.Speed)
				if vp_distance > 0 and vp_distance < SpellQ.Range then
					CastSpellToPredictionPos(minion, Q, vp_distance)--

				end
			else
				if QReady() and getDmg(Q, minion) > GetHealthPoint(minion) and GetDistance(minion) < SpellE.Range then
					local vp_distance = VPGetLineCastPosition(minion, SpellQ.Delay, SpellQ.Width, SpellQ.Range, SpellQ.Speed)
					if vp_distance > 0 and vp_distance < SpellQ.Range then
						CastSpellToPredictionPos(minion, Q, vp_distance)
					end
				end
			end
		end

		minion = GetMinion()
		if minion ~= 0 then
			if WReady() and CanMove() and Setting_IsLaneClearUseW() and not IsMyManaLowLaneClear() and GetDistance(minion) < SpellE.Range then
				CastSpellTarget(UpdateHeroInfo(), W)
			end
		end

		minion = GetMinion()
		if minion ~= 0 then
			if EReady() and CanMove() and Setting_IsLaneClearUseE() and not IsMyManaLowLaneClear() and GetDistance(minion) < SpellE.Range then
				CastSpellTarget(UpdateHeroInfo(), E)
			else
				if EReady() and CanMove() and getDmg(E, minion) > GetHealthPoint(minion) and GetDistance(minion) < SpellE.Range then
					CastSpellTarget(UpdateHeroInfo(), E)
				end
			end
		end
	end

end

function getDmg(Spell, Enemy)
	local Damage = 0

	if Spell == Q then
		if GetSpellLevel(UpdateHeroInfo(),Q) == 0 then return 0 end

		local DamageSpellQTable = {80, 120, 160, 200, 240}

		local Percent_Bonus_AD = 1

		local Damage_Bonus_AD = GetFlatPhysicalDamage(UpdateHeroInfo())

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
			Damage = (DamageSpellQ + Percent_Bonus_AD * Damage_Bonus_AD) * (100/(100 + Enemy_Armor))
		else
			Damage = (DamageSpellQ + Percent_Bonus_AD * Damage_Bonus_AD) * (2 - 100/(100 - Enemy_Armor))
		end


		return Damage
	end

	if Spell == E then
		if GetSpellLevel(UpdateHeroInfo(),E) == 0 then return 0 end

		local DamageSpellETable = {50, 60, 70, 80, 90}

		local Percent_Bonus_AD = 0.6

		local Damage_Bonus_AD = GetFlatPhysicalDamage(UpdateHeroInfo())

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
			Damage = (DamageSpellE + Percent_Bonus_AD * Damage_Bonus_AD) * (100/(100 + Enemy_Armor))
		else
			Damage = (DamageSpellE + Percent_Bonus_AD * Damage_Bonus_AD) * (2 - 100/(100 - Enemy_Armor))
		end

		return Damage
	end

	if Spell == R then
		if GetSpellLevel(UpdateHeroInfo(),R) == 0 then return 0 end

		local DamageSpellRTable = {100, 150, 200}

		local Percent_Bonus_AD = 1

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



function KillSteal()
    SearchAllChamp()
	local Enemies = pObjChamp
	for i, enemy in pairs(Enemies) do
        if enemy ~= 0 and ValidTarget(enemy) then

			if GetDistance(enemy) < SpellQ.Range then
				if GetHealthPoint(enemy) < getDmg(Q, enemy)and QReady() then
					CastQ(enemy)
				end
			end

			if getDmg(E, enemy) > GetHealthPoint(enemy) and EReady() and CanMove() and GetDistance(enemy) < SpellE.Range then
				CastE(enemy)
			end

        end
    end
end