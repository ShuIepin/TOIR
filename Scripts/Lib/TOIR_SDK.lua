----------------------------------------------------------------
-- SANDBOX
----------------------------------------------------------------

local assert = assert
local getmetatable = assert(getmetatable )
local ipairs = assert(ipairs)
local next = assert(next)
local pairs = assert(pairs)
local rawequal = assert(rawequal)
local rawset = assert(rawset)
local select = assert(select)
local setmetatable = assert(setmetatable)
local tonumber = assert(tonumber)
local tostring = assert(tostring)
local type = assert(type)
local require = assert(require)
local unpack = assert(unpack)

local t = {}
t.concat = assert(table.concat)
t.insert = assert(table.insert)
t.remove = assert(table.remove)
t.sort = assert(table.sort)

local str = {}
str.byte = assert(string.byte)
str.char = assert(string.char)
str.dump = assert(string.dump)
str.find = assert(string.find)
str.format = assert(string.format)
str.gmatch = assert(string.gmatch)
str.gsub = assert(string.gsub)
str.len = assert(string.len)
str.lower = assert(string.lower)
str.match = assert(string.match)
str.reverse = assert(string.reverse)
str.sub = assert(string.sub)
str.upper = assert(string.upper)

local m = {}
m.pi = assert(math.pi)
m.huge = assert(math.huge)
m.floor = assert(math.floor)
m.ceil = assert(math.ceil)
m.abs = assert(math.abs)
m.deg = assert(math.deg)
m.atan = assert(math.atan)
m.sqrt = assert(math.sqrt) 
m.sin = assert(math.sin) 
m.cos = assert(math.cos) 
m.acos = assert(math.acos) 
m.max = assert(math.max)
m.min = assert(math.min)

local IO = {}
IO.open = assert(io.open)
IO.close = assert(io.close)

function class()
        local cls = {}

        cls.__index = cls
        return setmetatable(cls, { __call = function (c, ...)
                local instance = setmetatable({}, cls)

                if cls.__init then
                        cls.__init(instance, ...)
                end

                return instance
        end })
end

----------------------------------------------------------------
-- GLOBALS
----------------------------------------------------------------

_G.myHero = GetMyHero()

----------------------------------------------------------------
-- CALLBACKS
----------------------------------------------------------------

local Keys = {}
local KeysActive = false
for i = 1, 255, 1 do
        Keys[i] = false
end

Callback = class()

local Callbacks = {
        ["Load"]         = {},
        ["Tick"]         = {},
        ["Update"]       = {},
        ["Draw"]         = {},
        ["UpdateBuff"]   = {},
        ["RemoveBuff"]   = {},
        ["ProcessSpell"] = {},
        ["CreateObject"] = {},
        ["DeleteObject"] = {},
        ["WndMsg"]       = {},
        ["KeyPress"]     = {},
        ["DoCast"]       = {},
        ["PlayAnimation"] = {},
}

Callback.Add = function(type, cb) t.insert(Callbacks[type], cb) end
Callback.Del = function(type, id) t.remove(Callbacks[type], id or 1) end

local function OnKeyPressEvent(keyCode, pressed)
        for i, cb in pairs(Callbacks["KeyPress"]) do
                cb(keyCode, pressed)
        end
end

local function OnKeyPressLoop()
        if not KeysActive then return end

        for i = 1, 255, 1 do
                if i ~= 117 and i ~= 118 then
                        local keyState = GetKeyPress(i) > 0

                        if Keys[i] ~= keyState then
                                OnKeyPressEvent(i, keyState)
                        end

                        Keys[i] = keyState
                end
        end
end

local function RegisterOnKeyPress(fn)
        if type(fn) == "function" then
                KeysActive = true
                Callbacks["KeyPress"][#Callbacks["KeyPress"] + 1] = fn
                return #Callbacks["KeyPress"]
        end
end

function OnLoad()
        for i, cb in pairs(Callbacks["Load"]) do
                cb()
        end
end

function OnTick()
        for i, cb in pairs(Callbacks["Tick"]) do
                cb()
        end
end

function OnUpdate()
        for i, cb in pairs(Callbacks["Update"]) do
                cb()
        end

        OnKeyPressLoop()
end

function OnDraw()
        for i, cb in pairs(Callbacks["Draw"]) do
                cb()
        end
end

function OnUpdateBuff(unit, buff, stacks)
        if unit and buff then
                for i, cb in pairs(Callbacks["UpdateBuff"]) do
                        cb(unit, buff, stacks)
                end
        end
end

function OnRemoveBuff(unit, buff)
        if unit and buff then
                for i, cb in pairs(Callbacks["RemoveBuff"]) do
                        cb(unit, buff)
                end
        end
end

function OnProcessSpell(unit, spell)
        if unit and spell then
                for i, cb in pairs(Callbacks["ProcessSpell"]) do
                        cb(unit, spell)
                end
        end
end

function OnCreateObject(unit)
        if unit then
                for i, cb in pairs(Callbacks["CreateObject"]) do
                        cb(unit)
                end
        end
end

function OnDeleteObject(unit)   
        if unit then
                for i, cb in pairs(Callbacks["DeleteObject"]) do
                        cb(unit)
                end
        end
end

function OnWndMsg(msg, key)   
        if msg then
                for i, cb in pairs(Callbacks["WndMsg"]) do
                        cb(msg, key)
                end
        end
end

function OnDoCast(unit, spell)
        if unit and spell then
                for i, cb in pairs(Callbacks["DoCast"]) do
                        cb(unit, spell)
                end
        end
end

function OnPlayAnimation(unit, anim)
        if unit and anim then
                for i, cb in pairs(Callbacks["PlayAnimation"]) do
                        cb(unit, anim)
                end
        end
end

----------------------------------------------------------------
-- COMMON
----------------------------------------------------------------

function string.join(arg, del)
        return t.concat(arg, del)
end

function string.trim(s)
        return s:match'^%s*(.*%S)' or ''
end

function string.unescape(s)
        return s:gsub(".",{
            ["\a"] = [[\a]],
            ["\b"] = [[\b]],
            ["\f"] = [[\f]],
            ["\n"] = [[\n]],
            ["\r"] = [[\r]],
            ["\t"] = [[\t]],
            ["\v"] = [[\v]],
            ["\\"] = [[\\]],
            ['"'] = [[\"]],
            ["'"] = [[\']],
            ["["] = "\\[",
            ["]"] = "\\]",
          })
end

--Math
function math.round(num, idp)
        local mult = 10 ^ (idp or 0)

        if num >= 0 then 
                return m.floor(num * mult + 0.5) / mult
        else 
                return m.ceil(num * mult - 0.5) / mult
        end
end

function math.roundStep(num, step)
        return math.round(num / step) * step
end

function math.calcRounding(num)
        num = num + 0.00000000000001

        local t = 1
        local places = t

        while true do
                if num >= t then 
                        return places - 1 
                end

                places = places + 1
                t = t / 10
        end
end

function math.close(a, b, eps)
        eps = eps or 1e-9
        return m.abs(a - b) <= eps
end

function math.limit(val, min, max)
        return m.min(max, m.max(min, val))
end

--Table
function table.copy(from, dcopy)
        if type(from) == "table" then
                local to = {}

                for k, v in pairs(from) do
                        if dcopy and type(v) == "table" then 
                                to[k] = table.copy(v)
                        else 
                                to[k] = v
                        end
                end

                return to
        end
end

function table.clear(t)
        for i, v in pairs(t) do
            t[i] = nil
        end
end

function table.contains(t, what, member)
        for i, v in pairs(t) do
                if member and v[member] == what or v == what then 
                        return i, v 
                end
        end
end

function table.merge(base, t, dmerge)
        for i, v in pairs(t) do
                if dmerge and type(v) == "table" and type(base[i]) == "table" then
                                base[i] = table.merge(base[i], v)
                else 
                        base[i] = v
                end
        end

        return base
end

function table.serialize(t, name, indent)
        local cart, autoref

        local function isEmptyTable(t)
                return next(t) == nil
        end

        local function basicSerialize(o)
                local ts = tostring(o)

                if type(o) == "function" then
                        return ts
                elseif type(o) == "number" or type(o) == "boolean" then
                        return ts
                else
                        return str.format("%q", ts)
                end
        end

        local function addToCart(value, name, indent, saved, field)
                indent = indent or ""
                saved = saved or {}
                field = field or name

                cart = cart .. indent .. field

                if type(value) ~= "table" then
                        cart = cart .. " = " .. basicSerialize(value) .. ";\n"
                else
                        if saved[value] then
                                cart = cart .. " = {}; -- " .. saved[value] 
                                .. " (self reference)\n"
                                autoref = autoref ..  name .. " = " .. saved[value] .. ";\n"
                        else
                                saved[value] = name

                                if isEmptyTable(value) then
                                        cart = cart .. " = {};\n"
                                else
                                        cart = cart .. " = {\n"

                                        for k, v in pairs(value) do
                                              k = basicSerialize(k)

                                              local fname = str.format("%s[%s]", name, k)
                                              field = str.format("[%s]", k)
                                              addToCart(v, fname, indent .. "   ", saved, field)
                                        end

                                        cart = cart .. indent .. "};\n"
                                end
                        end
                end
        end

        name = name or "<table>"

        if type(t) ~= "table" then
                  return name .. " = " .. basicSerialize(t)
        end

        cart, autoref = "", ""
        addToCart(t, name, indent)

        return cart .. autoref
end

local function ctype(t)
        local _type = type(t)
        if _type == "userdata" then
                local metatable = getmetatable(t)
                if not metatable or not metatable.__index then
                        t, _type = "userdata", "string"
                end
        end
        if _type == "userdata" or _type == "table" then
                local _getType = t.__type or t.type or t.Type
                _type = type(_getType)=="function" and _getType(t) or type(_getType)=="string" and _getType or _type
        end
        return _type
end

function print(...)
        local tV, len = {}, select("#", ...)

        for i = 1, len do
                local value = select(i, ...)
                local type = ctype(value)

                if type == "string" then 
                        tV[i] = value
                elseif type == "vector" then
                        tV[i] = tostring(value)
                elseif type == "number" then 
                        tV[i] = tostring(value)
                elseif type == "table" then 
                        tV[i] = table.serialize(value)
                elseif type == "boolean" then 
                    tV[i] = value and "true" or "false"
                else 
                    tV[i] = "<" .. type .. ">"
                end
        end

        if len > 0 then 
                __PrintTextGame(t.concat(tV)) 
        end
end 

function printDebug(...)
        local tV, len = {}, select("#", ...)

        for i = 1, len do
                local value = select(i, ...)
                local type = ctype(value)

                if type == "string" then 
                        tV[i] = value
                elseif type == "vector" then
                        tV[i] = tostring(value)
                elseif type == "number" then 
                        tV[i] = tostring(value)
                elseif type == "table" then 
                        tV[i] = table.serialize(value)
                elseif type == "boolean" then 
                    tV[i] = value and "true" or "false"
                else 
                    tV[i] = "<" .. type .. ">"
                end
        end

        if len > 0 then 
                __PrintDebug("[TOIR_DEBUG]" .. t.concat(tV)) 
        end
end

function GetOrigin(unit)
        if type(unit) == "number" then
                return { x = GetPosX(unit), y = GetPosY(unit), z = GetPosZ(unit) }
        elseif type(unit) == "table" then
                if unit.x and type(unit.x) == "number" then
                        return { x = unit.x, y = unit.y, z = unit.z }
                elseif unit[1] and type(unit[1]) == "number" then
                        return { x = unit[1], y = unit[2], z = unit[3] }
                end
        end
end

function GetPing()
        return GetLatency() / 1000
end

function GetTrueAttackRange()
        return GetAttackRange(myHero.Addr) + GetOverrideCollisionRadius(myHero.Addr)
end

function GetDistance(p1, p2)
        local p2 = p2 or GetOrigin(myHero)

        return GetDistance2D(p1.x, p1.z or p1.y, p2.x, p2.z or p2.y)
end

function GetPercentHP(unit)
        return GetHealthPoint(unit) / GetHealthPointMax(unit) * 100
end

function GetPercentMP(unit)
        return GetManaPoint(unit) / GetManaPointMax(unit) * 100
end

function GetPredictionPos(unit)
        if type(unit) == "number" then
                return { x = GetPredictionPosX(unit), y = GetPredictionPosY(unit), z = GetPredictionPosZ(unit) }
        end
end

function GetLongestString(textList)
        local mx = 0

        for i, s in ipairs(textList) do
                local l = GetTextWidth(s)
                if l > mx then
                        mx = l
                end
        end

        return mx
end

function IsValidTarget(unit, range)
        local range = range or m.huge
        return unit ~= 0 and not IsDead(unit) and not IsInFog(unit) and GetTargetableToTeam(unit) == 4 and IsEnemy(unit) and GetDistance(GetOrigin(unit)) <= range
end

function WorldToScreenPos(x, y, z)
        local r1, r2 = 0, 0

        if not x then
                return { x = r1, y = r2 }
        elseif not y then
                r1, r2 = WorldToScreen(x.x, x.y, x.z)
                return { x = r1, y = r2 }
        else
                r1, r2 = WorldToScreen(x, y, z)
                return { x = r1, y = r2 }
        end
end

function CircleCircleIntersection(c1, c2, r1, r2) 
        local D = GetDistance(c1, c2)
        if D > r1 + r2 or D <= m.abs(r1 - r2) then return nil end 
        local A = (r1 * r2 - r2 * r1 + D * D) / (2 * D) 
        local H = m.sqrt(r1 * r1 - A * A)
        local Direction = (c2 - c1):Normalized() 
        local PA = c1 + A * Direction 
        local S1 = PA + H * Direction:Perpendicular() 
        local S2 = PA - H * Direction:Perpendicular() 
        return S1, S2 
end

local delayedActions = {}
local delayedActionsExecuter = nil
function DelayAction(func, delay, args)
        if not delayedActionsExecuter then
                function delayedActionsExecuter()
                        for i, funcs in pairs(delayedActions) do
                                if i <= GetTimeGame() then
                                        for _, f in ipairs(funcs) do 
                                                f.func(unpack(f.args or {})) 
                                        end

                                        delayedActions[i] = nil
                                end
                        end
                end

                Callback.Add("Tick", delayedActionsExecuter)
        end

        local time = GetTimeGame() + (delay or 0)

        if delayedActions[time] then 
                t.insert(delayedActions[time], { func = func, args = args })
        else 
                delayedActions[time] = { { func = func, args = args } }
        end
end

function VPGetLineCastPosition(target, delay, speed)
        local distance = GetDistance(GetOrigin(target))
        local time = delay + distance / speed
        local realDistance = (time * GetMoveSpeed(target))
        if realDistance == 0 then return distance end
        return realDistance
end

function GetCollision(target, width, range, distance)
        local predPos = GetPredictionPos(target)
        local myHeroPos = GetOrigin(myHero)
        local targetPos = GetOrigin(target)

        local count = 0

        if predPos.x ~= 0 and predPos.z ~= 0 then
                count = CountObjectCollision(0, target, myHeroPos.x, myHeroPos.z, predPos.x, predPos.z, width, range, 10)
        else
                count = CountObjectCollision(0, target, myHeroPos.x, myHeroPos.z, targetPos.x, targetPos.z, width, range, 10)
        end

        if count == 0 then
                return false
        end

        return true
end

function IsAfterAttack()
        if CanMove() and not CanAttack() then
                return true
        else
                return false
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

function GetMousePos()
        return { x = GetMousePosX(), y = GetMousePosY(), z = GetMousePosZ() }
end

function GetCursorPos()
        return Vector(WorldToScreenPos(GetMousePos()))
end

function WriteFile(text, path, mode)
        local f = IO.open(path, mode or "w+")

        if not f then
                return false
        end

        f:write(text)
        f:close()
        return true
end

function GetEnemyHeroes()
        SearchAllChamp()
        local t = pObjChamp

        local result = {}

        for i, v in pairs(t) do
                if IsEnemy(v) and IsChampion(v) then
                        table.insert(result, v)
                end
        end

        return result
end

Callback.Add("Update", function()
        myHero = GetMyHero()
end)

----------------------------------------------------------------
-- COMMON
----------------------------------------------------------------

Vector = class()

local function IsVector(v)
        return v and v.x and type(v.x) == "number" and ((v.y and type(v.y) == "number") or (v.z and type(v.z) == "number"))
end

function Vector:__init(a, b, c)
        self.type = "vector"

        if a == nil then
                self.x, self.y, self.z = 0.0, 0.0, 0.0
        elseif b == nil then
                
                self.x, self.y, self.z = a.x, a.y, a.z
        else
                self.x = a
                if b and type(b) == "number" then self.y = b end
                if c and type(c) == "number" then self.z = c end
        end
end

function Vector:__tostring()
        if self.y and self.z then
                return "Vector(" .. tostring(self.x) .. "," .. tostring(self.y) .. "," .. tostring(self.z) .. ")"
        else
                return "Vector(" .. tostring(self.x) .. "," .. self.y and tostring(self.y) or tostring(self.z) .. ")"
        end
end

function Vector:__add(v)
        return Vector(self.x + v.x, (v.y and self.y) and self.y + v.y, (v.z and self.z) and self.z + v.z)
end

function Vector:__sub(v)
        return Vector(self.x - v.x, (v.y and self.y) and self.y - v.y, (v.z and self.z) and self.z - v.z)
end

function Vector.__mul(a, b)
        if type(a) == "number" and IsVector(b) then
                return Vector({ x = b.x * a, y = b.y and b.y * a, z = b.z and b.z * a })
        elseif type(b) == "number" and IsVector(a) then
                return Vector({ x = a.x * b, y = a.y and a.y * b, z = a.z and a.z * b })
        else
                return a:DotProduct(b)
        end
end

function Vector.__div(a, b)
        if type(a) == "number" and IsVector(b) then
                return Vector({ x = a / b.x, y = b.y and a / b.y, z = b.z and a / b.z })
        else
                return Vector({ x = a.x / b, y = a.y and a.y / b, z = a.z and a.z / b })
        end
end

function Vector.__lt(a, b)
        return a:Len() < b:Len()
end

function Vector.__le(a, b)
        return a:Len() <= b:Len()
end

function Vector:__eq(v)
        return self.x == v.x and self.y == v.y and self.z == v.z
end

function Vector:__unm()
        return Vector(-self.x, self.y and -self.y, self.z and -self.z)
end

function Vector:__tostring()
        return "Vector(" .. self.x .. ", " .. (self.y or 0) .. ", " .. (self.z or 0) .. ")"
end

function Vector:Clone()
        return Vector(self)
end

function Vector:Unpack()
    return self.x, self.y, self.z
end

function Vector:Len2(v)
        local v = v and Vector(v) or self
        return self.x * v.x + (self.y and self.y * v.y or 0) + (self.z and self.z * v.z or 0)
end

function Vector:Len()
        return m.sqrt(self:Len2())
end

function Vector:DistanceTo(v)
        local a = self - v
        return a:Len()
end

function Vector:Normalize()
        local l = self:Len()
        self.x = self.x / l
        self.y = self.y / l 
        self.z = self.z / l 
end

function Vector:Normalized()
        local v = self:Clone()
        v:Normalize()
        return v
end

function Vector:Center(v)
        return Vector((self + v) / 2)
end

function Vector:CrossProduct(v)
        return Vector({ x = v.z * self.y - v.y * self.z, y = v.x * self.z - v.z * self.x, z = v.y * self.x - v.x * self.y })
end

function Vector:DotProduct(v)
        return self.x * v.x + (self.y and (self.y * v.y) or 0) + (self.z and (self.z * v.z) or 0)
end

function Vector:ProjectOn(v)
        local s = self:Len2(v) / v:Len2()
        return Vector(v * s)
end

function Vector:MirrorOn(v)
        return self:ProjectOn(v) * 2
end

function Vector:Sin(v)
        local a = self:CrossProduct(v)
        return m.sqrt(a:Len2() / (self:Len2() * v:Len2()))
end

function Vector:Cos(v)
        return self:Len2(v) / m.sqrt(self:Len2() * v:Len2())
end

function Vector:Angle(v)
        return m.acos(self:Cos(v))
end

function Vector:AffineArea(v)
        local a = self:CrossProduct(v)
        return m.sqrt(a:Len2())
end

function Vector:TriangleArea(v)
        return self:AffineArea(v) / 2
end

function Vector:RotateX(phi)
        local c, s = m.cos(phi), m.sin(phi)
        self.y, self.z = self.y * c - self.z * s, self.z * c + self.y * s
end

function Vector:RotateY(phi)
        local c, s = m.cos(phi), m.sin(phi)
        self.x, self.z = self.x * c + self.z * s, self.z * c - self.x * s
end

function Vector:RotateZ(phi)
        local c, s = m.cos(phi), m.sin(phi)
        self.x, self.y = self.x * c - self.z * s, self.y * c + self.x * s
end

function Vector:Rotate(phiX, phiY, phiZ)
        if phiX ~= 0 then self:RotateX(phiX) end
        if phiY ~= 0 then self:RotateY(phiY) end
        if phiZ ~= 0 then self:RotateZ(phiZ) end
end

function Vector:Rotated(phiX, phiY, phiZ)
        local v = self:Clone()
        v:Rotate(phiX, phiY, phiZ)
        return v
end

function Vector:Polar()
        if math.close(self.x, 0, 0) then
                if self.z or self.y > 0 then 
                        return 90
                elseif self.z or self.y < 0 then 
                        return 270
                else 
                        return 0
                end
        else
                local theta = m.deg(m.atan((self.z or self.y) / self.x))

                if self.x < 0 then 
                        theta = theta + 180 
                end

                if theta < 0 then 
                        theta = theta + 360 
                end

                return theta
        end
end

function Vector:AngleBetween(v1, v2)
        local p1, p2 = (-self + v1), (-self + v2)
        local theta = p1:Polar() - p2:Polar()

        if theta < 0 then 
                theta = theta + 360 
        end

        if theta > 180 then 
                theta = 360 - theta 
        end

        return theta
end

function Vector:Perpendicular()
        return Vector(-self.z, self.y, self.x)
end

function Vector:Perpendicular2()
        return Vector(self.z, self.y, -self.x)
end

function Vector:Extended(to, distance)
        return self + (to - self):Normalized() * distance
end

function Vector:To2D()
        local v = self:Clone()
        local v2D = WorldToScreenPos(v.x, v.y, v.z)
        return Vector(v2D.x, v2D.y)
end

--[[
  ____             _ _ 
 / ___| _ __   ___| | |
 \___ \| '_ \ / _ \ | |
  ___) | |_) |  __/ | |
 |____/| .__/ \___|_|_|
       |_|             
--]]

Spell = class()

function Spell:__init(slot, range)
        self.slot = slot 
        self.range = range
end

function Spell:IsReady()
        return CanCast(self.slot)
end

function Spell:SetSkillShot(delay, speed, width, collision)
        self.delay = delay or 0.25
        self.speed = speed or 0
        self.width = width or 0
        self.collision = collision or false
        self.isSkillshot = true
end

function Spell:SetTargetted(delay, speed)
        self.delay = delay or 0.25
        self.speed = speed or 0
        self.isTargetted = true
end

function Spell:SetActive(delay)
        self.delay = delay or 0
        self.isActive = true
end

function Spell:VPGetLineCastPosition(target, delay, speed)
        local distance = GetDistance(GetOrigin(target))
        local time = delay + distance / speed
        local realDistance = (time * GetMoveSpeed(target))
        if realDistance == 0 then return distance end
        return realDistance
end

function Spell:GetCollision(target, width, range, distance)
        local predPos = GetPredictionPos(target)
        local myHeroPos = GetOrigin(myHero)
        local targetPos = GetOrigin(target)

        local count = 0

        if predPos.x ~= 0 and predPos.z ~= 0 then
                count = CountObjectCollision(0, target, myHeroPos.x, myHeroPos.z, predPos.x, predPos.z, width, range, 10)
        else
                count = CountObjectCollision(0, target, myHeroPos.x, myHeroPos.z, targetPos.x, targetPos.z, width, range, 10)
        end

        if count == 0 then
                return false
        end

        return true
end

function Spell:Cast(target)
        if self.isSkillshot then
                local distance = self:VPGetLineCastPosition(target, self.delay, self.speed)

                if distance > 0 and distance < self.range then
                        if self.collision then
                                if not self:GetCollision(target, self.width, self.range, distance) then
                                        CastSpellToPredictionPos(target, self.slot, distance)
                                end
                        else
                                CastSpellToPredictionPos(target, self.slot, distance)
                        end
                end
        elseif self.isTargetted then
                CastSpellTarget(target, self.slot)
        elseif self.isActive then
                CastSpellTarget(myHero.Addr, self.slot)
        end
end

--[[
  ____                     
 |  _ \ _ __ __ ___      __
 | | | | '__/ _` \ \ /\ / /
 | |_| | | | (_| |\ V  V / 
 |____/|_|  \__,_| \_/\_/  
                           
--]]

Draw = class()

local function DrawLines(t, w, c)
        for i = 1, #t - 1 do
                if t[i].x > 0 and t[i].y > 0 and t[i+1].x > 0 and t[i+1].y > 0 then
                        DrawLineD3DX(t[i].x, t[i].y, t[i + 1].x, t[i + 1].y, w, c)
                end
        end
end

function Draw:Circle2D(x, y, radius, width, quality, color)
        local quality, radius = quality and 2 * m.pi / quality or 2 * m.pi / 20, radius or 50
        local points = {}

        for theta = 0, 2 * m.pi + quality, quality do
                points[#points + 1] = Vector(x + radius * m.cos(theta), y - radius * m.sin(theta))
        end

        DrawLines(points, width or 1, color or Lua_ARGB(255, 255, 255, 255))
end

function Draw:Circle3D(x, y, z, radius, width, quality, color)
        local radius = radius or 300
        local quality = quality and 2 * m.pi / quality or 2 * m.pi / (radius / 5)
        local points = {}

        for theta = 0, 2 * m.pi + quality, quality do
                local c = WorldToScreenPos(Vector(x + radius * m.cos(theta), y, z - radius * m.sin(theta)))
                points[#points + 1] = Vector(c.x, c.y)
        end

        DrawLines(points, width or 1, color or Lua_ARGB(255, 255, 255, 255))
end

function Draw:Line3D(x, y, z, a, b, c, width,color)
        local p1 = WorldToScreenPos(x, y, z)
        local p2 = WorldToScreenPos(a, b, c)
        DrawLineD3DX(p1.x, p1.y, p2.x, p2.y, width or 1,color or Lua_ARGB(255, 255, 255, 255))
end
