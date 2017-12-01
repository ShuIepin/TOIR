local sdkPath = SCRIPT_PATH .. "\\Lib\\TOIR_SDK.lua"
local supportedChamps = { "Lucian", "Jayce", "Xayah", "Draven" }

local function PrintChat(msg)
	return __PrintTextGame("<b><font color=\"#ffffff\">[ShulepinAIO] </font></b> </font><font color=\"#c5eff7\"> " .. msg .. " </font><b><font color=\"#ffffff\"></font></b> </font>")
end

local function FileExists(path)
	local f = io.open(path, "r")

	if f then 
		io.close(f) 
		return true 
	else 
		return false 
	end
end

function OnLoad()
	if FileExists(sdkPath) then
		IncludeFile("Lib\\TOIR_SDK.lua")

		if SDK_VERSION and type(SDK_VERSION) == "number" then
			if SDK_VERSION == 0.1 then
				PrintChat("TOIR_SDK.lua loaded (v" .. SDK_VERSION .. ")")
			else
				PrintChat("You are used outdated TOIR_SDK.lua, please update it.")
				return
			end
		else
			PrintChat("Redownload TOIR_SDK.lua")
		end
	else
		function OnTick() end
		function OnUpdate() end
		function OnDraw() end
		function OnUpdateBuff(unit, buff, stacks) end
		function OnRemoveBuff(unit, buff) end
		function OnProcessSpell(unit, spell) end
		function OnCreateObject(unit) end
		function OnDeleteObject(unit) end
		function OnWndMsg(msg, key) end
		function OnDoCast(unit, spell) end
		function OnPlayAnimation(unit, anim) end
		PrintChat("TOIR_SDK.lua was not found.")
		return 
	end

	local enemyData = {}

	for i, enemy in pairs(GetEnemyHeroes()) do
		if enemy then
			if enemyData ~= {} then
				enemyData[GetId(enemy)] = { Addr = enemy, CharName = GetChampName(enemy), Id = GetId(enemy) }
			end
		end
	end

	ShulepinAIO_Lucian = class()
	ShulepinAIO_Jayce = class()
	ShulepinAIO_Xayah = class()
	ShulepinAIO_Draven = class()

	--Lucian

	function ShulepinAIO_Lucian:__init()
		--Disable inbuilt Lucian
		SetLuaCombo(true)

		--Main Menu
		self.menu = menuInst.addItem(SubMenu.new("Lucian", Lua_ARGB(255, 100, 250, 50)))

		--TS
		self.menu_ts = TargetSelector(1750, 1, myHero, true, self.menu, true)

		--Combo Menu
		self.menu_combo = self.menu.addItem(SubMenu.new("Combo"))
		self.menu_combo_q = self.menu_combo.addItem(MenuBool.new("Use Q", true))
		self.menu_combo_w = self.menu_combo.addItem(MenuBool.new("Use W", true))
		self.menu_combo_e = self.menu_combo.addItem(MenuBool.new("Use E", true))
		self.menu_combo_e_mode = self.menu_combo.addItem(MenuStringList.new("E Mode", { "Side  ", "Mouse", "Target " }, 1))
		self.menu_combo_prio = self.menu_combo.addItem(MenuStringList.new("Spell Priority", { "Q ", "W ", "E " }, 3))

		--Draw Menu
		self.menu_draw = self.menu.addItem(SubMenu.new("Drawings"))
		self.menu_draw_q = self.menu_draw.addItem(MenuBool.new("Draw Q Range", true))
		self.menu_draw_w = self.menu_draw.addItem(MenuBool.new("Draw W Range", true))
		self.menu_draw_e = self.menu_draw.addItem(MenuBool.new("Draw E Range", true))
		self.menu_draw_disable = self.menu_draw.addItem(MenuBool.new("Disable All Drawings", false))

		--Key Menu
		self.menu_key = self.menu.addItem(SubMenu.new("Keybinds"))
		self.menu_key_combo = self.menu_key.addItem(MenuKeyBind.new("Combo", 32))

		--Spells
		self.Q = Spell(_Q, 650)
		self.Q2 = Spell(_Q, 900)
		self.W = Spell(_W, 1000)
		self.E = Spell(_E, 425)

		self.Q:SetTargetted()
		self.Q2:SetTargetted()
		self.Q2.width = 25
		self.Q2.delay = 0.35
		self.W:SetSkillShot(0.30, 1600, 80, true)
		self.E:SetSkillShot()

		--Callbacks
		Callback.Add("DoCast", function(...) self:OnDoCast(...) end)
		Callback.Add("Draw", function(...) self:OnDraw(...) end)


		PrintChat("Lucian loaded.")
	end

	local ClosestToMouse = function(p1, p2) 
        	if GetDistance(GetMousePos(), p1) > GetDistance(GetMousePos(), p2) then return p2 else return p1 end
	end

	local RangeForE = function(target)
		return GetDistance(GetAIHero(target)) < GetTrueAttackRange() and 125 or 425
	end

	function ShulepinAIO_Lucian:CastE(target, mode, range)
		if mode == 1 then 
        		local c1, c2, r1, r2 = Vector(myHero), Vector(GetAIHero(target)), GetTrueAttackRange(), 525 
        		local O1, O2 = CircleCircleIntersection(c1, c2, r1, r2) 

        		if O1 or O2 then 
        			local pos = c1:Extended(Vector(ClosestToMouse(O1, O2)), range) 
        			self.E:CastToPos(pos)
        		end 
        	elseif mode == 2 then 
        		local pos = Vector(myHero):Extended(Vector(GetMousePos()), range)
        		self.E:CastToPos(pos) 
        	elseif mode == 3 then 
        		local pos = Vector(myHero):Extended(Vector(GetAIHero(target)), range) 
        		self.E:CastToPos(pos)
        	end 
	end

	function ShulepinAIO_Lucian:OnDoCast(unit, spell)
		if unit.IsMe and spell.Name:lower():find("attack") then
			local comboRotation = self.menu_combo_prio.getValue() - 1

			if self.menu_key_combo.getValue() then
				local enemy = enemyData[spell.TargetId]

				if enemy and enemy.Id == spell.TargetId then
					if self.menu_combo_q.getValue() and (comboRotation == 0 or not CanCast(comboRotation)) and self.Q:IsReady() then
						self.Q:Cast(enemy.Addr)
					elseif self.menu_combo_e.getValue() and (comboRotation == 2 or not CanCast(comboRotation)) and self.E:IsReady() then
						self:CastE(enemy.Addr, self.menu_combo_e_mode.getValue(), RangeForE(enemy.Addr))
					elseif self.menu_combo_w.getValue() and (comboRotation == 1 or not CanCast(comboRotation)) and self.W:IsReady() then
						self.W:Cast(enemy.Addr)
					end
				end
			end
		end
	end

	function ShulepinAIO_Lucian:OnDraw()
		if self.menu_draw_disable.getValue() then return end

        	if self.menu_draw_q.getValue() and CanCast(_Q) then
        		DrawCircleGame(myHero.x, myHero.y, myHero.z, self.Q.range, Lua_ARGB(255, 100, 100, 100))
        	end

        	if self.menu_draw_w.getValue() and CanCast(_W) then
        		DrawCircleGame(myHero.x, myHero.y, myHero.z, self.W.range, Lua_ARGB(255, 100, 100, 100))
        	end

        	if self.menu_draw_e.getValue() and CanCast(_E) then
        		DrawCircleGame(myHero.x, myHero.y, myHero.z, self.E.range, Lua_ARGB(255, 100, 100, 100))
        	end
	end

	--Jayce

	function ShulepinAIO_Jayce:__init()
		--Main Menu
		self.menu = menuInst.addItem(SubMenu.new("Jayce", Lua_ARGB(255, 100, 250, 50)))

		--TS
		self.menu_ts = TargetSelector(1750, 1, myHero, true, self.menu, true)

		--Draw Menu
		self.menu_draw = self.menu.addItem(SubMenu.new("Drawings"))
		self.menu_draw_qe = self.menu_draw.addItem(MenuBool.new("Draw QE Range", true))
		self.menu_draw_cd = self.menu_draw.addItem(MenuBool.new("Draw CD", true))
		self.menu_draw_disable = self.menu_draw.addItem(MenuBool.new("Disable All Drawings", false))

		--Key Menu
		self.menu_key = self.menu.addItem(SubMenu.new("Keybinds"))
		self.menu_key_combo = self.menu_key.addItem(MenuKeyBind.new("Combo", 32))

		self.Spells = {
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

        	Callback.Add("Tick", function(...) self:OnTick(...) end)
        	Callback.Add("Draw", function(...) self:OnDraw(...) end)
        	Callback.Add("ProcessSpell", function(...) self:OnProcessSpell(...) end)

        	PrintChat("Jayce loaded.")
	end

	function ShulepinAIO_Jayce:CD()
        	for i = 0, 3, 1 do
                	self.Spells.Range[i].T = self.Spells.Range[i].CDT + self.Spells.Range[i].CD - GetTimeGame()
                	self.Spells.Melee[i].T = self.Spells.Melee[i].CDT + self.Spells.Melee[i].CD - GetTimeGame()

                	if self.Spells.Range[i].T <= 0 and GetSpellLevel(myHero.Addr, i) > 0 then
                        	self.Spells.Range[i].Status = true
                        	self.Spells.Range[i].T = 0
               		else
                        	self.Spells.Range[i].Status = false
                	end

                	if self.Spells.Melee[i].T <= 0 and GetSpellLevel(myHero.Addr, i) > 0 then
                        	self.Spells.Melee[i].Status = true
                        	self.Spells.Melee[i].T = 0
                	else
                        	self.Spells.Melee[i].Status = false
                	end
        	end
	end

	function ShulepinAIO_Jayce:IsMelee()
        	return GetSpellNameByIndex(myHero.Addr, _Q) ~= "JayceShockBlast"
	end

	function ShulepinAIO_Jayce:Combo(target)
        	if target ~= 0 then
                	if not self:IsMelee() then
                        	if CanCast(_Q) and IsValidTarget(target, self.Spells.Range[_Q].RangeExt) then
                                	if CanCast(_E) then
                                        	local distance = VPGetLineCastPosition(target, self.Spells.Range[_Q].Delay, self.Spells.Range[_Q].SpeedExt)

                                        	if distance > 0 and distance < self.Spells.Range[_Q].RangeExt then
                                                	if not GetCollision(target, self.Spells.Range[_Q].Width, self.Spells.Range[_Q].RangeExt, distance) then
                                                        	CastSpellToPredictionPos(target, _Q, distance)
                                                	end
                                        	end
                                	else
                                        	local distance = VPGetLineCastPosition(target, self.Spells.Range[_Q].Delay, self.Spells.Range[_Q].Speed)

                                        	if distance > 0 and distance < self.Spells.Range[_Q].Range then
                                                	if not GetCollision(target, self.Spells.Range[_Q].Width, self.Spells.Range[_Q].Range, distance) then
                                                        	CastSpellToPredictionPos(target, _Q, distance)
                                                	end
                                        	end
                                	end
                        	end

                        	if CanCast(_W) and IsValidTarget(target, GetTrueAttackRange() + 150) then
                               		CastSpellTarget(myHero.Addr, _W)
                        	end

                        	if CanCast(_R) and not CanCast(_Q) and not CanCast(_W) and self.Spells.Melee[_Q].Status == true and GetDistance(GetOrigin(target)) <= self.Spells.Melee[_Q].Range then
                                	CastSpellTarget(myHero.Addr, _R)
                        	end
                	else
                        	if CanCast(_Q) and IsValidTarget(target, self.Spells.Melee[_Q].Range) then
                                	CastSpellTarget(target, _Q)
                        	end

                        	if CanCast(_W) and IsValidTarget(target, self.Spells.Melee[_W].Range) then
                                	CastSpellTarget(myHero.Addr, _W)
                        	end

                        	if CanCast(_E) and IsValidTarget(target, self.Spells.Melee[_E].Range) and GetBuffStack(myHero.Addr, "JayceHyperCharge") < 1 then
                                	CastSpellTarget(target, _E)
                        	end

                        	if CanCast(_R) then
                                	if not CanCast(_Q) and not CanCast(_W) and self.Spells.Range[_Q].Status == true and (self.Spells.Range[_W].Status == true or self.Spells.Range[_E].Status == true) then
                                        	CastSpellTarget(myHero.Addr, _R)
                                	end

                                	if not CanCast(_Q) and not CanCast(_W) and not CanCast(_E) then
                                        	CastSpellTarget(myHero.Addr, _R)
                                	end 
                        	end
                	end
        	end
	end

	function ShulepinAIO_Jayce:OnTick()
		self:CD()

		local target = self.menu_ts:GetTarget()

		if self.menu_key_combo.getValue() then
			self:Combo(target)
		end
	end

	function ShulepinAIO_Jayce:OnDraw()
		if self.menu_draw_disable.getValue() then return end

		if self.menu_draw_cd.getValue() then
			local pos = WorldToScreenPos(myHero.x, myHero.y, myHero.z)

        		if self:IsMelee() then
                		for i = 0, 3, 1 do
                        		local slot = ({ [_Q] = "Q", [_W] = "W", [_E] = "E", [_R] = "R" })[i]
                        		local color = self.Spells.Range[i].Status == true and Lua_ARGB(255, 0, 255, 10) or Lua_ARGB(255, 255, 0, 0)
                        		DrawTextD3DX(pos.x - 60 + (i * 40), pos.y + 50, slot .. ": " .. tostring(math.round(self.Spells.Range[i].T > 0 and self.Spells.Range[i].T or 0)), color)
                		end
        		else
                		for i = 0, 3, 1 do
                        		local slot = ({ [_Q] = "Q", [_W] = "W", [_E] = "E", [_R] = "R" })[i]
                        		local color = self.Spells.Melee[i].Status == true and Lua_ARGB(255, 0, 255, 10) or Lua_ARGB(255, 255, 0, 0)
                        		DrawTextD3DX(pos.x - 60 + (i * 40), pos.y + 50, slot .. ": " .. tostring(math.round(self.Spells.Melee[i].T > 0 and self.Spells.Melee[i].T or 0)), color)
                		end
        		end
        	end

        	if self.menu_draw_qe.getValue() then
        		if CanCast(_Q) and CanCast(_E) and not self:IsMelee() then
        			DrawCircleGame(myHero.x, myHero.y, myHero.z, 1750, Lua_ARGB(255, 100, 100, 100))
        		end
        	end
	end

	function ShulepinAIO_Jayce:OnProcessSpell(unit, spell)
		if unit.IsMe then
                	for i = 0, 3, 1 do
                        	if spell.Name == self.Spells.Range[i].Name then 
                                	self.Spells.Range[i].CDT = GetTimeGame()
                        	end
                	end

                	for i = 0, 3, 1 do
                        	if spell.Name == self.Spells.Melee[i].Name then 
                                	self.Spells.Melee[i].CDT = GetTimeGame()
                        	end
                	end

                	if self.menu_key_combo.getValue() then
                        	if spell.Name == "JayceShockBlast" then
                                	local gatePos = Vector(myHero.x, myHero.y, myHero.z):Extended(Vector(spell.DestPos_x, spell.DestPos_y, spell.DestPos_z), 300 + (GetPing()/2))
                                	if gatePos then
                                        	if CanCast(_E) then
                                                	DelayAction(function() CastSpellToPos(gatePos.x, gatePos.z, _E) end, spell.Delay + (GetPing() / 2))
                                        	end
                                	end
                        	end
                	end
        	end
	end

	-- Xayah

	function ShulepinAIO_Xayah:__init()
		--Main Menu
		self.menu = menuInst.addItem(SubMenu.new("Xayah", Lua_ARGB(255, 100, 250, 50)))

		--TS
		self.menu_ts = TargetSelector(1500, 1, myHero, true, self.menu, true)

		--Combo
		self.menu_combo = self.menu.addItem(SubMenu.new("Combo"))
		self.menu_combo_q = self.menu_combo.addItem(MenuBool.new("Use Q", true))
		self.menu_combo_w = self.menu_combo.addItem(MenuBool.new("Use W", true))
		self.menu_combo_e = self.menu_combo.addItem(MenuBool.new("Use E", true))

		--Draw
		self.menu_draw = self.menu.addItem(SubMenu.new("Drawings"))
		self.menu_draw_disable = self.menu_draw.addItem(MenuBool.new("Disable All Drawings", false))
		self.menu_draw_feathers = self.menu_draw.addItem(MenuBool.new("Draw Feathers", true))

		--Keys
		self.menu_key = self.menu.addItem(SubMenu.new("Keys"))
		self.menu_key_combo = self.menu_key.addItem(MenuKeyBind.new("Combo Key", 32))

		self.Q = Spell(_Q, 1075)
		self.W = Spell(_W, 1000)
		self.E = Spell(_E, 1075)
		self.Q:SetSkillShot(0.25, 2000, 75, false)
		self.W:SetActive()
		self.E:SetActive()
		self.E.width = 85

		self.Feathers = {}
		self.EnemyData = {}

		Callback.Add("Tick", function() self:OnTick() end)
		Callback.Add("Draw", function() self:OnDraw() end)
		Callback.Add("CreateObject", function(...) self:OnCreateObject(...) end)
		Callback.Add("DeleteObject", function(...) self:OnDeleteObject(...) end)

		PrintChat("Xayah loaded.")
	end

	function ShulepinAIO_Xayah:RootLogic(target, obj)
		local target = GetAIHero(target)
		local myHeroVector = Vector(myHero.x, myHero.y, myHero.z)
		local targetVector = Vector(target.x, target.y, target.z)
		local objVector = Vector(obj.x, obj.y, obj.z)
		local distanceToObj = myHeroVector:DistanceTo(objVector)
		local endPos = myHeroVector:Extended(objVector, distanceToObj)

		local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(myHeroVector, endPos, targetVector)
		local pointSegmentVector = Vector(pointSegment.x, targetVector.y, pointSegment.z)

		if isOnSegment and targetVector:DistanceTo(pointSegmentVector) <= self.E.width * 1.5 then
        		return true
    		end

    		return false
	end

	function ShulepinAIO_Xayah:FeathersHitCount(target)
		local count = 0

		for i, feather in pairs(self.Feathers) do
			if feather and self:RootLogic(target, feather) then
				count = count + 1
			end
		end

		return count
	end

	function ShulepinAIO_Xayah:CastQ(target)
		if self.Q:IsReady() and IsValidTarget(target, self.Q.range) then
			self.Q:Cast(target)
		end
	end

	function ShulepinAIO_Xayah:CastW(target)
		if self.W:IsReady() and IsValidTarget(target, self.W.range) then
			self.W:Cast(target)
		end
	end

	function ShulepinAIO_Xayah:CastE(target)
		if self.E:IsReady() and IsValidTarget(target, self.E.range) and self:FeathersHitCount(target) > 2 then
			self.E:Cast(target)
		end
	end

	function ShulepinAIO_Xayah:Combo(target)
		if self.menu_combo_q.getValue() then
			self:CastQ(target)
		end

		if self.menu_combo_w.getValue() then
			self:CastW(target)
		end

		if self.menu_combo_e.getValue() then
			self:CastE(target)
		end
	end

	function ShulepinAIO_Xayah:OnTick()
		local target = self.menu_ts:GetTarget()

		if self.menu_key_combo.getValue() then
			if target ~= 0 then
				self:Combo(target)
			end
		end
	end

	function ShulepinAIO_Xayah:OnDraw()
		if self.menu_draw_disable.getValue() then return end

		if self.menu_draw_feathers.getValue() then
			for i, feather in pairs(self.Feathers) do
				local pos = Vector(feather.x, feather.y, feather.z)
				DrawCircleGame(pos.x, pos.y, pos.z, 100, Lua_ARGB(100, 255, 255, 255))

				local x, y, z = pos.x, pos.y, pos.z
				local p1X, p1Y = WorldToScreen(x, y, z)
	        		local p2X, p2Y = WorldToScreen(myHero.x, myHero.y, myHero.z)
	        		DrawLineD3DX(p1X, p1Y, p2X, p2Y, 2, Lua_ARGB(100, 255, 255, 255))
			end
		end

		--[[

		GetAllObjectAroundAnObject(myHero.Addr, 2000)
		local fObjects = pObject
		for i, object in pairs(fObjects) do
			if object ~= 0 then
				local missile = GetMissile(object)

				if missile and missile.Type == 6 and missile.TargetId == 0 then
					for i, enemy in pairs(GetEnemyHeroes()) do
						local enemy = GetAIHero(enemy)
						local data = self.EnemyData[missile.OwnerId]

						if data then
							local startPos = Vector(missile.x, myHero.y, missile.z)
							local endPos = Vector(missile.DestPos_x, myHero.y, missile.DestPos_z)
							--local realEndPos = startPos:Extended(endPos, missile.Range)

							DrawLineGame(startPos.x, startPos.y, startPos.z, endPos.x, endPos.y, endPos.z, missile.Width)

							--local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(startPos, endPos, myHero)
						end
					end
				end
			end
		end]]
	end

	function ShulepinAIO_Xayah:OnCreateObject(obj)
		if string.find(obj.Name, "Passive_Dagger_indicator8s") and obj.IsValid and not IsDead(obj.Addr) then
			self.Feathers[#self.Feathers + 1] = obj
		end
	end

	function ShulepinAIO_Xayah:OnDeleteObject(obj)
		for i, feather in pairs(self.Feathers) do
			if feather.Addr == obj.Addr then
				table.remove(self.Feathers, i)
			end 
		end
	end

	--Draven

	function ShulepinAIO_Draven:__init()
	        --Main Menu
		self.menu = menuInst.addItem(SubMenu.new("Draven", Lua_ARGB(255, 100, 250, 50)))

		--TS
		self.menu_ts = TargetSelector(1500, 1, myHero, true, self.menu, true)

		--Combo
		self.menu_combo = self.menu.addItem(SubMenu.new("Combo"))
		self.menu_combo_q = self.menu_combo.addItem(MenuBool.new("Use Q", true))
		self.menu_combo_q_catch = self.menu_combo.addItem(MenuBool.new("Catch Q", true))
		self.menu_combo_q_range = self.menu_combo.addItem(MenuSlider.new("Catch Range", 500, 100, 1500, 10))
		self.menu_combo_w = self.menu_combo.addItem(MenuBool.new("Use W", true))
		self.menu_combo_e = self.menu_combo.addItem(MenuBool.new("Use E", true))

		--Draw
		self.menu_draw = self.menu.addItem(SubMenu.new("Drawings"))
		self.menu_draw_disable = self.menu_draw.addItem(MenuBool.new("Disable All Drawings", false))
		self.menu_draw_catch = self.menu_draw.addItem(MenuBool.new("Draw Catch Pos", true))

		--Keys
		self.menu_key = self.menu.addItem(SubMenu.new("Keys"))
		self.menu_key_combo = self.menu_key.addItem(MenuKeyBind.new("Combo Key", 32))

		--Spells
	        self.Q = Spell(_Q, GetTrueAttackRange())
	        self.Q:SetActive()
	        self.W = Spell(_W, 0)
	        self.W:SetActive()
	        self.E = Spell(_E, 1050)
	        self.E:SetSkillShot(0.25, 1400, 130, false)
	        self.R = Spell(_R, 15000)
	        self.R:SetSkillShot(0.4, 2000, 160, false)

	        self.Axes = {}

	        Callback.Add("Tick", function(...) self:OnTick(...) end)
	        Callback.Add("Draw", function(...) self:OnDraw(...) end)
	        Callback.Add("CreateObject", function(...) self:OnCreateObject(...) end)
	        Callback.Add("DeleteObject", function(...) self:OnDeleteObject(...) end)

	        PrintChat("Draven loaded.")
	end

	function ShulepinAIO_Draven:BestAxe()
	        local BestAxe = nil
	        local distance = 0

	        for i, Axe in pairs(self.Axes) do
	                if Axe then
	                        local axePos = GetOrigin(Axe)

	                        if GetDistance(GetMousePos()) <= self.menu_combo_q_range.getValue() and distance < GetDistance(axePos) then
	                                BestAxe = Axe
	                                distance = GetDistance(axePos)
	                        end
	                end
	        end

	        return BestAxe
	end

	function ShulepinAIO_Draven:Orbwalk(target)
	        if target then
	                local attackRange = GetTrueAttackRange()

	                if GetDistance(GetOrigin(target)) <= attackRange and IsValidTarget(target, attackRange) then
	                        if CanAttack() then
	                                BasicAttack(target)
	                        end

	                        if CanMove() and not CanAttack() then
	                                if self:BestAxe() and self.menu_combo_q_catch.getValue() then
	                                        local axe = Vector(GetOrigin(self:BestAxe()))
	                                        MoveToPos(axe.x, axe.z)
	                                else
	                                        MoveToPos(GetMousePos().x, GetMousePos().z)
	                                end
	                        end
	                else
	                        if CanMove() then
	                                if self:BestAxe() and self.menu_combo_q_catch.getValue() then
	                                        local axe = Vector(GetOrigin(self:BestAxe()))
	                                        MoveToPos(axe.x, axe.z)
	                                else
	                                        MoveToPos(GetMousePos().x, GetMousePos().z)
	                                end
	                        end
	                end
	        end
	end

	function ShulepinAIO_Draven:Combo(target)
	        if target ~= 0 then
	                if self.menu_combo_q.getValue() and self.Q:IsReady() and IsValidTarget(target, GetTrueAttackRange()) and GetBuffStack(myHero.Addr, "DravenSpinningAttack") < 2 then
	                        self.Q:Cast()
	                end

	                if self.menu_combo_w.getValue() and self.W:IsReady() and IsValidTarget(target, GetTrueAttackRange()) and GetBuffStack(myHero.Addr, "dravenfurybuff") < 1 then
	                        self.W:Cast()
	                end

	                if self.menu_combo_e.getValue() and self.E:IsReady() and IsValidTarget(target, self.E.range) then
	                        self.E:Cast(target)
	                end
	        end
	end

	function ShulepinAIO_Draven:OnTick()
	        local target = self.menu_ts:GetTarget()

	        if self.menu_key_combo.getValue() then
	                self:Orbwalk(target)
	                self:Combo(target)
	                SetLuaCombo(true)
	                SetLuaBasicAttackOnly(true)
	                SetLuaMoveOnly(true)
	        else
	                SetLuaCombo(false)
	                SetLuaBasicAttackOnly(false)
	                SetLuaMoveOnly(false)
	        end
	end

	function ShulepinAIO_Draven:OnDraw()
		if self.menu_draw_disable.getValue() then return end

		if self.menu_draw_catch.getValue() then
		        for i, Axe in pairs(self.Axes) do
		                local axeVector = Vector(GetOrigin(Axe))
		                local color = GetDistance(axeVector) <= 100 and Lua_ARGB(255, 255, 0, 0) or Lua_ARGB(255, 255, 255, 255)
		                
		                if axeVector and not IsDead(Axe) then
		                        Draw:Circle3D(axeVector.x, axeVector.y, axeVector.z, 100, 1, 10, color)
		                end
		        end

		        if self:BestAxe() then
		                local axe = Vector(GetOrigin(self:BestAxe()))
		                Draw:Line3D(myHero.x, myHero.y, myHero.z, axe.x, axe.y, axe.z, 1, Lua_ARGB(255, 255, 255, 0))
		        end

		        Draw:Circle3D(GetMousePos().x, GetMousePos().y, GetMousePos().z, self.menu_combo_q_range.getValue(), 1, 20, Lua_ARGB(100, 255, 255, 255))
		end
	end

	function ShulepinAIO_Draven:OnCreateObject(obj)
	        if string.find(obj.Name, "reticle_self") then
	                self.Axes[#self.Axes + 1] = obj 
	        end
	end

	function ShulepinAIO_Draven:OnDeleteObject(obj)
	        for i, Axe in pairs(self.Axes) do
	                if Axe.Addr == obj.Addr then
	                        table.remove(self.Axes, i) 
	                end
	        end
	end

	if table.contains(supportedChamps, myHero.CharName) then
		if _G["ShulepinAIO_" .. myHero.CharName] then
			_G["ShulepinAIO_" .. myHero.CharName]()
		end
	end

	menuInstSep.setValue("ShulepinAIO")
	menuInst.addItem(MenuSeparator.new("   Script Info", true))
	menuInst.addItem(MenuSeparator.new("Script Version: 1.17"))
	menuInst.addItem(MenuSeparator.new("LoL Version: 7.23"))
end
