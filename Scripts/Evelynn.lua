local Player = function() return GetMyChamp() end

if GetChampName(Player()) ~= "Evelynn" then return end

-----------------------------------------------------------------

local Common = {}

Common.Print = function(msg)
	return __PrintTextGame("--> [Evelynn]: " .. msg)
end

Common.GetDistance = function(unit, source)
	local source = source or Player()

	local x1, z1 = GetPosX(source), GetPosZ(source)
	local x2, z2 = GetPosX(unit), GetPosZ(unit)

	return GetDistance2D(x1, z1, x2, z2)
end

Common.IsAllured = function(unit)
	return GetBuffByName(unit, "EvelynnW") ~= 0
end 

Common.IsFullAllured = function(unit)
	local buff = GetBuffTimeBegin(unit, "EvelynnW")
	if buff > 0 and buff + 2.5 <= GetTimeGame() then
		return true
	end
	return false
end

Common.IsQ1 = function()
	return GetSpellNameByIndex(Player(), 0) == "EvelynnQ"
end

Common.IsQ2 = function()
	return GetSpellNameByIndex(Player(), 0) == "EvelynnQ2"
end

-----------------------------------------------------------------

local Spell = {}

Spell.New = function(slot, type, range, delay, width, speed, collision)
	local this = {}

	this.slot = slot
	this.range = range or math.huge
	this.delay = delay or 0.25
	this.width = width or 0
	this.speed = speed or math.huge
	this.collision = collision or false
	this.type = type or 0

	this.IsReady = function()
		return CanCast(this.slot)
	end

	this.IsValidTarget = function(unit, range)
		local range = range or this.range

		if not IsDead(unit) and IsEnemy(unit) and not IsInFog(unit) and GetTargetableToTeam(unit) == 4 and Common.GetDistance(unit) <= range then
			return true
		end

		return false
	end

	this.GetCollisionCount = function(unit, distance)
		if not this.collision then return 0 end

		local PredPosX, PredPosZ = GetPredictionPosX(unit, distance), GetPredictionPosZ(unit, distance)
		local x1, z1 = GetPosX(Player()), GetPosZ(Player())
		local x2, z2 = GetPosX(unit), GetPosZ(unit)

		local minionCount = 0

		if PredPosX ~= 0 and PredPosZ ~= 0 then
			minionCount = CountObjectCollision(0, unit, x1, z1, PredPosX, PredPosZ, this.width, this.range, 10)
		else
			minionCount = CountObjectCollision(0, unit, x1, z1, x2, z2, this.width, this.range, 10)
		end

		return minionCount
	end

	this.CanCast = function(unit, distance)
		local distance = distance or this.range

		if this.collision then
			if this.IsValidTarget(unit, distance) and this.GetCollisionCount(unit, distance) == 0 then
				return true
			end
			return false
		end

		return this.IsValidTarget(unit)
	end

	this.VPGetCastPosition = function(unit)
		local distance = Common.GetDistance(unit)

		if this.type == 0 then
			local timeMissile = this.delay + distance / this.speed
			local realDistance = timeMissile * GetMoveSpeed(unit)
			if realDistance == 0 then return distance end
			return realDistance
		elseif this.type == 1 then
			local timeMissile = this.delay
			local realDistance = timeMissile * GetMoveSpeed(unit)
			if realDistance == 0 then
				if distance - this.width / 2 > 0 then
					return distance - this.width / 2
				end
				return distance
			end
			if realDistance - this.width / 2 > 0 then
				return realDistance - this.width / 2
			end
			return realDistance
		end
	end

	this.Cast = function(unit)
		if this.type > -1 then
			local distance = this.VPGetCastPosition(unit)

			if distance > 0 and distance < this.range then
				if this.collision then
					local collisionCount = this.GetCollisionCount(unit, distance)

					if collisionCount == 0 then
						CastSpellToPredictionPos(unit, this.slot, distance)
					end
				else
					CastSpellToPredictionPos(unit, this.slot, distance)
				end
			end
		elseif this.type == -1 then
			CastSpellTarget(unit, this.slot)
		elseif this.type == -2 then
			CastSpellTarget(unit, this.slot)
		end
	end

	return this
end

-----------------------------------------------------------------

local Q  = Spell.New(0, 0, 800, 0.25, 75, 1000, true)
local Q2 = Spell.New(0, -2, 550)
local W  = Spell.New(1, -1, 1200)
local E  = Spell.New(2, -1, 300)

local lastW = 0

-----------------------------------------------------------------

local function DoCombo(target)

	local Qrange = Common.IsQ1() and Q.range or Q2.range
	local Wdelay = Setting_IsComboUseW() and lastW + 0.25 + (GetLatency()/1000) or 0

	--W (Better use manually)
	if Setting_IsComboUseW() and W.IsReady() and W.CanCast(target) then
		W.Cast(target)
		lastW = GetTimeGame()
	end

	--Q
	if Setting_IsComboUseQ() and Q.IsReady() and Wdelay < GetTimeGame() then
		if Q.CanCast(target, Qrange) then
			if Common.IsAllured(target) then
				if Common.IsFullAllured(target) then
					Q.Cast(target)
				end
			else
				Q.Cast(target)
			end
		end
	end

	--E
	if Setting_IsComboUseE() and E.IsReady() and E.CanCast(target) and Wdelay < GetTimeGame() then
		if Common.IsAllured(target) then
			if Common.IsFullAllured(target) then
				E.Cast(target)
			end
		else
			E.Cast(target)
		end
	end
end	

-----------------------------------------------------------------

function OnTick()

	local target = GetEnemyChampCanKillFastest(1500)

	local key = GetKeyCode()

	if key == string.byte(" ") then
		SetLuaCombo(true)
		if target ~= 0 then
			DoCombo(target)
		end
	end
end

-----------------------------------------------------------------

Common.Print("Loaded (v1.0)")