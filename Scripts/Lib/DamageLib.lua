--[[
@Credits: Deftsu

Usage:
local dmg = GetDamage("R", target, stage, level)
-------------------------------------------------------
params:
GetDamage(string_spell, target, stage, spell_level)
]]

local function GetBonusDmg(unit)
        return unit.BonusDmg
end

local function GetBonusAP(unit)
        return unit.MagicDmg
end

local function GetMaxHP(unit)
        return unit.MaxHP
end

local function GetCurrentHP(unit)
        return unit.HP
end

local function GetLevel(unit)
        return unit.Level
end

local function GetPercentHP(unit)
        return unit.MaxHP / unit.HP * 100
end

local function GetArmor(unit)
        return unit.Armor
end

local function GetBaseArmor(unit)
        return unit.BonusArmor
end

local function GetMaxMana(unit)
        return unit.MaxMP
end

local DamageLibTable = {
  ["Aatrox"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({10, 35, 60, 95, 120})[level] + 1.1 * source.TotalDmg end},
    {Slot = "W", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({45, 80, 115, 150, 185})[level] + 0.75 * source.BonusDmg end},
    {Slot = "E", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({70, 110, 150, 190, 230})[level] + 0.7 * source.BonusDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({200, 300, 400})[level] + source.MagicDmg end},
  },

  ["Ahri"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({40, 65, 90, 115, 140})[level] + 0.35 * source.MagicDmg end},
    {Slot = "Q", Stage = 2, DamageType = 3, Damage = function(source, target, level) return ({40, 65, 90, 115, 140})[level] + 0.35 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({40, 65, 90, 115, 140})[level] + 0.4 * source.MagicDmg end},
    {Slot = "W", Stage = 2, DamageType = 2, Damage = function(source, target, level) return ({12, 19.5, 27, 34.5, 42})[level] + 0.12 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 95, 130, 165, 200})[level] + 0.50 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({70, 110, 150})[level] + 0.3 * source.MagicDmg end},
  },

  ["Akali"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({35, 55, 75, 95, 115})[level] + 0.4 * source.MagicDmg end},
    {Slot = "Q", Stage = 2, DamageType = 2, Damage = function(source, target, level) return ({45, 70, 95, 120, 145})[level] + 0.5 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({70, 100, 130, 160, 190})[level] + 0.6 * source.MagicDmg + 0.8 * source.BonusDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({50, 100, 150})[level] + 0.35 * source.MagicDmg end},
  },

  ["Alistar"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({60, 105, 150, 195, 240})[level] + 0.5 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({55, 110, 165, 220, 275})[level] + 0.7 * source.MagicDmg end},
  },

  ["Amumu"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({80, 130, 180, 230, 280})[level] + 0.7 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({10, 15, 20, 25, 30})[level] + (({0.01, 0.0125, 0.015, 0.0175, 0.02})[level] + 0.01 * source.MagicDmg / 100) * target.MaxHP end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({75, 100, 125, 150, 175})[level] + 0.5 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({150, 250, 350})[level] + 0.8 * source.MagicDmg end},
  },

  ["Anivia"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 85, 110, 135, 160})[level] + 0.4 * source.MagicDmg end},
    {Slot = "Q", Stage = 2, DamageType = 2, Damage = function(source, target, level) return ({60, 90, 120, 150, 180})[level] * 2 + source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return (({50, 75, 100, 125, 150})[level] + 0.5 * source.MagicDmg) * (GetBuffStack(target.Addr, "chilled") > 0 and 2 or 1) end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({40, 60, 80})[level] + 0.125 * source.MagicDmg end},
    {Slot = "R", Stage = 2, DamageType = 2, Damage = function(source, target, level) return ({120, 180, 240})[level] + 0.375 * source.MagicDmg end},
  },

  ["Annie"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({80, 115, 150, 185, 220})[level] + 0.8 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({70, 115, 160, 205, 250})[level] + 0.85 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({210, 365, 520})[level] + 0.9 * source.MagicDmg end},
  },

  ["Ashe"] = {
    {Slot = "W", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({20, 35, 50, 65, 80})[level] + source.TotalDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({250, 425, 600})[level] + source.MagicDmg end},
    {Slot = "R", Stage = 2, DamageType = 2, Damage = function(source, target, level) return (({200, 400, 600})[level] + source.MagicDmg) / 2 end},
  },

  ["AurelionSol"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({70, 110, 150, 190, 230})[level] + 0.65 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({150, 250, 350})[level] + 0.7 * source.MagicDmg end},
  },
  
  ["Azir"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({65, 85, 105, 125, 145})[level] + 0.5 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({55, 60, 75, 80, 90})[level] + 0.6 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({80, 120, 160, 200, 240})[level] + 0.4 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({150, 225, 300})[level] + 0.6 * source.MagicDmg end},
  },

  ["Blitzcrank"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({80, 135, 190, 245, 300})[level] + source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 1, Damage = function(source, target, level) return source.TotalDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({250, 375, 500})[level] + source.MagicDmg end},
  },

  ["Bard"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({80, 125, 170, 215, 260})[level] + 0.65 * source.MagicDmg end},
  },

  ["Brand"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({80, 110, 140, 170, 200})[level] + 0.55 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({75, 120, 165, 210, 255})[level] + 0.6 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({70, 90, 110, 130, 150})[level] + 0.35 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({100, 200, 300})[level] + 0.25 * source.MagicDmg end},
  },

  ["Braum"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 105, 150, 195, 240})[level] + 0.025 * source.MaxHP end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({150, 250, 350})[level] + 0.6 * source.MagicDmg end},
  },

  ["Caitlyn"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({30, 70, 110, 150, 190})[level] + ({1.3, 1.4, 1.5, 1.6, 1.7})[level] * source.TotalDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({70, 110, 150, 190, 230})[level] + 0.8 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({250, 475, 700})[level] + 2 * source.TotalDmg end},
  },

  ["Cassiopeia"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({75, 120, 165, 210, 255})[level] + 0.7 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({20, 35, 50, 65, 80})[level] + 0.15 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return 48 + 4 * source.Level + 0.1 * source.MagicDmg + ({10, 40, 70, 100, 130})[level] + 0.35 * source.MagicDmg or 0 end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({150, 250, 350})[level] + 0.5 * source.MagicDmg end},
  },

  ["Chogath"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({80, 135, 190, 245, 305})[level] + source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({75, 125, 175, 225, 275})[level] + 0.7 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({20, 35, 50, 65, 80})[level] + 0.3 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 3, Damage = function(source, target, level) return ({300, 475, 650})[level] + 0.5 * source.MagicDmg end},
  },

  ["Corki"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({70, 115, 150, 205, 250})[level] + 0.5 * source.MagicDmg + 0.5 * source.TotalDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 90, 120, 150, 180})[level] + 0.4 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Stage = 2, Damage = function(source, target, level) return ({30, 45, 60, 75, 90})[level] + (1.5 * source.TotalDmg) + 0.2 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({20, 32, 44, 56, 68})[level] + 0.4 * source.TotalDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({75, 100, 125})[level] + 0.2 * source.MagicDmg + ({0.15, 0.45, 0.75})[level] * source.TotalDmg end},
    {Slot = "R", Stage = 2, DamageType = 2, Damage = function(source, target, level) return ({150, 200, 250})[level] + 0.4 * source.MagicDmg + ({0.3, 0.90, 1.5})[level] * source.TotalDmg end},
  },

  ["Darius"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({40, 70, 100, 130, 160})[level] + (({0.5, 1.1, 1.2, 1.3, 1.4})[level] * source.TotalDmg) end},
    {Slot = "W", Stage = 1, DamageType = 1, Damage = function(source, target, level) return 0.4 * source.TotalDmg end},
    {Slot = "R", Stage = 1, DamageType = 3, Damage = function(source, target, level) return ({100, 200, 300})[level] + 0.75 * source.BonusDmg end},
  },

  ["Diana"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 95, 130, 165, 200})[level] + 0.7 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({22, 34, 46, 58, 70})[level] + 0.2 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({100, 160, 220})[level] + 0.6 * source.MagicDmg end},
  },

  ["DrMundo"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) if target.Type == 1 then return math.min(({300, 350, 400, 450, 500})[level],math.max(({80, 130, 180, 230, 280})[level], ({15, 17.5, 20, 22.5, 25})[level] / 100 * target.HP)) end; return math.max(({80, 130, 180, 230, 280})[level],({15, 17.5, 20, 22.5, 25})[level] / 100 * target.HP) end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({35, 50, 65, 80, 95})[level] + 0.2 * source.MagicDmg end}
  },

  ["Draven"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({30, 35, 40, 45, 50})[level] + ({65, 75, 85, 95, 105})[level] / 100 * source.BonusDmg end},
    {Slot = "E", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({70, 105, 140, 175, 210})[level] + 0.5 * source.TotalDmg end},
    {Slot = "R", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({175, 275, 375})[level] + 1.1 * source.TotalDmg end},
  },

  ["Ekko"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 75, 90, 105, 120})[level] + 0.3 * source.MagicDmg end},
    {Slot = "Q", Stage = 2, DamageType = 2, Damage = function(source, target, level) return ({40, 65, 90, 115, 140})[level] + 0.6 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({150, 195, 240, 285, 330})[level] + 0.8 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({50, 80, 110, 140, 170})[level] + 0.2 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({150, 300, 450})[level] + 1.5 * source.MagicDmg end}
  },

  ["Elise"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({40, 75, 110, 145, 180})[level] + (0.08 + 0.03 / 100 * source.MagicDmg) * target.HP end},
    {Slot = "QM", Stage = 2, DamageType = 2, Damage = function(source, target, level) return ({60, 100, 140, 180, 220})[level] + (0.08 + 0.03 / 100 * source.MagicDmg) * (target.MaxHP - target.HP) end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({75, 125, 175, 225, 275})[level] + 0.8 * source.MagicDmg end},
  },

  ["Evelynn"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({40, 50, 60, 70, 80})[level] + ({35, 40, 45, 50, 55})[level] / 100 * source.MagicDmg + ({50, 55, 60, 65, 70})[level] / 100 * source.TotalDmg end},
    {Slot = "E", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({70, 110, 150, 190, 230})[level] + source.MagicDmg + source.TotalDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return (({0.15, 0.20, 0.25})[level] + 0.01 / 100 * source.MagicDmg) * target.HP end},
  },

  ["Ezreal"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({35, 55, 75, 95, 115})[level] + 0.4 * source.MagicDmg + 1.1 * source.TotalDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({70, 115, 160, 205, 250})[level] + 0.8 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({75, 125, 175, 225, 275})[level] + 0.75 * source.MagicDmg + 0.5 * source.TotalDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({350, 500, 650})[level] + 0.9 * source.MagicDmg + source.TotalDmg end},
  },

  ["Fiddlesticks"] = {
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({80, 105, 130, 155, 180})[level] + 0.45 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({65, 85, 105, 125, 145})[level] + 0.45 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({125, 225, 325})[level] + 0.45 * source.MagicDmg end},
  },

  ["Fiora"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({65, 75, 85, 95, 105})[level] + ({0.95, 1, 1.05, 1.1, 1.15})[level] * source.TotalDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({90, 130, 170, 210, 250})[level] + source.MagicDmg end},
  },

  ["Fizz"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({10, 25, 40, 55, 70})[level] + 0.55 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({25, 40, 55, 70, 85})[level] + 0.3 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({70, 120, 170, 220, 270})[level] + 0.75 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({150, 250, 350})[level] + 0.6 * source.MagicDmg end},
    {Slot = "R", Stage = 2, DamageType = 2, Damage = function(source, target, level) return ({225, 325, 425})[level] + 0.8 * source.MagicDmg end},
    {Slot = "R", Stage = 3, DamageType = 2, Damage = function(source, target, level) return ({300, 400, 500})[level] + 1.2 * source.MagicDmg end},
  },

  ["Galio"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({80, 135, 190, 245, 300})[level] + 0.6 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 105, 150, 195, 240})[level] + 0.5 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({360, 540, 720})[level] + source.MagicDmg end},
  },

  ["Gangplank"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({20, 45, 70, 95, 120})[level] + source.TotalDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({35, 60, 85})[level] + 0.1 * source.MagicDmg end},
  },

  ["Garen"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({30, 55, 80, 105, 130})[level] + 1.4 * source.TotalDmg end},
    {Slot = "E", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({20, 45, 70, 95, 120})[level] + ({70, 80, 90, 100, 110})[level] / 100 * source.TotalDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({175, 350, 525})[level] + ({28.57, 33.33, 40})[level] / 100 * (target.MaxHP - target.HP) end},
  },

  ["Gnar"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({5, 35, 65, 95, 125})[level] + 1.15 * source.TotalDmg end},
    {Slot = "QM", Stage = 2, DamageType = 1, Damage = function(source, target, level) return ({5, 45, 85, 125, 165})[level] + 1.2 * source.TotalDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({10, 20, 30, 40, 50})[level] + source.MagicDmg + ({6, 8, 10, 12, 14})[level] / 100 * target.MaxHP end},
    {Slot = "WM", Stage = 2, DamageType = 1, Damage = function(source, target, level) return ({25, 45, 65, 85, 105})[level] + source.TotalDmg end},
    {Slot = "E", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({20, 60, 100, 140, 180})[level] + source.MaxHP * 0.06 end},
    {Slot = "EM", Stage = 2, DamageType = 1, Damage = function(source, target, level) return ({20, 60, 100, 140, 180})[level] + source.MaxHP * 0.06 end},
    {Slot = "R", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({200, 300, 400})[level] + 0.5 * source.MagicDmg + 0.2 * source.TotalDmg end},
  },

  ["Gragas"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({80, 120, 160, 200, 240})[level] + 0.6 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({20, 50, 80, 110, 140})[level] + 8 / 100 * target.MaxHP + 0.3 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({80, 130, 180, 230, 280})[level] + 0.6 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({200, 300, 400})[level] + 0.7 * source.MagicDmg end},
  },

  ["Graves"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({55, 70, 85, 100, 115})[level] + 0.75 * source.TotalDmg end},
    {Slot = "Q", Stage = 2, DamageType = 1, Damage = function(source, target, level) return ({80, 125, 170, 215, 260})[level] + ({0.4, 0.6, 0.8, 1, 1.2})[level] * source.TotalDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 110, 160, 210, 260})[level] + 0.6 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({250, 400, 550})[level] + 1.5 * source.TotalDmg end},
  },

  ["Hecarim"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({50, 85, 120, 155, 190})[level] + 0.6 * source.TotalDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({20, 30, 40, 50, 60})[level] + 0.2 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({40, 75, 110, 145, 180})[level] + 0.5 * source.TotalDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({150, 250, 350})[level] + source.MagicDmg end},
  },

  ["Heimerdinger"] = {
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 90, 120, 150, 180})[level] + 0.45 * source.MagicDmg end},
    {Slot = "W", Stage = 2, DamageType = 2, Damage = function(source, target, level) return ({135, 180, 225})[source:GetSpellData(_R).level] + 0.45 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 100, 140, 180, 220})[level] + 0.6 * source.MagicDmg end},
    {Slot = "E", Stage = 2, DamageType = 2, Damage = function(source, target, level) return ({150, 200, 250})[source:GetSpellData(_R).level] + 0.6 * source.MagicDmg end},
  },

  ["Irelia"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({20, 50, 80, 110, 140})[level] + 1.2 * source.TotalDmg end},
    {Slot = "W", Stage = 1, DamageType = 3, Damage = function(source, target, level) return ({15, 30, 45, 60, 75})[level] end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({80, 120, 160, 200, 240})[level] + 0.5 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({80, 120, 160})[level] + 0.5 * source.MagicDmg + 0.7 * source.TotalDmg end},
  },

  ["Janna"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 85, 110, 135, 160})[level] + 0.35 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 115, 170, 225, 280})[level] + 0.5 * source.MagicDmg end},
  },

  ["JarvanIV"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({70, 115, 160, 205, 250})[level] + 1.2 * source.TotalDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 105, 150, 195, 240})[level] + 0.8 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({200, 325, 450})[level] + 1.5 * source.TotalDmg end},
  },

  ["Jax"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({70, 110, 150, 190, 230})[level] + source.TotalDmg + 0.6 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({40, 75, 110, 145, 180})[level] + 0.6 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({50, 75, 100, 125, 150})[level] + 0.5 * source.TotalDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({100, 160, 220})[level] + 0.7 * source.MagicDmg end},
  },

  ["Jayce"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({70, 120, 170, 220, 270, 320})[level] + 1.2 * source.TotalDmg end},
    {Slot = "QM", Stage = 2, DamageType = 1, Damage = function(source, target, level) return ({35, 70, 105, 140, 175, 210})[level] + source.TotalDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({25, 40, 55, 70, 85, 100})[level] + 0.25 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return (({8, 10.4, 12.8, 15.2, 17.6, 20})[level] / 100) * target.MaxHP + source.TotalDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({20, 60, 100, 140})[level] + 0.25 * source.BonusDmg end},
  },

  ["Jhin"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({50, 75, 100, 125, 150})[level] + ({0.3, 0.35, 0.4, 0.45, 0.5})[level] * source.TotalDmg + 0.6 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({50, 85, 120, 155, 190})[level] + 0.5 * source.TotalDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({20, 80, 140, 200, 260})[level] + 1.20 * source.TotalDmg + source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({40, 100, 160})[level] + 0.2 * source.TotalDmg * (1 + (100 - GetPercentHP(target)) * 1.025) end},
    {Slot = "R", Stage = 2, DamageType = 1, Damage = function(source, target, level) return ({40, 100, 160})[level] + 0.2 * source.TotalDmg * (1 + (100 - GetPercentHP(target)) * 1.025) * 2 end}, -- GetCritDamage..
  },

  ["Jinx"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return 0.1 * source.TotalDmg end},
    {Slot = "W", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({10, 60, 110, 160, 210})[level] + 1.4 * source.TotalDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({70, 120, 170, 220, 270})[level] + source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({25, 35, 45})[level] + ({25, 30, 35})[level] / 100 * (target.MaxHP - target.HP) + 0.15 * source.TotalDmg end},
    {Slot = "R", Stage = 2, DamageType = 1, Damage = function(source, target, level) return ({250, 350, 450})[level] + ({25, 30, 35})[level] / 100 * (target.MaxHP - target.HP) + 1.5 * source.TotalDmg end},
  },

  ["Karma"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({80, 125, 170, 215, 260})[level] + 0.6 * source.MagicDmg end},
    {Slot = "Q", Stage = 2, DamageType = 2, Damage = function(source, target, level) return ({80, 125, 170, 215, 260})[level] + ({25, 75, 125, 175})[source:GetSpellData(_R).level] + 0.9 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 110, 160, 210, 260})[level] + 0.9 * source.MagicDmg end},
    {Slot = "W", Stage = 2, DamageType = 2, Damage = function(source, target, level) return ({60, 110, 160, 210, 260})[level] + 0.9 * source.MagicDmg end},
  },

  ["Karthus"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return (({40, 60, 80, 100, 120})[level] + 0.3 * source.MagicDmg) * 2 end},
    {Slot = "Q", Stage = 2, DamageType = 2, Damage = function(source, target, level) return ({40, 60, 80, 100, 120})[level] + 0.3 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({30, 50, 70, 90, 110})[level] + 0.2 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({250, 400, 550})[level] + 0.6 * source.MagicDmg end},
  },

  ["Kassadin"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({65, 95, 125, 155, 185})[level] + 0.7 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({40, 65, 90, 115, 140})[level] + 0.6 * source.MagicDmg end},
    {Slot = "W", Stage = 2, DamageType = 2, Damage = function(source, target, level) return 20 + 0.1 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({80, 105, 130, 155, 180})[level] + 0.7 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({80, 100, 120})[level] + 0.3 * source.MagicDmg end},
    {Slot = "R", Stage = 2, DamageType = 2, Damage = function(source, target, level) return ({40, 50, 60})[level] + 0.1 * source.MagicDmg end},
  },

  ["Katarina"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({75, 105, 135, 165, 195})[level] + 0.3 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({30, 45, 60, 75, 90})[level] + 0.25 * source.MagicDmg + 0.5 * source.TotalDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({25, 37.5, 50})[level] + 0.22 * source.BonusDmg + 0.19 * source.MagicDmg end},
    {Slot = "R", Stage = 2, DamageType = 2, Damage = function(source, target, level) return ({375, 562.5, 750})[level] + 3.3 * source.BonusDmg + 2.85 * source.MagicDmg end},
  },

  ["Kayle"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 110, 160, 210, 260})[level] + source.TotalDmg + 0.6 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return source.range > 500 and ({20, 30, 40, 50, 60})[level] + 0.30 * source.MagicDmg or ({10, 15, 20, 25, 30})[level] + 0.15 * source.MagicDmg end},
  },

  ["Kennen"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({75, 115, 155, 195, 235})[level] + 0.75 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({40, 50, 60, 70, 80})[level] / 100 * source.TotalDmg end},
    {Slot = "W", Stage = 2, DamageType = 2, Damage = function(source, target, level) return ({65, 95, 125, 155, 185})[level] + 0.55 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({85, 125, 165, 205, 245})[level] + 0.6 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({40, 75, 110})[level] + 0.2 * source.MagicDmg end},
  },

  ["Khazix"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({70, 95, 120, 145, 170})[level] + 1.2 * source.BonusDmg end},
    {Slot = "Q", Stage = 2, DamageType = 1, Damage = function(source, target, level) return ({105, 142.5, 180, 217.5, 255})[level] + 1.56 * source.TotalDmg end},
    {Slot = "Q", Stage = 3, DamageType = 1, Damage = function(source, target, level) return ({70, 95, 120, 145, 170})[level] + 2.24 * source.TotalDmg + 10 * source.Level end},
    {Slot = "Q", Stage = 4, DamageType = 1, Damage = function(source, target, level) return ({105, 142.5, 180, 217.5, 255})[level] + 2.6 * source.TotalDmg + 10 * source.Level end},
    {Slot = "W", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({80, 110, 140, 170, 200})[level] + source.TotalDmg end},
    {Slot = "E", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({65, 100, 135, 170, 205})[level] + 0.2 * source.TotalDmg end},
  },

  ["Kogmaw"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({80, 130, 180, 230, 280})[level] + 0.5 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) local dmg = (({0.03, 0.04, 0.05, 0.06, 0.07})[level] + (0.01*source.MagicDmg)) * target.MaxHP ; if target.Type == 1 and dmg > 100 then dmg = 100 end ; return dmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 105, 150, 195, 240})[level] + 0.5 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return (({100, 140, 180})[level] + 0.65 * source.TotalDmg + 0.25 * source.MagicDmg) * (GetPercentHP(target) < 25 and 3 or (GetPercentHP(target) < 50 and 2 or 1)) end},
  },

  ["Kalista"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({10, 70, 130, 190, 250})[level] + source.TotalDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return (({12, 14, 16, 18, 20})[level] / 100) * target.MaxHP end},
    {Slot = "E", Stage = 1, DamageType = 1, Damage = function(source, target, level) local count = GetBuffStack(target.Addr, "kalistaexpungemarker") if count > 0 then return (({20, 30, 40, 50, 60})[level] + 0.6* (source.TotalDmg)) + ((count - 1)*(({10, 14, 19, 25, 32})[level]+({0.2, 0.225, 0.25, 0.275, 0.3})[level] * (source.TotalDmg))) end; return 0 end},
  },

  ["Kindred"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({55, 75, 95, 115, 135})[level] + source.TotalDmg * 0.2 end},
    {Slot = "W", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({25, 30, 35, 40, 45})[level] + source.TotalDmg * 0.4 end},
    {Slot = "E", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({40, 75, 110, 145, 180})[level] + source.TotalDmg * 0.2 + target.MaxHP * 0.05 end},
  },

  ["Leblanc"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({40, 55, 70, 85, 100})[level] + 0.2 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({85, 125, 165, 205, 245})[level] + 0.4 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({40, 60, 80, 100, 120})[level] + 0.5 * source.MagicDmg end},
  },

  ["LeeSin"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({50, 80, 110, 140, 170})[level] + 0.9 * source.TotalDmg end},
    {Slot = "Q", Stage = 2, DamageType = 1, Damage = function(source, target, level) return ({50, 80, 110, 140, 170})[level] + 0.9 * source.TotalDmg + 0.08 * (target.MaxHP - target.HP) end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 95, 130, 165, 200})[level] + source.TotalDmg end},
    {Slot = "R", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({150, 300, 450})[level] + 2 * source.TotalDmg end},
  },

  ["Leona"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({30, 55, 80, 105, 130})[level] + 0.3 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 100, 140, 180, 220})[level] + 0.4 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 100, 140, 180, 220})[level] + 0.4 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({100, 175, 250})[level] + 0.8 * source.MagicDmg end},
  },

  ["Lissandra"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({70, 100, 130, 160, 190})[level] + 0.7 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({70, 110, 150, 190, 230})[level] + 0.4 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({70, 115, 160, 205, 250})[level] + 0.6 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({150, 250, 350})[level] + 0.7 * source.MagicDmg end},
  },

  ["Lucian"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({80, 115, 150, 185, 220})[level] + ({0.6, 0.7, 0.8, 0.9, 1})[level] * source.TotalDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 100, 140, 180, 220})[level] + 0.9 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({40, 50, 60})[level] + 0.1 * source.MagicDmg + 0.25 * source.TotalDmg end},
  },

  ["Lulu"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({80, 125, 170, 215, 260})[level] + 0.5 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({80, 110, 140, 170, 200})[level] + 0.4 * source.MagicDmg end},
  },

  ["Lux"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({50, 100, 150, 200, 250})[level] + 0.7 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 105, 150, 195, 240})[level] + 0.6 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({300, 400, 500})[level] + 0.75 * source.MagicDmg end},
  },

  ["Malphite"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({70, 120, 170, 220, 270})[level] + 0.6 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({30, 38, 46, 54, 62})[level] / 100 * source.TotalDmg + 0.15 * source.BonusDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 100, 140, 180, 220})[level] + 0.3 * source.Armor + 0.2 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({200, 300, 400})[level] + source.MagicDmg end},
  },

  ["Malzahar"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({70, 110, 150, 190, 230})[level] + 0.7 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return (({4, 4.5, 5, 5.5, 6})[level] / 100 + 0.01 / 100 * source.MagicDmg) * target.MaxHP end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({80, 115, 150, 185, 220})[level] + 0.7 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return 2.5 * (({6, 8, 10})[level] / 100 + 0.015 * source.MagicDmg / 100) * target.MaxHP end},
  },

  ["Maokai"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({70, 115, 160, 205, 250})[level] + 0.4 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return (({9, 10, 11, 12, 13})[level] / 100 + 0.03 / 100 * source.MagicDmg) * target.MaxHP end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({40, 60, 80, 100, 120})[level] + 0.4 * source.MagicDmg end},
    {Slot = "E", Stage = 2, DamageType = 2, Damage = function(source, target, level) return ({80, 120, 160, 200, 240})[level] + 0.6 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({100, 150, 200})[level] + 0.5 * source.MagicDmg end},
  },

  ["MasterYi"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({25, 60, 95, 130, 165})[level] + source.TotalDmg + 0.6 * source.TotalDmg end},
    {Slot = "E", Stage = 1, DamageType = 3, Damage = function(source, target, level) return ({10, 12.5, 15, 17.5, 20})[level] / 100 * source.TotalDmg + ({14, 23, 32, 41, 50})[level] end},
  },

  ["MissFortune"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({20, 40, 60, 80, 100})[level] + 0.35 * source.MagicDmg + source.TotalDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return 0.06 * source.TotalDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({80, 115, 150, 185, 220})[level] + 0.8 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 1, Damage = function(source, target, level) return 0.75 * source.TotalDmg + 0.2 * source.MagicDmg end},
  },

  ["MonkeyKing"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({30, 60, 90, 120, 150})[level] + 0.1 * source.TotalDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({70, 115, 160, 205, 250})[level] + 0.6 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({60, 105, 150, 195, 240})[level] + 0.8 * source.TotalDmg end},
    {Slot = "R", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({20, 110, 200})[level] + 1.1 * source.TotalDmg end},
  },

  ["Mordekaiser"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({80, 110, 140, 170, 200})[level] + source.TotalDmg + 0.4 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({24, 38, 52, 66, 80})[level] + 0.2 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({70, 115, 160, 205, 250})[level] + 0.6 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return (({24, 29, 34})[level] / 100 + 0.04 / 100 * source.MagicDmg) * target.MaxHP end},
  },

  ["Morgana"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({80, 135, 190, 245, 300})[level] + 0.9 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({8, 16, 24, 32, 40})[level] + 0.11 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({150, 225, 300})[level] + 0.7 * source.MagicDmg end},
  },

  ["Nami"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({75, 130, 185, 240, 295})[level] + 0.5 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({70, 110, 150, 190, 230})[level] + 0.5 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({25, 40, 55, 70, 85})[level] + 0.2 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({150, 250, 350})[level] + 0.6 * source.MagicDmg end},
  },

  ["Nasus"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return GetBuffStack(source.Addr, "nasusqstacks") + ({30, 50, 70, 90, 110})[level] end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({55, 95, 135, 175, 215})[level] + 0.6 * source.MagicDmg end},
    {Slot = "E", Stage = 2, DamageType = 2, Damage = function(source, target, level) return ({11, 19, 27, 35, 43})[level] + 0.12 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return (({3, 4, 5})[level] / 100 + 0.01 / 100 * source.MagicDmg) * target.MaxHP end},
  },

  ["Nautilus"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 105, 150, 195, 240})[level] + 0.75 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({30, 40, 50, 60, 70})[level] + 0.4 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 100, 140, 180, 220})[level] + 0.3 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({200, 325, 450})[level] + 0.8 * source.MagicDmg end},
    {Slot = "R", Stage = 2, DamageType = 2, Damage = function(source, target, level) return ({125, 175, 225})[level] + 0.4 * source.MagicDmg end},
  },

  ["Nidalee"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({70, 85, 100, 115, 130})[level] + 0.4 * source.MagicDmg end},
    {Slot = "QM", Stage = 2, DamageType = 2, Damage = function(source, target, level) local dmg = (({5, 30, 55, 80})[source:GetSpellData(_R).level] + 0.4 * source.MagicDmg + 0.75 * source.TotalDmg) * ((target.MaxHP - target.HP) / target.MaxHP * 1.5 + 1) dmg = dmg * (GetBuffStack(target.Addr, "nidaleepassivehunted") > 0 and 1.4 or 1) return dmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({40, 80, 120, 160, 200})[level] + 0.2 * source.MagicDmg end},
    {Slot = "W", Stage = 2, DamageType = 2, Damage = function(source, target, level) return ({60, 110, 160, 210})[source:GetSpellData(_R).level] + 0.3 * source.MagicDmg end},
    {Slot = "E", Stage = 2, DamageType = 2, Damage = function(source, target, level) return ({70, 130, 190, 250})[source:GetSpellData(_R).level] + 0.45 * source.MagicDmg end},
  },

  ["Nocturne"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({60, 105, 150, 195, 240})[level] + 0.75 * source.TotalDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({80, 120, 160, 200, 260})[level] + source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({150, 250, 350})[level] + 1.2 * source.TotalDmg end},
  },

  ["Nunu"] = {
    {Slot = "Q", Stage = 1, DamageType = 3, Damage = function(source, target, level) return ({400, 550, 700, 850, 1000})[level] end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({85, 130, 175, 225, 275})[level] + source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({625, 875, 1125})[level] + 2.5 * source.MagicDmg end},
  },

  ["Olaf"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({70, 115, 160, 205, 250})[level] + 0.55 * source.BonusDmg end},
    {Slot = "E", Stage = 1, DamageType = 3, Damage = function(source, target, level) return ({70, 115, 160, 205, 250})[level] + 0.4 * source.TotalDmg end},
  },

  ["Orianna"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 90, 120, 150, 180})[level] + 0.5 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({70, 115, 160, 205, 250})[level] + 0.7 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 90, 120, 150, 180})[level] + 0.3 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({150, 225, 300})[level] + 0.7 * source.MagicDmg end},
  },

  ["Pantheon"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return (({65, 105, 145, 185, 225})[level] + 1.4 * source.TotalDmg) * ((target.HP / target.MaxHP < 0.15) and 2 or 1) end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({50, 75, 100, 125, 150})[level] + source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 1, Damage = function(source, target, level) return (({13, 23, 33, 43, 53})[level] + 0.6 * source.TotalDmg) * ((target.Type == 0) and 2 or 1) end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({400, 700, 1000})[level] + source.MagicDmg end},
    {Slot = "R", Stage = 2, DamageType = 2, Damage = function(source, target, level) return (({400, 700, 1000})[level] + source.MagicDmg) * 0.5 end},
  },

  ["Poppy"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({35, 55, 75, 95, 115})[level] + 0.80 * source.TotalDmg + 0.07 * target.MaxHP end},
    {Slot = "Q", Stage = 2, DamageType = 1, Damage = function(source, target, level) return ({70, 110, 150, 190, 230})[level] + 1.6 * source.TotalDmg + 0.14 * target.MaxHP end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({70, 110, 150, 190, 230})[level] + 0.7 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({50, 70, 90, 110, 130})[level] + 0.5 * source.TotalDmg end},
    {Slot = "E", Stage = 2, DamageType = 1, Damage = function(source, target, level) return ({100, 140, 180, 220, 260})[level] + source.TotalDmg end},
    {Slot = "R", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({100, 150, 200})[level] + 0.45 * source.BonusDmg end},
  },

  ["Quinn"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) local damage = (({20, 45, 70, 95, 120})[level] + ({0.8, 0.9, 1.0, 1.1, 1.2})[level] * source.TotalDmg) + 0.35 * source.MagicDmg ; damage = damage + damage * ((100 - GetPercentHP(target)) / 100) ; return damage end},
    {Slot = "E", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({40, 70, 100, 130, 160})[level] + 0.2 * source.TotalDmg end},
    {Slot = "R", Stage = 1, DamageType = 1, Damage = function(source, target, level) return 0.4 * source.TotalDmg end},
  },

  ["Rammus"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({100, 150, 200, 250, 300})[level] + source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({15, 25, 35, 45, 55})[level] + 0.1 * source.Armor end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({65, 130, 195})[level] + 0.3 * source.MagicDmg end},
  },

  ["Renekton"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({60, 90, 120, 150, 180})[level] + 0.8 * source.TotalDmg end},
    {Slot = "Q", Stage = 2, DamageType = 1, Damage = function(source, target, level) return ({60, 90, 120, 150, 180})[level] + 0.8 * source.TotalDmg * 1.5 end},
    {Slot = "W", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({10, 30, 50, 70, 90})[level] + 1.5 * source.TotalDmg end},
    {Slot = "W", Stage = 2, DamageType = 1, Damage = function(source, target, level) return ({10, 30, 50, 70, 90})[level] + 1.5 * source.TotalDmg * 1.5 end},
    {Slot = "E", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({30, 60, 90, 120, 150})[level] + 0.9 * source.TotalDmg end},
    {Slot = "E", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({30, 60, 90, 120, 150})[level] + 0.9 * source.TotalDmg * 1.5 end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({40, 80, 120})[level] + 0.1 * source.MagicDmg end},
  },

  ["Rengar"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({25, 45, 65, 85, 105})[level] + ({20, 30, 40, 50, 60})[level] / 100 * source.BonusDmg end},
    {Slot = "Q", Stage = 2, DamageType = 1, Damage = function(source, target, level) return ({60, 68, 76, 82, 88, 94, 100, 108, 116, 124, 132, 140, 148, 156, 164, 172, 180, 188, 196})[source.Level] + 1.1 * source.BonusDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({50, 80, 110, 140, 170})[level] + 0.8 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({50, 100, 150, 200, 250})[level] + 0.7 * source.TotalDmg end},
    {Slot = "E", Stage = 2, DamageType = 1, Damage = function(source, target, level) return ({50, 65, 80, 95, 110, 125, 140, 155, 170, 185, 200, 215, 230, 245, 260, 275, 290, 305})[source.Level] + 0.7 * source.TotalDmg end},
  },

  ["Riven"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({10, 30, 50, 70, 90})[level] + (source.TotalDmg / 100) * ({40, 45, 50, 55, 60})[level] end},
    {Slot = "W", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({50, 80, 110, 140, 170})[level] + source.BonusDmg end},
    {Slot = "R", Stage = 1, DamageType = 1, Damage = function(source, target, level) return (({100, 150, 200})[level] + 0.6 * source.BonusDmg) * math.max(0.04 * math.min(100 - GetPercentHP(target), 75), 1) end},
  },

  ["Rumble"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({75, 135, 195, 255, 315})[level] + source.MagicDmg end},
    {Slot = "Q", Stage = 2, DamageType = 2, Damage = function(source, target, level) return ({112.5, 202.5, 292.5, 382.5, 472.5})[level] + 1.5 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({45, 70, 95, 120, 145})[level] + 0.4 * source.MagicDmg end},
    {Slot = "E", Stage = 2, DamageType = 2, Damage = function(source, target, level) return ({67.5, 105, 142.5, 180, 217.5})[level] + 0.6 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({130, 185, 240})[level] + 0.3 * source.MagicDmg end},
    {Slot = "R", Stage = 2, DamageType = 2, Damage = function(source, target, level) return ({650, 925, 1200})[level] + 1.5 * source.MagicDmg end},
  },

  ["Ryze"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return (({60, 85, 110, 135, 160, 185})[level] + 0.45 * source.MagicDmg + 0.03 * source.MaxMP) * (1 + (GetBuffStack(target.Addr, "RyzeE") > 0 and ({40, 55, 70, 85, 100, 100})[level] / 100 or 0)) end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({80, 100, 120, 140, 160})[level] + 0.2 * source.MagicDmg + 0.01 * source.MaxMP end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({50, 75, 100, 125, 150})[level] + 0.3 * source.MagicDmg + 0.02 * source.MaxMP end},
  },

  ["Sejuani"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({80, 125, 170, 215, 260})[level] end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({4, 4.5, 5, 5.5, 6})[level] / 100 * target.MaxHP end},
    {Slot = "W", Stage = 2, DamageType = 2, Damage = function(source, target, level) return ({10, 17.5, 25, 32.5, 40})[level] + (({4, 6, 8, 10, 12})[level] / 100) * source.MaxHP + 0.15 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 90, 120, 150, 180})[level] + 0.5 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({150, 250, 350})[level] + 0.8 * source.MagicDmg end},
  },

  ["Shaco"] = {
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({35, 50, 65, 80, 95})[level] + 0.2 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({5, 35, 65, 95, 125})[level] + ({3, 4, 5, 6, 7, 8})[level] / 100 * (target.MaxHP - target.HP) + 0.9 * source.MagicDmg + 0.85 * source.TotalDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({300, 450, 600})[level] + source.MagicDmg end},
  },

  ["Shen"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) local dmg = (({2, 2.5, 3, 3.5, 4})[level] + 0.015 * source.MagicDmg) * target.MaxHP / 100; if target.Type == 0 then return dmg end; return math.min(({30, 50, 70, 90, 110})[level]+dmg, ({75, 100, 125, 150, 175})[level]) end},
    {Slot = "Q", Stage = 2, DamageType = 2, Damage = function(source, target, level) local dmg = (({4, 4.5, 5, 5.5, 6})[level] + 0.02 * source.MagicDmg) * target.MaxHP / 100; if target.Type == 0 then return dmg end; return math.min(({30, 50, 70, 90, 110})[level]+dmg, ({75, 100, 125, 150, 175})[level]) end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({50, 85, 120, 155, 190})[level] + 0.5 * source.MagicDmg end},
  },

  ["Shyvana"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({80, 85, 90, 95, 100})[level] / 100 * source.TotalDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({20, 32, 45, 57, 70})[level] + 0.2 * source.TotalDmg + 0.1 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 100, 140, 180, 220})[level] + 0.3 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({150, 250, 350})[level] + 0.7 * source.MagicDmg end},
  },

  ["Singed"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({22, 34, 46, 58, 70})[level] + 0.3 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({50, 65, 80, 95, 110})[level] + 0.75 * source.MagicDmg + ({4, 5.5, 7, 8.5, 10})[level] / 100 * target.MaxHP end},
  },

  ["Sion"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({20, 40, 60, 80, 100})[level] + 0.6 * source.TotalDmg end},
    {Slot = "Q", Stage = 2, DamageType = 1, Damage = function(source, target, level) return ({60, 120, 180, 240, 300})[level] + 1.8 * source.TotalDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({40, 65, 90, 115, 140})[level] + 0.4 * source.MagicDmg + ({10, 11, 12, 13, 14})[level] / 100 * target.MaxHP end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({70, 105, 140, 175, 210})[level] + 0.4 * source.MagicDmg end},
    {Slot = "E", Stage = 2, DamageType = 2, Damage = function(source, target, level) return (({70, 105, 140, 175, 210})[level] + 0.4 * source.MagicDmg) * 1.5 end},
    {Slot = "R", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({150, 300, 450})[level] + 0.4 * source.TotalDmg end},
    {Slot = "R", Stage = 2, DamageType = 1, Damage = function(source, target, level) return (({150, 300, 450})[level] + 0.4 * source.TotalDmg) * 2 end},
  },

  ["Sivir"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({25, 45, 65, 85, 105})[level] + ({70, 80, 90, 100, 110})[level] / 100 * source.TotalDmg + 0.5 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({60, 65, 70, 75, 80})[level] / 100 * source.TotalDmg end},
  },

  ["Skarner"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({20, 30, 40, 50, 60})[level] + 0.4 * source.TotalDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({40, 75, 110, 145, 180})[level] + 0.4 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return (({20, 60, 100})[level] + 0.5 * source.MagicDmg) + (0.60 * source.TotalDmg) end},
  },

  ["Sona"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({40, 70, 100, 130, 160})[level] + 0.4 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({150, 250, 350})[level] + 0.5 * source.MagicDmg end},
  },

  ["Soraka"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({70, 110, 150, 190, 230})[level] + 0.35 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({70, 110, 150, 190, 230})[level] + 0.4 * source.MagicDmg end},
  },

  ["Swain"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({30, 47.5, 65, 82.5, 100})[level] + 0.3 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({80, 120, 160, 200, 240})[level] + 0.7 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({50, 80, 110, 140, 170})[level] + source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({50, 70, 90})[level] + 0.2 * source.MagicDmg end},
  },

  ["Syndra"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({50, 95, 140, 185, 230})[level] + 0.75 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({70, 110, 150, 190, 230})[level] + 0.7 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({70, 115, 160, 205, 250})[level] + 0.5 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({270, 405, 540})[level] + 0.6 * source.MagicDmg end},
    {Slot = "R", Stage = 2, DamageType = 2, Damage = function(source, target, level) return ({90, 135, 180})[level] + 0.2 * source.MagicDmg end},
  },

  ["Talon"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({60, 85, 110, 135, 160})[level] + source.BonusDmg end},
    {Slot = "Q", Stage = 2, DamageType = 1, Damage = function(source, target, level) return ({120, 150, 180, 210, 240})[level] + 1.5 * source.BonusDmg end},
    {Slot = "W", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({50, 60, 70, 80, 90})[level] + 0.4 * source.BonusDmg end},
    {Slot = "W", Stage = 2, DamageType = 1, Damage = function(source, target, level) return ({60, 90, 120, 150, 180})[level] + 0.7 * source.BonusDmg end},
    {Slot = "R", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({80, 120, 160})[level] + 0.8 * source.BonusDmg end},
  },

  ["Taliyah"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 80, 100, 120, 140})[level] + 0.4 * source.MagicDmg end},
    {Slot = "Q", Stage = 2, DamageType = 2, Damage = function(source, target, level) return ({180, 240, 300, 360, 420})[level] + 1.2 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 80, 100, 120, 140})[level] + 0.4 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({70, 90, 110, 130, 150})[level] + 0.4 * source.MagicDmg end},
    {Slot = "E", Stage = 2, DamageType = 2, Damage = function(source, target, level) return ({160, 210, 260, 310, 360})[level] + 0.8 * source.MagicDmg end},
  },

  ["Taric"] = {
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({40, 80, 120, 160, 200})[level] + 0.2 * source.Armor end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({40, 70, 100, 130, 160})[level] + 0.2 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({150, 250, 350})[level] + 0.5 * source.MagicDmg end},
  },

  ["TahmKench"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({80, 130, 180, 230, 280})[level] + 0.7 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return target.Type == 1 and ({400, 450, 500, 550, 600})[level] or (({0.20, 0.23, 0.26, 0.29, 0.32})[level] + 0.02 * source.MagicDmg / 100) * target.MaxHP end},
    {Slot = "W", Stage = 2, DamageType = 2, Damage = function(source, target, level) return ({100, 150, 200, 250, 300})[level] + 0.6 * source.MagicDmg end},
  },


  ["Teemo"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({80, 125, 170, 215, 260})[level] + 0.8 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({34, 68, 102, 136, 170})[level] + 0.7 * source.MagicDmg end},
    {Slot = "E", Stage = 2, DamageType = 2, Damage = function(source, target, level) return ({10, 20, 30, 40, 50})[level] + 0.3 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({200, 325, 450})[level] + 0.5 * source.MagicDmg end},
  },

  ["Thresh"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({80, 120, 160, 200, 240})[level] + 0.5 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({65, 95, 125, 155, 185})[level] + 0.4 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({250, 400, 550})[level] + source.MagicDmg end},
  },

  ["Tristana"] = {
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 110, 160, 210, 260})[level] + 0.5 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({60, 70, 80, 90, 100})[level] + ({0.5, 0.65, 0.8, 0.95, 1.10})[level] * source.TotalDmg + 0.5 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({300, 400, 500})[level] + source.MagicDmg end},
  },

  ["Trundle"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({20, 40, 60, 80, 100})[level] + ({0, 0.5, 0.1, 0.15, 0.2})[level] * source.TotalDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return (({20, 24, 28})[level] / 100 + 0.02 * source.MagicDmg / 100) * target.MaxHP end},
  },

  ["Tryndamere"] = {
    {Slot = "E", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({70, 100, 130, 160, 190})[level] + 1.2 * source.TotalDmg + source.MagicDmg end},
  },

  ["TwistedFate"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 105, 150, 195, 240})[level] + 0.65 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({40, 60, 80, 100, 120})[level] + source.TotalDmg + 0.5 * source.MagicDmg end},
    {Slot = "W", Stage = 2, DamageType = 2, Damage = function(source, target, level) return ({30, 45, 60, 75, 90})[level] + source.TotalDmg + 0.5 * source.MagicDmg end},
    {Slot = "W", Stage = 3, DamageType = 2, Damage = function(source, target, level) return ({15, 22.5, 30, 37.5, 45})[level] + source.TotalDmg + 0.5 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({55, 80, 105, 130, 155})[level] + 0.5 * source.MagicDmg end},
  },

  ["Twitch"] = {
    {Slot = "E", Stage = 1, DamageType = 1, Damage = function(source, target, level) return (GetBuffStack(target.Addr, "twitchdeadlyvenom") * ({15, 20, 25, 30, 35})[level] + 0.2 * source.MagicDmg + 0.25 * source.TotalDmg) + ({20, 35, 50, 65, 80})[level] end},
    {Slot = "E", Stage = 2, DamageType = 1, Damage = function(source, target, level) return ({15, 20, 25, 30, 35})[level] + 0.2 * source.MagicDmg + 0.25 * source.TotalDmg + ({20, 35, 50, 65, 80})[level] end},
  },

  ["Udyr"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({30, 60, 90, 120, 150})[level] + (({120, 130, 140, 150, 160})[level] / 100) * source.TotalDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({10, 20, 30, 40, 50})[level] + 0.25 * source.MagicDmg end},

  },

  ["Urgot"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({10, 40, 70, 100, 130})[level] + 0.85 * source.TotalDmg end},
    {Slot = "E", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({75, 130, 185, 240, 295})[level] + 0.6 * source.TotalDmg end},
  },

  ["Varus"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({10, 47, 83, 120, 157})[level] + source.TotalDmg end},
    {Slot = "Q", Stage = 2, DamageType = 1, Damage = function(source, target, level) return ({15, 70, 125, 180, 235})[level] + 1.5 * source.TotalDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({10, 14, 18, 22, 26})[level] + 0.25 * source.MagicDmg end},
    {Slot = "W", Stage = 2, DamageType = 2, Damage = function(source, target, level) return (({2, 2.75, 3.5, 4.25, 5})[level] / 100 + 0.02 * source.MagicDmg / 100) * target.MaxHP end},
    {Slot = "E", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({65, 100, 135, 170, 205})[level] + 0.6 * source.TotalDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({100, 175, 250})[level] + source.MagicDmg end},
  },

  ["Vayne"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({30, 35, 40, 45, 50})[level] / 100 * source.TotalDmg end},
    {Slot = "W", Stage = 1, DamageType = 3, Damage = function(source, target, level) return math.max(({40, 60, 80, 100, 120})[level], (({6, 7.5, 9, 10.5, 12})[level] / 100) * target.MaxHP) end},
    {Slot = "E", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({45, 80, 115, 150, 185})[level] + 0.5 * source.TotalDmg end},
  },

  ["Veigar"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({70, 110, 150, 190, 230})[level] + 0.6 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({100, 150, 200, 250, 300})[level] + source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) local dmg = GetPercentHP(target) > 33.3 and ({175, 250, 325})[level] + 0.75 * source.MagicDmg or ({350, 500, 650})[level] + 1.5 * source.MagicDmg; return dmg+((0.015 * dmg) * (100 - ((target.HP / target.MaxHP) * 100))) end},
  },

  ["Velkoz"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({80, 120, 160, 200, 240})[level] + 0.6 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({30, 50, 70, 90, 110})[level] + ({45, 75, 105, 135, 165})[level] + 0.4 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({70, 100, 130, 160, 190})[level] + 0.3 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 3, Damage = function(source, target, level) return (GetBuffStack(target.Addr, "velkozresearchedstack") > 0 and ({450, 625, 800})[level] + 1.25* source.MagicDmg or CalcMagicalDamage(source, target, ({450, 625, 800})[level] + 1.25 * source.MagicDmg)) end},
  },

  ["Vi"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({50, 75, 100, 125, 150})[level] + 0.8 * source.TotalDmg end},
    {Slot = "W", Stage = 1, DamageType = 1, Damage = function(source, target, level) return (({4, 5.5, 7, 8.5, 10})[level] / 100 + 0.01 * source.TotalDmg / 35) * target.MaxHP end},
    {Slot = "E", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({5, 20, 35, 50, 65})[level] + 1.15 * source.TotalDmg + 0.7 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({150, 300, 450})[level] + 1.4 * source.TotalDmg end},
  },

  ["Viktor"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 80, 100, 120, 140})[level] + 0.4 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({70, 110, 150, 190, 230})[level] + 0.5 * source.MagicDmg end},
    {Slot = "E", Stage = 2, DamageType = 2, Damage = function(source, target, level) return ({90, 170, 250, 330, 410})[level] + 1.2 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({100, 175, 250})[level] + 0.5 * source.MagicDmg end},
    {Slot = "R", Stage = 2, DamageType = 2, Damage = function(source, target, level) return ({150, 250, 350})[level] + 0.6 * source.MagicDmg end},
  },

  ["Vladimir"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({75, 90, 105, 120, 135})[level] + 0.55 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 80, 100, 120, 140})[level] end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({30, 45, 60, 75, 90})[level] + 0.5 * source.MagicDmg + 0.3 * source.MaxHP end},
    {Slot = "E", Stage = 2, DamageType = 2, Damage = function(source, target, level) return ({60, 90, 120, 150, 180})[level] + source.MagicDmg + 0.6 * source.MaxHP end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({150, 250, 350})[level] + 0.7 * source.MagicDmg end},
  },

  ["Volibear"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({30, 60, 90, 120, 150})[level] end},
    {Slot = "W", Stage = 1, DamageType = 1, Damage = function(source, target, level) return (({60, 110, 160, 210, 260})[level]) * ((target.MaxHP - target.HP) / target.MaxHP + 1) end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 105, 150, 195, 240})[level] + 0.6 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({75, 115, 155})[level] + 0.3 * source.MagicDmg end},
  },

  ["Warwick"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return math.max(({75, 125, 175, 225, 275})[level],(({8, 10, 12, 14, 16})[level] / 100  * target.MaxHP) + source.MagicDmg) end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({150, 250, 350})[level] + 2 * source.TotalDmg end},
  },

  ["Xerath"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({80, 120, 160, 200, 240})[level] + 0.75 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 90, 120, 150, 180})[level] + 0.6 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({80, 110, 140, 170, 200})[level] + 0.45 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({200, 230, 260})[level] + 0.43 * source.MagicDmg end},
  },

  ["XinZhao"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({15, 30, 45, 60, 75})[level] + 0.2 * source.TotalDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({70, 110, 150, 190, 230})[level] + 0.6 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({75, 175, 275})[level] + source.TotalDmg + 0.15 * target.HP end},
  },

  ["Yasuo"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({20, 40, 60, 80, 100})[level] + source.TotalDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 70, 80, 90, 100})[level] + 0.2 * source.BonusDmg + 0.6 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({200, 300, 400})[level] + 1.5 * source.TotalDmg end},
  },

  ["Yorick"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({30, 60, 90, 120, 150})[level] + 1.2 * source.TotalDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 95, 130, 165, 200})[level] + source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({55, 85, 115, 145, 175})[level] + source.TotalDmg end},
  },

  ["Zac"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({70, 110, 150, 190, 230})[level] + 0.5 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({40, 55, 70, 85, 100})[level] + (({4, 5, 6, 7, 8})[level] / 100 + 0.02 * source.MagicDmg / 100) * target.MaxHP end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({80, 130, 180, 230, 280})[level] + 0.7 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({140, 210, 280})[level] + 0.4 * source.MagicDmg end},
  },

  ["Zed"] = {
    {Slot = "Q", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({70, 105, 140, 175, 210})[level] + source.TotalDmg end},
    {Slot = "E", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({65, 90, 115, 140, 165})[level] + 0.8 * source.TotalDmg end},
    {Slot = "R", Stage = 1, DamageType = 1, Damage = function(source, target, level) return source.TotalDmg end},
  },

  ["Ziggs"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({75, 120, 165, 210, 255})[level] + 0.65 * source.MagicDmg end},
    {Slot = "W", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({70, 105, 140, 175, 210})[level] + 0.35 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({40, 65, 90, 115, 140})[level] + 0.3 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({300, 450, 600})[level] + 1.1 * source.MagicDmg end},
  },

  ["Zilean"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({90, 145, 200, 260, 320})[level] + 0.9 * source.MagicDmg end},
  },

  ["Zyra"] = {
    {Slot = "Q", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 95, 130, 165, 200})[level] + 0.6 * source.MagicDmg end},
    {Slot = "E", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({60, 95, 130, 165, 200})[level] + 0.5 * source.MagicDmg end},
    {Slot = "R", Stage = 1, DamageType = 2, Damage = function(source, target, level) return ({180, 265, 350})[level] + 0.7 * source.MagicDmg end},
  }

}


function GetDamage(spell, target, stage, level)
        local source = myHero
        local stage = stage or 1
        local spellTable = {}
        local k = 0
        if stage > 4 then stage = 4 end

        if spell == "Q" or spell == "W" or spell == "E" or spell == "R" or spell == "QM" or spell == "WM" or spell == "EM" then
                local level = level or GetSpellLevel(source.Addr, ({["Q"] = _Q, ["QM"] = _Q, ["W"] = _W, ["WM"] = _W, ["E"] = _E, ["EM"] = _E, ["R"] = _R})[spell])
                if level <= 0 then return 0 end
                if level > 5 then level = 5 end

                if DamageLibTable[source.CharName] then
                        for i, spells in pairs(DamageLibTable[source.CharName]) do
                                if spells.Slot == spell then
                                        table.insert(spellTable, spells)
                                end
                        end

                        if stage > #spellTable then stage = #spellTable end

                        for v = #spellTable, 1, -1 do
                                local spells = spellTable[v]

                                if spells.Stage == stage then
                                        if spells.DamageType == 1 then
                                                return spells.Damage(source, target, level)
                                        elseif spells.DamageType == 2 then
                                                return source.CalcMagicDamage(target.Addr, spells.Damage(source, target, level))
                                        elseif spells.DamageType == 3 then
                                                return spells.Damage(source, target, level)
                                        end
                                end
                        end
                end
        end

        return 0
end
