IncludeFile("Vector.lua")

if GetChampName(UpdateHeroInfo()) ~= "Yasuo" then return end

local Q = 0
local W = 1
local E = 2
local R = 3

local SpaceKeyCode = 32
local CKeyCode = 67
local VKeyCode = 86

local SpellQ1 = { Range = 520, Speed = 1600, Delay = 0.25, Width = 60, Collision = false }
local SpellQ3 = { Range = 1100, Speed = 1200, Delay = 0.25, Width = 90, Collision = false }
local SpellW  = { Range = 400 }
local SpellE  = { Range = 475 }
local SpellR  = { Range = 1400 }

function QReady() return CanCast(Q) end
function WReady() return CanCast(W) end
function EReady() return CanCast(E) end
function RReady() return CanCast(R) end

function GetTarget(range) return GetEnemyChampCanKillFastest(range) end

function GetDistanceToUnit(target)
	local x1 = GetPosX(UpdateHeroInfo())
	local z1 = GetPosZ(UpdateHeroInfo())

	local x2 = GetPosX(target)
	local z2 = GetPosZ(target)

	return GetDistance2D(x1,z1,x2,z2)
end

function GetDistanceToPos(pos)
	local x1 = GetPosX(UpdateHeroInfo())
	local z1 = GetPosZ(UpdateHeroInfo())

	local x2 = pos[1]
	local z2 = pos[2]

	return GetDistance2D(x1,z1,x2,z2)
end

function ValidTarget(target)
	if target ~= 0 then
		if not IsDead(target) and not IsInFog(target) and GetTargetableToTeam(target) == 4 and IsEnemy(target) then
			return true
		end
	end
	return false
end

function ValidTargetInRange(target, range)
	if ValidTarget(target) and GetDistanceToUnit(target) < range then
		return true
	end
	return false
end

function VPGetLineCastPosition(target, delay, width, range, speed)
	local x1 = GetPosX(UpdateHeroInfo())
	local z1 = GetPosZ(UpdateHeroInfo())

	local x2 = GetPosX(target)
	local z2 = GetPosZ(target)

	local distance = GetDistance2D(x1,z1,x2,z2)

	local TimeMissile = delay + distance / speed
	local real_distance = (TimeMissile * GetMoveSpeed(target))

	if real_distance == 0 then return distance end
	return real_distance
end

function IsQ3()
	return GetSpellNameByIndex(UpdateHeroInfo(), Q) == "YasuoQ3W"
end

function DashEndPos(unit)
	local myHeroPos = { GetPosX(UpdateHeroInfo()), GetPosY(UpdateHeroInfo()), GetPosZ(UpdateHeroInfo()) }
	local unitPos = { GetPosX(unit), GetPosY(unit), GetPosZ(unit) }
	local myHeroVector = Vector(myHeroPos)
	local unitVector = Vector(unitPos)

	return myHeroVector:Extend(unitVector, 550)
end

function IsMarked(target)
	return GetBuffByName(target, "YasuoDashWrapper") > 0
end

function IsKnockedUp(target)
	return CountBuffByType(target, 29) > 0
end

function GetGapMinion(target)
	GetAllObjectAroundAnObject(UpdateHeroInfo(), 1500)
	local targetPos = { GetPosX(target), GetPosY(target), GetPosZ(target) }
	local targetVector = Vector(targetPos)
	local bestMinion, closest = nil, math.huge
	local minions = pObject
	for i, minion in pairs(minions) do
		if minion ~= 0 and IsMinion(minion) and IsEnemy(minion) and not IsDead(minion) and not IsInFog(minion) and GetTargetableToTeam(minion) == 4 then
			if ValidTargetInRange(minion, SpellE.Range) and not IsMarked(minion) then
				local dashEndPosVector = DashEndPos(minion)
				if dashEndPosVector:DistanceTo(targetVector) < GetDistanceToUnit(target) and dashEndPosVector:DistanceTo(targetVector) < closest then
					bestMinion = minion
					closest = dashEndPosVector:DistanceTo(targetVector)
				end
			end
		end
	end
	return bestMinion
end

function CastQ(target)
	local range = IsQ3() and SpellQ3.Range or SpellQ1.Range
	local delay = SpellQ1.Delay 
	local width = IsQ3() and SpellQ3.Width or SpellQ1.Width
	local speed = IsQ3() and SpellQ3.Speed or SpellQ1.Speed
	local distance = IsDashing(UpdateHeroInfo()) and SpellE.Range - 100 or range

	if target ~= 0 then
		if QReady() and ValidTargetInRange(target, distance) then
			local vp_distance = VPGetLineCastPosition(target, delay, width, range, speed)
			if vp_distance > 0 and vp_distance < range then
				CastSpellToPredictionPos(target, Q, vp_distance)
			end
		end
	end
end

function CastE(target)
	local targetPos = { GetPosX(target), GetPosY(target), GetPosZ(target) }
	local targetVector = Vector(targetPos)
	local dashEndPosVector = DashEndPos(target)

	if target ~= 0 then
		if EReady() then
			if ValidTargetInRange(target, SpellE.Range) and dashEndPosVector:DistanceTo(targetVector) <= GetDistanceToUnit(target) and not IsMarked(target) then
				CastSpellTarget(target, E)
			end

			local gapMinion = GetGapMinion(target)
			if gapMinion and gapMinion ~= 0 and ValidTargetInRange(target, 1500) then
				CastSpellTarget(gapMinion, E)
			end
		end
	end
end

function CastR()
	local target = GetTarget(SpellR.Range)

	if target ~= 0 then
		if Setting_IsComboUseR() then
			if RReady() and IsKnockedUp(target) then
				CastSpellTarget(UpdateHeroInfo(), R)
			end
		end
	end	
end

function Combo()
	local target = GetTarget(SpellR.Range)

	if target ~= 0 then
		if Setting_IsComboUseE() then
			CastE(target)
		end

		if Setting_IsComboUseQ() then
			CastQ(target)
		end
	end
end

function OnTick()
	if IsDead(UpdateHeroInfo()) then return end

	local nKeyCode = GetKeyCode()

	if nKeyCode == SpaceKeyCode then
		SetLuaCombo(true)
		Combo()
	end

	CastR()

	--local target = GetTarget(SpellR.Range)
	--
	--if target ~= 0 then 
	--	--__PrintTextGame( tostring( IsKnockedUp(target) ) )
	--end
end

__PrintTextGame("yasuo.lua loaded")
