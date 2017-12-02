SDK_VERSION = 0.2

----------------------------------------------------------------
-- SANDBOX
----------------------------------------------------------------

local assert 		= assert
local getmetatable 	= assert(getmetatable)
local ipairs 		= assert(ipairs)
local next 		= assert(next)
local pairs 		= assert(pairs)
local rawequal 		= assert(rawequal)
local rawset 		= assert(rawset)
local select 		= assert(select)
local setmetatable 	= assert(setmetatable)
local tonumber 		= assert(tonumber)
local tostring 		= assert(tostring)
local type 		= assert(type)
local require 		= assert(require)
local unpack 		= assert(unpack)

local t, str, m, IO = {}, {}, {}, {}

t.concat = assert(table.concat)
t.insert = assert(table.insert)
t.remove = assert(table.remove)
t.sort   = assert(table.sort)

str.byte 	= assert(string.byte)
str.char 	= assert(string.char)
str.dump 	= assert(string.dump)
str.find 	= assert(string.find)
str.format  	= assert(string.format)
str.gmatch  	= assert(string.gmatch)
str.gsub 	= assert(string.gsub)
str.len 	= assert(string.len)
str.lower 	= assert(string.lower)
str.match 	= assert(string.match)
str.reverse 	= assert(string.reverse)
str.sub 	= assert(string.sub)
str.upper	= assert(string.upper)

m.pi 	= assert(math.pi)
m.huge 	= assert(math.huge)
m.floor = assert(math.floor)
m.ceil 	= assert(math.ceil)
m.abs 	= assert(math.abs)
m.deg 	= assert(math.deg)
m.atan 	= assert(math.atan)
m.sqrt 	= assert(math.sqrt) 
m.sin 	= assert(math.sin) 
m.cos 	= assert(math.cos) 
m.acos 	= assert(math.acos) 
m.max 	= assert(math.max)
m.min 	= assert(math.min)

IO.open  = assert(io.open)
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
        end})
end

----------------------------------------------------------------
-- GLOBALS
----------------------------------------------------------------

_G.myHero = GetMyHero()
_G.SCRIPT_PATH = SCRIPT_PATH .. "\\"
_G.LIB_PATH = SCRIPT_PATH .. "Lib\\"

----------------------------------------------------------------
-- CALLBACKS
----------------------------------------------------------------

local Vision = {}
local NewPath = {}
local VisionTick = GetTickCount()
local WaypointTick = GetTickCount()
local Keys = {}
local KeysActive = false
for i = 1, 255, 1 do
        Keys[i] = false
end

Callback = class()

local Callbacks = {
        ["Load"]          = {},
        ["Tick"]          = {},
        ["Update"]        = {},
        ["Draw"]          = {},
        ["UpdateBuff"]    = {},
        ["RemoveBuff"]    = {},
        ["ProcessSpell"]  = {},
        ["CreateObject"]  = {},
        ["DeleteObject"]  = {},
        ["WndMsg"]        = {},
        ["KeyPress"]      = {},
        ["DoCast"]        = {},
        ["PlayAnimation"] = {},
        ["Vision"]        = {},
        ["NewPath"]       = {}, 
        ["Dash"]          = {},
}

Callback.Add = function(type, cb) t.insert(Callbacks[type], cb) end
Callback.Del = function(type, id) t.remove(Callbacks[type], id or 1) end

local function OnVision(pUnit)   
        local unit = GetAIHero(pUnit)

        if Vision[unit.NetworkId] == nil then 
                Vision[unit.NetworkId] = {state = unit.IsVisible , time = os.clock()} 
        end 

        if Vision[unit.NetworkId].state == true and not unit.IsVisible then
                Vision[unit.NetworkId].state = false 
                Vision[unit.NetworkId].time = os.clock() 
                
                for i, cb in pairs(Callbacks["Vision"]) do
                        cb(unit, Vision[unit.NetworkId].state, Vision[unit.NetworkId].time)             
                end     
        end

        if Vision[unit.NetworkId].state == false and unit.IsVisible then
                Vision[unit.NetworkId].state = true 
                Vision[unit.NetworkId].time = os.clock()  
                for i, cb in pairs(Callbacks["Vision"]) do
                        cb(unit, Vision[unit.NetworkId].state, Vision[unit.NetworkId].time)             
                end     
        end     
end

local function OnWaypoint(pUnit)            
        local unit = GetAIHero(pUnit)
        local unitPosTo = Vector(GetDestPos(pUnit))

        if NewPath[unit.NetworkId] == nil then 
                NewPath[unit.NetworkId] = {pos = unitPosTo , speed = unit.MoveSpeed, time = os.clock()} 
        end 

        if NewPath[unit.NetworkId].pos ~= unitPosTo then                      
                local unitPos = Vector(GetPos(pUnit))
                local isDash = unit.IsDash
                local dashSpeed = unit.DashSpeed or 0
                local dashGravity = unit.DashGravity or 0
                local dashDistance = GetDistance(unitPos, unitPosTo) 

                NewPath[unit.NetworkId] = {startPos = unitPos, pos = unitPosTo , speed = unit.MoveSpeed, time = os.clock()}
                for i, cb in pairs(Callbacks["NewPath"]) do
                        cb(unit, unitPos, unitPosTo, isDash, dashSpeed, dashGravity, dashDistance)         
                end     

                if isDash then
                        for i, cb in pairs(Callbacks["Dash"]) do
                                cb(unit, unitPos, unitPosTo, dashSpeed, dashGravity, dashDistance)            
                        end                                     
                end
        end                             
end

local function OnVisionLoop()      
        if GetTickCount() - VisionTick > 100 then
                SearchAllChamp()                
                local h = pObjChamp
                for k,v in pairs(h) do                  
                        if IsChampion(v) then
                                OnVision(v) 
                        end                            
                end
                VisionTick = GetTickCount()
        end
end

local function OnWaypointLoop()            
        if GetTickCount() - WaypointTick > 100 then
                SearchAllChamp()                
                local h = pObjChamp
                for k, v in pairs(h) do                          
                        if IsChampion(v) then
                                OnWaypoint(v)  
                        end                         
                end
                WaypointTick = GetTickCount()
        end
end

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
        OnVisionLoop() 
        OnWaypointLoop()
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

        name = name or "table"

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

                _type = type(_getType) == "function" and _getType(t) or type(_getType) == "string" and _getType or _type
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

function FileExists(path)
	local f = IO.open(path, "r")

	if f then 
		IO.close(f) 
		return true 
	else 
		return false 
	end
end

function WriteFile(text, path, mode)
        local path = path or SCRIPT_PATH .. "out.txt"
        local f = IO.open(path, mode or "w+")

        if not f then
                return false
        end

        f:write(text)
        f:close()
        return true
end

function ReadFile(path)
	local f = IO.open(path, "r")

	if not f then
		return "WRONG PATH"
	end

	local text = f:read("*all")
	f:close()
	return text
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

function GetAllyHeroes()
        SearchAllChamp()
        local t = pObjChamp

        local result = {}

        for i, v in pairs(t) do
                if IsAlly(v) and IsChampion(v) then
                        table.insert(result, v)
                end
        end

        return result
end

function GetAllHeroes()
        SearchAllChamp()
        local t = pObjChamp

        local result = {}

        for i, v in pairs(t) do
                if IsChampion(v) then
                        table.insert(result, v)
                end
        end

        return result
end
--[[
function GetPathIndex(unit)
        local result = 1--unit.GetPath(1)

        for i= 2, unit.PathCount do
                local myHeroPos = Vector(GetPos(unit.Addr))
                local iPath = Vector(unit.GetPath(i))
                local iMinusPath = Vector(unit.GetPath(i-1))

                if GetDistance(iPath,myHeroPos) < GetDistance(iMinusPath,myHeroPos) and 
                    GetDistance(iPath,iMinusPath) <= GetDistance(iMinusPath,myHeroPos) and i ~= unit.PathCount then
                        result = i --unit.GetPath(i)
                end
        end

        return result
end]]

Callback.Add("Update", function()
        myHero = GetMyHero()
end)

----------------------------------------------------------------
-- Vector
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

function Vector:RotateAroundPoint(v, angle)
	local cos, sin = m.cos(angle), m.sin(angle)
        local x = ((self.x - v.x) * cos) - ((v.y - self.y) * sin) + v.x
        local y = ((v.y - self.y) * cos) + ((self.x - v.x) * sin) + v.y
        return Vector(x, y, self.z or 0)
end

----------------------------------------------------------------
-- Rectangle
----------------------------------------------------------------

local Rectangle = class()

function Rectangle:__init(x, y, width, height)
        if type(x) == "table" then
                self.x = x.x
                self.y = x.y
                self.width = x.width
                self.height = x.height
        else
                self.x = x or 0
                self.y = y or 0
                self.width = width or 0
                self.height = height or 0
        end
end

function Rectangle:Contains(x, y)
        if type(x) == "table" then
                if not self.width then
                        local xmin = x.x
                        local xmax = xmin + x.width
                        local ymin = x.y
                        local ymax = ymin + x.height

                        return ((xmin > self.x and xmin < self.x + width) and (xmax > self.x and xmax < self.x + width))
                                and ((ymin > self.y and ymin < self.y + height) and (ymax > self.y and ymax < self.y + height))
                else
                        return self.x <= x.x and self.x + self.width >= x.x and self.y <= x.y and self.y + self.height >= x.y
                end
        else
                return self.x <= x and self.x + self.width >= x and self.y <= y and self.y + self.height >= y
        end
end

function Rectangle:Draw(color) 
        FilledRectD3DX(self.x, self.y, self.width, self.height, color or Lua_ARGB(255,255,255,255)) 
end

function Rectangle:Draw2(color) 
        FilledRectD3DX_2(self.x, self.y, self.width, self.height, color or Lua_ARGB(255,255,255,255)) 
end

----------------------------------------------------------------
-- Draw
----------------------------------------------------------------

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

----------------------------------------------------------------
-- Menu: Config
----------------------------------------------------------------

local Config = class()

function Config:__init()
        self.fileName = "MenuConfig"
        self.config = {}
end

function Config:Load()
        local gConfig = IncludeFile("Lib\\" .. self.fileName .. ".save")

        if gConfig and type(gConfig) == "table" then
                self.config = gConfig
        end
end

function Config:Save()
        local index = 1
        local buf = {[[local ]]}

        index = index + 1
        buf[index] = table.serialize(self.config, "gConfig")
        index = index + 1
        buf[index] = [[return gConfig]]
        index = index + 1
        buf[index] = "\n"
        index = index + 1

        WriteFile(t.concat(buf), SCRIPT_PATH .. "\\Lib\\" .. self.fileName .. ".save")
end

gConfig = Config()
gConfig:Load()

----------------------------------------------------------------
-- Menu: Properties
----------------------------------------------------------------

local ITEMHEIGHT 	= 30
local ITEMWIDTH 	= 200
local TEXTXOFFSET 	= 0
local TEXTYOFFSET 	= -7
local TOGGLEWIDTH 	= 30
local MENUTEXTCOLOR 	= Lua_ARGB(255, 255, 255, 255)
local MENUBGCOLOR	= Lua_ARGB(175, 0, 0, 0)
local MENUBGACTIVE 	= Lua_ARGB(255, 0, 36, 51)
local MENUBORDERCOLOR   = Lua_ARGB(255, 0, 0, 0)

----------------------------------------------------------------
-- Menu: Util functions
----------------------------------------------------------------

local function stripchars(s, chrs)
        return s:gsub("["..chrs.."]", ''):gsub("%[%]", "")
end

local function stripchars2(s, chrs)
        return s:gsub("%[%]")
end

local function codeToString(code)
        if code >= 48 and code <= 90 then
                return string.char(code)
        elseif code==1 then
                return "LMB"
        elseif code==2 then
                return "RMB"
        elseif code==4 then
                return "MMB"
        elseif code==5 then
                return "MX1"
        elseif code==6 then
                return "MX2"
        elseif code==6 then
                return "MMB"
        elseif code==13 then
                return "Enter"
        elseif code==16 then
                return "Shift"
        elseif code==8 then
                return "Backspace"
        elseif code==9 then
                return "Tab"
        elseif code==13 then
                return "Enter"
        elseif code==16 then
                return "Shift"
        elseif code==17 then
                return "CTRL"
        elseif code==18 then
                return "ALT"
        elseif code==19 then
                return "Pause"
        elseif code==20 then
                return "Caps Lock"
        elseif code==27 then
                return "Escape"
        elseif code==32 then
                return "SPACE"
        elseif code==33 then
                return "PageUP"
        elseif code==34 then
                return "PageDown"
        elseif code==35 then
                return "End"
        elseif code==36 then
                return "Home"
        elseif code==37 then
                return "Left"
        elseif code==38 then
                return "Up"
        elseif code==39 then
                return "Right"
        elseif code==40 then
                return "Down"
        elseif code==44 then
                return "PrintSc"
        elseif code==45 then
                return "Insert"
        elseif code==46 then
                return "Del"
        elseif code==47 then
                return "Help"
        elseif code==91 then
                return "lWindow"
        elseif code==92 then
                return "rWindow"
        elseif code==93 then
                return "Select"
        elseif code==96 then
                return "Num 0"
        elseif code==97 then
                return "Num 1"
        elseif code==98 then
                return "Num 2"
        elseif code==99 then
                return "Num 3"
        elseif code==100 then
                return "Num 4"
        elseif code==101 then
                return "Num 5"
        elseif code==102 then
                return "Num 6"
        elseif code==103 then
                return "Num 7"
        elseif code==104 then
                return "Num 8"
        elseif code==105 then
                return "Num 9"
        elseif code==106 then
                return "Num *"
        elseif code==107 then
                return "Num +"
        elseif code==109 then
                return "Num -"
        elseif code==111 then
                return "Num /"
        elseif code==112 then
                return "F1"
        elseif code==113 then
                return "F2"
        elseif code==114 then
                return "F3"
        elseif code==115 then
                return "F4"
        elseif code==116 then
                return "F5"
        elseif code==117 then
                return "F6"
        elseif code==118 then
                return "F7"
        elseif code==119 then
                return "F8"
        elseif code==120 then
                return "F9"
        elseif code==121 then
                return "F10"
        elseif code==122 then
                return "F11"
        elseif code==123 then
                return "F12"
        else 
        	return tostring(code) 
        end
end

local function GetTextWidth(text, offset)
        local ret = offset or 0

        for c in text:gmatch"." do
                if c==" " then 
                        ret = ret + 4
                elseif tonumber(c) ~= nil then 
                        ret = ret + 6
                elseif c == str.upper(c) then 
                        ret = ret + 8
                elseif c == str.lower(c) then 
                        ret = ret + 7
                else 
                        ret = ret + 5 
                end
        end

        return ret
end

local function GetLongestString(textList)
        local mx = 0

        for i, s in ipairs(textList) do
                local l = GetTextWidth(s)
                if l > mx then
                        mx = l
                end
        end

        return mx
end

----------------------------------------------------------------
-- Menu: Main Menu
----------------------------------------------------------------

MainMenu = {}

function MainMenu.new()
        local this = {}

        if gConfig.config.menu == nil then
                gConfig.config.menu={}
        end
        this.conf=gConfig.config.menu
        if gConfig.config.menuX==nil then
                gConfig.config.menuX=300
        end
        if gConfig.config.menuY==nil then
                gConfig.config.menuY=300
        end
        
        this.children = {}
        
        this.pos=Vector(gConfig.config.menuX, gConfig.config.menuY)
        this.setpos=Vector(gConfig.config.menuX, gConfig.config.menuY)
        this.width = width or ITEMWIDTH
        this.fullHeight = 0
        this.active = false
        
        function this.inputProcessor(key, pressed)
                if key == 160 then 
                        if pressed then
                                this.show()
                        else
                                this.hide()
                        end
                end
                if not this.active then return end
                local mousevec = Vector(GetCursorPos())
                for num, item in ipairs(this.children) do
                        item.processInput(key, pressed, mousevec)
                end
                
        end
        
        this.proc = RegisterOnKeyPress(this.inputProcessor)
        
        function this.show()
                this.active=true
                for num, item in ipairs(this.children) do
                        item.show()
                end
        end
        
        function this.hide()
                this.active=false
                for num, item in pairs(this.children) do
                        item.hide()
                        this.conf[item.name]=item.getValue(true)
                end
                gConfig.config.menuX=this.pos.x
                gConfig.config.menuY=this.pos.y
                gConfig:Save()
        end
        function this.addItem(MenuItem)
                local free=1
                for num, item in ipairs(this.children) do
                        free=free+1
                end
                MenuItem.name=stripchars(MenuItem.name, "\n\a\b\f\r\t\v\"%[%]" )
                this.expandMain(MenuItem.textlengthAdd+GetTextWidth(MenuItem.name, 0))
                MenuItem.setPosition(this.pos)
                MenuItem.setWidthInternal(this.width)
                MenuItem.parent=this
                MenuItem.mainMenu=this
                this.children[free]=MenuItem
                this.calculateY()
                if this.conf[MenuItem.name]~=nil then
                        MenuItem.setValue(this.conf[MenuItem.name])
                end
                return MenuItem
        end
        
        function this.deactivateAll()
                for num, item in ipairs(this.children) do
                        item.active=false
                end
        end
        
        function this.setMenuPosition(pos)
                this.setpos=Vector(pos)
        end
        
        function this.calculateY()
                local yOffset=0
                for i, item in ipairs(this.children) do
                        item.setYoffset(yOffset)
                        yOffset=yOffset+(item.rectangle.height or 0)
                end
                this.fullHeight=yOffset
                return MenuItem
        end
        
        function this.expandMain(newWidth)
                if newWidth>this.width then
                        this.width=newWidth
                        for i, item in ipairs(this.children) do
                                item.setWidthInternal(newWidth)
                        end
                end
        end
        
        function this.onLoop()
                if not this.active then return end
                if not (this.pos.x == this.setpos.x and this.pos.y == this.setpos.y) then
                        this.pos=this.setpos
                        for num, item in ipairs(this.children) do
                                item.setPosition(this.setpos)
                        end
                end
                for i, item in pairs(this.children) do
                        item.onLoop()
                end
                FilledRectD3DX_2(this.pos.x,this.pos.y,1,this.fullHeight+1, MENUBORDERCOLOR)
                FilledRectD3DX_2(this.pos.x+this.width,this.pos.y,1,this.fullHeight+1, MENUBORDERCOLOR)
                FilledRectD3DX_2(this.pos.x,this.pos.y+this.fullHeight,this.width,1, MENUBORDERCOLOR)
        end
        
        return this
end

----------------------------------------------------------------
-- Menu: Sub Menu
----------------------------------------------------------------

SubMenu = {}

function SubMenu.new(name, color)
        local this = {}

        this.conf = {}
        this.name = name or "Unnamed"
        this.parent=parent
        this.mainMenu=nil
        this.textY=0
        this.pos= Vector()
        this.rectangle = Rectangle(0, 0, ITEMWIDTH, ITEMHEIGHT)
        this.active=false
        this.allowDrag=true
        this.dragPos=Vector()
        this.dragging=false
        this.dragUnlocked=false
        this.fullHeight = 0
        this.yOffset=0
        this.childWidth= ITEMWIDTH
        this.color = color or MENUTEXTCOLOR
        this.children = {}
        
        this.textlengthAdd=55
        
        function this.getValue()
                for num, item in pairs(this.children) do
                        this.conf[item.name]=item.getValue(true)
                end
                return this.conf
        end
        
        function this.setValue(val)
                this.conf=val
        end

        function this.setColor(color)
                this.color = color
        end
        
        function this.processInput(key, pressed, mouseVector)
        
                if key==1 and not pressed then
                        this.dragging=false
                end
                if key==1 and this.rectangle:Contains(mouseVector) and pressed then
                                this.dragging=true
                                this.dragUnlocked=false
                                this.dragPos=Vector(mouseVector)
                                this.parent.deactivateAll()
                                this.deactivateAll()
                                this.active=true
                end

                if not this.active then return end
                for num, item in ipairs(this.children) do
                        item.processInput(key, pressed, mouseVector)
                end
        end
        
        function this.show()
                for num, item in ipairs(this.children) do
                        item.show()
                end
        end
        
        function this.hide()
                this.dragging=false
                for num, item in ipairs(this.children) do
                        item.hide()
                end
        end
        
        function this.addItem(MenuItem)
                local free=1
                for num, item in ipairs(this.children) do
                        free=free+1
                end 
                MenuItem.name=stripchars(MenuItem.name, "\n\a\b\f\r\t\v\"%[%]" )
                MenuItem.parent=this
                MenuItem.mainMenu=this.mainMenu
                this.expandChild(MenuItem.textlengthAdd+GetTextWidth(MenuItem.name, 0))
                MenuItem.setWidthInternal(this.childWidth)
                MenuItem.setPosition(Vector(this.pos.x+this.rectangle.width, this.pos.y+this.yOffset))
                this.children[free]=MenuItem
                this.calculateY()
                if this.conf[MenuItem.name]~=nil then
                        MenuItem.setValue(this.conf[MenuItem.name])
                end
                return MenuItem
        end
        
        function this.setYoffset(newoff)
                this.yOffset=newoff
                this.rectangle.y=this.yOffset+this.pos.y
                this.textY=this.rectangle.y+this.rectangle.height/2+TEXTYOFFSET
        end
        
        function this.setPosition(v)
                this.pos=v
                this.rectangle.x=v.x
                this.rectangle.y=this.yOffset+this.pos.y
                this.textY=this.rectangle.y+this.rectangle.height/2+TEXTYOFFSET
                this.setChildPos(Vector(this.pos.x+this.rectangle.width, this.pos.y+this.yOffset))
        end
        
        function this.setWidth(newWidth)
                if this.parent.setChildWidth~=nil then 
                        this.parent.setChildWidth(newWidth) 
                else
                        this.parent.expandMain(newWidth)
                end
        end
        
        function this.expand(newWidth)
                if this.parent.expandChild~=nil then 
                        this.parent.expandChild(newWidth) 
                else
                        this.parent.expandMain(newWidth)
                end
        end
        
        function this.expandChild(newWidth)
                if newWidth>this.childWidth then
                        this.childWidth=newWidth
                        for i, item in ipairs(this.children) do
                                item.setWidthInternal(newWidth)
                        end
                end
        end
        
        function this.setWidthInternal(newWidth)
                this.rectangle.width=newWidth
                this.setChildPos(Vector(this.pos.x+this.rectangle.width, this.pos.y+this.yOffset))
        end
        
        function this.setHeight(newHeight)
                this.rectangle.height=newHeight
                this.textY=this.rectangle.y+this.rectangle.height/2+TEXTYOFFSET
                this.setChildPos(Vector(this.pos.x+this.rectangle.width, this.rectangle.y))
                this.parent.calculateY()
        end
        
        function this.setChildWidth(newWidth)
                this.childWidth=(newWidth)
                this.setChildPos(Vector(this.pos.x+this.rectangle.width, this.rectangle.y))
                for i, item in ipairs(this.children) do
                        item.setWidthInternal(newWidth)
                end
        end
        
        function this.setChildPos(v)
                for num, item in ipairs(this.children) do
                        item.setPosition(v)
                end
        end
        
        function this.deactivateAll()
                for num, item in ipairs(this.children) do
                        item.active=false
                end
        end
        
        function this.calculateY()
        	local yOffset=0
                for i, item in ipairs(this.children) do
                        item.setYoffset(yOffset)
                        yOffset=yOffset+(item.rectangle.height or 0)
                end
                this.fullHeight=yOffset
                return MenuItem
        end
        
        function this.onLoop()
        
                if this.active then
                        if this.dragging then
                                tempVec= Vector(GetCursorPos()) - this.dragPos
                                if this.dragUnlocked then
                                        this.dragPos=Vector(GetCursorPos())
                                        this.mainMenu.setMenuPosition(tempVec + this.mainMenu.pos)
                                elseif not this.dragUnlocked and tempVec:Len2()>100 then
                                        this.dragUnlocked=true
                                        this.dragPos=Vector(GetCursorPos())
                                end
                        end
                        this.rectangle:Draw(MENUBGACTIVE)
                else
                        this.rectangle:Draw2(MENUBGCOLOR)
                end 
                DrawTextD3DX(this.pos.x+this.rectangle.width-15, this.textY, ">", MENUTEXTCOLOR)
                DrawTextD3DX(this.pos.x+5, this.textY, this.name, this.color)
                FilledRectD3DX_2(this.rectangle.x,this.rectangle.y,this.rectangle.width,1,MENUBORDERCOLOR)
                
                if not this.active then return end

                
                if next(this.children) == nil then return end
                
                for i, item in pairs(this.children) do
                        item.onLoop()
                end
                FilledRectD3DX_2(this.pos.x+this.rectangle.width,this.rectangle.y,1,this.fullHeight+1, MENUBORDERCOLOR)
                FilledRectD3DX_2(this.pos.x+this.rectangle.width+this.childWidth,this.rectangle.y,1,this.fullHeight+1, MENUBORDERCOLOR)
                FilledRectD3DX_2(this.pos.x+this.rectangle.width,this.rectangle.y+this.fullHeight,this.childWidth,1, MENUBORDERCOLOR)

        end
        
        return this
end

----------------------------------------------------------------
-- Menu: Bool
----------------------------------------------------------------

MenuBool = {}

function MenuBool.new(name, active)
        local this = {}
        this.name = name or "Unnamed"
        this.valueActive=active or false
        this.parent=parent
        this.mainMenu=nil
        this.textY=0
        this.yOffset=0
        this.pos=Vector()
        this.rectangle = Rectangle(0, 0, ITEMWIDTH, ITEMHEIGHT)
        this.activeRectangle = Rectangle(0, 0, TOGGLEWIDTH, ITEMHEIGHT)
        this.textlengthAdd=60

        this.allowDrag=true
        this.dragPos=Vector()
        this.dragging=false
        this.dragUnlocked=false
        
        function this.processInput(key, pressed, mouseVector)
                if key==1 and pressed and this.activeRectangle:Contains(mouseVector) then
                        this.valueActive = not this.valueActive
                end
                if key==1 and not pressed then
                        this.dragging=false
                end
                if key==1 and this.rectangle:Contains(mouseVector) and pressed then
                                this.dragging=true
                                this.dragUnlocked=false
                                this.dragPos=Vector(mouseVector)
                                this.active=true
                end
        end

        function this.getValue()
                return this.valueActive
        end
        
        function this.setValue(va)
                if type(va)~="boolean" then return end
                this.valueActive=va
        end
        
        function this.expand(newWidth)
                this.parent.expandChild(newWidth)
        end
        
        function this.setYoffset(newoff)
                this.yOffset=newoff
                this.rectangle.y=this.pos.y+this.yOffset
                this.activeRectangle.y=this.rectangle.y
                this.textY=this.rectangle.y+this.rectangle.height/2+TEXTYOFFSET
        end
        
        function this.setPosition(v)
                this.rectangle.x=v.x
                this.activeRectangle.x=this.rectangle.x+this.rectangle.width-TOGGLEWIDTH
                this.pos=v
                this.rectangle.y=this.pos.y+this.yOffset
                this.activeRectangle.y=this.rectangle.y
                this.textY=this.rectangle.y+this.rectangle.height/2+TEXTYOFFSET
        end
        
        function this.setWidth(newWidth)
                if this.parent.setChildWidth~=nil then 
                        this.parent.setChildWidth(newWidth) 
                else
                        this.parent.expandMain(newWidth)
                end
        end
        
        function this.setWidthInternal(newWidth)
                this.rectangle.width=newWidth
                this.activeRectangle.x=this.rectangle.x+newWidth-TOGGLEWIDTH
        end
        
        function this.setHeight(newHeight)
                this.rectangle.height=newHeight
                this.activeRectangle.height=this.rectangle.height
                this.textY=this.rectangle.y+this.height/2+TEXTYOFFSET
                this.parent.calculateY()
        end

        function this.onLoop()
                if this.active then
                        if this.dragging then
                                tempVec = Vector(GetCursorPos()) - this.dragPos
                                if this.dragUnlocked then
                                        this.dragPos = Vector(GetCursorPos())
                                        this.mainMenu.setMenuPosition(tempVec + this.mainMenu.pos)
                                elseif not this.dragUnlocked and tempVec:Len2()>100 then
                                        this.dragUnlocked=true
                                        this.dragPos = Vector(GetCursorPos())
                                end
                        end
                end
                
                this.rectangle:Draw2(MENUBGCOLOR)
                if this.valueActive then
                        this.activeRectangle:Draw(Lua_ARGB(255, 2, 171, 232))
                        DrawTextD3DX(this.pos.x+this.rectangle.width-25, this.textY, "On", MENUTEXTCOLOR)
                else
                        this.activeRectangle:Draw(Lua_ARGB(255, 36, 36, 36))
                        DrawTextD3DX(this.pos.x+this.rectangle.width-25, this.textY, "Off", MENUTEXTCOLOR)
                end
                FilledRectD3DX_2(this.activeRectangle.x-1,this.activeRectangle.y,1,this.activeRectangle.height,MENUBORDERCOLOR)
                DrawTextD3DX(this.pos.x+5, this.textY, this.name, MENUTEXTCOLOR)
                FilledRectD3DX_2(this.rectangle.x,this.rectangle.y,this.rectangle.width,1,MENUBORDERCOLOR)
        end
        function this.show()
        end
        
        function this.hide()

        end
        return this
end

----------------------------------------------------------------
-- Menu: Slider
----------------------------------------------------------------

MenuSlider = {}

function MenuSlider.new(name, value, mi, ma, step)
        local this = {}

        this.name = name or "Unnamed"
        this.min = mi or 0
        this.max = ma or 10
        
        if value==nil or value<mi then
                this.value=mi
        else
                this.value=value
        end
        
        this.step = step or 1
        this.sliderActive = false
        this.places = math.calcRounding(this.step)
        this.parent = parent
        this.mainMenu=nil
        this.textY=0
        this.yOffset=0
        this.pos=Vector()
        this.rectangle = Rectangle(0, 0, ITEMWIDTH, ITEMHEIGHT)
        this.sliderRectangle = Rectangle(0, 0,      2, ITEMHEIGHT)
        this.textlengthAdd=20+GetTextWidth(string.format("%."..this.places.."f", this.max))
        
        function this.processInput(key, pressed, mouseVector)
                if key~=1 then return end
                if pressed and this.rectangle:Contains(mouseVector) then
                        this.sliderActive = true
                        return
                end
                this.sliderActive=false
        end

        function this.getValue()
                return this.value
        end
        
        function this.setValue(va)
                if type(va)~="number" then return end
                va=va or 0
                local val = math.roundStep(va, this.step)
                if val<this.min then val=this.min end
                if val>this.max then val=this.max end
                this.value=val
                this.updateSlider()
        end
        
        function this.expand(newWidth)
                this.parent.expandChild(newWidth)
        end
        
        function this.updateSlider()
                this.sliderRectangle.x=2+this.rectangle.x+(this.rectangle.width-5)*(this.value-this.min)/(this.max-this.min)
                this.sliderRectangle.y=this.rectangle.y
        end
        
        function this.setYoffset(newoff)
                this.yOffset=newoff
                this.rectangle.y=this.pos.y+this.yOffset
                this.sliderRectangle.y=this.rectangle.y
                this.updateSlider()
                this.textY=this.rectangle.y+this.rectangle.height/2+TEXTYOFFSET
        end
        
        function this.setPosition(v)
                this.rectangle.x=v.x
                this.pos=v
                this.rectangle.y=this.pos.y+this.yOffset
                this.sliderRectangle.y=this.rectangle.y
                this.updateSlider()
                this.textY=this.rectangle.y+this.rectangle.height/2+TEXTYOFFSET
        end
        
        function this.setWidth(newWidth)
                if this.parent.setChildWidth~=nil then 
                        this.parent.setChildWidth(newWidth) 
                else
                        this.parent.expandMain(newWidth)
                end
        end
        
        function this.setWidthInternal(newWidth)
                this.rectangle.width=newWidth
                this.updateSlider()
        end
        
        function this.setHeight(newHeight)
                this.rectangle.height=newHeight
                this.sliderRectangle.height=this.rectangle.height
                this.updateSlider()
                
                this.textY=this.rectangle.y+this.height/2+TEXTYOFFSET
                this.parent.calculateY()
        end

        function this.onLoop()
                if this.sliderActive then
                        local val = math.roundStep(Vector(Vector(GetCursorPos()) - Vector(this.rectangle)).x/this.rectangle.width*(this.max-this.min)+this.min, this.step)
                        if val<this.min then val=this.min end
                        if val>this.max then val=this.max end
                        this.value=val
                        this.updateSlider()
                end
                this.rectangle:Draw2(MENUBGCOLOR)
                this.sliderRectangle:Draw(4278190335)
                DrawTextD3DX(this.pos.x+5, this.textY, this.name, MENUTEXTCOLOR)
                local textval=str.format("%."..this.places.."f", this.value)
                DrawTextD3DX(this.pos.x+this.rectangle.width-GetTextWidth(textval, 10), this.textY, textval, MENUTEXTCOLOR)
                
                FilledRectD3DX_2(this.rectangle.x,this.rectangle.y,this.rectangle.width,1,MENUBORDERCOLOR)
        end
        
        function this.show()
        end
        
        function this.hide()
        	this.sliderActive=false
        end

        return this
end

----------------------------------------------------------------
-- Menu: Main Separator
----------------------------------------------------------------

MenuSeparator = {}

function MenuSeparator.new(name, center, color)
        local this = {}

        this.name = name or "Unnamed"
        this.parent=parent
        this.mainMenu=nil
        this.textX=0
        this.textY=0
        this.textW = GetTextWidth(name, 0)
        this.textCenter = center or false
        this.yOffset=0
        this.pos=Vector()
        this.rectangle = Rectangle(0, 0, ITEMWIDTH, ITEMHEIGHT)
        this.textlengthAdd=20
        
        this.allowDrag=true
        this.dragPos=Vector()
        this.dragging=false
        this.dragUnlocked=false

        this.color = color or MENUTEXTCOLOR
        
        function this.processInput(key, pressed, mouseVector)
                if key==1 and not pressed then
                        this.dragging=false
                end
                if key==1 and this.rectangle:Contains(mouseVector) and pressed then
                                this.dragging=true
                                this.dragUnlocked=false
                                this.dragPos=Vector(mouseVector)
                                this.active=true
                end
        end

        function this.getValue()
                return this.name
        end

        function this.setValue(val)
                this.name = val
        end

        function this.setColor(color)
                this.color = color
        end
        
        function this.expand(newWidth)
                this.parent.expandChild(newWidth)
        end
        
        function this.setYoffset(newoff)
                this.yOffset=newoff
                this.rectangle.y=this.pos.y+this.yOffset
                this.textX = this.rectangle.x + this.rectangle.width/2+TEXTXOFFSET
                this.textY=this.rectangle.y+this.rectangle.height/2+TEXTYOFFSET
        end
        
        function this.setPosition(v)
                this.rectangle.x=v.x
                this.pos=v
                this.rectangle.y=this.pos.y+this.yOffset
                this.textX=this.rectangle.x+this.rectangle.width/2+TEXTXOFFSET
                this.textY=this.rectangle.y+this.rectangle.height/2+TEXTYOFFSET
        end
        
        function this.setWidth(newWidth)
                if this.parent.setChildWidth~=nil then 
                        this.parent.setChildWidth(newWidth) 
                else
                        this.parent.expandMain(newWidth)
                end
        end
        
        function this.setWidthInternal(newWidth)
                this.rectangle.width=newWidth
        end
        
        function this.setHeight(newHeight)
                this.rectangle.height=newHeight
                this.textY=this.rectangle.y+this.height/2+TEXTYOFFSET
                this.parent.calculateY()
        end

        function this.onLoop()
                if this.active then
                        if this.dragging then
                                tempVec=Vector(GetCursorPos()) - this.dragPos
                                if this.dragUnlocked then
                                        this.dragPos=Vector(GetCursorPos())
                                        this.mainMenu.setMenuPosition(tempVec + this.mainMenu.pos)
                                elseif not this.dragUnlocked and tempVec:Len2()>100 then
                                        this.dragUnlocked=true
                                        this.dragPos=Vector(GetCursorPos())
                                end
                        end
                end
        
                local textH = this.textCenter and (this.textX - (this.textW/2)) or this.pos.x + 5

                this.rectangle:Draw2(MENUBGCOLOR)
                DrawTextD3DX(textH, this.textY, this.name, this.color)
                FilledRectD3DX_2(this.rectangle.x,this.rectangle.y,this.rectangle.width,1,MENUBORDERCOLOR)
        end
        
        function this.show()
        end
        
        function this.hide()
                this.dragging=false
        end
        
        return this
end

----------------------------------------------------------------
-- Menu: Keybind
----------------------------------------------------------------

MenuKeyBind = {}

function MenuKeyBind.new(name, keycode)
        local this = {}

        this.name = name or "Unnamed"
        this.keycode = keycode or 0
        this.parent=parent
        this.mainMenu=nil
        this.textY=0
        this.yOffset=0
        this.pos=Vector()
        this.rectangle = Rectangle(0, 0, ITEMWIDTH, ITEMHEIGHT)
        this.activeRectangle = Rectangle(0, 0, TOGGLEWIDTH, ITEMHEIGHT)
        this.waitingForKey=false
        this.keycodeString=codeToString(this.keycode)
        this.textlengthAdd=90
        
        function this.processInput(key, pressed, mouseVector)
                if this.waitingForKey and pressed and (key~=1 or this.rectangle:Contains(mouseVector)) then
                        this.keycode = key
                        this.keycodeString=codeToString(this.keycode)
                        this.waitingForKey=false
                end
                if key==1 and pressed then
                        if this.rectangle:Contains(mouseVector) then
                                this.waitingForKey=true
                                this.keycodeString="Select New Key"
                        else
                                this.waitingForKey=false
                                this.keycodeString=codeToString(this.keycode)
                        end
                end
        end

        function this.getValue(a)
                if a==nil then return GetKeyPress(this.keycode) > 0 end
                return this.keycode
        end
        
        function this.setValue(va)
                if type(va)~="number" then return end
                this.keycode = math.abs(math.round(va))
                this.keycodeString=codeToString(this.keycode)
        end
        
        function this.setWidth(newWidth)
                if this.parent.setChildWidth~=nil then 
                        this.parent.setChildWidth(newWidth) 
                else
                        this.parent.expandMain(newWidth)
                end
        end
        
        function this.setYoffset(newoff)
                this.yOffset=newoff
                this.rectangle.y=this.pos.y+this.yOffset
                this.activeRectangle.y=this.rectangle.y
                this.textY=this.rectangle.y+this.rectangle.height/2+TEXTYOFFSET
        end
        
        function this.setPosition(v)
                this.rectangle.x=v.x
                this.activeRectangle.x=this.rectangle.x+this.rectangle.width-TOGGLEWIDTH
                this.pos=v
                this.rectangle.y=this.pos.y+this.yOffset
                this.activeRectangle.y=this.rectangle.y
                this.textY=this.rectangle.y+this.rectangle.height/2+TEXTYOFFSET
        end
        
        function this.setWidth(newWidth)
                if this.parent.expand~=nil then this.parent.expand(newWidth) end
                if this.parent.setChildWidth~=nil then this.parent.setChildWidth(newWidth) end
        end
        
        function this.setWidthInternal(newWidth)
                this.rectangle.width=newWidth
                this.activeRectangle.x=this.rectangle.x+newWidth-TOGGLEWIDTH
        end
        
        function this.setHeight(newHeight)
                this.rectangle.height=newHeight
                this.activeRectangle.height=this.rectangle.height
                this.textY=this.rectangle.y+this.height/2+TEXTYOFFSET
                this.parent.calculateY()
        end

        function this.onLoop()
                this.rectangle:Draw2(MENUBGCOLOR)
                if this.getValue() then
                        this.activeRectangle:Draw(Lua_ARGB(255, 2, 171, 232))
                        DrawTextD3DX(this.pos.x+this.rectangle.width-24, this.textY, "On",MENUTEXTCOLOR)
                else
                        this.activeRectangle:Draw(Lua_ARGB(255, 36, 36, 36))
                        DrawTextD3DX(this.pos.x+this.rectangle.width-24, this.textY, "Off",MENUTEXTCOLOR)
                end
                FilledRectD3DX_2(this.activeRectangle.x-1,this.activeRectangle.y,1,this.activeRectangle.height,MENUBORDERCOLOR)
                DrawTextD3DX(this.pos.x+5, this.textY, string.format("%s [%s]",this.name, this.keycodeString),MENUTEXTCOLOR)
                FilledRectD3DX_2(this.rectangle.x,this.rectangle.y,this.rectangle.width,1,MENUBORDERCOLOR)
        end
        
        function this.show()
        end
        
        function this.hide()
                if this.waitingForKey then
                        this.waitingForKey=false
                        this.keycodeString=tostring(this.keycode)
                end
        end
        return this
end

----------------------------------------------------------------
-- Menu: String List
----------------------------------------------------------------

MenuStringList = {}

function MenuStringList.new(name, stringlist, index)
        local this = {}

        this.name = name or "Unnamed"
        this.stringlist=stringlist or {"Empty"}
        this.selectedIndex=index or 1
        this.parent=parent
        this.mainMenu=nil
        this.textY=0
        this.yOffset=0
        this.pos=Vector()
        this.rectangle = Rectangle(0, 0, ITEMWIDTH, ITEMHEIGHT)
        this.leftRectangle = Rectangle(0, 0, TOGGLEWIDTH, ITEMHEIGHT)
        this.rightRectangle = Rectangle(0, 0, TOGGLEWIDTH, ITEMHEIGHT)
        this.textlengthAdd= 80 + GetLongestString(this.stringlist)
        this.isShow = false

        
        function this.processInput(key, pressed, mouseVector)
                if isShow and key==1 and pressed then
                        if this.leftRectangle:Contains(mouseVector) then
                                if this.selectedIndex==1 then 
                                        this.selectedIndex=#this.stringlist
                                else
                                        this.selectedIndex=this.selectedIndex-1
                                end
                        elseif this.rightRectangle:Contains(mouseVector) then
                                if this.selectedIndex==#this.stringlist then 
                                        this.selectedIndex=1
                                else
                                        this.selectedIndex=this.selectedIndex+1
                                end
                        end
                end
        end

        function this.getValue()
                return this.selectedIndex
        end
        
        function this.setValue(va)
                this.selectedIndex=(math.abs(math.round(va-1))%#this.stringlist)+1
        end
        
        function this.expand(newWidth)
                this.parent.expandChild(newWidth)
        end
        
        function this.setYoffset(newoff)
                this.yOffset=newoff
                this.rectangle.y=this.pos.y+this.yOffset
                this.leftRectangle.y=this.rectangle.y
                this.rightRectangle.y=this.rectangle.y
                this.textY=this.rectangle.y+this.rectangle.height/2+TEXTYOFFSET
        end
        
        function this.setPosition(v)
                this.rectangle.x=v.x
                this.leftRectangle.x=this.rectangle.x+this.rectangle.width-TOGGLEWIDTH*2-2
                this.rightRectangle.x=this.rectangle.x+this.rectangle.width-TOGGLEWIDTH
                this.pos=v
                this.rectangle.y=this.pos.y+this.yOffset
                this.leftRectangle.y=this.rectangle.y
                this.rightRectangle.y=this.rectangle.y
                this.textY=this.rectangle.y+this.rectangle.height/2+TEXTYOFFSET
        end
        
        function this.setWidth(newWidth)
                if this.parent.setChildWidth~=nil then 
                        this.parent.setChildWidth(newWidth) 
                else
                        this.parent.expandMain(newWidth)
                end
        end
        
        function this.setWidthInternal(newWidth)
                this.rectangle.width=newWidth
                this.leftRectangle.x=this.rectangle.x+newWidth-TOGGLEWIDTH*2-2
                this.rightRectangle.x=this.rectangle.x+newWidth-TOGGLEWIDTH
        end
        
        function this.setHeight(newHeight)
                this.rectangle.height=newHeight
                
                this.leftRectangle.height=this.rectangle.height
                this.rightRectangle.height=this.rectangle.height
                
                this.textY=this.rectangle.y+this.height/2+TEXTYOFFSET
                this.parent.calculateY()
        end

        function this.onLoop()
                this.rectangle:Draw2(MENUBGCOLOR)
                
                this.leftRectangle:Draw(Lua_ARGB(255, 0, 36, 51))
                this.rightRectangle:Draw(Lua_ARGB(255, 0, 36, 51))
                FilledRectD3DX_2(this.leftRectangle.x-2,this.leftRectangle.y,1,this.leftRectangle.height,MENUBORDERCOLOR)
                FilledRectD3DX_2(this.rightRectangle.x-2,this.rightRectangle.y,1,this.rightRectangle.height,MENUBORDERCOLOR)
                DrawTextD3DX(this.rightRectangle.x+10, this.textY, ">",MENUTEXTCOLOR)
                DrawTextD3DX(this.leftRectangle.x+10, this.textY, "<",MENUTEXTCOLOR)
                DrawTextD3DX(this.pos.x+5, this.textY, this.name,MENUTEXTCOLOR)
                DrawTextD3DX(this.leftRectangle.x-GetTextWidth(this.stringlist[this.selectedIndex], 5), this.textY, this.stringlist[this.selectedIndex], MENUTEXTCOLOR)
                FilledRectD3DX_2(this.rectangle.x,this.rectangle.y,this.rectangle.width,1,MENUBORDERCOLOR)
        end

        function this.show()
                isShow = true
        end
        
        function this.hide()
                isShow = false
        end

        return this
end

----------------------------------------------------------------
-- Menu: Init
----------------------------------------------------------------

menuInst = MainMenu.new() 
menuInstSep = menuInst.addItem(MenuSeparator.new("TOIR MENU", true))

Callback.Add("Draw", function()
        menuInst.onLoop()
end)

----------------------------------------------------------------
-- Spell
----------------------------------------------------------------

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

function Spell:CastToPos(pos)
        CastSpellToPos(pos.x, pos.z, self.slot)
end

----------------------------------------------------------------
-- Damage Lib
----------------------------------------------------------------

local function GetBonusDmg(unit) return unit.BonusDmg end
local function GetBonusAP(unit) return unit.MagicDmg end
local function GetMaxHP(unit) return unit.MaxHP end
local function GetCurrentHP(unit) return unit.HP end
local function GetLevel(unit) return unit.Level end
local function GetPercentHP(unit) return unit.MaxHP / unit.HP * 100 end
local function GetArmor(unit) return unit.Armor end
local function GetBaseArmor(unit) return unit.BonusArmor end
local function GetMaxMana(unit) return unit.MaxMP end

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

  ["Xayah"] = {
    {Slot = "E", Stage = 1, DamageType = 1, Damage = function(source, target, level) return ({55, 65, 75, 85, 95})[level] + 0.6 * source.BonusDmg end},
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
                                                return source.CalcDamage(target.Addr, spells.Damage(source, target, level))
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

----------------------------------------------------------------
-- Target Selector
----------------------------------------------------------------

TargetSelector = class()

function TargetSelector:__init(range, damageType, from, focusSelected, menu, draw)
        self.range = range or -1
        self.damageType = damageType or 1
        self.from = from
        self.focusSelected = focusSelected or false

        self.CalcDamage = function(target, DamageType, value) 
                return DamageType == 1 and myHero.CalcDamage(target, value) or myHero.CalcMagicDamage(target, value)
        end

        self.sorting = {
                [1] = function(a,b) a = GetAIHero(a); b = GetAIHero(b); return self.CalcDamage(a, self.damageType, 100) / (1 + a.HP) * self:GetPriority(a) > self.CalcDamage(b, self.damageType, 100) / (1 + b.HP) * self:GetPriority(b) end,
                [2] = function(a,b) a = GetAIHero(a); b = GetAIHero(b); return self.CalcDamage(a, 1, 100) / (1 + a.HP) * self:GetPriority(a) > self.CalcDamage(b, 1, 100) / (1 + b.HP) * self:GetPriority(b) end,
                [3] = function(a,b) a = GetAIHero(a); b = GetAIHero(b); return self.CalcDamage(a, 2, 100) / (1 + a.HP) * self:GetPriority(a) > self.CalcDamage(b, 2, 100) / (1 + b.HP) * self:GetPriority(b) end,
                [4] = function(a,b) a = GetAIHero(a); b = GetAIHero(b); return a.HP < b.HP end,
                [5] = function(a,b) a = GetAIHero(a); b = GetAIHero(b); return a.TotalDmg > b.TotalDmg end,
                [6] = function(a,b) a = GetAIHero(a); b = GetAIHero(b); return a.MagicDmg > b.MagicDmg end,
                [7] = function(a,b) a = GetAIHero(a); b = GetAIHero(b); return GetDistance(a, self.from and self.from or myHero) < GetDistance(b, self.from and self.from or myHero) end,
                [8] = function(a,b) a = GetAIHero(a); b = GetAIHero(b); return GetDistance(a, GetMousePos()) < GetDistance(b, GetMousePos()) end
        }

        self.SelectedTarget = nil

        if menu then
                self.tsMenu = menu.addItem(SubMenu.new("Target Selector"))
                self.tsMenu_focus = self.tsMenu.addItem(SubMenu.new("Focus Target Settings"))
                self.tsMenu_focus_selected = self.tsMenu_focus.addItem(MenuBool.new("Focus Selected Target", true))
                self.tsMenu_focus_selected_only = self.tsMenu_focus.addItem(MenuBool.new("Attack Only Selected Target", true))
                self.tsMenu_mode = self.tsMenu.addItem(MenuStringList.new("Mode", {"Auto Priority", "Less Attack", "Less Cast", "Lowest HP", "Most AD", "Most AP", "Closest", "Closest to Mouse"}, 1))

                self.ts_prio = {}
                self.tsMenu.addItem(MenuSeparator.new("    Priority Settings", true))

                for i, enemy in pairs(GetEnemyHeroes()) do
                        t.insert(self.ts_prio, { charName = GetAIHero(enemy).CharName, menu = self.tsMenu.addItem(MenuSlider.new(GetAIHero(enemy).CharName, self:GetDBPriority(GetAIHero(enemy).CharName), 1, 4, 1)) })
                end
        end      

        if draw then
                Callback.Add("Draw", function(...) self:OnDraw(...) end)
        end
        Callback.Add("WndMsg", function(...) self:OnWndMsg(...) end)
end

function TargetSelector:OnDraw()
        if (self.tsMenu and self.tsMenu_focus_selected or self.focusSelected) and IsValidTarget(self.SelectedTarget) then
                local pos = Vector(GetAIHero(self.SelectedTarget))
                --DrawCircleGame(pos.x, pos.y, pos.z, 150, Lua_ARGB(255, 255, 0, 0))
                Draw:Circle3D(pos.x, pos.y, pos.z, 150, 2, 10, Lua_ARGB(255, 255, 0, 0))
        end
end

function TargetSelector:OnWndMsg(msg, key)
        if msg == 513 and (self.tsMenu and self.tsMenu_focus_selected.getValue() or self.focusSelected) then
                local target, distance = nil, math.huge
                for i, enemy in pairs(GetEnemyHeroes()) do
                        if IsValidTarget(enemy) then
                                local distance2 = GetDistance(GetAIHero(enemy), GetMousePos())
                                if distance2 < distance and distance2 < GetOverrideCollisionRadius(enemy) * 1.25 then
                                        target = enemy
                                        distance = distance2
                                else
                                        self.SelectedTarget = nil
                                end
                        end
                end
                if target then self.SelectedTarget = target end
        end
end

function TargetSelector:GetPriority(unit)
        local prio = 1
        if self.tsMenu == nil then return prio end
        
        for i = 1, #self.ts_prio do
                local index = 0

                if self.ts_prio[i].charName == unit.CharName then
                        index = i
                end

                if index ~= 0 then
                        prio = self.ts_prio[index].menu.getValue()
                end
        end

        if prio == 2 then
                return 1.5
        elseif prio == 3 then
                return 1.75
        elseif prio == 4 then
                return 2
        elseif prio == 5 then 
                return 2.5
        end
        return prio
end

function TargetSelector:GetDBPriority(charName)
        local p1 = {"Alistar", "Amumu", "Bard", "Blitzcrank", "Braum", "Cho'Gath", "Dr. Mundo", "Garen", "Gnar", "Hecarim", "Janna", "Jarvan IV", "Leona", "Lulu", "Malphite", "Nami", "Nasus", "Nautilus", "Nunu", "Olaf", "Rammus", "Renekton", "Sejuani", "Shen", "Shyvana", "Singed", "Sion", "Skarner", "Sona", "Taric", "TahmKench", "Thresh", "Volibear", "Warwick", "MonkeyKing", "Yorick", "Zac", "Zyra"}
        local p2 = {"Aatrox", "Darius", "Elise", "Evelynn", "Galio", "Gangplank", "Gragas", "Irelia", "Jax", "Lee Sin", "Maokai", "Morgana", "Nocturne", "Pantheon", "Poppy", "Rengar", "Rumble", "Ryze", "Swain", "Trundle", "Tryndamere", "Udyr", "Urgot", "Vi", "XinZhao", "RekSai", "Kayn"}
        local p3 = {"Akali", "Diana", "Ekko", "Fiddlesticks", "Fiora", "Fizz", "Heimerdinger", "Jayce", "Kassadin", "Kayle", "Kha'Zix", "Lissandra", "Mordekaiser", "Nidalee", "Riven", "Shaco", "Vladimir", "Yasuo", "Zilean"}
        local p4 = {"Ahri", "Anivia", "Annie", "Ashe", "Azir", "Brand", "Caitlyn", "Cassiopeia", "Corki", "Draven", "Ezreal", "Graves", "Jinx", "Kalista", "Karma", "Karthus", "Katarina", "Kennen", "KogMaw", "Kindred", "Leblanc", "Lucian", "Lux", "Malzahar", "MasterYi", "MissFortune", "Orianna", "Quinn", "Sivir", "Syndra", "Talon", "Teemo", "Tristana", "TwistedFate", "Twitch", "Varus", "Vayne", "Veigar", "Velkoz", "Viktor", "Xerath", "Zed", "Ziggs", "Jhin", "Soraka", "Xayah", "Zoe"}
        if table.contains(p1, charName) then return 1 end
        if table.contains(p2, charName) then return 2 end
        if table.contains(p3, charName) then return 3 end
        return table.contains(p4, charName) and 4 or 1
end

function TargetSelector:GetTarget(range)
        if (self.tsMenu and self.tsMenu_focus_selected.getValue() or self.focusSelected) and IsValidTarget(self.SelectedTarget, range or self.range) then
                return self.SelectedTarget
        end

        local targets = {}
        for i, enemy in pairs(GetEnemyHeroes()) do
                if IsValidTarget(enemy, range or self.range) then
                        t.insert(targets, enemy)
                end
        end

        self.SortMode = self.tsMenu and self.tsMenu_mode.getValue() or 1
        t.sort(targets, self.sorting[self.SortMode])
        return #targets > 0 and targets[1] or 0
end
