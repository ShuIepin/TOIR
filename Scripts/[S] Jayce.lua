IncludeFile("Lib\\TOIR_SDK.lua")

SetLuaCombo(true)
SetLuaHarass(true)
SetLuaLaneClear(true)

local comboKey = string.byte("Z") 
local qeKey = string.byte("T") 
local qeToMouseKey = string.byte("G")

local Spells = {
	["Range"] = {
		[_Q] = { CD = GetCDSpell(myHero.Addr, _Q) == 0 and 8 or GetCDSpell(myHero.Addr, _Q), CDT = 0, T = 0, Name = "JayceShockBlast", Status = false, Range = 1150, RangeExt = 1750, Speed = 1300, SpeedExt = 2350, Delay = 0.15, Width = 70 },
		[_W] = { CD = GetCDSpell(myHero.Addr, _W) == 0 and 13 or GetCDSpell(myHero.Addr, _W), CDT = 0, T = 0, Name = "JayceHyperCharge", Status = false },
		[_E] = { CD = GetCDSpell(myHero.Addr, _E) == 0 and 16 or GetCDSpell(myHero.Addr, _E), CDT = 0, T = 0, Name = "JayceAccelerationGate", Status = false },
		[_R] = { CD = GetCDSpell(myHero.Addr, _R) == 0 and 6 or GetCDSpell(myHero.Addr, _R), CDT = 0, T = 0, Name = "JayceStanceGtH", Status = false }
	},
	["Melee"] = {
		[_Q] = { CD = GetCDSpell(myHero.Addr, _Q) == 0 and 16 or GetCDSpell(myHero.Addr, _Q), CDT = 0, T = 0, Name = "JayceToTheSkies", Status = false, Range = 600 },
		[_W] = { CD = GetCDSpell(myHero.Addr, _W) == 0 and 10 or GetCDSpell(myHero.Addr, _W), CDT = 0, T = 0, Name = "JayceStaticField", Status = false, Range = 350 },
		[_E] = { CD = GetCDSpell(myHero.Addr, _E) == 0 and 15 or GetCDSpell(myHero.Addr, _E), CDT = 0, T = 0, Name = "JayceThunderingBlow", Status = false, Range = 250 },
		[_R] = { CD = GetCDSpell(myHero.Addr, _R) == 0 and 6 or GetCDSpell(myHero.Addr, _R), CDT = 0, T = 0, Name = "JayceStanceHtG", Status = false }
	}
}

local function CD()
	for i = 0, 3, 1 do
		Spells.Range[i].T = Spells.Range[i].CDT + Spells.Range[i].CD - GetTimeGame()
		Spells.Melee[i].T = Spells.Melee[i].CDT + Spells.Melee[i].CD - GetTimeGame()

		if Spells.Range[i].T <= 0 and GetSpellLevel(myHero.Addr, i) > 0 then
			Spells.Range[i].Status = true
			Spells.Range[i].T = 0
		else
			Spells.Range[i].Status = false
		end

		if Spells.Melee[i].T <= 0 and GetSpellLevel(myHero.Addr, i) > 0 then
			Spells.Melee[i].Status = true
			Spells.Melee[i].T = 0
		else
			Spells.Melee[i].Status = false
		end
	end
end

local function IsMelee()
	return GetSpellNameByIndex(myHero.Addr, _Q) ~= "JayceShockBlast"
end

local function Orbwalk(target)
	if target then
		local attackRange = GetTrueAttackRange()

		if GetDistance(GetOrigin(target)) <= attackRange and IsValidTarget(target, attackRange) then
			if CanAttack() then
				BasicAttack(target)
			end

			if CanMove() and not CanAttack() then
				MoveToPos(GetMousePos().x, GetMousePos().z)
			end
		else
			if CanMove() then
				MoveToPos(GetMousePos().x, GetMousePos().z)
			end
		end
	end
end

local function Combo(target)
	if target ~= 0 then
		if not IsMelee() then
			if CanCast(_Q) and IsValidTarget(target, Spells.Range[_Q].RangeExt) then
				if CanCast(_E) then
					local distance = VPGetLineCastPosition(target, Spells.Range[_Q].Delay, Spells.Range[_Q].SpeedExt)

					if distance > 0 and distance < Spells.Range[_Q].RangeExt then
						if not GetCollision(target, Spells.Range[_Q].Width, Spells.Range[_Q].RangeExt, distance) then
							CastSpellToPredictionPos(target, _Q, distance)
						end
					end
				else
					local distance = VPGetLineCastPosition(target, Spells.Range[_Q].Delay, Spells.Range[_Q].Speed)

					if distance > 0 and distance < Spells.Range[_Q].Range then
						if not GetCollision(target, Spells.Range[_Q].Width, Spells.Range[_Q].Range, distance) then
							CastSpellToPredictionPos(target, _Q, distance)
						end
					end
				end
			end

			if CanCast(_W) and IsValidTarget(target, GetTrueAttackRange() + 150) then
				CastSpellTarget(myHero.Addr, _W)
			end

			if CanCast(_R) and not CanCast(_Q) and not CanCast(_W) and Spells.Melee[_Q].Status == true and GetDistance(GetOrigin(target)) <= Spells.Melee[_Q].Range then
				CastSpellTarget(myHero.Addr, _R)
			end
		else
			if CanCast(_Q) and IsValidTarget(target, Spells.Melee[_Q].Range) then
				CastSpellTarget(target, _Q)
			end

			if CanCast(_W) and IsValidTarget(target, Spells.Melee[_W].Range) then
				CastSpellTarget(myHero.Addr, _W)
			end

			if CanCast(_E) and IsValidTarget(target, Spells.Melee[_E].Range) and GetBuffCount(myHero.Addr, "JayceHyperCharge") < 1 then
				CastSpellTarget(target, _E)
			end

			if CanCast(_R) then
				if not CanCast(_Q) and not CanCast(_W) and Spells.Range[_Q].Status == true and (Spells.Range[_W].Status == true or Spells.Range[_E].Status == true) then
					CastSpellTarget(myHero.Addr, _R)
				end

				if not CanCast(_Q) and not CanCast(_W) and not CanCast(_E) then
					CastSpellTarget(myHero.Addr, _R)
				end 
			end
		end
	end
end

local function QE(target)
	if target ~= 0 then
		if CanMove() then
			MoveToPos(GetMousePos().x, GetMousePos().z)
		end

		if not IsMelee() then
			if CanCast(_Q) and CanCast(_E) and IsValidTarget(target, Spells.Range[_Q].RangeExt) then
				local distance = VPGetLineCastPosition(target, Spells.Range[_Q].Delay, Spells.Range[_Q].SpeedExt)

				if distance > 0 and distance < Spells.Range[_Q].RangeExt then
					if not GetCollision(target, Spells.Range[_Q].Width, Spells.Range[_Q].RangeExt, distance) then
						CastSpellToPredictionPos(target, _Q, distance)
					end
				end
			end
		end
	end
end

local function QE_ToMouse()
	if CanMove() then
		MoveToPos(GetMousePos().x, GetMousePos().z)
	end

	if not IsMelee() then
		if CanCast(_Q) and CanCast(_E) then
			CastSpellToPos(GetMousePos().x, GetMousePos().z, _Q)
		end
	end
end

Callback.Add("Update", function()
	CD()

	local nKeyCode = GetKeyCode()
	local target = GetEnemyChampCanKillFastest(1800)

	if nKeyCode == comboKey then
		Orbwalk(target)
		Combo(target)
	end

	if nKeyCode == qeKey then
		QE(target)
	end

	if nKeyCode == qeToMouseKey then
		QE_ToMouse()
	end
end)

Callback.Add("Draw", function()
	local pos = WorldToScreen(myHero.x, myHero.y, myHero.z)

	if IsMelee() then
		for i = 0, 3, 1 do
			local slot = ({ [_Q] = "Q", [_W] = "W", [_E] = "E", [_R] = "R" })[i]
			local color = Spells.Range[i].Status == true and Lua_ARGB(255, 0, 255, 10) or Lua_ARGB(255, 255, 0, 0)
			DrawTextD3DX(pos.x - 60 + (i * 40), pos.y + 50, slot .. ": " .. tostring(math.round(Spells.Range[i].T > 0 and Spells.Range[i].T or 0)), color)
		end
	else
		for i = 0, 3, 1 do
			local slot = ({ [_Q] = "Q", [_W] = "W", [_E] = "E", [_R] = "R" })[i]
			local color = Spells.Melee[i].Status == true and Lua_ARGB(255, 0, 255, 10) or Lua_ARGB(255, 255, 0, 0)
			DrawTextD3DX(pos.x - 60 + (i * 40), pos.y + 50, slot .. ": " .. tostring(math.round(Spells.Melee[i].T > 0 and Spells.Melee[i].T or 0)), color)
		end
	end
end)

Callback.Add("ProcessSpell", function(unit, spell)
	if unit == myHero.Addr then
		for i = 0, 3, 1 do
			if spell.name == Spells.Range[i].Name then 
				Spells.Range[i].CDT = GetTimeGame()
			end
    		end

    		for i = 0, 3, 1 do
			if spell.name == Spells.Melee[i].Name then 
				Spells.Melee[i].CDT = GetTimeGame()
			end
    		end

    		local nKeyCode = GetKeyCode()

    		if nKeyCode == comboKey or nKeyCode == qeKey or nKeyCode == qeToMouseKey then
    			if spell.name == "JayceShockBlast" then
    				local gatePos = Vector(myHero.x, myHero.y, myHero.z):Extend(spell.endPos, 300 + (GetPing()/2))
				if gatePos then
					if CanCast(_E) then
						DelayAction(function() CastSpellToPos(gatePos.x, gatePos.z, _E) end, spell.delay + (GetPing()/2))
					end
				end
    			end
    		end
	end
end)

print("[S] Jayce Loaded! (v1.0)")
