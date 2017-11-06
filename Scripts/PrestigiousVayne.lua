-------------------------------------<INIT>-------------------------------------

--[[
Author: RMAN
]]

IncludeFile("Lib\\Callbacks.lua")
IncludeFile("Lib\\Vector.lua")
local myHero = function() return GetMyChamp() end
if GetChampName(myHero()) ~= "Vayne" then return end
local myHeroPos = Vector({GetPosX(myHero()), GetPosY(myHero()), GetPosZ(myHero())})
local mousePos = Vector({GetCursorPosX(myHero()), GetCursorPosY(myHero()), GetCursorPosZ(myHero())})
local _enemies = function() return GetEnemies() end
local _heroes = function() return GetHeroes() end
SetLuaCombo(true)

__PrintTextGame("Prestigious Vayne Loaded, Good Luck!")

local Q = 0
local W = 1
local E = 2
local R = 3

local SpaceKeyCode = 32
local CKeyCode = 67
--local VKeyCode = 86


local SpellQ = {Range = 300, Speed = 2000, Delay = 0.25}
local SpellW = {Range = 550, Target = nil, Count = nil}
local SpellE = {Range = 550, Speed = 2000, Delay = 0.5}
local SpellR = {Range = 1000, Delay = 0.50}


-------------------------------------</INIT>-------------------------------------

-------------------------------------<Base Functions>-------------------------------------
local function GetHeroes()

	SearchAllChamp()
	local t = pObjChamp
	return t
end

local function GetEnemies()
	local t = {}
	local h = GetHeroes()
	for k,v in pairs(h) do
		if IsEnemy(v) and IsChampion(v) then
			table.insert(t, v)
		end
	end
	return t
end


local function GetTarget(range)
	return GetEnemyChampCanKillFastest(range)
end

local function GetDistance(p1, p2)
    return math.sqrt(GetDistanceSqr(p1, p2))
end

local function GetDistance2D(p1,p2)
	return  math.sqrt(math.pow((p2.x - p1.x),2) + math.pow((p2.y - p1.y),2))
end

local function GetDistanceSqr(Pos1, Pos2)
	local Pos2 = Pos2 or myHeroPos
	local dx = Pos1.x - Pos2.x
	local dz = (Pos1.z or Pos1.y) - (Pos2.z or Pos2.y)
	return dx * dx + dz * dz
end


local function IsImmobile(unit)
	if CountBuffByType(unit, 5) or CountBuffByType(unit, 11) or CountBuffByType(unit, 24) or CountBuffByType(unit, 29) or IsRecall(unit) then
		return true
	end
	return false
end

local function IsValidTarget(target, range)
	if target ~= 0 then
		local targetPos = Vector({GetPosX(target), GetPosY(target), GetPosZ(target)})
		if IsDead(target) == false and IsInFog(target) == false and GetTargetableToTeam(target) == 4 and IsEnemy(target) and GetDistanceSqr(myHeroPos, targetPos) < range * range and CountBuffByType(target, 17) == 0 and CountBuffByType(target, 15) == 0 then
			return true
		end
	end
	return false
end

local function IsUnderEnemyTurret(pos)			--Will Only work near myHero
	GetAllUnitAroundAnObject(myHero(), 2000)

	local objects = pUnit
	for k,v in pairs(objects) do

		if IsTurret(v) and IsDead(v) == false and IsEnemy(v) and GetTargetableToTeam(v) == 4 then
			local turretPos = Vector({GetPosX(v), GetPosY(v), GetPosZ(v)})
			if GetDistanceSqr(turretPos,pos) < 915*915 then
				return true
			end
		end
	end
	return false
end

local function IsUnderAllyTurret(pos)			--Will Only work near myHero
	GetAllUnitAroundAnObject(myHero(), 2000)
	local objects = pUnit
	for k,v in pairs(objects) do
		if IsTurret(v) and IsDead(v) == false and IsAlly(v) and GetTargetableToTeam(v) == 4 then
			local turretPos = Vector({GetPosX(v), GetPosY(v), GetPosZ(v)})
			if GetDistanceSqr(turretPos,pos) < 915*915 then
				return true
			end
		end
	end
	return false
end

local function EnemiesAround(object, range)
	return CountEnemyChampAroundObject(object, range)
end

local function GetPercentHP(target)
	return GetHealthPoint(target)/GetHealthPointMax(target) * 100
end

local function IsAfterAttack()
    if CanMove() and not CanAttack() then
        return true
    else
        return false
	end
end

-------------------------------------</Base Functions>-------------------------------------



-------------------------------------<Unique Functions>-------------------------------------

local function BOTRK(target)
	local iBOTRK = GetSpellIndexByName("ItemSwordOfFeastAndFamine")
	local iCutlass = GetSpellIndexByName("BilgewaterCutlass")
	if iBOTRK and CanCast(iBOTRK) then
		CastSpellTargetByName(target, "ItemSwordOfFeastAndFamine")
	elseif iCutlass and CanCast(iCutlass) then
		CastSpellTargetByName(target, "BilgewaterCutlass")
	end
end

local function UpdateBuff()										--Check if need delay
	SpellW.Target = nil
	SpellW.Count = nil
	local t = GetEnemies()
	for k,v in pairs(t) do
		local var = GetBuffCount(v, "VayneSilveredDebuff")   --Check if buffstack
        if var ~= nil and var ~= 0 then
        	SpellW.Target = v
        	SpellW.Count = var
        end
    end
end

local function IsCollisionable(vector)
	return IsWall(vector.x,vector.y,vector.z)
end

local function IsCondemnable(target)
	local pP = Vector({GetPosX(myHero()),GetPosY(myHero()),GetPosZ(myHero())})
	local eP = Vector({GetPosX(target),GetPosY(target),GetPosZ(target)})
	local pD = 450
	if (IsCollisionable(eP:Extend(pP,-pD)) or IsCollisionable(eP:Extend(pP, -pD/2)) or IsCollisionable(eP:Extend(pP, -pD/3))) then
		if IsImmobile(target) or IsCasting(target) then
			return true
		end

		local enemiesCount = CountEnemyChampAroundObject(myHero(), 1200)
		if 	enemiesCount > 1 and enemiesCount <= 3 then
			for i=15, pD, 75 do
				vector3 = eP:Extend(pP, -i)
				if IsCollisionable(vector3) then
					return true
				end
			end
		else
			local hitchance = 50
			local angle = 0.2 * hitchance
			local travelDistance = 0.5
			local alpha = {(eP.x + travelDistance * math.cos(math.pi/180 * angle)),eP.y ,(eP.z + travelDistance * math.sin(math.pi/180 * angle))}
			local beta = {(eP.x	- travelDistance * math.cos(math.pi/180 * angle)),eP.y, (eP.z - travelDistance * math.sin(math.pi/180 * angle))}
			for i=15, pD, 100 do
				local col1 = pP:Extend(alpha, i)
				local col2 = pP:Extend(beta, i)
				if i>pD then return false end
				if IsCollisionable(col1) and IsCollisionable(col2) then return true end
			end
			return false
		end
	end
end


local function IsDangerousPosition(pos)
	if IsUnderEnemyTurret(pos) then return true end


	local t = GetEnemies()

	for k,v in pairs(t) do

		local vPos = Vector({GetPosX(v), GetPosY(v), GetPosZ(v)})
    	if IsDead(v) == false and IsEnemy(v) and GetDistanceSqr(pos, vPos) < 350 * 350 then return true end
    end
   	return false
end


local function GetSmartTumblePos(target)

	if IsDangerousPosition(mousePos) == false then
		local rangePos = (mousePos - myHeroPos):Normalized() * 300
		if IsDangerousPosition(rangePos) == false then return mousePos end
	end


	local targetPos = Vector({GetPosX(target), GetPosY(target), GetPosZ(target)})
	local p0 = myHeroPos
	local points= {
	[1] = p0 + Vector(300,0,0),
	[2] = p0 + Vector(212,0,212),
	[3] = p0 + Vector(0,0,300),
	[4] = p0 + Vector(-212,0,212),
	[5] = p0 + Vector(-300,0,0),
	[6] = p0 + Vector(-212,0,-212),
	[7] = p0 + Vector(0,0,-300),
	[8] = p0 + Vector(212,0,-212)}

	for i=1,#points do
		if IsDangerousPosition(points[i]) == false and GetDistanceSqr(points[i], targetPos) < 500 * 500 then return points[i] end
	end
end


local function AntiGapCloser()
	local target = CountEnemyChampAroundObject(myHero(), 600)
	if IsCasting(myHero()) or CanCast(E) == false or Setting_IsComboUseE() == false or target == nil or target == 0 then return end
	local t = GetEnemies()
    for k,v in pairs(t) do
        if IsValidTarget(v, 550) then
        	if IsDashing(v) then
        		local dashFrom = Vector({GetPosX(v), GetPosY(v), GetPosZ(v)})
				local dashTo =  Vector({GetMoveDestPointPosX(v), GetMoveDestPointPosY(v), GetMoveDestPointPosZ(v)})
				if (myHeroPos - dashFrom) > (myHeroPos - dashTo) then
        			CastSpellTarget(v, E)
        			return
         		end
			end
        end
    end
end


--[[				--Placeholder
function Interrupt()
	if not Ready(_E) then return end
	local t = GetEnemies()
	for k,v in pairs(t) do
		local targetPos = Vector({GetPosX(v), GetPosY(v), GetPosZ(v)})
		if not IsDead(v) and IsEnemy(v) and GetDistanceSqr(targetPos, myHeroPos) < 550 * 550 then
			if IsCasting(v) then
				DelayAction(function()
					if IsCasting(v) and GetDistanceSqr(target.pos, myHeroPos) < 550 * 550 then
						CastSpellTarget(v, E)
					end
				end,0.5)
			end
		end
	end
end]]
local function StayInvisible()
	local var = GetBuffByName(myHero(), "vaynetumblefade")
	if (var == nil or var == 0) or EnemiesAround(myHero(), 350) == 0 then
		--__PrintTextGame("Enabled atk")
		SetLuaBasicAttackOnly(false)
		return
	end

	local t = GetEnemies()
    for k,v in pairs(t) do
    	if GetAttackRange(v) < 400 and IsValidTarget(v, 350) then
    		SetLuaBasicAttackOnly(true)
    		--__PrintTextGame("Disabled atk")
    		return
    	end
    end
end




-------------------------------------</Unique Functions>-------------------------------------



-------------------------------------<Main Script>-------------------------------------


local function Combo()
	local target = GetTarget(550)



	if IsValidTarget(target,550) == false or IsCasting(myHero()) then return end

	--if GetPercentHP(target) < 80 then
	--	BOTRK(target)
	--end

	if Setting_IsComboUseR() and EnemiesAround(myHero(), 800) >= 2 and CanCast(R) then

    	CastSpellToPos(GetCursorPosX(),GetCursorPosZ(),R)
    end

    if Setting_IsComboUseQ() and CanCast(Q) then
    	local qPos = GetSmartTumblePos(target)
    	if qPos ~= nil and IsAfterAttack() then
    		CastSpellToPos(qPos.x,qPos.z,Q)
     	end
    end

end

local function Harass()
	local target = GetTarget(550)
	if IsValidTarget(target,550) == false or IsCasting(myHero()) then return end


    if Setting_IsHarassUseQ() and CanCast(Q) then
    	local qPos = GetSmartTumblePos(target)
    	if qPos ~= nil and IsAfterAttack() then
    		CastSpellToPos(qPos.x,qPos.z, Q)
    	end
    end

    if Setting_IsHarassUseE() and CanCast(E) and SpellW.Count == 2 then
    	local eTarg = SpellW.Target
    	CastSpellTarget(eTarg, E)
    end


end

local function AutoCondemn()

	local target = CountEnemyChampAroundObject(myHero(), 600)

	if IsCasting(myHero()) or CanCast(E) == false or Setting_IsComboUseE() == false or target == nil or target == 0 then return end

	local t = GetEnemies()
    for k,v in pairs(t) do

        if IsValidTarget(v, 550) then

        	if IsCondemnable(v) then
        		CastSpellTarget(v, E)
         		break
			end
        end
    end
end


Callback.Add("Update", function()

	--__PrintTextGame(tostring(SpellW.Count))

	if IsDead(myHero()) then return end
	myHeroPos = Vector({GetPosX(myHero()), GetPosY(myHero()), GetPosZ(myHero())})
	mousePos = Vector({GetCursorPosX(myHero()), GetCursorPosY(myHero()), GetCursorPosZ(myHero())})
	UpdateBuff()

	StayInvisible()
	--AntiGapCloser()

	AutoCondemn()
	--KillSteal()


	if IsTyping() then return end --Wont Orbwalk while chatting
	local nKeyCode = GetKeyCode()
	--sleep(0.01)
	if nKeyCode == SpaceKeyCode then
		Combo()
	elseif nKeyCode == CKeyCode then
		SetLuaHarass(true)
		Harass()
	end
	--[[
	if nKeyCode == VKeyCode then
		LaneClear()
	end]]
end)


-------------------------------------</Main Script>-------------------------------------


