local sdkPath = SCRIPT_PATH .. "\\Lib\\TOIR_SDK.lua"
local supportedChamps = { "Lucian", "Jayce", "Xayah", "Draven", "Fiora" } --"Yasuo"

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
			if SDK_VERSION == 0.3 then
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
	ShulepinAIO_Fiora = class()
	ShulepinAIO_Yasuo = class()

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
		self.menu_combo_e_mode = self.menu_combo.addItem(MenuStringList.new("E Mode", { "Side  ", "Target", "Mouse " }, 1))
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
		self.SpellData = {
			["Aatrox"] = {
				["aatroxeconemissile"] = {slot = 2, danger = 2, name = "Blade of Torment", isSkillshot = true}
			},
			["Ahri"] = {
				["ahriorbmissile"] = { slot = 0, danger = 3, name = "Orb of Deception", isSkillshot = true },
				["ahrifoxfiremissiletwo"] = {slot = 1, danger = 2, name = "Fox-Fire", isSkillshot = false},
				["ahriseducemissile"] = {slot = 2, danger = 4, name = "Charm", isSkillshot = true},
				["ahritumblemissile"] = {slot = 3, danger = 2, name = "SpiritRush", isSkillshot = false}
			},
			["Akali"] = {
				["akalimota"] = {slot = 0, danger = 2, name = "Mark of the Assasin", isSkillshot = false}
			},
			["Amumu"] = {
				["sadmummybandagetoss"] = {slot = 0, danger = 4, name = "Bandage Toss", isSkillshot = true}
			},
			["Anivia"] = {
				["flashfrostspell"] = {slot = 0, danger = 2, name = "Flash Frost", isSkillshot = true},
				["frostbite"] = {slot = 2, danger = 3, name = "Frostbite", isSkillshot = false}
			},
			["Annie"] = {
				["disintegrate"] = {slot = 0, danger = 3, name = "Disintegrate", isSkillshot = false}
			},
			["Ashe"] = {
				["volleyattack"] = {slot = 1, danger = 2, name = "Volley", isSkillshot = true},
				["enchantedcrystalarrow"] = {slot = 3, danger = 5, name = "Enchanted Crystal Arrow", isSkillshot = true}
			},
			["AurelionSol"] = {
				["aurelionsolqmissile"] = {slot = 0, danger = 2, name = "Starsurge", isSkillshot = true}
			},
			["Bard"] = {
				["bardqmissile"] = {slot = 0, danger = 4, name = "Cosmic Binding", isSkillshot = true}
			},
			["Blitzcrank"] = {
				["rocketgrabmissile"] = {slot = 0, danger = 5, name = "Rocket Grab", isSkillshot = true}
			},
			["Brand"] = {
				["brandqmissile"] = {slot = 0, danger = 3, name = "Sear", isSkillshot = true},
				["brandr"] = {slot = 3, danger = 5, name = "Pyroclasm", isSkillshot = false}
			},
			["Braum"] = {
				["braumqmissile"] = {slot = 0, danger = 3, name = "Winter's Bite", isSkillshot = true},
				["braumrmissile"] = {slot = 3, danger = 5, name = "Glacial Fissure", isSkillshot = true}
			},
			["Caitlyn"] = {
				["caitlynpiltoverpeacemaker"] = {slot = 0, danger = 2, name = "Piltover Peacemaker", isSkillshot = true},
				["caitlynaceintheholemissile"] = {slot = 3, danger = 4, name = "Ace in the Hole", isSkillshot = false}
			},
			["Cassiopeia"] = {
				["cassiopeiatwinfang"] = {slot = 2, danger = 2, name = "Twin Fang", isSkillshot = false}
			},
			["Corki"] = {
				["phosphorusbombmissile"] = {slot = 0, danger = 2, name = "Phosphorus Bomb", isSkillshot = true},
				["missilebarragemissile"] = {slot = 3, danger = 2, name = "Missile Barrage", isSkillshot = true},
				["missilebarragemissile2"] = {slot = 3, danger = 2, name = "Big Missile Barrage", isSkillshot = true}
			},
			["Diana"] = {
				["dianaarcthrow"] = {slot = 0, danger = 2, name = "Crescent Strike", isSkillshot = true}
			},
			["DrMundo"] = {
				["infectedcleavermissile"] = {slot = 0, danger = 2, name = "Infected Cleaver", isSkillshot = true}
			},
			["Draven"] = {
				["dravenr"] = {slot = 3, danger = 4, name = "Whirling Death", isSkillshot = true}
			},
			["Ekko"] = {
				["ekkoqmis"] = {slot = 0, danger = 2, name = "Timewinder", isSkillshot = true}
			},
			["Elise"] = {
				["elisehumanq"] = {slot = 0, danger = 3, name = "Neurotoxin", isSkillshot = false},
				["elisehumane"] = {slot = 2, danger = 4, name = "Cocoon", isSkillshot = true}
			},
			["Ezreal"] = {
				["ezrealmysticshotmissile"] = {slot = 0, danger = 2, name = "Mystic Shot", isSkillshot = true},
				["ezrealessencefluxmissile"] = {slot = 1, danger = 2, name = "Essence Flux", isSkillshot = true},
				["ezrealarcaneshiftmissile"] = {slot = 2, danger = 1, name = "Arcane Shift", isSkillshot = false},
				["ezrealtrueshotbarrage"] = {slot = 3, danger = 4, name = "Trueshot Barrage", isSkillshot = true}
			},
			["FiddleSticks"] = {
				["fiddlesticksdarkwindmissile"] = {slot = 2, danger = 3, name = "Dark Wind", isSkillshot = false}
			},
			["Gangplank"] = {
				["parley"] = {slot = 0, danger = 2, name = "Parley", isSkillshot = false}
			},
			["Gnar"] = {
				["gnarqmissile"] = {slot = 0, danger = 2, name = "Boomerang Throw", isSkillshot = true},
				["gnarbigqmissile"] = {slot = 0, danger = 3, name = "Boulder Toss", isSkillshot = true}
			},
			["Gragas"] = {
				["gragasqmissile"] = {slot = 0, danger = 2, name = "Barrel Roll", isSkillshot = true},
				["gragasrboom"] = {slot = 3, danger = 4, name = "Explosive Cask", isSkillshot = true}
			},
			["Graves"] = {
				["gravesqlinemis"] = {slot = 0, danger = 2, name = "End of the Line", isSkillshot = true},
				["graveschargeshotshot"] = {slot = 3, danger = 4, name = "Collateral Damage", isSkillshot = true}
			},
			["Illaoi"] = {
				["illaoiemis"] = {slot = 2, danger = 3, name = "Test of Spirit", isSkillshot = true}
			},
			["Irelia"] = {
				["IreliaTranscendentBlades"] = {slot = 3, danger = 2, name = "Transcendent Blades", isSkillshot = true}
			},
			["Janna"] = {
				["howlinggalespell"] = {slot = 0, danger = 1, name = "Howling Gale", isSkillshot = true},
				["sowthewind"] = {slot = 1, danger = 2, name = "Zephyr", isSkillshot = false}
			},
			["Jayce"] = {
				["jayceshockblastmis"] = {slot = 0, danger = 2, name = "Shock Blast", isSkillshot = true},
				["jayceshockblastwallmis"] = {slot = 0, danger = 3, name = "Empowered Shock Blast", isSkillshot = true}
			},
			["Jinx"] = {
				["jinxwmissile"] = {slot = 1, danger = 2, name = "Zap!", isSkillshot = true},
				["jinxr"] = {slot = 3, danger = 4, name = "Super Mega Death Rocket!", isSkillshot = true}
			},
			["Jhin"] = {
				["jhinwmissile"] = {slot = 1, danger = 2, name = "Deadly Flourish", isSkillshot = true},
				["jhinrshotmis"] = {slot = 3, danger = 3, name = "Curtain Call's", isSkillshot = true}
			},
			["Kalista"] = {
				["kalistamysticshotmis"] = {slot = 0, danger = 2, name = "Pierce", isSkillshot = true}
			},
			["Karma"] = {
				["karmaqmissile"] = {slot = 0, danger = 2, name = "Inner Flame ", isSkillshot = true},
				["karmaqmissilemantra"] = {slot = 0, danger = 3, name = "Mantra: Inner Flame", isSkillshot = true}
			},
			["Kassadin"] = {
				["nulllance"] = {slot = 0, danger = 3, name = "Null Sphere", isSkillshot = false}
			},
			["Katarina"] = {
				["katarinaqmis"] = {slot = 0, danger = 3, name = "Bouncing Blade", isSkillshot = false}
			},
			["Kayle"] = {
				["judicatorreckoning"] = {slot = 0, danger = 3, name = "Reckoning", isSkillshot = false}
			},
			["Kennen"] = {
				["kennenshurikenhurlmissile1"] = {slot = 0, danger = 2, name = "Thundering Shuriken", isSkillshot = true}
			},
			["Khazix"] = {
				["khazixwmissile"] = {slot = 1, danger = 3, name = "Void Spike", isSkillshot = true}
			},
			["Kogmaw"] = {
				["kogmawq"] = {slot = 0, danger = 2, name = "Caustic Spittle", isSkillshot = true},
				["kogmawvoidoozemissile"] = {slot = 3, danger = 2, name = "Void Ooze", isSkillshot = true},
			},
			["Leblanc"] = {
				["leblancchaosorbm"] = {slot = 0, danger = 3, name = "Shatter Orb", isSkillshot = false},
				["leblancsoulshackle"] = {slot = 2, danger = 3, name = "Ethereal Chains", isSkillshot = true},
				["leblancsoulshacklem"] = {slot = 2, danger = 3, name = "Ethereal Chains Clone", isSkillshot = true}
			},
			["LeeSin"] = {
				["blindmonkqone"] = {slot = 0, danger = 3, name = "Sonic Wave", isSkillshot = true}
			},
			["Leona"] = {
				["LeonaZenithBladeMissile"] = {slot = 2, danger = 3, name = "Zenith Blade", isSkillshot = true}
			},
			["Lissandra"] = {
				["lissandraqmissile"] = {slot = 0, danger = 2, name = "Ice Shard", isSkillshot = true},
				["lissandraemissile"] = {slot = 2, danger = 1, name = "Glacial Path ", isSkillshot = true}
			},
			["Lucian"] = {
				["lucianwmissile"] = {slot = 1, danger = 1, name = "Ardent Blaze", isSkillshot = true},
				["lucianrmissileoffhand"] = {slot = 3, danger = 3, name = "The Culling", isSkillshot = true}
			},
			["Lulu"] = {
				["luluqmissile"] = {slot = 0, danger = 2, name = "Glitterlance", isSkillshot = true}
			},
			["Lux"] = {
				["luxlightbindingmis"] = {slot = 0, danger = 3, name = "Light Binding", isSkillshot = true} 
			},
			["Malphite"] = {
				["seismicshard"] = {slot = 0, danger = 3, name = "Seismic Shard", isSkillshot = false}
			},
			["MissFortune"] = {
				["missfortunericochetshot"] = {slot = 0, danger = 3, name = "Double Up", isSkillshot = false}
			},
			["Morgana"] = {
				["darkbindingmissile"] = {slot = 0, danger = 4, name = "Dark Binding ", isSkillshot = true}
			},
			["Nami"] = {
				["namiwmissileenemy"] = {slot = 1, danger = 2, name = "Ebb and Flow", isSkillshot = false}
			},
			["Nunu"] = {
				["iceblast"] = {slot = 2, danger = 3, name = "Ice Blast", isSkillshot = false}
			},
			["Nautilus"] = {
				["nautilusanchordragmissile"] = {slot = 0, danger = 3, name = "", isSkillshot = true}
			},
			["Nidalee"] = {
				["JavelinToss"] = {slot = 0, danger = 2, name = "Javelin Toss", isSkillshot = true}
			},
			["Nocturne"] = {
				["nocturneduskbringer"] = {slot = 0, danger = 2, name = "Duskbringer", isSkillshot = true}
			},
			["Pantheon"] = {
				["pantheonq"] = {slot = 0, danger = 2, name = "Spear Shot", isSkillshot = false}
			},
			["RekSai"] = {
				["reksaiqburrowedmis"] = {slot = 0, danger = 2, name = "Prey Seeker", isSkillshot = true}
			},
			["Rengar"] = {
				["rengarefinal"] = {slot = 2, danger = 3, name = "Bola Strike", isSkillshot = true}
			},
			["Riven"] = {
				["rivenlightsabermissile"] = {slot = 3, danger = 5, name = "Wind Slash", isSkillshot = true}
			},
			["Rumble"] = {
				["rumblegrenade"] = {slot = 2, danger = 2, name = "Electro Harpoon", isSkillshot = true}
			},
			["Ryze"] = {
				["ryzeq"] = {slot = 0, danger = 2, name = "Overload", isSkillshot = true},
				["ryzee"] = {slot = 2, danger = 2, name = "Spell Flux", isSkillshot = false}
			},
			["Sejuani"] = {
				["sejuaniglacialprison"] = {slot = 3, danger = 5, name = "Glacial Prison", isSkillshot = true}
			},
			["Sivir"] = {
				["sivirqmissile"] = {slot = 0, danger = 2, name = "Boomerang Blade", isSkillshot = true}
			},
			["Skarner"] = {
				["skarnerfracturemissile"] = {slot = 0, danger = 2, name = "Fracture ", isSkillshot = true}
			},
			["Shaco"] = {
				["twoshivpoison"] = {slot = 2, danger = 3, name = "Two-Shiv Poison", isSkillshot = false}
			},
			["Sona"] = {
				["sonaqmissile"] = {slot = 0, danger = 3, name = "Hymn of Valor", isSkillshot = false},
				["sonar"] = {slot = 3, danger = 5, name = "Crescendo ", isSkillshot = true}
			},
			["Swain"] = {
				["swaintorment"] = {slot = 2, danger = 4, name = "Torment", isSkillshot = false}
			},
			["Syndra"] = {
				["syndrarspell"] = {slot = 3, danger = 5, name = "Unleashed Power", isSkillshot = false}
			},
			["Teemo"] = {
				["blindingdart"] = {slot = 0, danger = 4, name = "Blinding Dart", isSkillshot = false}
			},
			["Tristana"] = {
				["detonatingshot"] = {slot = 2, danger = 3, name = "Explosive Charge", isSkillshot = false}
			},
			["TahmKench"] = {
				["tahmkenchqmissile"] = {slot = 0, danger = 2, name = "Tongue Lash", isSkillshot = true}
			},
			["Taliyah"] = {
				["taliyahqmis"] = {slot = 0, danger = 2, name = "Threaded Volley", isSkillshot = true}
			},
			["Talon"] = {
				["talonrakemissileone"] = {slot = 1, danger = 2, name = "Rake", isSkillshot = true}
			},
			["TwistedFate"] = {
				["bluecardpreattack"] = {slot = 1, danger = 3, name = "Blue Card", isSkillshot = false},
				["goldcardpreattack"] = {slot = 1, danger = 4, name = "Gold Card", isSkillshot = false},
				["redcardpreattack"] = {slot = 1, danger = 3, name = "Red Card", isSkillshot = false}
			},
			["Urgot"] = {
				--
			},
			["Varus"] = {
				["varusqmissile"] = {slot = 0, danger = 2, name = "Piercing Arrow", isSkillshot = true},
				["varusrmissile"] = {slot = 3, danger = 5, name = "Chain of Corruption", isSkillshot = true}
			},
			["Vayne"] = {
				["vaynecondemnmissile"] = {slot = 2, danger = 3, name = "Condemn", isSkillshot = false}
			},
			["Veigar"] = {
				["veigarbalefulstrikemis"] = {slot = 0, danger = 2, name = "Baleful Strike", isSkillshot = true},
				["veigarr"] = {slot = 3, danger = 5, name = "Primordial Burst", isSkillshot = false}
			},
			["Velkoz"] = {
				["velkozqmissile"] = {slot = 0, danger = 2, name = "Plasma Fission", isSkillshot = true},
				["velkozqmissilesplit"] = {slot = 0, danger = 2, name = "Plasma Fission Split", isSkillshot = true}
	 		},
			["Viktor"] = {
				["viktorpowertransfer"] = {slot = 0, danger = 3, name = "Siphon Power", isSkillshot = false},
				["viktordeathraymissile"] = {slot = 2, danger = 3, name = "Death Ray", isSkillshot = true}
			},
			["Vladimir"] = {
				["vladimirtidesofbloodnuke"] = {slot = 2, danger = 3, name = "Tides of Blood", isSkillshot = false}
			},
			["Yasuo"] = {
				["yasuoq3w"] = {slot = 0, danger = 3, name = "Gathering Storm", isSkillshot = true}
			},
			["Zed"] = {
				["zedqmissile"] = {slot = 0, danger = 2, name = "Razor Shuriken ", isSkillshot = true}
			},
			["Zyra"] = {
				["zyrae"] = {slot = 2, danger = 3, name = "Grasping Roots", isSkillshot = true}
			}
		}

		--Main Menu
		self.menu = menuInst.addItem(SubMenu.new("Xayah", Lua_ARGB(255, 100, 250, 50)))

		--TS
		self.menu_ts = TargetSelector(1500, 1, myHero, true, self.menu, true)

		--Combo
		self.menu_combo = self.menu.addItem(SubMenu.new("Combo"))
		self.menu_combo_q = self.menu_combo.addItem(MenuBool.new("Use Q", true))
		self.menu_combo_w = self.menu_combo.addItem(MenuBool.new("Use W", true))
		self.menu_combo_e = self.menu_combo.addItem(MenuBool.new("Use E", true))

		--Evade
		self.menu_evade = self.menu.addItem(SubMenu.new("Evade R"))
		self.menu_evade.addItem(MenuSeparator.new("Spell Settings", true))
		self.menu_evade_spells = {}
		self.menu_evade_spells_dec = {}
		for i, enemy in pairs(GetEnemyHeroes()) do
			local enemy = GetAIHero(enemy)
			if self.SpellData[enemy.CharName] then
				for i, v in pairs(self.SpellData[enemy.CharName]) do
					if enemy and v then
						local SlotToStr = ({[_Q] = "Q", [_W] = "W", [_E] = "E", [_R] = "R"})[v.slot]

						table.insert(self.menu_evade_spells, {
							charName = enemy.CharName,
							slot = v.slot,
							menu = self.menu_evade.addItem(SubMenu.new(enemy.CharName.." | "..SlotToStr.." | "..v.name))
							})

						
						for i = 1, #self.menu_evade_spells do
					                local index = 0

					                if self.menu_evade_spells[i].charName == enemy.CharName and self.menu_evade_spells[i].slot == v.slot then
					                        index = i
					                end

					                if index ~= 0 then
					                        table.insert(self.menu_evade_spells_dec, {
					                        	name = v.name,
					                        	enabled = self.menu_evade_spells[index].menu.addItem(MenuBool.new("Enabled", true)),
					                        	danger = self.menu_evade_spells[index].menu.addItem(MenuSlider.new("Danger Value", v.danger or 1, 1, 5, 1))
					                        	})
					                end
        					end
					end
				end
			end
		end
		self.menu_evade.addItem(MenuSeparator.new("Evade Settings", true))
		self.menu_evade_enabled = self.menu_evade.addItem(MenuBool.new("Enabled", true))
		self.menu_evade_combo = self.menu_evade.addItem(MenuBool.new("Only On Combo", true))
		self.menu_evade_danger = self.menu_evade.addItem(MenuSlider.new("Min. Danger Value", 3, 1, 5, 1))

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
		self.MissileSpellsData = {}

		Callback.Add("Tick", function() self:OnTick() end)
		Callback.Add("Draw", function() self:OnDraw() end)
		Callback.Add("CreateObject", function(...) self:OnCreateObject(...) end)
		Callback.Add("DeleteObject", function(...) self:OnDeleteObject(...) end)
		Callback.Add("UpdateBuff", function(...) self:OnUpdateBuff(...) end)
		Callback.Add("RemoveBuff", function(...) self:OnRemoveBuff(...) end)

		PrintChat("Xayah loaded.")
	end

	function ShulepinAIO_Xayah:OnUpdateBuff(unit, buff)
		if unit.IsMe and buff.Name == "XayahR" then
			SetLuaBasicAttackOnly(true)
		end
	end

	function ShulepinAIO_Xayah:OnRemoveBuff(unit, buff)
		if unit.IsMe and buff.Name == "XayahR" then
			SetLuaBasicAttackOnly(false)
		end
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

		local function dRectangleOutline(s, e, w, t, c)--start,end,width,thickness,color
			local z1 = s+Vector(Vector(e)-s):Perpendicular():Normalized()*w/2
			local z2 = s+Vector(Vector(e)-s):Perpendicular2():Normalized()*w/2
			local z3 = e+Vector(Vector(s)-e):Perpendicular():Normalized()*w/2
			local z4 = e+Vector(Vector(s)-e):Perpendicular2():Normalized()*w/2
			local z5 = s+Vector(Vector(e)-s):Perpendicular():Normalized()*w
			local z6 = s+Vector(Vector(e)-s):Perpendicular2():Normalized()*w
			local c1 = WorldToScreenPos(z1.x, z1.y, z1.z)
			local c2 = WorldToScreenPos(z2.x, z2.y, z2.z)
			local c3 = WorldToScreenPos(z3.x, z3.y, z3.z)
			local c4 = WorldToScreenPos(z4.x, z4.y, z4.z)
			local c5 = WorldToScreenPos(z5.x, z5.y, z5.z)
			local c6 = WorldToScreenPos(z6.x, z6.y, z6.z)
			DrawLineD3DX(c5.x,c5.y,c6.x,c6.y,t+1,Lua_ARGB(200,250,192,0))
			DrawLineD3DX(c2.x,c2.y,c3.x,c3.y,t,c)
			DrawLineD3DX(c3.x,c3.y,c4.x,c4.y,t,c)
			DrawLineD3DX(c1.x,c1.y,c4.x,c4.y,t,c)
		end

		if self.menu_evade_enabled.getValue() then
			for i, missile in pairs(self.MissileSpellsData) do
				if missile then
					if not IsDead(missile.addr) then
						local enabled, danger = nil, nil

						for i = 1, #self.menu_evade_spells_dec do
					                local index = 0

					                if self.menu_evade_spells_dec[i].name == missile.name then
					                        index = i
					                end

					                if index ~= 0 then
					                        enabled = self.menu_evade_spells_dec[index].enabled
					                        danger = self.menu_evade_spells_dec[index].danger
					                end
        					end

        					if enabled and enabled.getValue() then
							if missile.isSkillshot and GetMissile(missile.addr).TargetId == 0 then
								local spellPos_x, spellPos_y, spellPos_z = GetPos(missile.addr)
								local spellPos = Vector(spellPos_x, spellPos_y, spellPos_z)

								dRectangleOutline(Vector(spellPos_x, myHero.y, spellPos_z), 
						  			Vector(missile.endPos.x, myHero.y, missile.endPos.z), 
						  			missile.width + GetOverrideCollisionRadius(myHero.Addr), 2, Lua_ARGB(255,255,255,255))

								local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(missile.startPos, missile.endPos, myHero)

								if isOnSegment and GetDistance(pointSegment) < missile.width + (GetOverrideCollisionRadius(myHero.Addr) / 2) then
									local time = (GetDistance(spellPos) - GetOverrideCollisionRadius(myHero.Addr)) / GetMissile(missile.addr).MissileSpeed

									if danger and danger.getValue() >= self.menu_evade_danger.getValue() then
										if CanCast(_R) and time < 0.2 + (GetPing()/2) then
											local target = self.menu_ts:GetTarget() ~= 0 and GetAIHero(self.menu_ts:GetTarget()) or GetMousePos()

											if self.menu_evade_combo.getValue() then
												if self.menu_key_combo.getValue() then
													CastSpellToPos(target.x, target.z, _R)
												end
											else
												CastSpellToPos(target.x, target.z, _R)
											end
										end
									end
								end
							elseif not missile.isSkillshot and GetMissile(missile.addr).TargetId == myHero.Id then
								if danger and danger.getValue() >= self.menu_evade_danger.getValue() then
									if CanCast(_R) then
										local target = self.menu_ts:GetTarget() ~= 0 and GetAIHero(self.menu_ts:GetTarget()) or GetMousePos()

										if self.menu_evade_combo.getValue() then
											if self.menu_key_combo.getValue() then
												CastSpellToPos(target.x, target.z, _R)
											end
										else
											CastSpellToPos(target.x, target.z, _R)
										end
									end
								end
							end
        					end
					end
				end
			end
		end
	end

	function ShulepinAIO_Xayah:OnCreateObject(obj)
		if string.find(obj.Name, "Passive_Dagger_indicator8s") and obj.IsValid and not IsDead(obj.Addr) then
			self.Feathers[#self.Feathers + 1] = obj
		end

		if obj and obj.Type == 6 then
			local missile = GetMissile(obj.Addr)

			if missile then
				if self.SpellData and self.SpellData[missile.OwnerCharName] then
					local data = self.SpellData[missile.OwnerCharName]

					if data and data[missile.Name:lower()] then
						local spell = data[missile.Name:lower()]

						local startPos = Vector(missile.SrcPos_x, missile.SrcPos_y, missile.SrcPos_z)
						local __endPos = Vector(missile.DestPos_x, missile.DestPos_y, missile.DestPos_z)
						local endPos = Vector(startPos):Extended(__endPos, missile.Range)

						table.insert(self.MissileSpellsData, {
							addr = missile.Addr,
							name = spell.name,
							slot = spell.slot,
							danger = spell.danger,
							isSkillshot = spell.isSkillshot,
							startPos = startPos,
							endPos = endPos,
							width = missile.Width,
							range = missile.Range,
							})
					end
				end
			end
		end
	end

	function ShulepinAIO_Xayah:OnDeleteObject(obj)
		for i, feather in pairs(self.Feathers) do
			if feather.Addr == obj.Addr then
				table.remove(self.Feathers, i)
			end 
		end

		for i, missile in pairs(self.MissileSpellsData) do
			if missile.addr == obj.Addr then
				table.remove(self.MissileSpellsData, i)
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

	--Fiora

	function ShulepinAIO_Fiora:__init()
		self.SpellData = {
			["Aatrox"] = {
				["aatroxeconemissile"] = {slot = 2, danger = 2, name = "Blade of Torment", isSkillshot = true}
			},
			["Ahri"] = {
				["ahriorbmissile"] = { slot = 0, danger = 3, name = "Orb of Deception", isSkillshot = true },
				["ahrifoxfiremissiletwo"] = {slot = 1, danger = 2, name = "Fox-Fire", isSkillshot = false},
				["ahriseducemissile"] = {slot = 2, danger = 4, name = "Charm", isSkillshot = true},
				["ahritumblemissile"] = {slot = 3, danger = 2, name = "SpiritRush", isSkillshot = false}
			},
			["Akali"] = {
				["akalimota"] = {slot = 0, danger = 2, name = "Mark of the Assasin", isSkillshot = false}
			},
			["Amumu"] = {
				["sadmummybandagetoss"] = {slot = 0, danger = 4, name = "Bandage Toss", isSkillshot = true}
			},
			["Anivia"] = {
				["flashfrostspell"] = {slot = 0, danger = 2, name = "Flash Frost", isSkillshot = true},
				["frostbite"] = {slot = 2, danger = 3, name = "Frostbite", isSkillshot = false}
			},
			["Annie"] = {
				["disintegrate"] = {slot = 0, danger = 3, name = "Disintegrate", isSkillshot = false}
			},
			["Ashe"] = {
				["volleyattack"] = {slot = 1, danger = 2, name = "Volley", isSkillshot = true},
				["enchantedcrystalarrow"] = {slot = 3, danger = 5, name = "Enchanted Crystal Arrow", isSkillshot = true}
			},
			["AurelionSol"] = {
				["aurelionsolqmissile"] = {slot = 0, danger = 2, name = "Starsurge", isSkillshot = true}
			},
			["Bard"] = {
				["bardqmissile"] = {slot = 0, danger = 4, name = "Cosmic Binding", isSkillshot = true}
			},
			["Blitzcrank"] = {
				["rocketgrabmissile"] = {slot = 0, danger = 5, name = "Rocket Grab", isSkillshot = true}
			},
			["Brand"] = {
				["brandqmissile"] = {slot = 0, danger = 3, name = "Sear", isSkillshot = true},
				["brandr"] = {slot = 3, danger = 5, name = "Pyroclasm", isSkillshot = false}
			},
			["Braum"] = {
				["braumqmissile"] = {slot = 0, danger = 3, name = "Winter's Bite", isSkillshot = true},
				["braumrmissile"] = {slot = 3, danger = 5, name = "Glacial Fissure", isSkillshot = true}
			},
			["Caitlyn"] = {
				["caitlynpiltoverpeacemaker"] = {slot = 0, danger = 2, name = "Piltover Peacemaker", isSkillshot = true},
				["caitlynaceintheholemissile"] = {slot = 3, danger = 4, name = "Ace in the Hole", isSkillshot = false}
			},
			["Cassiopeia"] = {
				["cassiopeiatwinfang"] = {slot = 2, danger = 2, name = "Twin Fang", isSkillshot = false}
			},
			["Corki"] = {
				["phosphorusbombmissile"] = {slot = 0, danger = 2, name = "Phosphorus Bomb", isSkillshot = true},
				["missilebarragemissile"] = {slot = 3, danger = 2, name = "Missile Barrage", isSkillshot = true},
				["missilebarragemissile2"] = {slot = 3, danger = 2, name = "Big Missile Barrage", isSkillshot = true}
			},
			["Diana"] = {
				["dianaarcthrow"] = {slot = 0, danger = 2, name = "Crescent Strike", isSkillshot = true}
			},
			["DrMundo"] = {
				["infectedcleavermissile"] = {slot = 0, danger = 2, name = "Infected Cleaver", isSkillshot = true}
			},
			["Draven"] = {
				["dravenr"] = {slot = 3, danger = 4, name = "Whirling Death", isSkillshot = true}
			},
			["Ekko"] = {
				["ekkoqmis"] = {slot = 0, danger = 2, name = "Timewinder", isSkillshot = true}
			},
			["Elise"] = {
				["elisehumanq"] = {slot = 0, danger = 3, name = "Neurotoxin", isSkillshot = false},
				["elisehumane"] = {slot = 2, danger = 4, name = "Cocoon", isSkillshot = true}
			},
			["Ezreal"] = {
				["ezrealmysticshotmissile"] = {slot = 0, danger = 2, name = "Mystic Shot", isSkillshot = true},
				["ezrealessencefluxmissile"] = {slot = 1, danger = 2, name = "Essence Flux", isSkillshot = true},
				["ezrealarcaneshiftmissile"] = {slot = 2, danger = 1, name = "Arcane Shift", isSkillshot = false},
				["ezrealtrueshotbarrage"] = {slot = 3, danger = 4, name = "Trueshot Barrage", isSkillshot = true}
			},
			["FiddleSticks"] = {
				["fiddlesticksdarkwindmissile"] = {slot = 2, danger = 3, name = "Dark Wind", isSkillshot = false}
			},
			["Gangplank"] = {
				["parley"] = {slot = 0, danger = 2, name = "Parley", isSkillshot = false}
			},
			["Gnar"] = {
				["gnarqmissile"] = {slot = 0, danger = 2, name = "Boomerang Throw", isSkillshot = true},
				["gnarbigqmissile"] = {slot = 0, danger = 3, name = "Boulder Toss", isSkillshot = true}
			},
			["Gragas"] = {
				["gragasqmissile"] = {slot = 0, danger = 2, name = "Barrel Roll", isSkillshot = true},
				["gragasrboom"] = {slot = 3, danger = 4, name = "Explosive Cask", isSkillshot = true}
			},
			["Graves"] = {
				["gravesqlinemis"] = {slot = 0, danger = 2, name = "End of the Line", isSkillshot = true},
				["graveschargeshotshot"] = {slot = 3, danger = 4, name = "Collateral Damage", isSkillshot = true}
			},
			["Illaoi"] = {
				["illaoiemis"] = {slot = 2, danger = 3, name = "Test of Spirit", isSkillshot = true}
			},
			["Irelia"] = {
				["IreliaTranscendentBlades"] = {slot = 3, danger = 2, name = "Transcendent Blades", isSkillshot = true}
			},
			["Janna"] = {
				["howlinggalespell"] = {slot = 0, danger = 1, name = "Howling Gale", isSkillshot = true},
				["sowthewind"] = {slot = 1, danger = 2, name = "Zephyr", isSkillshot = false}
			},
			["Jayce"] = {
				["jayceshockblastmis"] = {slot = 0, danger = 2, name = "Shock Blast", isSkillshot = true},
				["jayceshockblastwallmis"] = {slot = 0, danger = 3, name = "Empowered Shock Blast", isSkillshot = true}
			},
			["Jinx"] = {
				["jinxwmissile"] = {slot = 1, danger = 2, name = "Zap!", isSkillshot = true},
				["jinxr"] = {slot = 3, danger = 4, name = "Super Mega Death Rocket!", isSkillshot = true}
			},
			["Jhin"] = {
				["jhinwmissile"] = {slot = 1, danger = 2, name = "Deadly Flourish", isSkillshot = true},
				["jhinrshotmis"] = {slot = 3, danger = 3, name = "Curtain Call's", isSkillshot = true}
			},
			["Kalista"] = {
				["kalistamysticshotmis"] = {slot = 0, danger = 2, name = "Pierce", isSkillshot = true}
			},
			["Karma"] = {
				["karmaqmissile"] = {slot = 0, danger = 2, name = "Inner Flame ", isSkillshot = true},
				["karmaqmissilemantra"] = {slot = 0, danger = 3, name = "Mantra: Inner Flame", isSkillshot = true}
			},
			["Kassadin"] = {
				["nulllance"] = {slot = 0, danger = 3, name = "Null Sphere", isSkillshot = false}
			},
			["Katarina"] = {
				["katarinaqmis"] = {slot = 0, danger = 3, name = "Bouncing Blade", isSkillshot = false}
			},
			["Kayle"] = {
				["judicatorreckoning"] = {slot = 0, danger = 3, name = "Reckoning", isSkillshot = false}
			},
			["Kennen"] = {
				["kennenshurikenhurlmissile1"] = {slot = 0, danger = 2, name = "Thundering Shuriken", isSkillshot = true}
			},
			["Khazix"] = {
				["khazixwmissile"] = {slot = 1, danger = 3, name = "Void Spike", isSkillshot = true}
			},
			["Kogmaw"] = {
				["kogmawq"] = {slot = 0, danger = 2, name = "Caustic Spittle", isSkillshot = true},
				["kogmawvoidoozemissile"] = {slot = 3, danger = 2, name = "Void Ooze", isSkillshot = true},
			},
			["Leblanc"] = {
				["leblancchaosorbm"] = {slot = 0, danger = 3, name = "Shatter Orb", isSkillshot = false},
				["leblancsoulshackle"] = {slot = 2, danger = 3, name = "Ethereal Chains", isSkillshot = true},
				["leblancsoulshacklem"] = {slot = 2, danger = 3, name = "Ethereal Chains Clone", isSkillshot = true}
			},
			["LeeSin"] = {
				["blindmonkqone"] = {slot = 0, danger = 3, name = "Sonic Wave", isSkillshot = true}
			},
			["Leona"] = {
				["LeonaZenithBladeMissile"] = {slot = 2, danger = 3, name = "Zenith Blade", isSkillshot = true}
			},
			["Lissandra"] = {
				["lissandraqmissile"] = {slot = 0, danger = 2, name = "Ice Shard", isSkillshot = true},
				["lissandraemissile"] = {slot = 2, danger = 1, name = "Glacial Path ", isSkillshot = true}
			},
			["Lucian"] = {
				["lucianwmissile"] = {slot = 1, danger = 1, name = "Ardent Blaze", isSkillshot = true},
				["lucianrmissileoffhand"] = {slot = 3, danger = 3, name = "The Culling", isSkillshot = true}
			},
			["Lulu"] = {
				["luluqmissile"] = {slot = 0, danger = 2, name = "Glitterlance", isSkillshot = true}
			},
			["Lux"] = {
				["luxlightbindingmis"] = {slot = 0, danger = 3, name = "Light Binding", isSkillshot = true} 
			},
			["Malphite"] = {
				["seismicshard"] = {slot = 0, danger = 3, name = "Seismic Shard", isSkillshot = false}
			},
			["MissFortune"] = {
				["missfortunericochetshot"] = {slot = 0, danger = 3, name = "Double Up", isSkillshot = false}
			},
			["Morgana"] = {
				["darkbindingmissile"] = {slot = 0, danger = 4, name = "Dark Binding ", isSkillshot = true}
			},
			["Nami"] = {
				["namiwmissileenemy"] = {slot = 1, danger = 2, name = "Ebb and Flow", isSkillshot = false}
			},
			["Nunu"] = {
				["iceblast"] = {slot = 2, danger = 3, name = "Ice Blast", isSkillshot = false}
			},
			["Nautilus"] = {
				["nautilusanchordragmissile"] = {slot = 0, danger = 3, name = "", isSkillshot = true}
			},
			["Nidalee"] = {
				["JavelinToss"] = {slot = 0, danger = 2, name = "Javelin Toss", isSkillshot = true}
			},
			["Nocturne"] = {
				["nocturneduskbringer"] = {slot = 0, danger = 2, name = "Duskbringer", isSkillshot = true}
			},
			["Pantheon"] = {
				["pantheonq"] = {slot = 0, danger = 2, name = "Spear Shot", isSkillshot = false}
			},
			["RekSai"] = {
				["reksaiqburrowedmis"] = {slot = 0, danger = 2, name = "Prey Seeker", isSkillshot = true}
			},
			["Rengar"] = {
				["rengarefinal"] = {slot = 2, danger = 3, name = "Bola Strike", isSkillshot = true}
			},
			["Riven"] = {
				["rivenlightsabermissile"] = {slot = 3, danger = 5, name = "Wind Slash", isSkillshot = true}
			},
			["Rumble"] = {
				["rumblegrenade"] = {slot = 2, danger = 2, name = "Electro Harpoon", isSkillshot = true}
			},
			["Ryze"] = {
				["ryzeq"] = {slot = 0, danger = 2, name = "Overload", isSkillshot = true},
				["ryzee"] = {slot = 2, danger = 2, name = "Spell Flux", isSkillshot = false}
			},
			["Sejuani"] = {
				["sejuaniglacialprison"] = {slot = 3, danger = 5, name = "Glacial Prison", isSkillshot = true}
			},
			["Sivir"] = {
				["sivirqmissile"] = {slot = 0, danger = 2, name = "Boomerang Blade", isSkillshot = true}
			},
			["Skarner"] = {
				["skarnerfracturemissile"] = {slot = 0, danger = 2, name = "Fracture ", isSkillshot = true}
			},
			["Shaco"] = {
				["twoshivpoison"] = {slot = 2, danger = 3, name = "Two-Shiv Poison", isSkillshot = false}
			},
			["Sona"] = {
				["sonaqmissile"] = {slot = 0, danger = 3, name = "Hymn of Valor", isSkillshot = false},
				["sonar"] = {slot = 3, danger = 5, name = "Crescendo ", isSkillshot = true}
			},
			["Swain"] = {
				["swaintorment"] = {slot = 2, danger = 4, name = "Torment", isSkillshot = false}
			},
			["Syndra"] = {
				["syndrarspell"] = {slot = 3, danger = 5, name = "Unleashed Power", isSkillshot = false}
			},
			["Teemo"] = {
				["blindingdart"] = {slot = 0, danger = 4, name = "Blinding Dart", isSkillshot = false}
			},
			["Tristana"] = {
				["detonatingshot"] = {slot = 2, danger = 3, name = "Explosive Charge", isSkillshot = false}
			},
			["TahmKench"] = {
				["tahmkenchqmissile"] = {slot = 0, danger = 2, name = "Tongue Lash", isSkillshot = true}
			},
			["Taliyah"] = {
				["taliyahqmis"] = {slot = 0, danger = 2, name = "Threaded Volley", isSkillshot = true}
			},
			["Talon"] = {
				["talonrakemissileone"] = {slot = 1, danger = 2, name = "Rake", isSkillshot = true}
			},
			["TwistedFate"] = {
				["bluecardpreattack"] = {slot = 1, danger = 3, name = "Blue Card", isSkillshot = false},
				["goldcardpreattack"] = {slot = 1, danger = 4, name = "Gold Card", isSkillshot = false},
				["redcardpreattack"] = {slot = 1, danger = 3, name = "Red Card", isSkillshot = false}
			},
			["Urgot"] = {
				--
			},
			["Varus"] = {
				["varusqmissile"] = {slot = 0, danger = 2, name = "Piercing Arrow", isSkillshot = true},
				["varusrmissile"] = {slot = 3, danger = 5, name = "Chain of Corruption", isSkillshot = true}
			},
			["Vayne"] = {
				["vaynecondemnmissile"] = {slot = 2, danger = 3, name = "Condemn", isSkillshot = false}
			},
			["Veigar"] = {
				["veigarbalefulstrikemis"] = {slot = 0, danger = 2, name = "Baleful Strike", isSkillshot = true},
				["veigarr"] = {slot = 3, danger = 5, name = "Primordial Burst", isSkillshot = false}
			},
			["Velkoz"] = {
				["velkozqmissile"] = {slot = 0, danger = 2, name = "Plasma Fission", isSkillshot = true},
				["velkozqmissilesplit"] = {slot = 0, danger = 2, name = "Plasma Fission Split", isSkillshot = true}
	 		},
			["Viktor"] = {
				["viktorpowertransfer"] = {slot = 0, danger = 3, name = "Siphon Power", isSkillshot = false},
				["viktordeathraymissile"] = {slot = 2, danger = 3, name = "Death Ray", isSkillshot = true}
			},
			["Vladimir"] = {
				["vladimirtidesofbloodnuke"] = {slot = 2, danger = 3, name = "Tides of Blood", isSkillshot = false}
			},
			["Yasuo"] = {
				["yasuoq3w"] = {slot = 0, danger = 3, name = "Gathering Storm", isSkillshot = true}
			},
			["Zed"] = {
				["zedqmissile"] = {slot = 0, danger = 2, name = "Razor Shuriken ", isSkillshot = true}
			},
			["Zyra"] = {
				["zyrae"] = {slot = 2, danger = 3, name = "Grasping Roots", isSkillshot = true}
			}
		}

		-- Passive
		self.objList = {}
		self.trackList = {}
		self.passtiveList = {
			["Fiora_Base_Passive_NE.troy"] = { x = 0, z = 200},
			["Fiora_Base_Passive_NW.troy"] = { x = 200, z = 0},
			["Fiora_Base_Passive_SE.troy"] = { x = -1 * 200, z = 0},
			["Fiora_Base_Passive_SW.troy"] = { x = 0, z = -1 * 200},
			["Fiora_Base_R_Mark_NE_FioraOnly.troy"] = { x = 0, z = 200},
			["Fiora_Base_R_Mark_NW_FioraOnly.troy"] = { x = 200, z = 0},
			["Fiora_Base_R_Mark_SE_FioraOnly.troy"] = { x = -1 * 200, z = 0},
			["Fiora_Base_R_Mark_SW_FioraOnly.troy"] = { x = 0, z = -1 * 200}
		}

		--Main Menu
		self.menu = menuInst.addItem(SubMenu.new("Fiora", Lua_ARGB(255, 100, 250, 50)))

		--TS
		self.menu_ts = TargetSelector(1500, 1, myHero, true, self.menu, true)

		--Combo
		self.menu_combo = self.menu.addItem(SubMenu.new("Combo"))
		self.menu_combo_q = self.menu_combo.addItem(MenuBool.new("Use Q", true))
		--self.menu_combo_w = self.menu_combo.addItem(MenuBool.new("Use W", true))
		self.menu_combo_e = self.menu_combo.addItem(MenuBool.new("Use E", true))
		--self.menu_combo_r = self.menu_combo.addItem(MenuBool.new("Use R", true))
		self.menu_combo_items = self.menu_combo.addItem(MenuBool.new("Use Items", true))

		--Evade
		self.menu_evade = self.menu.addItem(SubMenu.new("W Block"))
		self.menu_evade.addItem(MenuSeparator.new("Spell Settings", true))
		self.menu_evade_spells = {}
		self.menu_evade_spells_dec = {}
		for i, enemy in pairs(GetEnemyHeroes()) do
			local enemy = GetAIHero(enemy)
			if self.SpellData[enemy.CharName] then
				for i, v in pairs(self.SpellData[enemy.CharName]) do
					if enemy and v then
						local SlotToStr = ({[_Q] = "Q", [_W] = "W", [_E] = "E", [_R] = "R"})[v.slot]

						table.insert(self.menu_evade_spells, {
							charName = enemy.CharName,
							slot = v.slot,
							menu = self.menu_evade.addItem(SubMenu.new(enemy.CharName.." | "..SlotToStr.." | "..v.name))
							})

						
						for i = 1, #self.menu_evade_spells do
					                local index = 0

					                if self.menu_evade_spells[i].charName == enemy.CharName and self.menu_evade_spells[i].slot == v.slot then
					                        index = i
					                end

					                if index ~= 0 then
					                        table.insert(self.menu_evade_spells_dec, {
					                        	name = v.name,
					                        	enabled = self.menu_evade_spells[index].menu.addItem(MenuBool.new("Enabled", true)),
					                        	danger = self.menu_evade_spells[index].menu.addItem(MenuSlider.new("Danger Value", v.danger or 1, 1, 5, 1))
					                        	})
					                end
        					end
					end
				end
			end
		end
		self.menu_evade.addItem(MenuSeparator.new("Block Settings", true))
		self.menu_evade_enabled = self.menu_evade.addItem(MenuBool.new("Enabled", true))
		self.menu_evade_combo = self.menu_evade.addItem(MenuBool.new("Only On Combo", true))
		self.menu_evade_danger = self.menu_evade.addItem(MenuSlider.new("Min. Danger Value", 3, 1, 5, 1))

		--Draw
		self.menu_draw = self.menu.addItem(SubMenu.new("Drawings"))
		self.menu_draw_disable = self.menu_draw.addItem(MenuBool.new("Disable All Drawings", false))

		--Keys
		self.menu_key = self.menu.addItem(SubMenu.new("Keys"))
		self.menu_key_combo = self.menu_key.addItem(MenuKeyBind.new("Combo Key", 32))

		self.MissileSpellsData = {}

		Callback.Add("Tick", function() self:OnTick() end)
		Callback.Add("Draw", function() self:OnDraw() end)
		Callback.Add("DoCast", function(...) self:OnDoCast(...) end)
		Callback.Add("CreateObject", function(...) self:OnCreateObject(...) end)
		Callback.Add("DeleteObject", function(...) self:OnDeleteObject(...) end)

		PrintChat("Fiora loaded.")
	end

	function ShulepinAIO_Fiora:GetQPos()
		local result = nil
		local distanceTemp = math.huge

		for i, obj in pairs(self.trackList) do
			local origin_x, origin_y, origin_z = GetPos(obj.Addr)
			local origin = Vector(origin_x, origin_y, origin_z)

			if origin then
				local distance = self.passtiveList[obj.Name]

				local buff_pos = {
					x = origin.x + distance.x,
					y = origin.y,
					z = origin.z + distance.z
				}

				local buff_pos_distance = GetDistance(buff_pos)
				if not result or buff_pos_distance < distanceTemp then
					result = buff_pos
					distanceTemp = buff_pos_distance
				end
			end
		end

		return result, distanceTemp
	end

	function ShulepinAIO_Fiora:ObjList()
		local result = {}

		for i, object in pairs(self.objList) do
			local nID = object.NetworkId

			if nID then
				self.trackList[nID] = object
			else
				table.insert(result, object)
			end
		end

		self.objList = result
	end

	function ShulepinAIO_Fiora:CastQ()
		local buff_pos, distance = self:GetQPos()
		if buff_pos and distance > 100 then
			if CanCast(_Q) and distance < 450 then
				CastSpellToPos(buff_pos.x, buff_pos.z, _Q)
			end
		end
	end

	function ShulepinAIO_Fiora:OnTick()
		self:ObjList()

		if self.menu_key_combo.getValue() then
			if self.menu_combo_q.getValue() then
				self:CastQ()
			end
		end
	end

	function ShulepinAIO_Fiora:OnDraw()
		--if self.menu_draw_disable.getValue() then return end

		--for i, obj in pairs(self.trackList) do
		--	local origin_x, origin_y, origin_z = GetPos(obj.Addr)
		--	local origin = Vector(origin_x, origin_y, origin_z)
		--
		--	if origin then
		--		local distance = self.passtiveList[obj.Name]
		--		DrawCircleGame(origin.x + distance.x, origin.y, origin.z + distance.z,100, Lua_ARGB(255,255,255,255))
		--	end
		--end

		local function dRectangleOutline(s, e, w, t, c)
			local z1 = s+Vector(Vector(e)-s):Perpendicular():Normalized()*w/2
			local z2 = s+Vector(Vector(e)-s):Perpendicular2():Normalized()*w/2
			local z3 = e+Vector(Vector(s)-e):Perpendicular():Normalized()*w/2
			local z4 = e+Vector(Vector(s)-e):Perpendicular2():Normalized()*w/2
			local z5 = s+Vector(Vector(e)-s):Perpendicular():Normalized()*w
			local z6 = s+Vector(Vector(e)-s):Perpendicular2():Normalized()*w
			local c1 = WorldToScreenPos(z1.x, z1.y, z1.z)
			local c2 = WorldToScreenPos(z2.x, z2.y, z2.z)
			local c3 = WorldToScreenPos(z3.x, z3.y, z3.z)
			local c4 = WorldToScreenPos(z4.x, z4.y, z4.z)
			local c5 = WorldToScreenPos(z5.x, z5.y, z5.z)
			local c6 = WorldToScreenPos(z6.x, z6.y, z6.z)
			DrawLineD3DX(c5.x,c5.y,c6.x,c6.y,t+1,Lua_ARGB(200,250,192,0))
			DrawLineD3DX(c2.x,c2.y,c3.x,c3.y,t,c)
			DrawLineD3DX(c3.x,c3.y,c4.x,c4.y,t,c)
			DrawLineD3DX(c1.x,c1.y,c4.x,c4.y,t,c)
		end

		if self.menu_evade_enabled.getValue() then
			for i, missile in pairs(self.MissileSpellsData) do
				if missile then
					if not IsDead(missile.addr) then
						local enabled, danger = nil, nil

						for i = 1, #self.menu_evade_spells_dec do
					                local index = 0

					                if self.menu_evade_spells_dec[i].name == missile.name then
					                        index = i
					                end

					                if index ~= 0 then
					                        enabled = self.menu_evade_spells_dec[index].enabled
					                        danger = self.menu_evade_spells_dec[index].danger
					                end
        					end

        					if enabled and enabled.getValue() then
							if missile.isSkillshot and GetMissile(missile.addr).TargetId == 0 then
								local spellPos_x, spellPos_y, spellPos_z = GetPos(missile.addr)
								local spellPos = Vector(spellPos_x, spellPos_y, spellPos_z)

								dRectangleOutline(Vector(spellPos_x, myHero.y, spellPos_z), 
						  			Vector(missile.endPos.x, myHero.y, missile.endPos.z), 
						  			missile.width + GetOverrideCollisionRadius(myHero.Addr), 2, Lua_ARGB(255,255,255,255))

								local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(missile.startPos, missile.endPos, myHero)

								if isOnSegment and GetDistance(pointSegment) < missile.width + (GetOverrideCollisionRadius(myHero.Addr) / 2) then
									local time = (GetDistance(spellPos) - GetOverrideCollisionRadius(myHero.Addr)) / GetMissile(missile.addr).MissileSpeed

									if danger and danger.getValue() >= self.menu_evade_danger.getValue() then
										if CanCast(_W) and time < 0.2 + (GetPing()/2) then
											local target = self.menu_ts:GetTarget() ~= 0 and GetAIHero(self.menu_ts:GetTarget()) or GetMousePos()

											if self.menu_evade_combo.getValue() then
												if self.menu_key_combo.getValue() then
													CastSpellToPos(target.x, target.z, _R)
												end
											else
												CastSpellToPos(target.x, target.z, _W)
											end
										end
									end
								end
							elseif not missile.isSkillshot and GetMissile(missile.addr).TargetId == myHero.Id then
								if danger and danger.getValue() >= self.menu_evade_danger.getValue() then
									if CanCast(_W) then
										local target = self.menu_ts:GetTarget() ~= 0 and GetAIHero(self.menu_ts:GetTarget()) or GetMousePos()

										if self.menu_evade_combo.getValue() then
											if self.menu_key_combo.getValue() then
												CastSpellToPos(target.x, target.z, _W)
											end
										else
											CastSpellToPos(target.x, target.z, _W)
										end
									end
								end
							end
        					end
					end
				end
			end
		end
	end

	function ShulepinAIO_Fiora:OnDoCast(unit, spell)
		if unit.IsMe and self.menu_key_combo.getValue() then
			if spell.Name:lower():find("attack") and CanCast(_E) and self.menu_combo_e.getValue() then
				CastSpellTarget(myHero.Addr, _E)
			end

			if (spell.Name == "FioraEAttack") and not CanCast(_E) and self.menu_combo_items.getValue() then --3077 3748 ItemTiamatCleave  ItemTitanicHydraCleave spell.Name == "FioraEAttack"
				local tiamat = GetSpellIndexByName("ItemTiamatCleave")
				local titan = GetSpellIndexByName("ItemTitanicHydraCleave")

				if myHero.HasItem(3074) and CanCast(tiamat) then
					CastSpellTarget(myHero.Addr, tiamat)
				end

				if myHero.HasItem(3077) and CanCast(tiamat) then
					CastSpellTarget(myHero.Addr, tiamat)
				end

				if myHero.HasItem(3748) and CanCast(titan) then
					CastSpellTarget(myHero.Addr, titan)
				end
			end
		end
	end

	function ShulepinAIO_Fiora:OnCreateObject(obj)
		if self.passtiveList[obj.Name] then
			table.insert(self.objList, obj)
		end

		if obj and obj.Type == 6 then
			local missile = GetMissile(obj.Addr)

			if missile then
				if self.SpellData and self.SpellData[missile.OwnerCharName] then
					local data = self.SpellData[missile.OwnerCharName]

					if data and data[missile.Name:lower()] then
						local spell = data[missile.Name:lower()]

						local startPos = Vector(missile.SrcPos_x, missile.SrcPos_y, missile.SrcPos_z)
						local __endPos = Vector(missile.DestPos_x, missile.DestPos_y, missile.DestPos_z)
						local endPos = Vector(startPos):Extended(__endPos, missile.Range)

						table.insert(self.MissileSpellsData, {
							addr = missile.Addr,
							name = spell.name,
							slot = spell.slot,
							danger = spell.danger,
							isSkillshot = spell.isSkillshot,
							startPos = startPos,
							endPos = endPos,
							width = missile.Width,
							range = missile.Range,
							})
					end
				end
			end
		end
	end

	function ShulepinAIO_Fiora:OnDeleteObject(obj)
		if self.passtiveList[obj.Name] then
			self.trackList[obj.NetworkId] = nil
		end

		for i, missile in pairs(self.MissileSpellsData) do
			if missile.addr == obj.Addr then
				table.remove(self.MissileSpellsData, i)
			end
		end
	end

	function ShulepinAIO_Yasuo:__init()
		--Disable inbuilt Yasuo
		SetLuaCombo(true)

		self.SpellData = {
			["Aatrox"] = {
				["aatroxeconemissile"] = {slot = 2, danger = 2, name = "Blade of Torment", isSkillshot = true}
			},
			["Ahri"] = {
				["ahriorbmissile"] = { slot = 0, danger = 3, name = "Orb of Deception", isSkillshot = true },
				["ahrifoxfiremissiletwo"] = {slot = 1, danger = 2, name = "Fox-Fire", isSkillshot = false},
				["ahriseducemissile"] = {slot = 2, danger = 4, name = "Charm", isSkillshot = true},
				["ahritumblemissile"] = {slot = 3, danger = 2, name = "SpiritRush", isSkillshot = false}
			},
			["Akali"] = {
				["akalimota"] = {slot = 0, danger = 2, name = "Mark of the Assasin", isSkillshot = false}
			},
			["Amumu"] = {
				["sadmummybandagetoss"] = {slot = 0, danger = 4, name = "Bandage Toss", isSkillshot = true}
			},
			["Anivia"] = {
				["flashfrostspell"] = {slot = 0, danger = 2, name = "Flash Frost", isSkillshot = true},
				["frostbite"] = {slot = 2, danger = 3, name = "Frostbite", isSkillshot = false}
			},
			["Annie"] = {
				["disintegrate"] = {slot = 0, danger = 3, name = "Disintegrate", isSkillshot = false}
			},
			["Ashe"] = {
				["volleyattack"] = {slot = 1, danger = 2, name = "Volley", isSkillshot = true},
				["enchantedcrystalarrow"] = {slot = 3, danger = 5, name = "Enchanted Crystal Arrow", isSkillshot = true}
			},
			["AurelionSol"] = {
				["aurelionsolqmissile"] = {slot = 0, danger = 2, name = "Starsurge", isSkillshot = true}
			},
			["Bard"] = {
				["bardqmissile"] = {slot = 0, danger = 4, name = "Cosmic Binding", isSkillshot = true}
			},
			["Blitzcrank"] = {
				["rocketgrabmissile"] = {slot = 0, danger = 5, name = "Rocket Grab", isSkillshot = true}
			},
			["Brand"] = {
				["brandqmissile"] = {slot = 0, danger = 3, name = "Sear", isSkillshot = true},
				["brandr"] = {slot = 3, danger = 5, name = "Pyroclasm", isSkillshot = false}
			},
			["Braum"] = {
				["braumqmissile"] = {slot = 0, danger = 3, name = "Winter's Bite", isSkillshot = true},
				["braumrmissile"] = {slot = 3, danger = 5, name = "Glacial Fissure", isSkillshot = true}
			},
			["Caitlyn"] = {
				["caitlynpiltoverpeacemaker"] = {slot = 0, danger = 2, name = "Piltover Peacemaker", isSkillshot = true},
				["caitlynaceintheholemissile"] = {slot = 3, danger = 4, name = "Ace in the Hole", isSkillshot = false}
			},
			["Cassiopeia"] = {
				["cassiopeiatwinfang"] = {slot = 2, danger = 2, name = "Twin Fang", isSkillshot = false}
			},
			["Corki"] = {
				["phosphorusbombmissile"] = {slot = 0, danger = 2, name = "Phosphorus Bomb", isSkillshot = true},
				["missilebarragemissile"] = {slot = 3, danger = 2, name = "Missile Barrage", isSkillshot = true},
				["missilebarragemissile2"] = {slot = 3, danger = 2, name = "Big Missile Barrage", isSkillshot = true}
			},
			["Diana"] = {
				["dianaarcthrow"] = {slot = 0, danger = 2, name = "Crescent Strike", isSkillshot = true}
			},
			["DrMundo"] = {
				["infectedcleavermissile"] = {slot = 0, danger = 2, name = "Infected Cleaver", isSkillshot = true}
			},
			["Draven"] = {
				["dravenr"] = {slot = 3, danger = 4, name = "Whirling Death", isSkillshot = true}
			},
			["Ekko"] = {
				["ekkoqmis"] = {slot = 0, danger = 2, name = "Timewinder", isSkillshot = true}
			},
			["Elise"] = {
				["elisehumanq"] = {slot = 0, danger = 3, name = "Neurotoxin", isSkillshot = false},
				["elisehumane"] = {slot = 2, danger = 4, name = "Cocoon", isSkillshot = true}
			},
			["Ezreal"] = {
				["ezrealmysticshotmissile"] = {slot = 0, danger = 2, name = "Mystic Shot", isSkillshot = true},
				["ezrealessencefluxmissile"] = {slot = 1, danger = 2, name = "Essence Flux", isSkillshot = true},
				["ezrealarcaneshiftmissile"] = {slot = 2, danger = 1, name = "Arcane Shift", isSkillshot = false},
				["ezrealtrueshotbarrage"] = {slot = 3, danger = 4, name = "Trueshot Barrage", isSkillshot = true}
			},
			["FiddleSticks"] = {
				["fiddlesticksdarkwindmissile"] = {slot = 2, danger = 3, name = "Dark Wind", isSkillshot = false}
			},
			["Gangplank"] = {
				["parley"] = {slot = 0, danger = 2, name = "Parley", isSkillshot = false}
			},
			["Gnar"] = {
				["gnarqmissile"] = {slot = 0, danger = 2, name = "Boomerang Throw", isSkillshot = true},
				["gnarbigqmissile"] = {slot = 0, danger = 3, name = "Boulder Toss", isSkillshot = true}
			},
			["Gragas"] = {
				["gragasqmissile"] = {slot = 0, danger = 2, name = "Barrel Roll", isSkillshot = true},
				["gragasrboom"] = {slot = 3, danger = 4, name = "Explosive Cask", isSkillshot = true}
			},
			["Graves"] = {
				["gravesqlinemis"] = {slot = 0, danger = 2, name = "End of the Line", isSkillshot = true},
				["graveschargeshotshot"] = {slot = 3, danger = 4, name = "Collateral Damage", isSkillshot = true}
			},
			["Illaoi"] = {
				["illaoiemis"] = {slot = 2, danger = 3, name = "Test of Spirit", isSkillshot = true}
			},
			["Irelia"] = {
				["IreliaTranscendentBlades"] = {slot = 3, danger = 2, name = "Transcendent Blades", isSkillshot = true}
			},
			["Janna"] = {
				["howlinggalespell"] = {slot = 0, danger = 1, name = "Howling Gale", isSkillshot = true},
				["sowthewind"] = {slot = 1, danger = 2, name = "Zephyr", isSkillshot = false}
			},
			["Jayce"] = {
				["jayceshockblastmis"] = {slot = 0, danger = 2, name = "Shock Blast", isSkillshot = true},
				["jayceshockblastwallmis"] = {slot = 0, danger = 3, name = "Empowered Shock Blast", isSkillshot = true}
			},
			["Jinx"] = {
				["jinxwmissile"] = {slot = 1, danger = 2, name = "Zap!", isSkillshot = true},
				["jinxr"] = {slot = 3, danger = 4, name = "Super Mega Death Rocket!", isSkillshot = true}
			},
			["Jhin"] = {
				["jhinwmissile"] = {slot = 1, danger = 2, name = "Deadly Flourish", isSkillshot = true},
				["jhinrshotmis"] = {slot = 3, danger = 3, name = "Curtain Call's", isSkillshot = true}
			},
			["Kalista"] = {
				["kalistamysticshotmis"] = {slot = 0, danger = 2, name = "Pierce", isSkillshot = true}
			},
			["Karma"] = {
				["karmaqmissile"] = {slot = 0, danger = 2, name = "Inner Flame ", isSkillshot = true},
				["karmaqmissilemantra"] = {slot = 0, danger = 3, name = "Mantra: Inner Flame", isSkillshot = true}
			},
			["Kassadin"] = {
				["nulllance"] = {slot = 0, danger = 3, name = "Null Sphere", isSkillshot = false}
			},
			["Katarina"] = {
				["katarinaqmis"] = {slot = 0, danger = 3, name = "Bouncing Blade", isSkillshot = false}
			},
			["Kayle"] = {
				["judicatorreckoning"] = {slot = 0, danger = 3, name = "Reckoning", isSkillshot = false}
			},
			["Kennen"] = {
				["kennenshurikenhurlmissile1"] = {slot = 0, danger = 2, name = "Thundering Shuriken", isSkillshot = true}
			},
			["Khazix"] = {
				["khazixwmissile"] = {slot = 1, danger = 3, name = "Void Spike", isSkillshot = true}
			},
			["Kogmaw"] = {
				["kogmawq"] = {slot = 0, danger = 2, name = "Caustic Spittle", isSkillshot = true},
				["kogmawvoidoozemissile"] = {slot = 3, danger = 2, name = "Void Ooze", isSkillshot = true},
			},
			["Leblanc"] = {
				["leblancchaosorbm"] = {slot = 0, danger = 3, name = "Shatter Orb", isSkillshot = false},
				["leblancsoulshackle"] = {slot = 2, danger = 3, name = "Ethereal Chains", isSkillshot = true},
				["leblancsoulshacklem"] = {slot = 2, danger = 3, name = "Ethereal Chains Clone", isSkillshot = true}
			},
			["LeeSin"] = {
				["blindmonkqone"] = {slot = 0, danger = 3, name = "Sonic Wave", isSkillshot = true}
			},
			["Leona"] = {
				["LeonaZenithBladeMissile"] = {slot = 2, danger = 3, name = "Zenith Blade", isSkillshot = true}
			},
			["Lissandra"] = {
				["lissandraqmissile"] = {slot = 0, danger = 2, name = "Ice Shard", isSkillshot = true},
				["lissandraemissile"] = {slot = 2, danger = 1, name = "Glacial Path ", isSkillshot = true}
			},
			["Lucian"] = {
				["lucianwmissile"] = {slot = 1, danger = 1, name = "Ardent Blaze", isSkillshot = true},
				["lucianrmissileoffhand"] = {slot = 3, danger = 3, name = "The Culling", isSkillshot = true}
			},
			["Lulu"] = {
				["luluqmissile"] = {slot = 0, danger = 2, name = "Glitterlance", isSkillshot = true}
			},
			["Lux"] = {
				["luxlightbindingmis"] = {slot = 0, danger = 3, name = "Light Binding", isSkillshot = true} 
			},
			["Malphite"] = {
				["seismicshard"] = {slot = 0, danger = 3, name = "Seismic Shard", isSkillshot = false}
			},
			["MissFortune"] = {
				["missfortunericochetshot"] = {slot = 0, danger = 3, name = "Double Up", isSkillshot = false}
			},
			["Morgana"] = {
				["darkbindingmissile"] = {slot = 0, danger = 4, name = "Dark Binding ", isSkillshot = true}
			},
			["Nami"] = {
				["namiwmissileenemy"] = {slot = 1, danger = 2, name = "Ebb and Flow", isSkillshot = false}
			},
			["Nunu"] = {
				["iceblast"] = {slot = 2, danger = 3, name = "Ice Blast", isSkillshot = false}
			},
			["Nautilus"] = {
				["nautilusanchordragmissile"] = {slot = 0, danger = 3, name = "", isSkillshot = true}
			},
			["Nidalee"] = {
				["JavelinToss"] = {slot = 0, danger = 2, name = "Javelin Toss", isSkillshot = true}
			},
			["Nocturne"] = {
				["nocturneduskbringer"] = {slot = 0, danger = 2, name = "Duskbringer", isSkillshot = true}
			},
			["Pantheon"] = {
				["pantheonq"] = {slot = 0, danger = 2, name = "Spear Shot", isSkillshot = false}
			},
			["RekSai"] = {
				["reksaiqburrowedmis"] = {slot = 0, danger = 2, name = "Prey Seeker", isSkillshot = true}
			},
			["Rengar"] = {
				["rengarefinal"] = {slot = 2, danger = 3, name = "Bola Strike", isSkillshot = true}
			},
			["Riven"] = {
				["rivenlightsabermissile"] = {slot = 3, danger = 5, name = "Wind Slash", isSkillshot = true}
			},
			["Rumble"] = {
				["rumblegrenade"] = {slot = 2, danger = 2, name = "Electro Harpoon", isSkillshot = true}
			},
			["Ryze"] = {
				["ryzeq"] = {slot = 0, danger = 2, name = "Overload", isSkillshot = true},
				["ryzee"] = {slot = 2, danger = 2, name = "Spell Flux", isSkillshot = false}
			},
			["Sejuani"] = {
				["sejuaniglacialprison"] = {slot = 3, danger = 5, name = "Glacial Prison", isSkillshot = true}
			},
			["Sivir"] = {
				["sivirqmissile"] = {slot = 0, danger = 2, name = "Boomerang Blade", isSkillshot = true}
			},
			["Skarner"] = {
				["skarnerfracturemissile"] = {slot = 0, danger = 2, name = "Fracture ", isSkillshot = true}
			},
			["Shaco"] = {
				["twoshivpoison"] = {slot = 2, danger = 3, name = "Two-Shiv Poison", isSkillshot = false}
			},
			["Sona"] = {
				["sonaqmissile"] = {slot = 0, danger = 3, name = "Hymn of Valor", isSkillshot = false},
				["sonar"] = {slot = 3, danger = 5, name = "Crescendo ", isSkillshot = true}
			},
			["Swain"] = {
				["swaintorment"] = {slot = 2, danger = 4, name = "Torment", isSkillshot = false}
			},
			["Syndra"] = {
				["syndrarspell"] = {slot = 3, danger = 5, name = "Unleashed Power", isSkillshot = false}
			},
			["Teemo"] = {
				["blindingdart"] = {slot = 0, danger = 4, name = "Blinding Dart", isSkillshot = false}
			},
			["Tristana"] = {
				["detonatingshot"] = {slot = 2, danger = 3, name = "Explosive Charge", isSkillshot = false}
			},
			["TahmKench"] = {
				["tahmkenchqmissile"] = {slot = 0, danger = 2, name = "Tongue Lash", isSkillshot = true}
			},
			["Taliyah"] = {
				["taliyahqmis"] = {slot = 0, danger = 2, name = "Threaded Volley", isSkillshot = true}
			},
			["Talon"] = {
				["talonrakemissileone"] = {slot = 1, danger = 2, name = "Rake", isSkillshot = true}
			},
			["TwistedFate"] = {
				["bluecardpreattack"] = {slot = 1, danger = 3, name = "Blue Card", isSkillshot = false},
				["goldcardpreattack"] = {slot = 1, danger = 4, name = "Gold Card", isSkillshot = false},
				["redcardpreattack"] = {slot = 1, danger = 3, name = "Red Card", isSkillshot = false}
			},
			["Urgot"] = {
				--
			},
			["Varus"] = {
				["varusqmissile"] = {slot = 0, danger = 2, name = "Piercing Arrow", isSkillshot = true},
				["varusrmissile"] = {slot = 3, danger = 5, name = "Chain of Corruption", isSkillshot = true}
			},
			["Vayne"] = {
				["vaynecondemnmissile"] = {slot = 2, danger = 3, name = "Condemn", isSkillshot = false}
			},
			["Veigar"] = {
				["veigarbalefulstrikemis"] = {slot = 0, danger = 2, name = "Baleful Strike", isSkillshot = true},
				["veigarr"] = {slot = 3, danger = 5, name = "Primordial Burst", isSkillshot = false}
			},
			["Velkoz"] = {
				["velkozqmissile"] = {slot = 0, danger = 2, name = "Plasma Fission", isSkillshot = true},
				["velkozqmissilesplit"] = {slot = 0, danger = 2, name = "Plasma Fission Split", isSkillshot = true}
	 		},
			["Viktor"] = {
				["viktorpowertransfer"] = {slot = 0, danger = 3, name = "Siphon Power", isSkillshot = false},
				["viktordeathraymissile"] = {slot = 2, danger = 3, name = "Death Ray", isSkillshot = true}
			},
			["Vladimir"] = {
				["vladimirtidesofbloodnuke"] = {slot = 2, danger = 3, name = "Tides of Blood", isSkillshot = false}
			},
			["Yasuo"] = {
				["yasuoq3w"] = {slot = 0, danger = 3, name = "Gathering Storm", isSkillshot = true}
			},
			["Zed"] = {
				["zedqmissile"] = {slot = 0, danger = 2, name = "Razor Shuriken ", isSkillshot = true}
			},
			["Zyra"] = {
				["zyrae"] = {slot = 2, danger = 3, name = "Grasping Roots", isSkillshot = true}
			}
		}

		--Main Menu
		self.menu = menuInst.addItem(SubMenu.new("Yasuo", Lua_ARGB(255, 100, 250, 50)))

		--TS
		self.menu_ts = TargetSelector(1500, 1, myHero, true, self.menu, true)

		--Combo
		self.menu_combo = self.menu.addItem(SubMenu.new("Combo"))
		self.menu_combo_q = self.menu_combo.addItem(MenuBool.new("Use Q", true))
		self.menu_combo_q2 = self.menu_combo.addItem(MenuBool.new("Use Q Circle", true))
		--self.menu_combo_w = self.menu_combo.addItem(MenuBool.new("Use W", true))
		self.menu_combo_e = self.menu_combo.addItem(MenuBool.new("Use E", true))
		self.menu_combo_e_gap = self.menu_combo.addItem(MenuBool.new("Use E For Gap", true))
		--self.menu_combo_r = self.menu_combo.addItem(MenuBool.new("Use R", true))
		--self.menu_combo_items = self.menu_combo.addItem(MenuBool.new("Use Items", true))

		--Evade
		self.menu_evade = self.menu.addItem(SubMenu.new("W Block"))
		self.menu_evade.addItem(MenuSeparator.new("Spell Settings", true))
		self.menu_evade_spells = {}
		self.menu_evade_spells_dec = {}
		for i, enemy in pairs(GetEnemyHeroes()) do
			local enemy = GetAIHero(enemy)
			if self.SpellData[enemy.CharName] then
				for i, v in pairs(self.SpellData[enemy.CharName]) do
					if enemy and v then
						local SlotToStr = ({[_Q] = "Q", [_W] = "W", [_E] = "E", [_R] = "R"})[v.slot]

						table.insert(self.menu_evade_spells, {
							charName = enemy.CharName,
							slot = v.slot,
							menu = self.menu_evade.addItem(SubMenu.new(enemy.CharName.." | "..SlotToStr.." | "..v.name))
							})

						
						for i = 1, #self.menu_evade_spells do
					                local index = 0

					                if self.menu_evade_spells[i].charName == enemy.CharName and self.menu_evade_spells[i].slot == v.slot then
					                        index = i
					                end

					                if index ~= 0 then
					                        table.insert(self.menu_evade_spells_dec, {
					                        	name = v.name,
					                        	enabled = self.menu_evade_spells[index].menu.addItem(MenuBool.new("Enabled", true)),
					                        	danger = self.menu_evade_spells[index].menu.addItem(MenuSlider.new("Danger Value", v.danger or 1, 1, 5, 1))
					                        	})
					                end
        					end
					end
				end
			end
		end
		self.menu_evade.addItem(MenuSeparator.new("Block Settings", true))
		self.menu_evade_enabled = self.menu_evade.addItem(MenuBool.new("Enabled", true))
		self.menu_evade_combo = self.menu_evade.addItem(MenuBool.new("Only On Combo", true))
		self.menu_evade_danger = self.menu_evade.addItem(MenuSlider.new("Min. Danger Value", 3, 1, 5, 1))

		--Draw
		self.menu_draw = self.menu.addItem(SubMenu.new("Drawings"))
		self.menu_draw_disable = self.menu_draw.addItem(MenuBool.new("Disable All Drawings", false))

		--Keys
		self.menu_key = self.menu.addItem(SubMenu.new("Keys"))
		self.menu_key_combo = self.menu_key.addItem(MenuKeyBind.new("Combo Key", 32))

		self.MissileSpellsData = {}

		--Spells
		self.Q = Spell(_Q, 425)
		self.W = Spell(_W, 600)
		self.E = Spell(_E, 475)
		self.R = Spell(_R, 1200)

		self.E:SetTargetted()

		Callback.Add("Tick", function() self:OnTick() end)
		Callback.Add("Draw", function() self:OnDraw() end)
		Callback.Add("CreateObject", function(...) self:OnCreateObject(...) end)
		Callback.Add("DeleteObject", function(...) self:OnDeleteObject(...) end)

		PrintChat("Yasuo loaded.")
	end

	function ShulepinAIO_Yasuo:DashEndPos(target)
		local point = 0

		if GetDistance(target) < 410 then
			point = Vector(myHero):Extended(Vector(target), 485)
		else
			point = Vector(myHero):Extended(Vector(target), GetDistance(target) + 65)
		end

		return point
	end

	function ShulepinAIO_Yasuo:IsMarked(target)
		return target.HasBuff("YasuoDashWrapper")
	end

	--[[

	function ShulepinAIO_Yasuo:GetGapMinion(target)
		local bestMinion = nil
		local closest = math.huge

		GetAllUnitAroundAnObject(myHero.Addr, 1500)

		local units = pUnit
		for i, unit in pairs(units) do
			if unit and unit ~= 0 and IsMinion(unit) and IsEnemy(unit) and not IsDead(unit) and not IsInFog(unit) and GetTargetableToTeam(unit) == 4 and not self:IsMarked(GetUnit(unit)) then
				if GetDistance(target, self:DashEndPos(GetUnit(unit))) < GetDistance(target) and GetDistance(self:DashEndPos(GetUnit(unit))) < closest then
					bestMinion = unit
					closest = GetDistance(self:DashEndPos(GetUnit(unit)), target)
				end
			end
		end

		return bestMinion
	end ]]

	function ShulepinAIO_Yasuo:GetGapMinion(target)
		local bestMinion = nil
		local closest = 0

		GetAllUnitAroundAnObject(myHero.Addr, 1500)

		local units = pUnit
		for i, unit in pairs(units) do
			if unit and unit ~= 0 and IsMinion(unit) and IsEnemy(unit) and not IsDead(unit) and not IsInFog(unit) and GetTargetableToTeam(unit) == 4 and not self:IsMarked(GetUnit(unit)) and GetDistance(GetUnit(unit)) < 375 then
				if GetDistance(self:DashEndPos(GetUnit(unit)), target) < GetDistance(target) and closest < GetDistance(GetUnit(unit)) then
					closest = GetDistance(GetUnit(unit))
					bestMinion = unit
				end
			end
		end

		return bestMinion
	end

	function ShulepinAIO_Yasuo:Combo(target)
		if target and target ~= 0 then
			print(GetDamage("Q", GetAIHero(target)))
			if self.E:IsReady() then
				if self.menu_combo_e.getValue() and IsValidTarget(target, self.E.range) and not self:IsMarked(GetAIHero(target)) and GetDistance(GetAIHero(target), self:DashEndPos(GetAIHero(target))) <= GetDistance(GetAIHero(target)) then
					self.E:Cast(target)
				end 

				if self.menu_combo_e_gap.getValue() then
					local gapMinion = self:GetGapMinion(GetAIHero(target))

					if gapMinion and gapMinion ~= 0 then
						self.E:Cast(gapMinion)
					end
				end
			end

			if self.Q:IsReady() and IsValidTarget(target, self.Q.range) then
				if self.menu_combo_q.getValue() and not myHero.IsDash then
					self.Q:Cast(target)
				end

				if self.menu_combo_q2.getValue() and myHero.IsDash and GetDistance(GetAIHero(target)) <= 250 then
					self.Q:Cast(target)
				end
			end
		end
	end

	function ShulepinAIO_Yasuo:OnTick()
		if GetSpellNameByIndex(myHero.Addr, _Q) == "YasuoQW" then
			self.Q.range = 425
			self.Q:SetSkillShot(0.25, math.huge, 30, false) 
		elseif GetSpellNameByIndex(myHero.Addr, _Q) == "YasuoQ3W" then
			self.Q.range = 1000
			self.Q:SetSkillShot(0.25, 1200, 90, false)
		end

		if self.menu_key_combo.getValue() then
			local target = self.menu_ts:GetTarget()

			self:Combo(target)
		end
	end

	function ShulepinAIO_Yasuo:OnDraw()
		--if self.menu_draw_disable.getValue() then return end

		local target = self.menu_ts:GetTarget()
		
		if target and target ~= 0 then
			local pos = self:DashEndPos(GetAIHero(target))
			if pos then
				DrawCircleGame(pos.x, pos.y, pos.z, 150, Lua_ARGB(255, 255, 255, 255))
			end

			local gap = self:GetGapMinion(GetAIHero(target))

			if gap and gap ~= 0 then
				local gap = GetUnit(gap)
				DrawCircleGame(gap.x, gap.y, gap.z, 150, Lua_ARGB(255, 255, 255, 255))
			end
		end

		local function dRectangleOutline(s, e, w, t, c)
			local z1 = s+Vector(Vector(e)-s):Perpendicular():Normalized()*w/2
			local z2 = s+Vector(Vector(e)-s):Perpendicular2():Normalized()*w/2
			local z3 = e+Vector(Vector(s)-e):Perpendicular():Normalized()*w/2
			local z4 = e+Vector(Vector(s)-e):Perpendicular2():Normalized()*w/2
			local z5 = s+Vector(Vector(e)-s):Perpendicular():Normalized()*w
			local z6 = s+Vector(Vector(e)-s):Perpendicular2():Normalized()*w
			local c1 = WorldToScreenPos(z1.x, z1.y, z1.z)
			local c2 = WorldToScreenPos(z2.x, z2.y, z2.z)
			local c3 = WorldToScreenPos(z3.x, z3.y, z3.z)
			local c4 = WorldToScreenPos(z4.x, z4.y, z4.z)
			local c5 = WorldToScreenPos(z5.x, z5.y, z5.z)
			local c6 = WorldToScreenPos(z6.x, z6.y, z6.z)
			DrawLineD3DX(c5.x,c5.y,c6.x,c6.y,t+1,Lua_ARGB(200,250,192,0))
			DrawLineD3DX(c2.x,c2.y,c3.x,c3.y,t,c)
			DrawLineD3DX(c3.x,c3.y,c4.x,c4.y,t,c)
			DrawLineD3DX(c1.x,c1.y,c4.x,c4.y,t,c)
		end

		if self.menu_evade_enabled.getValue() then
			for i, missile in pairs(self.MissileSpellsData) do
				if missile then
					if not IsDead(missile.addr) then
						local enabled, danger = nil, nil

						for i = 1, #self.menu_evade_spells_dec do
					                local index = 0

					                if self.menu_evade_spells_dec[i].name == missile.name then
					                        index = i
					                end

					                if index ~= 0 then
					                        enabled = self.menu_evade_spells_dec[index].enabled
					                        danger = self.menu_evade_spells_dec[index].danger
					                end
        					end

        					if enabled and enabled.getValue() then
							if missile.isSkillshot and GetMissile(missile.addr).TargetId == 0 then
								local spellPos_x, spellPos_y, spellPos_z = GetPos(missile.addr)
								local spellPos = Vector(spellPos_x, spellPos_y, spellPos_z)

								dRectangleOutline(Vector(spellPos_x, myHero.y, spellPos_z), 
						  			Vector(missile.endPos.x, myHero.y, missile.endPos.z), 
						  			missile.width + GetOverrideCollisionRadius(myHero.Addr), 2, Lua_ARGB(255,255,255,255))

								local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(missile.startPos, missile.endPos, myHero)

								if isOnSegment and GetDistance(pointSegment) < missile.width + (GetOverrideCollisionRadius(myHero.Addr) / 2) then
									local time = (GetDistance(spellPos) - GetOverrideCollisionRadius(myHero.Addr)) / GetMissile(missile.addr).MissileSpeed

									if danger and danger.getValue() >= self.menu_evade_danger.getValue() then
										if CanCast(_W) and time < 0.3 + (GetPing()/2) then
											local target = self.menu_ts:GetTarget() ~= 0 and GetAIHero(self.menu_ts:GetTarget()) or GetMousePos()

											if self.menu_evade_combo.getValue() then
												if self.menu_key_combo.getValue() then
													CastSpellToPos(spellPos.x, spellPos.z, _R)
												end
											else
												CastSpellToPos(spellPos.x, spellPos.z, _W)
											end
										end
									end
								end
							elseif not missile.isSkillshot and GetMissile(missile.addr).TargetId == myHero.Id then
								if danger and danger.getValue() >= self.menu_evade_danger.getValue() then
									if CanCast(_W) then
										local target = self.menu_ts:GetTarget() ~= 0 and GetAIHero(self.menu_ts:GetTarget()) or GetMousePos()

										if self.menu_evade_combo.getValue() then
											if self.menu_key_combo.getValue() then
												CastSpellToPos(spellPos.x, spellPos.z, _W)
											end
										else
											CastSpellToPos(spellPos.x, spellPos.z, _W)
										end
									end
								end
							end
        					end
					end
				end
			end
		end
	end

	function ShulepinAIO_Yasuo:OnCreateObject(obj)
		if obj and obj.Type == 6 then
			local missile = GetMissile(obj.Addr)

			if missile then
				if self.SpellData and self.SpellData[missile.OwnerCharName] then
					local data = self.SpellData[missile.OwnerCharName]

					if data and data[missile.Name:lower()] then
						local spell = data[missile.Name:lower()]

						local startPos = Vector(missile.SrcPos_x, missile.SrcPos_y, missile.SrcPos_z)
						local __endPos = Vector(missile.DestPos_x, missile.DestPos_y, missile.DestPos_z)
						local endPos = Vector(startPos):Extended(__endPos, missile.Range)

						table.insert(self.MissileSpellsData, {
							addr = missile.Addr,
							name = spell.name,
							slot = spell.slot,
							danger = spell.danger,
							isSkillshot = spell.isSkillshot,
							startPos = startPos,
							endPos = endPos,
							width = missile.Width,
							range = missile.Range,
							})
					end
				end
			end
		end
	end

	function ShulepinAIO_Yasuo:OnDeleteObject(obj)
		for i, missile in pairs(self.MissileSpellsData) do
			if missile.addr == obj.Addr then
				table.remove(self.MissileSpellsData, i)
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
	menuInst.addItem(MenuSeparator.new("Script Version: 1.19"))
	menuInst.addItem(MenuSeparator.new("LoL Version: 7.24"))
end
