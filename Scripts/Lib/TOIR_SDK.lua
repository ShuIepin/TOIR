SDK_VERSION = 0.4

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

function GetTargetById(targetid, range)
        GetAllUnitAroundAnObject(myHero.Addr, range)
        for i, obj in pairs(pUnit) do
                if obj ~= 0 and GetId(obj) == targetid then
                        return obj
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

function GetPredictionPos(unit) --.
        if type(unit) == "number" then
                return { x = GetPredictionPosX(unit), y = GetPredictionPosY(unit), z = GetPredictionPosZ(unit) }
        end
end

function IsValidTarget(unit, range)
        local range = range or m.huge
        if type(unit) == "number" then
                return unit ~= 0 and not IsDead(unit) and not IsInFog(unit) and GetTargetableToTeam(unit) == 4 and IsEnemy(unit) and GetDistance(GetOrigin(unit)) <= range
        else
                return unit and not IsDead(unit.Addr) and not IsInFog(unit.Addr) and GetTargetableToTeam(unit.Addr) == 4 and IsEnemy(unit.Addr) and GetDistance(unit) <= range
        end
end

function ValidTarget(unit, range, enemyTeam)
        local enemyTeam = (enemyTeam ~= false)
        local range = range or m.huge
        if type(unit) == "number" then
            return (unit ~= 0 or unit ~= nil) and not IsDead(unit) and not IsInFog(unit) and GetTargetableToTeam(unit) == 4 and IsEnemy(unit) == enemyTeam and (GetDistance(GetOrigin(unit)) <= range or range == nil) and (IsInvulnerable(unit) == false or enemyTeam == false)
        else
            return (unit ~= 0 or unit ~= nil) and not IsDead(unit.Addr) and not IsInFog(unit.Addr) and GetTargetableToTeam(unit.Addr) == 4 and IsEnemy(unit.Addr) == enemyTeam and (GetDistance(unit) <= range or range == nil) and (IsInvulnerable(unit.Addr) == false or enemyTeam == false)
        end
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

function VectorMovementCollision(startPoint1, endPoint1, v1, startPoint2, v2, delay)
    local sP1x, sP1y, eP1x, eP1y, sP2x, sP2y = startPoint1.x, startPoint1.z or startPoint1.y, endPoint1.x, endPoint1.z or endPoint1.y, startPoint2.x, startPoint2.z or startPoint2.y
    --v2 * t = Distance(P, A + t * v1 * (B-A):Norm())
    --(v2 * t)^2 = (r+S*t)^2+(j+K*t)^2 and v2 * t >= 0
    --0 = (S*S+K*K-v2*v2)*t^2+(-r*S-j*K)*2*t+(r*r+j*j) and v2 * t >= 0
    local d, e = eP1x-sP1x, eP1y-sP1y
    local dist, t1, t2 = math.sqrt(d*d+e*e), nil, nil
    local S, K = dist~=0 and v1*d/dist or 0, dist~=0 and v1*e/dist or 0
    local function GetCollisionPoint(t) return t and {x = sP1x+S*t, y = sP1y+K*t} or nil end
    if delay and delay~=0 then sP1x, sP1y = sP1x+S*delay, sP1y+K*delay end
    local r, j = sP2x-sP1x, sP2y-sP1y
    local c = r*r+j*j
    if dist>0 then
        if v1 == math.huge then
            local t = dist/v1
            t1 = v2*t>=0 and t or nil
        elseif v2 == math.huge then
            t1 = 0
        else
            local a, b = S*S+K*K-v2*v2, -r*S-j*K
            if a==0 then
                if b==0 then --c=0->t variable
                    t1 = c==0 and 0 or nil
                else --2*b*t+c=0
                    local t = -c/(2*b)
                    t1 = v2*t>=0 and t or nil
                end
            else --a*t*t+2*b*t+c=0
                local sqr = b*b-a*c
                if sqr>=0 then
                    local nom = math.sqrt(sqr)
                    local t = (-nom-b)/a
                    t1 = v2*t>=0 and t or nil
                    t = (nom-b)/a
                    t2 = v2*t>=0 and t or nil
                end
            end
        end
    elseif dist==0 then
        t1 = 0
    end
    return t1, GetCollisionPoint(t1), t2, GetCollisionPoint(t2), dist
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
local MENUBGACTIVE 	= Lua_ARGB(175, 0, 36, 51)
local MENUBORDERCOLOR   = Lua_ARGB(175, 0, 0, 0)

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
                        ret = ret + 2
                elseif tonumber(c) ~= nil then 
                        ret = ret + 4
                elseif c == str.upper(c) then 
                        ret = ret + 6
                elseif c == str.lower(c) then 
                        ret = ret + 5
                else 
                        ret = ret + 3 
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
                FilledRectD3DX(this.pos.x,this.pos.y,1,this.fullHeight+1, MENUBORDERCOLOR)
                FilledRectD3DX(this.pos.x+this.width,this.pos.y,1,this.fullHeight+1, MENUBORDERCOLOR)
                FilledRectD3DX(this.pos.x,this.pos.y+this.fullHeight,this.width,1, MENUBORDERCOLOR)
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
                        this.rectangle:Draw(MENUBGCOLOR)
                end 
                DrawTextD3DX(this.pos.x+this.rectangle.width-15, this.textY, ">", MENUTEXTCOLOR, 1, 1)
                DrawTextD3DX(this.pos.x+5, this.textY, this.name, this.color, 1, 1)
                FilledRectD3DX(this.rectangle.x,this.rectangle.y,this.rectangle.width,1,MENUBORDERCOLOR)
                
                if not this.active then return end

                
                if next(this.children) == nil then return end
                
                for i, item in pairs(this.children) do
                        item.onLoop()
                end
                FilledRectD3DX(this.pos.x+this.rectangle.width,this.rectangle.y,1,this.fullHeight+1, MENUBORDERCOLOR)
                FilledRectD3DX(this.pos.x+this.rectangle.width+this.childWidth,this.rectangle.y,1,this.fullHeight+1, MENUBORDERCOLOR)
                FilledRectD3DX(this.pos.x+this.rectangle.width,this.rectangle.y+this.fullHeight,this.childWidth,1, MENUBORDERCOLOR)

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
                
                this.rectangle:Draw(MENUBGCOLOR)
                if this.valueActive then
                        this.activeRectangle:Draw(Lua_ARGB(255, 2, 171, 232))
                        DrawTextD3DX(this.pos.x+this.rectangle.width-23, this.textY, "On", MENUTEXTCOLOR, 1)
                else
                        this.activeRectangle:Draw(Lua_ARGB(255, 36, 36, 36))
                        DrawTextD3DX(this.pos.x+this.rectangle.width-23, this.textY, "Off", MENUTEXTCOLOR, 1)
                end
                FilledRectD3DX(this.activeRectangle.x-1,this.activeRectangle.y,1,this.activeRectangle.height,MENUBORDERCOLOR)
                DrawTextD3DX(this.pos.x+5, this.textY, this.name, MENUTEXTCOLOR, 1)
                FilledRectD3DX(this.rectangle.x,this.rectangle.y,this.rectangle.width,1,MENUBORDERCOLOR)
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
                this.rectangle:Draw(MENUBGCOLOR)
                this.sliderRectangle:Draw(4278190335)
                DrawTextD3DX(this.pos.x+5, this.textY, this.name, MENUTEXTCOLOR, 1)
                local textval=str.format("%."..this.places.."f", this.value)
                DrawTextD3DX(this.pos.x+this.rectangle.width-GetTextWidth(textval, 10), this.textY, textval, MENUTEXTCOLOR, 1)
                
                FilledRectD3DX(this.rectangle.x,this.rectangle.y,this.rectangle.width,1,MENUBORDERCOLOR)
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

                this.rectangle:Draw(MENUBGCOLOR)
                DrawTextD3DX(textH, this.textY, this.name, this.color, 1)
                FilledRectD3DX(this.rectangle.x,this.rectangle.y,this.rectangle.width,1,MENUBORDERCOLOR)
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
                this.rectangle:Draw(MENUBGCOLOR)
                if this.getValue() then
                        this.activeRectangle:Draw(Lua_ARGB(255, 2, 171, 232))
                        DrawTextD3DX(this.pos.x+this.rectangle.width-23, this.textY, "On",MENUTEXTCOLOR, 1)
                else
                        this.activeRectangle:Draw(Lua_ARGB(255, 36, 36, 36))
                        DrawTextD3DX(this.pos.x+this.rectangle.width-23, this.textY, "Off",MENUTEXTCOLOR, 1)
                end
                FilledRectD3DX(this.activeRectangle.x-1,this.activeRectangle.y,1,this.activeRectangle.height,MENUBORDERCOLOR)
                DrawTextD3DX(this.pos.x+5, this.textY, string.format("%s [%s]",this.name, this.keycodeString),MENUTEXTCOLOR, 1)
                FilledRectD3DX(this.rectangle.x,this.rectangle.y,this.rectangle.width,1,MENUBORDERCOLOR)
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
                this.rectangle:Draw(MENUBGCOLOR)
                
                this.leftRectangle:Draw(Lua_ARGB(255, 0, 36, 51))
                this.rightRectangle:Draw(Lua_ARGB(255, 0, 36, 51))
                FilledRectD3DX(this.leftRectangle.x-2,this.leftRectangle.y,1,this.leftRectangle.height,MENUBORDERCOLOR)
                FilledRectD3DX(this.rightRectangle.x-2,this.rightRectangle.y,1,this.rightRectangle.height,MENUBORDERCOLOR)
                DrawTextD3DX(this.rightRectangle.x+10, this.textY, ">",MENUTEXTCOLOR, 1)
                DrawTextD3DX(this.leftRectangle.x+10, this.textY, "<",MENUTEXTCOLOR, 1)
                DrawTextD3DX(this.pos.x+5, this.textY, this.name,MENUTEXTCOLOR, 1)
                DrawTextD3DX(this.leftRectangle.x-GetTextWidth(this.stringlist[this.selectedIndex], 5), this.textY, this.stringlist[this.selectedIndex], MENUTEXTCOLOR, 1)
                FilledRectD3DX(this.rectangle.x,this.rectangle.y,this.rectangle.width,1,MENUBORDERCOLOR)
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
        assert(type(spell) == "string", "GetDamage: Wrong argument types (<string> expected for <1> arg)")
        assert(type(target) == "table", "GetDamage: Wrong argument types (<table> expected for <2> arg)")

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

--[[

EVERYTHING BENEATH HERE IS NEEDED FOR VPREDICTION/HPREDICTION DO NOT REMOVE/EDIT THESE FUNCTIONS 

]]

--Creadits to RMAN for this function! :D
local function GetPathIndex(unit)
    local result = 1
    for i= 2, unit.PathCount do
        local myHeroPos = Vector(GetPos(unit.Addr))
        local iPath = Vector(unit.GetPath(i))
        local iMinusPath = Vector(unit.GetPath(i-1))
        if GetDistance(iPath,myHeroPos) < GetDistance(iMinusPath,myHeroPos) and 
            GetDistance(iPath,iMinusPath) <= GetDistance(iMinusPath,myHeroPos) and i ~= unit.PathCount then
                result = i
        end
    end
    return result
end

local function GetDistanceSqr(p1, p2)
        p2 = p2 or GetMyHero()

        if type(p1) == "number" or type(p2) == "number" then
                return 0
        end

        return (p1.x - p2.x) ^ 2 + ((p1.z or p1.y) - (p2.z or p2.y)) ^ 2
end

local function GetDistance(p1, p2)
        if type(p1) == "number" or type(p2) == "number" then
                return 0
        end

        return math.sqrt(GetDistanceSqr(p1, p2))
end

local function _has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

--// Object Manager //--

_objManager = class()

function _objManager:__init()
    self.objects = {}
    self.maxObjects = 0

    myHero = GetMyHero()

    GetAllObjectAroundAnObject(myHero.Addr, 3000)

    -- 0=champ, 1=minion, 2=turret, 3=jungle, 4= Inhibitor, 5=Nexus, 6=Missile, -1= other

    for i, obj in pairs(pObject) do
        if obj ~= 0 then
            local object = nil
            if GetType(obj) == 0 then
                object = GetAIHero(obj)
            elseif _has_value({1,2,3}, GetType(obj)) then
                object = GetUnit(obj)
            elseif GetType(obj) == 6 then
                object = GetMissile(obj)
            elseif _has_value({4,5}, GetType(obj)) then
                object = GetBarrack(obj)
            elseif GetType(obj) == -1 then
                object = {}
                object.Addr = obj
                object.Type = -1
                object.Id = GetId(obj)
                --object.Name = GetObjName(obj)
                --object.CharName = GetChampName(obj)
            end

            if object then
                table.insert(self.objects, object)
                self.maxObjects = self.maxObjects + 1
            end
        end
    end

    setmetatable(self.objects,{
                    __newindex = function(self, key, value)
                        error("Adding to EnemyHeroes is not granted. Use table.copy.")
                    end,
                })

    return self
end

function _objManager:getObject(i)
        return self.objects[i]
end

function _objManager:GetObjectByNetworkId(NetworkID)
        for i=1, self.maxObjects do
                if self.objects[i].NetworkId == NetworkID then
                        return self.objects[i]
                end
        end
end

function _objManager:AddObject(object)
        if object and object.Addr ~= 0 then
                table.insert(self.objects, object)
                self.maxObjects = self.maxObjects + 1

                setmetatable(self.objects,{
                        __newindex = function(self, key, value)
                                error("Adding to EnemyHeroes is not granted. Use table.copy.")
                        end,
                })
        end
end

function _objManager:update()
    self.objects = {}
    self.maxObjects = 0

    myHero = GetMyHero()

    GetAllObjectAroundAnObject(myHero.Addr, 3000)

    -- 0=champ, 1=minion, 2=turret, 3=jungle, 4= Inhibitor, 5=Nexus, 6=Missile, -1= other

    for i, obj in pairs(pObject) do
        if obj ~= 0 then
            local object = nil
            if GetType(obj) == 0 then
                object = GetAIHero(obj)
            elseif _has_value({1,2,3}, GetType(obj)) then
                object = GetUnit(obj)
            elseif GetType(obj) == 6 then
                object = GetMissile(obj)
            elseif _has_value({4,5}, GetType(obj)) then
                object = GetBarrack(obj)
            elseif GetType(obj) == -1 then
                object = {}
                object.Addr = obj
                object.Type = -1
                object.Id = GetId(obj)
                --object.Name = GetObjName(obj)
                --object.CharName = GetChampName(obj)
            end

            if object then
                table.insert(self.objects, object)
                self.maxObjects = self.maxObjects + 1
            end
        end
    end

    setmetatable(self.objects,{
                    __newindex = function(self, key, value)
                        error("Adding to EnemyHeroes is not granted. Use table.copy.")
                    end,
                })
end

function _objManager:RemoveObject(object)
    if object and object.Addr ~= 0 then
        for i=1, self.maxObjects do
            if self.objects[i] and self.objects[i].Addr == object.Addr then
                table.remove(self.objects, i)
                self.maxObjects = self.maxObjects - 1

                setmetatable(self.objects,{
                    __newindex = function(self, key, value)
                        error("Adding to EnemyHeroes is not granted. Use table.copy.")
                    end,
                })
            end
        end
    end
end

objManager = _objManager()

--// Hero Manager //--

_heroManager = class()

function _heroManager:__init()
    self.heroes = {}
    self.iCount = 0
    SearchAllChamp()
    for i,h in ipairs(pObjChamp) do
        if h ~= 0 then
          local hero = GetAIHero(h)
          table.insert(self.heroes, hero)
          self.iCount = self.iCount + 1
        end
    end

        return self
end

function _heroManager:update()
    self.heroes = {}
    self.iCount = 0
    SearchAllChamp()
    for i,h in ipairs(pObjChamp) do
        if h ~= 0 then
          local hero = GetAIHero(h)
          table.insert(self.heroes, hero)
          self.iCount = self.iCount + 1
        end
    end
end

function _heroManager:GetHero(i)
  return self.heroes[i]
end

heroManager = _heroManager()

--// Minion Manager //--

local _minionTable = { {}, {}, {}, {}, {} }
local _minionManager = { init = true, tick = 0, ally = "##", enemy = "##" }

MINION_ALL = 1
MINION_ENEMY = 2
MINION_ALLY = 3
MINION_JUNGLE = 4
MINION_OTHER = 5
MINION_SORT_HEALTH_ASC = function(a, b) return a.HP < b.HP end
MINION_SORT_HEALTH_DEC = function(a, b) return a.HP > b.HP end
MINION_SORT_MAXHEALTH_ASC = function(a, b) return a.MaxHP < b.MaxHP end
MINION_SORT_MAXHEALTH_DEC = function(a, b) return a.MaxHP > b.MaxHP end
MINION_SORT_AD_ASC = function(a, b) return a.TotalDmg < b.TotalDmg end
MINION_SORT_AD_DEC = function(a, b) return a.TotalDmg > b.TotalDmg end


function __minionManager__OnCreateObj(object)
    if object and object.IsValid and _has_value({1,3},object.Type) then
        if object and object.IsValid and _has_value({1,3},object.Type) --[["obj_AI_Minion"]] and object.IsVisible and not object.IsDead then
            --local name = object.name
            --table.insert(_minionTable[MINION_ALL], object)
            if not object.IsEnemy and object.Type == 1 then table.insert(_minionTable[MINION_ALLY], object)
            elseif object.IsEnemy and object.Type == 1 then table.insert(_minionTable[MINION_ENEMY], object)
            elseif object.Type == 3 then table.insert(_minionTable[MINION_JUNGLE], object)
            else table.insert(_minionTable[MINION_OTHER], object)
            end
        end
    end
end

minionManager = class()

function minionManager:__init(mode, range, fromPos, sortMode)
        assert(type(mode) == "number" and type(range) == "number", "minionManager: Wrong argument types (<mode>, <number> expected)")

        self.mode = mode
        self.range = range
        self.fromPos = fromPos or player
        self.sortMode = type(sortMode) == "function" and sortMode
        self.objects = {}
        self.iCount = 0
        self:update()

        return self
end

function minionManager:update()
    self.fromPos = GetMyHero()
    self.objects = {}

    _minionTable[self.mode] = {}
    objManager:update()
    for i = 1, objManager.maxObjects do
        __minionManager__OnCreateObj(objManager:getObject(i))
    end

    --print(tostring(objManager.maxObjects))

    for _, object in pairs(_minionTable[self.mode]) do
        if object and object.IsValid and not object.IsDead and object.IsVisible and GetDistanceSqr(self.fromPos, object) <= (self.range) ^ 2 then
            table.insert(self.objects, object)
        end
    end
    if self.sortMode then table.sort(self.objects, self.sortMode) end
    self.iCount = #self.objects
end

--// Prediction //--

--Circle Class
Circle = class()
function Circle:__init(center, radius)
    --[[assert((VectorType(center) or center == nil) and (type(radius) == "number" or radius == nil), "Circle: wrong argument types (expected <Vector> or nil, <number> or nil)")]]
    self.center = Vector(center) or Vector()
    self.radius = radius or 0

    return self
end

function Circle:Contains(v)
    --[[assert(VectorType(v), "Contains: wrong argument types (expected <Vector>)")]]
    return math.close(self.center:DistanceTo(v), self.radius)
end

function Circle:__tostring()
    return "{center: " .. tostring(self.center) .. ", radius: " .. tostring(self.radius) .. "}"
end

local function VectorDirection(v1, v2, v)
    --assert(VectorType(v1) and VectorType(v2) and VectorType(v), "VectorDirection: wrong argument types (3 <Vector> expected)")
    return ((v.z or v.y) - (v1.z or v1.y)) * (v2.x - v1.x) - ((v2.z or v2.y) - (v1.z or v1.y)) * (v.x - v1.x)
end

local function VectorIntersection(a1, b1, a2, b2) --returns a 2D point where to lines intersect (assuming they have an infinite length)
    --[[assert(VectorType(a1) and VectorType(b1) and VectorType(a2) and VectorType(b2), "VectorIntersection: wrong argument types (4 <Vector> expected)")]]
    --http://thirdpartyninjas.com/blog/2008/10/07/line-segment-intersection/
    local x1, y1, x2, y2, x3, y3, x4, y4 = a1.x, a1.z or a1.y, b1.x, b1.z or b1.y, a2.x, a2.z or a2.y, b2.x, b2.z or b2.y
    local r, s, u, v, k, l = x1 * y2 - y1 * x2, x3 * y4 - y3 * x4, x3 - x4, x1 - x2, y3 - y4, y1 - y2
    local px, py, divisor = r * u - v * s, r * k - l * s, v * k - l * u
    return divisor ~= 0 and Vector(px / divisor, py / divisor)
end

-- MEC class section
MEC = class()

function MEC:__init(points)
    self.circle = Circle()
    self.points = {}
    if points then
        self:SetPoints(points)
    end

    return self
end

function MEC:SetPoints(points)
    -- Set the points
    self.points = {}
    for _, p in ipairs(points) do
        table.insert(self.points, Vector(p))
    end
end

function MEC:HalfHull(left, right, pointTable, factor)
    -- Computes the half hull of a set of points
    local input = pointTable
    table.insert(input, right)
    local half = {}
    table.insert(half, left)
    for _, p in ipairs(input) do
        table.insert(half, p)
        while #half >= 3 do
            local dir = factor * VectorDirection(half[(#half + 1) - 3], half[(#half + 1) - 1], half[(#half + 1) - 2])
            if dir <= 0 then
                table.remove(half, #half - 1)
            else
                break
            end
        end
    end
    return half
end

function MEC:ConvexHull()
    -- Computes the set of points that represent the convex hull of the set of points
    local left, right = self.points[1], self.points[#self.points]
    local upper, lower, ret = {}, {}, {}
    -- Partition remaining points into upper and lower buckets.
    for i = 2, #self.points - 1 do
        --[[if VectorType(self.points[i]) == false then print(string.format("[SDK]VPrediction[MEC Class]: self.points[" .. tostring(i) .. "] is not a Vector!")) end]]
        table.insert((VectorDirection(left, right, self.points[i]) < 0 and upper or lower), self.points[i])
    end
    local upperHull = self:HalfHull(left, right, upper, -1)
    local lowerHull = self:HalfHull(left, right, lower, 1)
    local unique = {}
    for _, p in ipairs(upperHull) do
        unique["x" .. p.x .. "z" .. p.z] = p
    end
    for _, p in ipairs(lowerHull) do
        unique["x" .. p.x .. "z" .. p.z] = p
    end
    for _, p in pairs(unique) do
        table.insert(ret, p)
    end
    return ret
end

function MEC:Compute()
    -- Compute the MEC.
    -- Make sure there are some points.
    if #self.points == 0 then return nil end
    -- Handle degenerate cases first
    if #self.points == 1 then
        self.circle.center = self.points[1]
        self.circle.radius = 0
        self.circle.radiusPoint = self.points[1]
    elseif #self.points == 2 then
        local a = self.points
        self.circle.center = a[1]:Center(a[2]) --< CAPITALIZE THE C IN CENTER
        self.circle.radius = a[1]:DistanceTo(self.circle.center)
        self.circle.radiusPoint = a[1]
    else
        local a = self:ConvexHull()
        local point_a = a[1]
        local point_b
        local point_c = a[2]
        if not point_c then
            self.circle.center = point_a
            self.circle.radius = 0
            self.circle.radiusPoint = point_a
            return self.circle
        end
        -- Loop until we get appropriate values for point_a and point_c
        while true do
            point_b = nil
            local best_theta = 180.0
            -- Search for the point "b" which subtends the smallest angle a-b-c.
            for _, point in ipairs(self.points) do
                if (not point == point_a) and (not point == point_c) then
                    local theta_abc = point:AngleBetween(point_a, point_c)
                    if theta_abc < best_theta then
                        point_b = point
                        best_theta = theta_abc
                    end
                end
            end
            -- If the angle is obtuse, then line a-c is the diameter of the circle,
            -- so we can return.
            if best_theta >= 90.0 or (not point_b) then
                self.circle.center = point_a:Center(point_c)
                self.circle.radius = point_a:DistanceTo(self.circle.center)
                self.circle.radiusPoint = point_a
                return self.circle
            end
            local ang_bca = point_c:AngleBetween(point_b, point_a)
            local ang_cab = point_a:AngleBetween(point_c, point_b)
            if ang_bca > 90.0 then
                point_c = point_b
            elseif ang_cab <= 90.0 then
                break
            else
                point_a = point_b
            end
        end
        local ch1 = (point_b - point_a) * 0.5
        local ch2 = (point_c - point_a) * 0.5
        local n1 = ch1:Perpendicular2()
        local n2 = ch2:Perpendicular2()
        ch1 = point_a + ch1
        ch2 = point_a + ch2
        self.circle.center = VectorIntersection(ch1, n1, ch2, n2)
        self.circle.radius = self.circle.center:DistanceTo(point_a)
        self.circle.radiusPoint = point_a
    end
    return self.circle
end

local _enemyHeroes
local function GetEnemyHeroes()
    if _enemyHeroes then return _enemyHeroes end
    _enemyHeroes = {}
    for i = 1, heroManager.iCount do
        local hero = heroManager:GetHero(i)
        if hero.IsEnemy then
            table.insert(_enemyHeroes, hero)
        end
    end
    return setmetatable(_enemyHeroes,{
        __newindex = function(self, key, value)
            error("Adding to EnemyHeroes is not granted. Use table.copy.")
        end,
    })
end

local function GetTargetFromTargetId(targetid)
    myHero = GetMyHero()
    GetAllObjectAroundAnObject(myHero.Addr, 3000)

    -- 0=champ, 1=minion, 2=turret, 3=jungle, 4= Inhibitor, 5=Nexus, 6=Missile, -1= other

    for i, obj in pairs(pObject) do
        if obj ~= 0 then
            local object = nil
            if GetType(obj) == 0 then
                object = GetAIHero(obj)
            elseif _has_value({1,2,3}, GetType(obj)) then
                object = GetUnit(obj)
            elseif GetType(obj) == 6 then
                object = GetMissile(obj)
            elseif _has_value({4,5}, GetType(obj)) then
                object = GetBarrack(obj)
            elseif GetType(obj) == -1 then
                object = {}
                object.Addr = obj
                object.Type = -1
                object.Id = GetId(obj)
                --object.Name = GetObjName(obj)
                --object.CharName = GetChampName(obj)
            end

            if object and object.Id == targetid then
                return object
            end
        end
    end

    return nil
end

local function GetCollisionVPredDraw(target, width, range, predPos)
        local predPos = IsVector(predPos) and predPos or Vector(0,0,0)
        local myHeroPos = GetOrigin(myHero)
        local targetPos = GetOrigin(target)

        local count = 0

        if predPos.x ~= 0 and predPos.z ~= 0 then
                count = CountObjectCollision(1, target, myHeroPos.x, myHeroPos.z, predPos.x, predPos.z, width, range, 10)
        end

        if count == 0 then
                return false
        end

        return true
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------VPrediction Ported For Toir+ (SDK Edition)-------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------By: Dewblackio2----------------------------------------------------------------------------------------------------------------------
local minionTar = {}
local function GetAggro(unit)
    if unit.spell and unit.spell.target then
        return unit.spell.target
    else
        return minionTar[unit.NetworkId] and minionTar[unit.NetworkId] or nil
    end
end
local _FAST, _MEDIUM, _SLOW = 1, 2, 3
local PA = {}

for i, champ in pairs(GetEnemyHeroes()) do
    PA[champ.NetworkId] = {}
end
PA[myHero.NetworkId] = {}

VPrediction = class()

function VPrediction:__init(menu)
        self.version = 1.02
        --self.LastFocusedTarget = nil
        --self.showdevmode = false
        self.hitboxes = {['Braum'] = 80, ['RecItemsCLASSIC'] = 65, ['TeemoMushroom'] = 50.0, ['TestCubeRender'] = 65, ['Xerath'] = 65, ['Kassadin'] = 65, ['Rengar'] = 65, ['Thresh'] = 55.0, ['RecItemsTUTORIAL'] = 65, ['Ziggs'] = 55.0, ['ZyraPassive'] = 20.0, ['ZyraThornPlant'] = 20.0, ['KogMaw'] = 65, ['HeimerTBlue'] = 35.0, ['EliseSpider'] = 65, ['Skarner'] = 80.0, ['ChaosNexus'] = 65, ['Katarina'] = 65, ['Riven'] = 65, ['SightWard'] = 1, ['HeimerTYellow'] = 35.0, ['Ashe'] = 65, ['VisionWard'] = 1, ['TT_NGolem2'] = 80.0, ['ThreshLantern'] = 65, ['RecItemsCLASSICMap10'] = 65, ['RecItemsODIN'] = 65, ['TT_Spiderboss'] = 200.0, ['RecItemsARAM'] = 65, ['OrderNexus'] = 65, ['Soraka'] = 65, ['Jinx'] = 65, ['TestCubeRenderwCollision'] = 65, ['Red_Minion_Wizard'] = 48.0, ['JarvanIV'] = 65, ['Blue_Minion_Wizard'] = 48.0, ['TT_ChaosTurret2'] = 88.4, ['TT_ChaosTurret3'] = 88.4, ['TT_ChaosTurret1'] = 88.4, ['ChaosTurretGiant'] = 88.4, ['Dragon'] = 100.0, ['LuluSnowman'] = 50.0, ['Worm'] = 100.0, ['ChaosTurretWorm'] = 88.4, ['TT_ChaosInhibitor'] = 65, ['ChaosTurretNormal'] = 88.4, ['AncientGolem'] = 100.0, ['ZyraGraspingPlant'] = 20.0, ['HA_AP_OrderTurret3'] = 88.4, ['HA_AP_OrderTurret2'] = 88.4, ['Tryndamere'] = 65, ['OrderTurretNormal2'] = 88.4, ['Singed'] = 65, ['OrderInhibitor'] = 65, ['Diana'] = 65, ['HA_FB_HealthRelic'] = 65, ['TT_OrderInhibitor'] = 65, ['GreatWraith'] = 80.0, ['Yasuo'] = 65, ['OrderTurretDragon'] = 88.4, ['OrderTurretNormal'] = 88.4, ['LizardElder'] = 65.0, ['HA_AP_ChaosTurret'] = 88.4, ['Ahri'] = 65, ['Lulu'] = 65, ['ChaosInhibitor'] = 65, ['HA_AP_ChaosTurret3'] = 88.4, ['HA_AP_ChaosTurret2'] = 88.4, ['ChaosTurretWorm2'] = 88.4, ['TT_OrderTurret1'] = 88.4, ['TT_OrderTurret2'] = 88.4, ['TT_OrderTurret3'] = 88.4, ['LuluFaerie'] = 65, ['HA_AP_OrderTurret'] = 88.4, ['OrderTurretAngel'] = 88.4, ['YellowTrinketUpgrade'] = 1, ['MasterYi'] = 65, ['Lissandra'] = 65, ['ARAMOrderTurretNexus'] = 88.4, ['Draven'] = 65, ['FiddleSticks'] = 65, ['SmallGolem'] = 80.0, ['ARAMOrderTurretFront'] = 88.4, ['ChaosTurretTutorial'] = 88.4, ['NasusUlt'] = 80.0, ['Maokai'] = 80.0, ['Wraith'] = 50.0, ['Wolf'] = 50.0, ['Sivir'] = 65, ['Corki'] = 65, ['Janna'] = 65, ['Nasus'] = 80.0, ['Golem'] = 80.0, ['ARAMChaosTurretFront'] = 88.4, ['ARAMOrderTurretInhib'] = 88.4, ['LeeSin'] = 65, ['HA_AP_ChaosTurretTutorial'] = 88.4, ['GiantWolf'] = 65.0, ['HA_AP_OrderTurretTutorial'] = 88.4, ['YoungLizard'] = 50.0, ['Jax'] = 65, ['LesserWraith'] = 50.0, ['Blitzcrank'] = 80.0, ['brush_D_SR'] = 65, ['brush_E_SR'] = 65, ['brush_F_SR'] = 65, ['brush_C_SR'] = 65, ['brush_A_SR'] = 65, ['brush_B_SR'] = 65, ['ARAMChaosTurretInhib'] = 88.4, ['Shen'] = 65, ['Nocturne'] = 65, ['Sona'] = 65, ['ARAMChaosTurretNexus'] = 88.4, ['YellowTrinket'] = 1, ['OrderTurretTutorial'] = 88.4, ['Caitlyn'] = 65, ['Trundle'] = 65, ['Malphite'] = 80.0, ['Mordekaiser'] = 80.0, ['ZyraSeed'] = 65, ['Vi'] = 50, ['Tutorial_Red_Minion_Wizard'] = 48.0, ['Renekton'] = 80.0, ['Anivia'] = 65, ['Fizz'] = 65, ['Heimerdinger'] = 55.0, ['Evelynn'] = 65, ['Rumble'] = 80.0, ['Leblanc'] = 65, ['Darius'] = 80.0, ['OlafAxe'] = 50.0, ['Viktor'] = 65, ['XinZhao'] = 65, ['Orianna'] = 65, ['Vladimir'] = 65, ['Nidalee'] = 65, ['Tutorial_Red_Minion_Basic'] = 48.0, ['ZedShadow'] = 65, ['Syndra'] = 65, ['Zac'] = 80.0, ['Olaf'] = 65, ['Veigar'] = 55.0, ['Twitch'] = 65, ['Alistar'] = 80.0, ['Akali'] = 65, ['Urgot'] = 80.0, ['Leona'] = 65, ['Talon'] = 65, ['Karma'] = 65, ['Jayce'] = 65, ['Galio'] = 80.0, ['Shaco'] = 65, ['Taric'] = 65, ['TwistedFate'] = 65, ['Varus'] = 65, ['Garen'] = 65, ['Swain'] = 65, ['Vayne'] = 65, ['Fiora'] = 65, ['Quinn'] = 65, ['Kayle'] = 65, ['Blue_Minion_Basic'] = 48.0, ['Brand'] = 65, ['Teemo'] = 55.0, ['Amumu'] = 55.0, ['Annie'] = 55.0, ['Odin_Blue_Minion_caster'] = 48.0, ['Elise'] = 65, ['Nami'] = 65, ['Poppy'] = 55.0, ['AniviaEgg'] = 65, ['Tristana'] = 55.0, ['Graves'] = 65, ['Morgana'] = 65, ['Gragas'] = 80.0, ['MissFortune'] = 65, ['Warwick'] = 65, ['Cassiopeia'] = 65, ['Tutorial_Blue_Minion_Wizard'] = 48.0, ['DrMundo'] = 80.0, ['Volibear'] = 80.0, ['Irelia'] = 65, ['Odin_Red_Minion_Caster'] = 48.0, ['Lucian'] = 65, ['Yorick'] = 80.0, ['RammusPB'] = 65, ['Red_Minion_Basic'] = 48.0, ['Udyr'] = 65, ['MonkeyKing'] = 65, ['Tutorial_Blue_Minion_Basic'] = 48.0, ['Kennen'] = 55.0, ['Nunu'] = 65, ['Ryze'] = 65, ['Zed'] = 65, ['Nautilus'] = 80.0, ['Gangplank'] = 65, ['shopevo'] = 65, ['Lux'] = 65, ['Sejuani'] = 80.0, ['Ezreal'] = 65, ['OdinNeutralGuardian'] = 65, ['Khazix'] = 65, ['Sion'] = 80.0, ['Aatrox'] = 65, ['Hecarim'] = 80.0, ['Pantheon'] = 65, ['Shyvana'] = 50.0, ['Zyra'] = 65, ['Karthus'] = 65, ['Rammus'] = 65, ['Zilean'] = 65, ['Chogath'] = 80.0, ['Malzahar'] = 65, ['YorickRavenousGhoul'] = 1.0, ['YorickSpectralGhoul'] = 1.0, ['JinxMine'] = 65, ['YorickDecayedGhoul'] = 1.0, ['XerathArcaneBarrageLauncher'] = 65, ['Odin_SOG_Order_Crystal'] = 65, ['TestCube'] = 65, ['ShyvanaDragon'] = 80.0, ['FizzBait'] = 65, ['ShopKeeper'] = 65, ['Blue_Minion_MechMelee'] = 65.0, ['OdinQuestBuff'] = 65, ['TT_Buffplat_L'] = 65, ['TT_Buffplat_R'] = 65, ['KogMawDead'] = 65, ['TempMovableChar'] = 48.0, ['Lizard'] = 50.0, ['GolemOdin'] = 80.0, ['OdinOpeningBarrier'] = 65, ['TT_ChaosTurret4'] = 88.4, ['TT_Flytrap_A'] = 65, ['TT_Chains_Order_Periph'] = 65, ['TT_NWolf'] = 65.0, ['ShopMale'] = 65, ['OdinShieldRelic'] = 65, ['TT_Chains_Xaos_Base'] = 65, ['LuluSquill'] = 50.0, ['TT_Shopkeeper'] = 65, ['redDragon'] = 100.0, ['MonkeyKingClone'] = 65, ['Odin_skeleton'] = 65, ['OdinChaosTurretShrine'] = 88.4, ['Cassiopeia_Death'] = 65, ['OdinCenterRelic'] = 48.0, ['Ezreal_cyber_1'] = 65, ['Ezreal_cyber_3'] = 65, ['Ezreal_cyber_2'] = 65, ['OdinRedSuperminion'] = 55.0, ['TT_Speedshrine_Gears'] = 65, ['JarvanIVWall'] = 65, ['DestroyedNexus'] = 65, ['ARAMOrderNexus'] = 65, ['Red_Minion_MechCannon'] = 65.0, ['OdinBlueSuperminion'] = 55.0, ['SyndraOrbs'] = 65, ['LuluKitty'] = 50.0, ['SwainNoBird'] = 65, ['LuluLadybug'] = 50.0, ['CaitlynTrap'] = 65, ['TT_Shroom_A'] = 65, ['ARAMChaosTurretShrine'] = 88.4, ['Odin_Windmill_Propellers'] = 65, ['DestroyedInhibitor'] = 65, ['TT_NWolf2'] = 50.0, ['OdinMinionGraveyardPortal'] = 1.0, ['SwainBeam'] = 65, ['Summoner_Rider_Order'] = 65.0, ['TT_Relic'] = 65, ['odin_lifts_crystal'] = 65, ['OdinOrderTurretShrine'] = 88.4, ['SpellBook1'] = 65, ['Blue_Minion_MechCannon'] = 65.0, ['TT_ChaosInhibitor_D'] = 65, ['Odin_SoG_Chaos'] = 65, ['TrundleWall'] = 65, ['HA_AP_HealthRelic'] = 65, ['OrderTurretShrine'] = 88.4, ['OriannaBall'] = 48.0, ['ChaosTurretShrine'] = 88.4, ['LuluCupcake'] = 50.0, ['HA_AP_ChaosTurretShrine'] = 88.4, ['TT_Chains_Bot_Lane'] = 65, ['TT_NWraith2'] = 50.0, ['TT_Tree_A'] = 65, ['SummonerBeacon'] = 65, ['Odin_Drill'] = 65, ['TT_NGolem'] = 80.0, ['Shop'] = 65, ['AramSpeedShrine'] = 65, ['DestroyedTower'] = 65, ['OriannaNoBall'] = 65, ['Odin_Minecart'] = 65, ['Summoner_Rider_Chaos'] = 65.0, ['OdinSpeedShrine'] = 65, ['TT_Brazier'] = 65, ['TT_SpeedShrine'] = 65, ['odin_lifts_buckets'] = 65, ['OdinRockSaw'] = 65, ['OdinMinionSpawnPortal'] = 1.0, ['SyndraSphere'] = 48.0, ['TT_Nexus_Gears'] = 65, ['Red_Minion_MechMelee'] = 65.0, ['SwainRaven'] = 65, ['crystal_platform'] = 65, ['MaokaiSproutling'] = 48.0, ['Urf'] = 65, ['TestCubeRender10Vision'] = 65, ['MalzaharVoidling'] = 10.0, ['GhostWard'] = 1, ['MonkeyKingFlying'] = 65, ['LuluPig'] = 50.0, ['AniviaIceBlock'] = 65, ['TT_OrderInhibitor_D'] = 65, ['yonkey'] = 65, ['Odin_SoG_Order'] = 65, ['RammusDBC'] = 65, ['FizzShark'] = 65, ['LuluDragon'] = 50.0, ['OdinTestCubeRender'] = 65, ['OdinCrane'] = 65, ['TT_Tree1'] = 65, ['ARAMOrderTurretShrine'] = 88.4, ['TT_Chains_Order_Base'] = 65, ['Odin_Windmill_Gears'] = 65, ['ARAMChaosNexus'] = 65, ['TT_NWraith'] = 50.0, ['TT_OrderTurret4'] = 88.4, ['Odin_SOG_Chaos_Crystal'] = 65, ['TT_SpiderLayer_Web'] = 65, ['OdinQuestIndicator'] = 1.0, ['JarvanIVStandard'] = 65, ['TT_DummyPusher'] = 65, ['OdinClaw'] = 65, ['EliseSpiderling'] = 1.0, ['QuinnValor'] = 65, ['UdyrTigerUlt'] = 65, ['UdyrTurtleUlt'] = 65, ['UdyrUlt'] = 65, ['UdyrPhoenixUlt'] = 65, ['ShacoBox'] = 10, ['HA_AP_Poro'] = 65, ['AnnieTibbers'] = 80.0, ['UdyrPhoenix'] = 65, ['UdyrTurtle'] = 65, ['UdyrTiger'] = 65, ['HA_AP_OrderShrineTurret'] = 88.4, ['HA_AP_OrderTurretRubble'] = 65, ['HA_AP_Chains_Long'] = 65, ['HA_AP_OrderCloth'] = 65, ['HA_AP_PeriphBridge'] = 65, ['HA_AP_BridgeLaneStatue'] = 65, ['HA_AP_ChaosTurretRubble'] = 88.4, ['HA_AP_BannerMidBridge'] = 65, ['HA_AP_PoroSpawner'] = 50.0, ['HA_AP_Cutaway'] = 65, ['HA_AP_Chains'] = 65, ['HA_AP_ShpSouth'] = 65, ['HA_AP_HeroTower'] = 65, ['HA_AP_ShpNorth'] = 65, ['ChaosInhibitor_D'] = 65, ['ZacRebirthBloblet'] = 65, ['OrderInhibitor_D'] = 65, ['Nidalee_Spear'] = 65, ['Nidalee_Cougar'] = 65, ['TT_Buffplat_Chain'] = 65, ['WriggleLantern'] = 1, ['TwistedLizardElder'] = 65.0, ['RabidWolf'] = 65.0, ['HeimerTGreen'] = 50.0, ['HeimerTRed'] = 50.0, ['ViktorFF'] = 65, ['TwistedGolem'] = 80.0, ['TwistedSmallWolf'] = 50.0, ['TwistedGiantWolf'] = 65.0, ['TwistedTinyWraith'] = 50.0, ['TwistedBlueWraith'] = 50.0, ['TwistedYoungLizard'] = 50.0, ['Red_Minion_Melee'] = 48.0, ['Blue_Minion_Melee'] = 48.0, ['Blue_Minion_Healer'] = 48.0, ['Ghast'] = 60.0, ['blueDragon'] = 100.0, ['Red_Minion_MechRange'] = 65.0, ['Test_CubeSphere'] = 65,}
        self.projectilespeeds = {["Velkoz"]= 2000,["TeemoMushroom"] = math.huge,["TestCubeRender"] = math.huge ,["Xerath"] = 2000.0000 ,["Kassadin"] = math.huge ,["Rengar"] = math.huge ,["Thresh"] = 1000.0000 ,["Ziggs"] = 1500.0000 ,["ZyraPassive"] = 1500.0000 ,["ZyraThornPlant"] = 1500.0000 ,["KogMaw"] = 1800.0000 ,["HeimerTBlue"] = 1599.3999 ,["EliseSpider"] = 500.0000 ,["Skarner"] = 500.0000 ,["ChaosNexus"] = 500.0000 ,["Katarina"] = 467.0000 ,["Riven"] = 347.79999 ,["SightWard"] = 347.79999 ,["HeimerTYellow"] = 1599.3999 ,["Ashe"] = 2000.0000 ,["VisionWard"] = 2000.0000 ,["TT_NGolem2"] = math.huge ,["ThreshLantern"] = math.huge ,["TT_Spiderboss"] = math.huge ,["OrderNexus"] = math.huge ,["Soraka"] = 1000.0000 ,["Jinx"] = 2750.0000 ,["TestCubeRenderwCollision"] = 2750.0000 ,["Red_Minion_Wizard"] = 650.0000 ,["JarvanIV"] = 20.0000 ,["Blue_Minion_Wizard"] = 650.0000 ,["TT_ChaosTurret2"] = 1200.0000 ,["TT_ChaosTurret3"] = 1200.0000 ,["TT_ChaosTurret1"] = 1200.0000 ,["ChaosTurretGiant"] = 1200.0000 ,["Dragon"] = 1200.0000 ,["LuluSnowman"] = 1200.0000 ,["Worm"] = 1200.0000 ,["ChaosTurretWorm"] = 1200.0000 ,["TT_ChaosInhibitor"] = 1200.0000 ,["ChaosTurretNormal"] = 1200.0000 ,["AncientGolem"] = 500.0000 ,["ZyraGraspingPlant"] = 500.0000 ,["HA_AP_OrderTurret3"] = 1200.0000 ,["HA_AP_OrderTurret2"] = 1200.0000 ,["Tryndamere"] = 347.79999 ,["OrderTurretNormal2"] = 1200.0000 ,["Singed"] = 700.0000 ,["OrderInhibitor"] = 700.0000 ,["Diana"] = 347.79999 ,["HA_FB_HealthRelic"] = 347.79999 ,["TT_OrderInhibitor"] = 347.79999 ,["GreatWraith"] = 750.0000 ,["Yasuo"] = 347.79999 ,["OrderTurretDragon"] = 1200.0000 ,["OrderTurretNormal"] = 1200.0000 ,["LizardElder"] = 500.0000 ,["HA_AP_ChaosTurret"] = 1200.0000 ,["Ahri"] = 1750.0000 ,["Lulu"] = 1450.0000 ,["ChaosInhibitor"] = 1450.0000 ,["HA_AP_ChaosTurret3"] = 1200.0000 ,["HA_AP_ChaosTurret2"] = 1200.0000 ,["ChaosTurretWorm2"] = 1200.0000 ,["TT_OrderTurret1"] = 1200.0000 ,["TT_OrderTurret2"] = 1200.0000 ,["TT_OrderTurret3"] = 1200.0000 ,["LuluFaerie"] = 1200.0000 ,["HA_AP_OrderTurret"] = 1200.0000 ,["OrderTurretAngel"] = 1200.0000 ,["YellowTrinketUpgrade"] = 1200.0000 ,["MasterYi"] = math.huge ,["Lissandra"] = 2000.0000 ,["ARAMOrderTurretNexus"] = 1200.0000 ,["Draven"] = 1700.0000 ,["FiddleSticks"] = 1750.0000 ,["SmallGolem"] = math.huge ,["ARAMOrderTurretFront"] = 1200.0000 ,["ChaosTurretTutorial"] = 1200.0000 ,["NasusUlt"] = 1200.0000 ,["Maokai"] = math.huge ,["Wraith"] = 750.0000 ,["Wolf"] = math.huge ,["Sivir"] = 1750.0000 ,["Corki"] = 2000.0000 ,["Janna"] = 1200.0000 ,["Nasus"] = math.huge ,["Golem"] = math.huge ,["ARAMChaosTurretFront"] = 1200.0000 ,["ARAMOrderTurretInhib"] = 1200.0000 ,["LeeSin"] = math.huge ,["HA_AP_ChaosTurretTutorial"] = 1200.0000 ,["GiantWolf"] = math.huge ,["HA_AP_OrderTurretTutorial"] = 1200.0000 ,["YoungLizard"] = 750.0000 ,["Jax"] = 400.0000 ,["LesserWraith"] = math.huge ,["Blitzcrank"] = math.huge ,["ARAMChaosTurretInhib"] = 1200.0000 ,["Shen"] = 400.0000 ,["Nocturne"] = math.huge ,["Sona"] = 1500.0000 ,["ARAMChaosTurretNexus"] = 1200.0000 ,["YellowTrinket"] = 1200.0000 ,["OrderTurretTutorial"] = 1200.0000 ,["Caitlyn"] = 2500.0000 ,["Trundle"] = 347.79999 ,["Malphite"] = 1000.0000 ,["Mordekaiser"] = math.huge ,["ZyraSeed"] = math.huge ,["Vi"] = 1000.0000 ,["Tutorial_Red_Minion_Wizard"] = 650.0000 ,["Renekton"] = math.huge ,["Anivia"] = 1400.0000 ,["Fizz"] = math.huge ,["Heimerdinger"] = 1500.0000 ,["Evelynn"] = 467.0000 ,["Rumble"] = 347.79999 ,["Leblanc"] = 1700.0000 ,["Darius"] = math.huge ,["OlafAxe"] = math.huge ,["Viktor"] = 2300.0000 ,["XinZhao"] = 20.0000 ,["Orianna"] = 1450.0000 ,["Vladimir"] = 1400.0000 ,["Nidalee"] = 1750.0000 ,["Tutorial_Red_Minion_Basic"] = math.huge ,["ZedShadow"] = 467.0000 ,["Syndra"] = 1800.0000 ,["Zac"] = 1000.0000 ,["Olaf"] = 347.79999 ,["Veigar"] = 1100.0000 ,["Twitch"] = 2500.0000 ,["Alistar"] = math.huge ,["Akali"] = 467.0000 ,["Urgot"] = 1300.0000 ,["Leona"] = 347.79999 ,["Talon"] = math.huge ,["Karma"] = 1500.0000 ,["Jayce"] = 347.79999 ,["Galio"] = 1000.0000 ,["Shaco"] = math.huge ,["Taric"] = math.huge ,["TwistedFate"] = 1500.0000 ,["Varus"] = 2000.0000 ,["Garen"] = 347.79999 ,["Swain"] = 1600.0000 ,["Vayne"] = 2000.0000 ,["Fiora"] = 467.0000 ,["Quinn"] = 2000.0000 ,["Kayle"] = math.huge ,["Blue_Minion_Basic"] = math.huge ,["Brand"] = 2000.0000 ,["Teemo"] = 1300.0000 ,["Amumu"] = 500.0000 ,["Annie"] = 1200.0000 ,["Odin_Blue_Minion_caster"] = 1200.0000 ,["Elise"] = 1600.0000 ,["Nami"] = 1500.0000 ,["Poppy"] = 500.0000 ,["AniviaEgg"] = 500.0000 ,["Tristana"] = 2250.0000 ,["Graves"] = 3000.0000 ,["Morgana"] = 1600.0000 ,["Gragas"] = math.huge ,["MissFortune"] = 2000.0000 ,["Warwick"] = math.huge ,["Cassiopeia"] = 1200.0000 ,["Tutorial_Blue_Minion_Wizard"] = 650.0000 ,["DrMundo"] = math.huge ,["Volibear"] = 467.0000 ,["Irelia"] = 467.0000 ,["Odin_Red_Minion_Caster"] = 650.0000 ,["Lucian"] = 2800.0000 ,["Yorick"] = math.huge ,["RammusPB"] = math.huge ,["Red_Minion_Basic"] = math.huge ,["Udyr"] = 467.0000 ,["MonkeyKing"] = 20.0000 ,["Tutorial_Blue_Minion_Basic"] = math.huge ,["Kennen"] = 1600.0000 ,["Nunu"] = 500.0000 ,["Ryze"] = 2400.0000 ,["Zed"] = 467.0000 ,["Nautilus"] = 1000.0000 ,["Gangplank"] = 1000.0000 ,["Lux"] = 1600.0000 ,["Sejuani"] = 500.0000 ,["Ezreal"] = 2000.0000 ,["OdinNeutralGuardian"] = 1800.0000 ,["Khazix"] = 500.0000 ,["Sion"] = math.huge ,["Aatrox"] = 347.79999 ,["Hecarim"] = 500.0000 ,["Pantheon"] = 20.0000 ,["Shyvana"] = 467.0000 ,["Zyra"] = 1700.0000 ,["Karthus"] = 1200.0000 ,["Rammus"] = math.huge ,["Zilean"] = 1200.0000 ,["Chogath"] = 500.0000 ,["Malzahar"] = 2000.0000 ,["YorickRavenousGhoul"] = 347.79999 ,["YorickSpectralGhoul"] = 347.79999 ,["JinxMine"] = 347.79999 ,["YorickDecayedGhoul"] = 347.79999 ,["XerathArcaneBarrageLauncher"] = 347.79999 ,["Odin_SOG_Order_Crystal"] = 347.79999 ,["TestCube"] = 347.79999 ,["ShyvanaDragon"] = math.huge ,["FizzBait"] = math.huge ,["Blue_Minion_MechMelee"] = math.huge ,["OdinQuestBuff"] = math.huge ,["TT_Buffplat_L"] = math.huge ,["TT_Buffplat_R"] = math.huge ,["KogMawDead"] = math.huge ,["TempMovableChar"] = math.huge ,["Lizard"] = 500.0000 ,["GolemOdin"] = math.huge ,["OdinOpeningBarrier"] = math.huge ,["TT_ChaosTurret4"] = 500.0000 ,["TT_Flytrap_A"] = 500.0000 ,["TT_NWolf"] = math.huge ,["OdinShieldRelic"] = math.huge ,["LuluSquill"] = math.huge ,["redDragon"] = math.huge ,["MonkeyKingClone"] = math.huge ,["Odin_skeleton"] = math.huge ,["OdinChaosTurretShrine"] = 500.0000 ,["Cassiopeia_Death"] = 500.0000 ,["OdinCenterRelic"] = 500.0000 ,["OdinRedSuperminion"] = math.huge ,["JarvanIVWall"] = math.huge ,["ARAMOrderNexus"] = math.huge ,["Red_Minion_MechCannon"] = 1200.0000 ,["OdinBlueSuperminion"] = math.huge ,["SyndraOrbs"] = math.huge ,["LuluKitty"] = math.huge ,["SwainNoBird"] = math.huge ,["LuluLadybug"] = math.huge ,["CaitlynTrap"] = math.huge ,["TT_Shroom_A"] = math.huge ,["ARAMChaosTurretShrine"] = 500.0000 ,["Odin_Windmill_Propellers"] = 500.0000 ,["TT_NWolf2"] = math.huge ,["OdinMinionGraveyardPortal"] = math.huge ,["SwainBeam"] = math.huge ,["Summoner_Rider_Order"] = math.huge ,["TT_Relic"] = math.huge ,["odin_lifts_crystal"] = math.huge ,["OdinOrderTurretShrine"] = 500.0000 ,["SpellBook1"] = 500.0000 ,["Blue_Minion_MechCannon"] = 1200.0000 ,["TT_ChaosInhibitor_D"] = 1200.0000 ,["Odin_SoG_Chaos"] = 1200.0000 ,["TrundleWall"] = 1200.0000 ,["HA_AP_HealthRelic"] = 1200.0000 ,["OrderTurretShrine"] = 500.0000 ,["OriannaBall"] = 500.0000 ,["ChaosTurretShrine"] = 500.0000 ,["LuluCupcake"] = 500.0000 ,["HA_AP_ChaosTurretShrine"] = 500.0000 ,["TT_NWraith2"] = 750.0000 ,["TT_Tree_A"] = 750.0000 ,["SummonerBeacon"] = 750.0000 ,["Odin_Drill"] = 750.0000 ,["TT_NGolem"] = math.huge ,["AramSpeedShrine"] = math.huge ,["OriannaNoBall"] = math.huge ,["Odin_Minecart"] = math.huge ,["Summoner_Rider_Chaos"] = math.huge ,["OdinSpeedShrine"] = math.huge ,["TT_SpeedShrine"] = math.huge ,["odin_lifts_buckets"] = math.huge ,["OdinRockSaw"] = math.huge ,["OdinMinionSpawnPortal"] = math.huge ,["SyndraSphere"] = math.huge ,["Red_Minion_MechMelee"] = math.huge ,["SwainRaven"] = math.huge ,["crystal_platform"] = math.huge ,["MaokaiSproutling"] = math.huge ,["Urf"] = math.huge ,["TestCubeRender10Vision"] = math.huge ,["MalzaharVoidling"] = 500.0000 ,["GhostWard"] = 500.0000 ,["MonkeyKingFlying"] = 500.0000 ,["LuluPig"] = 500.0000 ,["AniviaIceBlock"] = 500.0000 ,["TT_OrderInhibitor_D"] = 500.0000 ,["Odin_SoG_Order"] = 500.0000 ,["RammusDBC"] = 500.0000 ,["FizzShark"] = 500.0000 ,["LuluDragon"] = 500.0000 ,["OdinTestCubeRender"] = 500.0000 ,["TT_Tree1"] = 500.0000 ,["ARAMOrderTurretShrine"] = 500.0000 ,["Odin_Windmill_Gears"] = 500.0000 ,["ARAMChaosNexus"] = 500.0000 ,["TT_NWraith"] = 750.0000 ,["TT_OrderTurret4"] = 500.0000 ,["Odin_SOG_Chaos_Crystal"] = 500.0000 ,["OdinQuestIndicator"] = 500.0000 ,["JarvanIVStandard"] = 500.0000 ,["TT_DummyPusher"] = 500.0000 ,["OdinClaw"] = 500.0000 ,["EliseSpiderling"] = 2000.0000 ,["QuinnValor"] = math.huge ,["UdyrTigerUlt"] = math.huge ,["UdyrTurtleUlt"] = math.huge ,["UdyrUlt"] = math.huge ,["UdyrPhoenixUlt"] = math.huge ,["ShacoBox"] = 1500.0000 ,["HA_AP_Poro"] = 1500.0000 ,["AnnieTibbers"] = math.huge ,["UdyrPhoenix"] = math.huge ,["UdyrTurtle"] = math.huge ,["UdyrTiger"] = math.huge ,["HA_AP_OrderShrineTurret"] = 500.0000 ,["HA_AP_Chains_Long"] = 500.0000 ,["HA_AP_BridgeLaneStatue"] = 500.0000 ,["HA_AP_ChaosTurretRubble"] = 500.0000 ,["HA_AP_PoroSpawner"] = 500.0000 ,["HA_AP_Cutaway"] = 500.0000 ,["HA_AP_Chains"] = 500.0000 ,["ChaosInhibitor_D"] = 500.0000 ,["ZacRebirthBloblet"] = 500.0000 ,["OrderInhibitor_D"] = 500.0000 ,["Nidalee_Spear"] = 500.0000 ,["Nidalee_Cougar"] = 500.0000 ,["TT_Buffplat_Chain"] = 500.0000 ,["WriggleLantern"] = 500.0000 ,["TwistedLizardElder"] = 500.0000 ,["RabidWolf"] = math.huge ,["HeimerTGreen"] = 1599.3999 ,["HeimerTRed"] = 1599.3999 ,["ViktorFF"] = 1599.3999 ,["TwistedGolem"] = math.huge ,["TwistedSmallWolf"] = math.huge ,["TwistedGiantWolf"] = math.huge ,["TwistedTinyWraith"] = 750.0000 ,["TwistedBlueWraith"] = 750.0000 ,["TwistedYoungLizard"] = 750.0000 ,["Red_Minion_Melee"] = math.huge ,["Blue_Minion_Melee"] = math.huge ,["Blue_Minion_Healer"] = 1000.0000 ,["Ghast"] = 750.0000 ,["blueDragon"] = 800.0000 ,["Red_Minion_MechRange"] = 3000, ["SRU_OrderMinionRanged"] = 650, ["SRU_ChaosMinionRanged"] = 650, ["SRU_OrderMinionSiege"] = 1200, ["SRU_ChaosMinionSiege"] = 1200, ["SRUAP_Turret_Chaos1"]  = 1200, ["SRUAP_Turret_Chaos2"]  = 1200, ["SRUAP_Turret_Chaos3"] = 1200, ["SRUAP_Turret_Order1"]  = 1200, ["SRUAP_Turret_Order2"]  = 1200, ["SRUAP_Turret_Order3"] = 1200, ["SRUAP_Turret_Chaos4"] = 1200, ["SRUAP_Turret_Chaos5"] = 500, ["SRUAP_Turret_Order4"] = 1200, ["SRUAP_Turret_Order5"] = 500 }

        self.ActiveAttacks = {}
        self.MinionsAttacks = {}

        self.lastick = 0

        self.nohitboxmode = false
        self.DontUseWayPoints = false
        self.ShotAtMaxRange = true

        if menu then
            self.VPredictionMenu = menu.addItem(SubMenu.new("<SDK> VPrediction"))
            self.VPMenu_Mode = self.VPredictionMenu.addItem(MenuStringList.new("Cast Mode:", {"Fast", "Medium", "Slow"}, 1))
            self.VPMenu_Collision = self.VPredictionMenu.addItem(SubMenu.new("Collision Settings"))
            self.VPMenu_Buffer = self.VPMenu_Collision.addItem(MenuSlider.new("Collision Buffer", 20, 0, 100, 1))
            self.VPMenu_Minions = self.VPMenu_Collision.addItem(MenuBool.new("Normal Minions", true))
            self.VPMenu_Mobs = self.VPMenu_Collision.addItem(MenuBool.new("Jungle Minions", true))
            self.VPMenu_Others = self.VPMenu_Collision.addItem(MenuBool.new("Others", true))
            --self.VPMenu_CHealth = self.VPMenu_Collision.addItem(MenuBool.new("Check if minions about to die", false))
            --self.VPMenu_info = self.VPMenu_Collision.addItem(MenuSeparator.new("^ May cause FPS drops ^"))

            self.VPMenu_UnitPos = self.VPMenu_Collision.addItem(MenuBool.new("Check Collision at Unit Pos", true))
            self.VPMenu_CastPos = self.VPMenu_Collision.addItem(MenuBool.new("Check Collision at Cast Pos", true))
            self.VPMenu_PredictPos = self.VPMenu_Collision.addItem(MenuBool.new("Check Collision at Predicted Pos", false))

            self.VPMenu_Developers = self.VPredictionMenu.addItem(SubMenu.new("Developer Settings"))
            self.VPMenu_Debug = self.VPMenu_Developers.addItem(MenuBool.new("Draw Enemy Hitboxes", false))
            --self.VPMenu_SC = self.VPMenu_Developers.addItem(MenuBool.new("Show Collision", false))
            --self.VPMenu_ColRect = self.VPMenu_Developers.addItem(MenuSlider.new("Skillshot Width: ", 65, 0, 200, 5))
            self.VPMenu_Version = self.VPredictionMenu.addItem(MenuSeparator.new(string.format("Version: " .. tostring(self.version)), true))
            self.VPMenu_Credit = self.VPredictionMenu.addItem(MenuSeparator.new("Ported & Updated By: Dewblackio2", true))
        end

        --[[Use waypoints from the last 10 seconds]]
        self.WaypointsTime = 10


        self.EnemyMinions = minionManager(MINION_ENEMY, 2000, myHero, MINION_SORT_HEALTH_ASC)
        self.JungleMinions = minionManager(MINION_JUNGLE, 2000, myHero, MINION_SORT_HEALTH_ASC)
        self.OtherMinions = minionManager(MINION_OTHER, 2000, myHero, MINION_SORT_HEALTH_ASC)

        self.TargetsVisible = {}
        self.TargetsWaypoints = {}
        self.TargetsImmobile = {}
        self.TargetsDashing = {}
        self.TargetsSlowed = {}
        self.DontShoot = {}
        self.DontShoot2 = {}
        self.DontShootUntilNewWaypoints = {}


--[[

        AddProcessSpellCallback(function(unit, spell) self:OnProcessSpell(unit, spell) end)
        AddTickCallback(function() self:OnTick() end)
        AddDrawCallback(function() self:OnDraw() end)
        AddProcessSpellCallback(function(unit, spell) self:CollisionProcessSpell(unit, spell) end)
]]

        Callback.Add("Tick", function() self:OnTick() end)
        Callback.Add("Draw", function() self:OnDraw() end)
        Callback.Add("ProcessSpell", function(unit, spell) self:OnProcessSpell(unit, spell) end)
        Callback.Add("ProcessSpell", function(unit, spell) self:CollisionProcessSpell(unit, spell) end)
        Callback.Add("UpdateBuff", function(unit, buff) self:OnGainBuff(unit, buff) end)
        Callback.Add("PlayAnimation", function(unit, anim) self:Animation(unit, anim) end)
        Callback.Add("NewPath", function(...) self:OnNewPath(...) end)

        self.BlackList =
        {
                {name = "aatroxq", duration = 0.75}, --[[4 Dashes, OnDash fails]]
        }

        --[[Spells that will cause OnDash to fire, dont shoot and wait to OnDash]]
        self.dashAboutToHappend =
        {
                {name = "ahritumble", duration = 0.25},--ahri's r
                {name = "akalishadowdance", duration = 0.25},--akali r
                {name = "headbutt", duration = 0.25},--alistar w
                {name = "caitlynentrapment", duration = 0.25},--caitlyn e
                {name = "carpetbomb", duration = 0.25},--corki w
                {name = "dianateleport", duration = 0.25},--diana r
                {name = "fizzpiercingstrike", duration = 0.25},--fizz q
                {name = "fizzjump", duration = 0.25},--fizz e
                {name = "gragasbodyslam", duration = 0.25},--gragas e
                {name = "gravesmove", duration = 0.25},--graves e
                {name = "ireliagatotsu", duration = 0.25},--irelia q
                {name = "jarvanivdragonstrike", duration = 0.25},--jarvan q
                {name = "jaxleapstrike", duration = 0.25},--jax q
                {name = "khazixe", duration = 0.25},--khazix e and e evolved
                {name = "leblancslide", duration = 0.25},--leblanc w
                {name = "leblancslidem", duration = 0.25},--leblanc w (r)
                {name = "blindmonkqtwo", duration = 0.25},--lee sin q
                {name = "blindmonkwone", duration = 0.25},--lee sin w
                {name = "luciane", duration = 0.25},--lucian e
                {name = "maokaiunstablegrowth", duration = 0.25},--maokai w
                {name = "nocturneparanoia2", duration = 0.25},--nocturne r
                {name = "pantheon_leapbash", duration = 0.25},--pantheon e?
                {name = "renektonsliceanddice", duration = 0.25},--renekton e
                {name = "riventricleave", duration = 0.25},--riven q
                {name = "rivenfeint", duration = 0.25},--riven e
                {name = "sejuaniarcticassault", duration = 0.25},--sejuani q
                {name = "shenshadowdash", duration = 0.25},--shen e
                {name = "shyvanatransformcast", duration = 0.25},--shyvana r
                {name = "rocketjump", duration = 0.25},--tristana w
                {name = "slashcast", duration = 0.25},--tryndamere e
                {name = "vaynetumble", duration = 0.25},--vayne q
                {name = "viq", duration = 0.25},--vi q
                {name = "monkeykingnimbus", duration = 0.25},--wukong q
                {name = "xenzhaosweep", duration = 0.25},--xin xhao q
                {name = "yasuodashwrapper", duration = 0.25},--yasuo e

        }
        --[[Spells that don't allow movement (durations approx)]]
        self.spells = {
                {name = "katarinar", duration = 1}, --Katarinas R
                {name = "drain", duration = 1}, --Fiddle W
                {name = "crowstorm", duration = 1}, --Fiddle R
                {name = "consume", duration = 0.5}, --Nunu Q
                {name = "absolutezero", duration = 1}, --Nunu R
                {name = "rocketgrab", duration = 0.5}, --Blitzcrank Q
                {name = "staticfield", duration = 0.5}, --Blitzcrank R
                {name = "cassiopeiapetrifyinggaze", duration = 0.5}, --Cassio's R
                {name = "ezrealtrueshotbarrage", duration = 1}, --Ezreal's R
                {name = "galioidolofdurand", duration = 1}, --Ezreal's R
                --{name = "gragasdrunkenrage", duration = 1}, --Gragas W, Rito changed it so that it allows full movement while casting
                {name = "luxmalicecannon", duration = 1}, --Lux R
                {name = "reapthewhirlwind", duration = 1}, --Jannas R
                {name = "jinxw", duration = 0.6}, --jinxW
                {name = "jinxr", duration = 0.6}, --jinxR
                {name = "missfortunebullettime", duration = 1}, --MissFortuneR
                {name = "shenstandunited", duration = 1}, --ShenR
                {name = "threshe", duration = 0.4}, --ThreshE
                {name = "threshrpenta", duration = 0.75}, --ThreshR
                {name = "infiniteduress", duration = 1}, --Warwick R
                {name = "meditate", duration = 1} --yi W
        }

        self.blinks = {
                {name = "ezrealarcaneshift", range = 475, delay = 0.25, delay2=0.8},--Ezreals E
                {name = "deceive", range = 400, delay = 0.25, delay2=0.8}, --Shacos Q
                {name = "riftwalk", range = 700, delay = 0.25, delay2=0.8},--KassadinR
                {name = "gate", range = 5500, delay = 1.5, delay2=1.5},--Twisted fate R
                {name = "katarinae", range = math.huge, delay = 0.25, delay2=0.8},--Katarinas E
                {name = "elisespideredescent", range = math.huge, delay = 0.25, delay2=0.8},--Elise E
                {name = "elisespidere", range = math.huge, delay = 0.25, delay2=0.8},--Elise insta E
        }

        __PrintTextGame("<b><font color=\"#ff00ff\">[SDK]VPrediction:</font></b> <b><font color=\"#ffffff\">Loaded! (v" .. self.version .. ").</font></b><b><font color=\"#ff00ff\"></font></b> </font>")
        return self
end

function VPrediction:GetTime()
        return os.clock()
end
function VPrediction:GetVersion()
    return self.version
end

function VPrediction:OnGainBuff(unit, buff)
    buff.duration = buff.EndT - buff.BeginT
    if unit.Type == myHero.Type and (buff.Type == 5 or buff.Type == 11 or buff.Type == 29 or buff.Type == 24) then
    self.TargetsImmobile[unit.NetworkId] = self:GetTime() + buff.duration
    elseif unit.Type == myHero.Type and (buff.Type == 10 or buff.Type == 22 or buff.Type == 21 or buff.Type == 8) then
    self.TargetsSlowed[unit.NetworkId] = self:GetTime() + buff.duration
    end

    if unit.Type == myHero.Type and (buff.Type == 30) then
    self.DontShoot[unit.NetworkId] = self:GetTime() + 1
    end
end

function VPrediction:OnProcessSpell(unit, spell)
    if unit and unit.Type == myHero.Type then
        for i, s in ipairs(self.spells) do
            if spell.Name:lower() == s.name then
                self.TargetsImmobile[unit.NetworkId] = self:GetTime() + s.duration
                return
            end
        end
        spell.endPos = {x=spell.DestPos_x, y=spell.DestPos_y, z=spell.DestPos_z}
        spell.startPos =  {x=spell.SourcePos_x, y=spell.SourcePos_y, z=spell.SourcePos_z}
        for i, s in ipairs(self.blinks) do
            local LandingPos = GetDistance(unit, Vector(spell.endPos)) < s.range and Vector(spell.endPos) or Vector(unit) + s.range * (Vector(spell.endPos) - Vector(unit)):Normalized()
            if spell.Name:lower() == s.name and not IsWall(spell.endPos.x, spell.endPos.y, spell.endPos.z) then
                self.TargetsDashing[unit.NetworkId] = {isblink = true, duration = s.delay, endT = self:GetTime() + s.delay, endT2 = self:GetTime() + s.delay2, startPos = Vector(unit), endPos = LandingPos}
                return
            end
        end

        for i, s in ipairs(self.BlackList) do
            if spell.Name:lower() == s.name then
                self.DontShoot[unit.NetworkId] = self:GetTime() + s.duration
                return
            end
        end

        for i, s in ipairs(self.dashAboutToHappend) do
            if spell.Name:lower() == s.name then
                self.DontShoot2[unit.NetworkId] = self:GetTime() + s.duration
                return
            end
        end
    end

    --[[if unit and unit.Type == myHero.Type and unit.IsMe then
        self.LastFocusedTarget = GetTargetFromTargetId(spell.TargetId)
    end]]

    --[[if unit and unit.IsValid and unit.Type ~= myHero.Type and unit.TeamId == myHero.TeamId and spell.Name:lower():find("basicattack") and not self.projectilespeeds[unit.CharName] then

        local time = self:GetTime() + 0.393 - GetLatency()/2000
        local tar = GetTargetFromTargetId(spell.TargetId) ~= nil and GetTargetFromTargetId(spell.TargetId) or nil
        if tar ~= nil then
            table.insert(self.ActiveAttacks, {Attacker = unit, pos = Vector(unit), Target = tar, animationTime = math.huge, damage = unit.TotalDmg, hittime=time, starttime = self:GetTime() - GetLatency()/2000, windUpTime = 0.393, projectilespeed = math.huge})
        end
    end]]
end

function VPrediction:OnNewPath(unit, startPos, endPos, isDash, dashSpeed ,dashGravity, dashDistance)
    if unit.Type == myHero.Type and unit.TeamId ~= myHero.TeamId or unit == myHero then
        if PA[unit.NetworkId][#PA[unit.NetworkId] -1] then
            local p1 = PA[unit.NetworkId][#PA[unit.NetworkId] -1].p
            local p2 = PA[unit.NetworkId][#PA[unit.NetworkId]].p
            local angle = Vector(unit.x, unit.y, unit.z):AngleBetween(Vector(p2.x, p2.y, p2.z), Vector(p1.x, p1.y, p1.z))
            if angle > 20 then
                local submit = {t = os.clock(), p = endPos}
                table.insert(PA[unit.NetworkId], submit)
            end
        else
            local submit = {t = os.clock(), p = endPos}
            table.insert(PA[unit.NetworkId], submit)
        end
    end
    local object = unit
    local NetworkID = unit.NetworkId
    if object and object.IsValid and object.NetworkId and object.Type == myHero.Type then
        self.DontShootUntilNewWaypoints[NetworkID] = false
        if self.TargetsWaypoints[NetworkID] == nil then
                self.TargetsWaypoints[NetworkID] = {}
        end
        local WaypointsToAdd = self:GetCurrentWayPoints(unit)
        if WaypointsToAdd and #WaypointsToAdd >= 1 then
                --[[Save only the last waypoint (where the player clicked)]]
                table.insert(self.TargetsWaypoints[NetworkID], {unitpos = Vector(object) , waypoint = WaypointsToAdd[#WaypointsToAdd], time = self:GetTime(), n = #WaypointsToAdd})
        end
    elseif object and object.IsValid and object.Type ~= myHero.Type then
        local i = 1
        while i <= #self.ActiveAttacks do
            if (self.ActiveAttacks[i].Attacker and self.ActiveAttacks[i].Attacker.IsValid and self.ActiveAttacks[i].Attacker.NetworkId == NetworkID and (self.ActiveAttacks[i].starttime + self.ActiveAttacks[i].windUpTime - GetLatency()/2000) > self:GetTime()) then
                local wpts = self:GetWaypoints(unit.NetworkId)
                if #wpts > 1 then
                    table.remove(self.ActiveAttacks, i)
                else
                    i = i + 1
                end
            else
                i = i + 1
            end
        end
    end
    --[[OnDash Alternative]]
    if isDash then
        local dash = {}
        if unit.Type == myHero.Type then
            dash.startPos = startPos
            dash.endPos = endPos
            dash.speed = dashSpeed
            dash.startT = self:GetTime() - GetLatency()/2000
            local dis = GetDistance(startPos, endPos)
            dash.endT = dash.startT + (dis/dashSpeed)
            self.TargetsDashing[unit.NetworkId] = dash
            self.DontShootUntilNewWaypoints[unit.NetworkId] = true
        end
    end
end

function VPrediction:IsImmobile(unit, delay, radius, speed, from, spelltype)
    if self.TargetsImmobile[unit.NetworkId] then
        local ExtraDelay = speed == math.huge and  0 or (GetDistance(from, unit) / speed)
        if (self.TargetsImmobile[unit.NetworkId] > (self:GetTime() + delay + ExtraDelay) and spelltype == "circular") then
            return true, Vector(unit), Vector(unit) + (radius/3) * (Vector(from) - Vector(unit)):Normalized()
        elseif (self.TargetsImmobile[unit.NetworkId] + (radius / unit.MoveSpeed)) > (self:GetTime() + delay + ExtraDelay) then
            return true, Vector(unit), Vector(unit)
        end
    end
    return false, Vector(unit), Vector(unit)
end

function VPrediction:isSlowed(unit, delay, speed, from)
    if self.TargetsSlowed[unit.NetworkId] then
        if self.TargetsSlowed[unit.NetworkId] > (self:GetTime() + delay + GetDistance(unit, from) / speed) then
            return true
        end
    end
    return false
end

function VPrediction:IsDashing(unit, delay, radius, speed, from)
    local TargetDashing = false
    local CanHit = false
    local Position

    if self.TargetsDashing[unit.NetworkId] then
        local dash = self.TargetsDashing[unit.NetworkId]
        if dash.endT >= self:GetTime() then
            TargetDashing = true
            if dash.isblink then
                if (dash.endT - self:GetTime()) <= (delay + GetDistance(from, dash.endPos)/speed) then
                    Position = Vector(dash.endPos.x, 0, dash.endPos.z)
                    CanHit = (unit.MoveSpeed * (delay + GetDistance(from, dash.endPos)/speed - (dash.endT2 - self:GetTime()))) < radius
                end

                if ((dash.endT - self:GetTime()) >= (delay + GetDistance(from, dash.startPos)/speed)) and not CanHit then
                    Position = Vector(dash.startPos.x, 0, dash.startPos.z)
                    CanHit = true
                end
            else
                local t1, p1, t2, p2, dist = VectorMovementCollision(dash.startPos, dash.endPos, dash.speed, from, speed, (self:GetTime() - dash.startT) + delay)
                t1, t2 = (t1 and 0 <= t1 and t1 <= (dash.endT - self:GetTime() - delay)) and t1 or nil, (t2 and 0 <= t2 and t2 <=  (dash.endT - self:GetTime() - delay)) and t2 or nil
                local t = t1 and t2 and math.min(t1,t2) or t1 or t2
                if t then
                    Position = t==t1 and Vector(p1.x, 0, p1.y) or Vector(p2.x, 0, p2.y)
                    CanHit = true
                else
                    Position = Vector(dash.endPos.x, 0, dash.endPos.z)
                    CanHit = (unit.MoveSpeed * (delay + GetDistance(from, Position)/speed - (dash.endT - self:GetTime()))) < radius
                end
            end
        end
    end
    return TargetDashing, CanHit, Position
end

function VPrediction:GetWaypoints(NetworkID, from, to)
    local Result = {}
    to = to and to or self:GetTime()
    if self.TargetsWaypoints[NetworkID] then
        for i, waypoint in ipairs(self.TargetsWaypoints[NetworkID]) do
            if from <= waypoint.time  and to >= waypoint.time then
                table.insert(Result, waypoint)
            end
        end
    end
    return Result, #Result
end

function VPrediction:CountWaypoints(NetworkID, from, to)
    local R, N = self:GetWaypoints(NetworkID, from, to)
    --if N == nil then N = 0 end
    return N
end

function VPrediction:GetWaypointsLength(Waypoints)
    local result = 0
    for i = 1, #Waypoints -1 do
        result = result + GetDistance(Waypoints[i], Waypoints[i + 1])
    end
    return result
end

function VPrediction:CutWaypoints(Waypoints, distance)
    local result = {}
    local remaining = distance
    if distance > 0 then
        for i = 1, #Waypoints -1 do
            local A, B = Waypoints[i], Waypoints[i + 1]
            local dist = GetDistance(A, B)
            if dist >= remaining then
                result[1] = Vector(A) + remaining * (Vector(B) - Vector(A)):Normalized()

                for j = i + 1, #Waypoints do
                    result[j - i + 1] = Waypoints[j]
                end
                remaining = 0
                break
            else
                remaining = remaining - dist
            end
        end
    else
        local A, B = Waypoints[1], Waypoints[2]
        result = Waypoints
        result[1] = Vector(A) - distance * (Vector(B) - Vector(A)):Normalized()
    end

    return result
end

function VPrediction:GetCurrentWayPoints(object)
    local result = {}

    if object.PathCount > 0 then
        table.insert(result, Vector(object))
        for i = 1, object.PathCount do

            local x,y,z = object.GetPath(i)
            table.insert(result, Vector(x,y,z))
        end
    else
        table.insert(result, Vector(object))
    end
    return result
end

--[[Calculate the hero position based on the last waypoints]]
function VPrediction:CalculateTargetPosition(unit, delay, radius, speed, from, spelltype, second)
    if unit.Type == myHero.Type and unit.TeamId ~= myHero.TeamId or unit == myHero then
        --print(unit.charName.." "..#PA[unit.networkID])
        if #PA[unit.NetworkId] > 4 then
            return Vector(unit), Vector(unit)
        elseif #PA[unit.NetworkId] > 3 then
            delay = delay*.8
            speed = speed*1.20
        end

    end
    local spot
    unit.endPath = {x=unit.DestPos_x,y=unit.DestPos_y,z=unit.DestPos_z}
    unit.pos = {x=unit.x,y=unit.y,z=unit.z}
    if ValidTarget(unit) and unit.endPath or unit == myHero then    ---- FIX
        local p90x = second and second or unit
        local pathPot = (unit.MoveSpeed*((GetDistance(myHero, p90x)/speed)+delay))

        if unit.PathCount < 3 then
            local v = Vector(unit) + (Vector(unit.endPath)-Vector(unit)):Normalized()*(pathPot - unit.CollisionRadius + 10)
            if GetDistance(unit, v) > 1 then
                if GetDistance(unit.endPath, unit) >= GetDistance(unit, v) then
                    spot = v
                else
                    spot = Vector(unit.endPath)
                end
            else
                spot = Vector(unit.endPath)
            end
        else
            unit.pathIndex = GetPathIndex(unit)
            for i = unit.pathIndex, unit.PathCount do
                if unit.GetPath(i) and unit.GetPath(i-1) then
                    local pStart = i == unit.pathIndex and unit.pos or unit.GetPath(i-1)
                    local pEnd = unit.GetPath(i)
                    local iPathDist = GetDistance(pStart, pEnd)
                    if unit.GetPath(unit.pathIndex  - 1) then
                        if pathPot > iPathDist then
                            pathPot = pathPot-iPathDist
                        else
                            local v = Vector(pStart) + (Vector(pEnd)-Vector(pStart)):Normalized()*(pathPot- unit.CollisionRadius + 10)
                            spot = v
                            if second then
                                return spot, spot
                            else
                                return self:CalculateTargetPosition(unit, delay, radius, speed, from, spelltype, spot)
                            end
                        end
                    end
                end
            end
            if GetDistance(unit, unit.endPath) > unit.CollisionRadius then
                spot = Vector(unit.endPath)
            else
                spot = Vector(unit)
            end
        end
    end
    spot = spot and spot or Vector(unit)
    if second then
        return spot, spot
    else
        return self:CalculateTargetPosition(unit, delay, radius, speed, from, spelltype, spot)
    end
end

function VPrediction:MaxAngle(unit, currentwaypoint, from)
    local WPtable, n = self:GetWaypoints(unit.NetworkId, from)
    local Max = 0
    local CV = (Vector(currentwaypoint.x, 0, currentwaypoint.y) - Vector(unit))
        for i, waypoint in ipairs(WPtable) do
            local angle = Vector(0, 0, 0):AngleBetween(CV, Vector(waypoint.waypoint.x, 0, waypoint.waypoint.y) - Vector(waypoint.unitpos.x, 0, waypoint.unitpos.y))
            if angle > Max then
                Max = angle
            end
        end
    return Max
end

function VPrediction:WayPointAnalysis(unit, delay, radius, range, speed, from, spelltype)
    local Position, CastPosition, HitChance
    local SavedWayPoints = self.TargetsWaypoints[unit.NetworkId] and self.TargetsWaypoints[unit.NetworkId] or {}
    local CurrentWayPoints = self:GetCurrentWayPoints(unit)
    local VisibleSince = self.TargetsVisible[unit.NetworkId] and self.TargetsVisible[unit.NetworkId] or self:GetTime()

    if delay < 0.25 then
        HitChance = 2
    else
        HitChance = 1
    end

    Position, CastPosition = self:CalculateTargetPosition(unit, delay, radius, speed, from, spelltype)

    if self:CountWaypoints(unit.NetworkId, self:GetTime() - 0.1) >= 1 or self:CountWaypoints(unit.NetworkId, self:GetTime() - 1) == 1 then
        HitChance = 2
    end

    local N = 0
    local t1 = 0

    if self.VPMenu_Mode then
        N = (self.VPMenu_Mode.getValue() == _SLOW) and 3 or 2
        t1 = (self.VPMenu_Mode.getValue() == _SLOW) and 1 or 0.5
    else
        N = 2
        t1 = 0.5
    end

    if self:CountWaypoints(unit.NetworkId, self:GetTime() - 0.75) >= N then
        local angle = self:MaxAngle(unit, CurrentWayPoints[#CurrentWayPoints], self:GetTime() - t1)
        if angle > 90 then
            HitChance = 1
        elseif angle < 30 and self:CountWaypoints(unit.NetworkId, self:GetTime() - 0.1) >= 1 then
            HitChance = 2
        end
    end

    if self.VPMenu_Mode then
        N = (self.VPMenu_Mode.getValue() == _SLOW) and 2 or 1
    else
        N = 1
    end
    if self:CountWaypoints(unit.NetworkId, self:GetTime() - N) == 0 then
        HitChance = 2
    end

    if self.VPMenu_Mode then
        if self.VPMenu_Mode.getValue() == _FAST then
            HitChance = 2
        end
    else
        HitChance = 2
    end

    if #CurrentWayPoints <= 1 and self:GetTime() - VisibleSince > 1 then
        HitChance = 2
    end

    if self:isSlowed(unit, delay, speed, from) then
        HitChance = 2
    end

    if Position and CastPosition and ((radius / unit.MoveSpeed >= delay + GetDistance(from, CastPosition)/speed) or (radius / unit.MoveSpeed >= delay + GetDistance(from, Position)/speed)) then
        HitChance = 3
    end
            --[[Angle too wide]]
    if Vector(from):AngleBetween(Vector(unit), Vector(CastPosition)) > 60 then
        HitChance = 1
    end

    if not Position or not CastPosition then
        HitChance = 0
        CastPosition = Vector(unit)
        Position = CastPosition
    end

    if GetDistance(myHero, unit) < 250 and unit ~= myHero then
        HitChance = 2
        Position, CastPosition = self:CalculateTargetPosition(unit, delay*0.5, radius, speed*2, from, spelltype)
        Position = CastPosition
    end

    if #SavedWayPoints == 0 and (self:GetTime() - VisibleSince) > 3 then
        HitChance = 2
    end

    if self.DontShootUntilNewWaypoints[unit.NetworkId] then
        HitChance = 0
        CastPosition = Vector(unit)
        Position = CastPosition
    end

    return CastPosition, HitChance, Position
end

function VPrediction:GetBestCastPosition(unit, delay, radius, range, speed, from, collision, spelltype)
    assert(unit, "[SDK]VPrediction: Target can't be nil")
    --self.LastFocusedTarget = unit
    range = range and range - 15 or math.huge
    radius = radius == 0 and 1 or (radius + self:GetHitBox(unit)) - 4
    speed = speed and speed or math.huge
    from = from and from or Vector(myHero)
    --excludeWaypoints = excludeWaypoints and excludeWaypoints or false

    if from.NetworkId and from.NetworkId == myHero.NetworkId then
        from = Vector(myHero)
    end
    local IsFromMyHero = GetDistanceSqr(from, myHero) < 50*50 and true or false

    delay = delay + (0.07 + GetLatency() / 2000)

    local Position, CastPosition, HitChance = Vector(unit), Vector(unit), 0
    local TargetDashing, CanHitDashing, DashPosition = self:IsDashing(unit, delay, radius, speed, from)
    local TargetImmobile, ImmobilePos, ImmobileCastPosition = self:IsImmobile(unit, delay, radius, speed, from, spelltype)
    local VisibleSince = self.TargetsVisible[unit.NetworkId] and self.TargetsVisible[unit.NetworkId] or self:GetTime()

    if unit.Type ~= myHero.Type then
        Position, CastPosition = self:CalculateTargetPosition(unit, delay, radius, speed, from, spelltype)
        HitChance = 2
    else
        if self.DontShoot[unit.NetworkId] and self.DontShoot[unit.NetworkId] > self:GetTime() then
            Position, CastPosition = Vector(unit),  Vector(unit)
            HitChance = 0
        elseif TargetDashing then
            if CanHitDashing then
                    HitChance = 5
            else
                    HitChance = 0
            end
            Position, CastPosition = DashPosition, DashPosition
        elseif self.DontShoot2[unit.NetworkId] and self.DontShoot2[unit.NetworkId] > self:GetTime() then
            Position, CastPosition = Vector(unit.x, unit.y, unit.z),  Vector(unit.x, unit.y, unit.z)
            HitChance = 7
        elseif TargetImmobile then
            Position, CastPosition = ImmobilePos, ImmobileCastPosition
            HitChance = 4
        elseif not self.DontUseWayPoints then
            CastPosition, HitChance, Position = self:WayPointAnalysis(unit, delay, radius, range, speed, from, spelltype)
        end
    end

    --[[Out of range]]
    if IsFromMyHero then
        if (spelltype == "line" and GetDistanceSqr(from, Position) >= range * range) then
            HitChance = 0
        end
        if (spelltype == "circular" and (GetDistanceSqr(from, Position) >= (range + radius)^2)) then
            HitChance = 0
        end

        if self.ShotAtMaxRange and HitChance ~= 0 and spelltype == "circular" and (GetDistanceSqr(from, CastPosition) > range ^ 2) then
            if GetDistanceSqr(from, Position) <= (range + radius / 1.4) ^ 2 then
                if GetDistanceSqr(from, Position) <= range * range then
                    CastPosition = Position
                else
                    CastPosition = Vector(from) + range * (Vector(Position) - Vector(from)):Normalized()
                end
            end
        elseif (GetDistanceSqr(from, CastPosition) > range ^ 2) then
            HitChance = 0
        end
    end

    radius = radius - self:GetHitBox(unit) + 4

    if collision and HitChance > 0 then
        self.EnemyMinions.range = range + 500 * (delay + range/speed)
        self.JungleMinions.range = self.EnemyMinions.range
        self.OtherMinions.range = self.EnemyMinions.range
        self.EnemyMinions:update()
        self.JungleMinions:update()
        self.OtherMinions:update()

        if self.VPMenu_Collision then
            if self.VPMenu_CastPos.getValue() and self:CheckMinionCollision(unit, CastPosition, delay, radius, range, speed, from, false, false) then
                HitChance = -1
            elseif self.VPMenu_PredictPos.getValue() and self:CheckMinionCollision(unit, Position, delay, radius, range, speed, from, false, false) then
                HitChance = -1
            end
            if self.VPMenu_UnitPos.getValue() and self:CheckMinionCollision(unit, unit, delay, radius, range, speed, from, false, false) then
                HitChance = -1
            end
        else
            if self:CheckMinionCollision(unit, CastPosition, delay, radius, range, speed, from, false, false) then
                HitChance = -1
            end
            if self:CheckMinionCollision(unit, unit, delay, radius, range, speed, from, false, false) then
                HitChance = -1
            end
        end
    end
    return CastPosition, HitChance, Position
end

--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--Collision
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------

function VPrediction:GetPredictedHealth(unit, time, delay)
    local IncDamage = 0
    local i = 1
    local MaxDamage = 0
    local count = 0

    delay = delay and delay or 0.07
    while i <= #self.ActiveAttacks do
        if self.ActiveAttacks[i].Attacker and not self.ActiveAttacks[i].Attacker.IsDead and self.ActiveAttacks[i].Target and self.ActiveAttacks[i].Target.NetworkId == unit.NetworkId then
            local hittime = self.ActiveAttacks[i].starttime + self.ActiveAttacks[i].windUpTime + (GetDistance(self.ActiveAttacks[i].pos, unit)) / self.ActiveAttacks[i].projectilespeed + delay
            if self:GetTime() < hittime - delay and hittime < self:GetTime() + time  then
                IncDamage = IncDamage + self.ActiveAttacks[i].damage
                count = count + 1
                if self.ActiveAttacks[i].damage > MaxDamage then
                    MaxDamage = self.ActiveAttacks[i].damage
                end
            end
        end
        i = i + 1
    end

    return unit.HP - IncDamage, MaxDamage, count
end

function VPrediction:GetClosestUnit(obj)
    local closest = nil

    for i = 1, objManager.maxObjects do
        local object = objManager:getObject(i)

        if object and object.IsValid and obj ~= object and (object.Type == myHero.Type or object.Type == 1 or object.Type == 3) and object.TeamId ~= myHero.TeamId and  GetDistanceSqr(Vector(object), Vector(myHero)) < 2000*2000  then
            if GetDistanceSqr(Vector(obj), Vector(object)) < 250*250 then
                if object.CharName and object.CharName ~= "SRU_BaronSpawn" then
                    if closest == nil then
                        closest = object
                    elseif GetDistanceSqr(Vector(object), Vector(obj)) < GetDistanceSqr(Vector(closest), Vector(obj)) then
                        closest = object
                    end
                end
            end
        end
    end
    return closest
end

function VPrediction:GetPredictedHealth2(unit, t)
    local damage = 0
    local i = 1

    while i <= #self.ActiveAttacks do
        local n = 0
        if (self:GetTime() - 0.1) <= self.ActiveAttacks[i].starttime + self.ActiveAttacks[i].animationTime and self.ActiveAttacks[i].Target and self.ActiveAttacks[i].Target.IsValid and self.ActiveAttacks[i].Target.NetworkId == unit.NetworkId and self.ActiveAttacks[i].Attacker and self.ActiveAttacks[i].Attacker.IsValid and not self.ActiveAttacks[i].Attacker.IsDead then
            local FromT = self.ActiveAttacks[i].starttime
            local ToT = t + self:GetTime()

            while FromT < ToT do
                if FromT >= self:GetTime() and (FromT + (self.ActiveAttacks[i].windUpTime + GetDistance(Vector(unit), self.ActiveAttacks[i].pos) / self.ActiveAttacks[i].projectilespeed)) < ToT then
                    n = n + 1
                end
                FromT = FromT + self.ActiveAttacks[i].animationTime
            end
        end
        damage = damage + n * self.ActiveAttacks[i].damage
        i = i + 1
    end

    return unit.HP - damage
end
function VPrediction:Animation(unit, anim)
    if unit and _has_value({1,2,3}, unit.Type) then
        unit = GetUnit(unit.Addr)
    elseif unit and _has_value({0}, unit.Type) then
        unit = GetAIHero(unit.Addr)
    end

    if unit and unit.IsValid and unit.Type ~= myHero.Type and unit.TeamId == myHero.TeamId and string.find(string.lower(tostring(anim)), "atta") and not self.projectilespeeds[unit.CharName] then

        local time = self:GetTime() + 0.393 - GetLatency()/2000
        local tar = GetAggro(unit)
        if tar then
            table.insert(self.ActiveAttacks, {Attacker = unit, pos = Vector(unit), Target = tar, animationTime = math.huge, damage = unit.TotalDmg, hittime=time, starttime = self:GetTime() - GetLatency()/2000, windUpTime = 0.393, projectilespeed = math.huge})
        end
    end
end
function VPrediction:CollisionProcessSpell(unit, spell)
    if unit and _has_value({1,2,3}, unit.Type) then
        unit = GetUnit(unit.Addr)
    elseif unit and _has_value({0}, unit.Type) then
        unit = GetAIHero(unit.Addr)
    end
    spell.target = GetTargetFromTargetId(spell.TargetId)
    if unit and unit.IsValid and spell.target and unit.Type ~= myHero.Type and (spell.target.Type == 1 or spell.target.Type == 3) and unit.TeamId == myHero.TeamId and spell and spell.Name and (spell.Name:lower():find("attack") or (spell.Name == "frostarrow")) and spell.TimeCast and spell.target then
        if GetDistanceSqr(unit) < 4000000 then
            if self.projectilespeeds[unit.CharName] then
                local time = self:GetTime() + GetDistance(spell.target, unit) / self:GetProjectileSpeed(unit) - GetLatency()/2000
                local i = 1
                while i <= #self.ActiveAttacks do
                    if (self.ActiveAttacks[i].Attacker and self.ActiveAttacks[i].Attacker.IsValid and self.ActiveAttacks[i].Attacker.NetworkId == unit.NetworkId) or ((self.ActiveAttacks[i].hittime + 3) < self:GetTime()) then
                        table.remove(self.ActiveAttacks, i)
                    else
                        i = i + 1
                    end
                end

                table.insert(self.ActiveAttacks, {Attacker = unit, pos = Vector(unit), Target = spell.target, animationTime = spell.AnimationTime, damage = self:CalcDamageOfAttack(unit, spell.target, spell, 0), hittime=time, starttime = self:GetTime() - GetLatency()/2000, windUpTime = 0, projectilespeed = self:GetProjectileSpeed(unit)})
            else
                minionTar[unit.NetworkId] = spell.target
            end
        end
    end
end

function VPrediction:CheckCol(unit, minion, Position, delay, radius, range, speed, from, draw)
    if unit.NetworkId == minion.NetworkId then
        return false
    end

    --[[Check first if the minion is going to be dead when skillshots reaches his position]]
    if minion.Type ~= myHero.Type and self:GetPredictedHealth(minion,  delay + GetDistance(from, minion) / speed) < 0 then
        return false
    end

    local waypoints = self:GetCurrentWayPoints(minion)
    local MPos, CastPosition = minion.PathCount == 1 and Vector(minion) or self:CalculateTargetPosition(minion, delay, radius, speed, from, "line")
    if GetDistanceSqr(from, MPos) <= (range)^2 and GetDistanceSqr(from, minion) <= (range + 100)^2 then
        local buffer = 0
        if self.VPMenu_Buffer then
            buffer = (minion.PathCount > 1) and self.VPMenu_Buffer.getValue() or 8
        else
            if (minion.PathCount > 1) then
                buffer = 20
            else
                buffer = 8
            end
        end

        if minion.Type == myHero.Type then
            buffer = buffer + self:GetHitBox(minion)
        end

        --[[if draw then
            --Draw:Circle3D(x, y, z, radius, width, quality, color)
            Draw:Circle3D(minion.x, myHero.y, minion.z, self:GetHitBox(minion) + buffer, 1, 10, Lua_ARGB(175, 255, 0, 0))
            Draw:Circle3D(MPos.x, myHero.y, MPos.z, self:GetHitBox(minion) + buffer, 1, 10, Lua_ARGB(175, 0, 0, 255))
            self:DLine(MPos, minion, Lua_ARGB(175, 255, 255, 255))
        end]]

        if minion.PathCount > 1 then
            local proj1, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(Vector(from), Vector(Position), Vector(MPos))
            if isOnSegment and (GetDistanceSqr(MPos, proj1) <= (self:GetHitBox(minion) + radius + buffer) ^ 2) then
                return true
            end
        end

        local proj2, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(from, Position, Vector(minion))
        if isOnSegment and (GetDistanceSqr(minion, proj2) <= (self:GetHitBox(minion) + radius + buffer) ^ 2) then
            return true
        end
    end
    return false
end

function VPrediction:CheckMinionCollision(unit, Position, delay, radius, range, speed, from, draw, updatemanagers)
    Position = Vector(Position)
    from = from and Vector(from) or myHero
    --local draw = true
    if updatemanagers then
        self.EnemyMinions.range = range + 500 * (delay + range / speed)
        self.JungleMinions.range = self.EnemyMinions.range
        self.OtherMinions.range = self.EnemyMinions.range
        self.EnemyMinions:update()
        self.JungleMinions:update()
        self.OtherMinions:update()
    end

    local result = false
    if self.VPMenu_Collision then
        if self.VPMenu_Minions.getValue() then
            for i, minion in ipairs(self.EnemyMinions.objects) do
                if self:CheckCol(unit, minion, Position, delay, radius, range, speed, from, draw) then
                    if not draw then
                        return true
                    else
                        result = true
                    end
                end
            end
        end

        if self.VPMenu_Mobs.getValue() then
            for i, minion in ipairs(self.JungleMinions.objects) do
                if self:CheckCol(unit, minion, Position, delay, radius, range, speed, from, draw) then
                    if not draw then
                        return true
                    else
                        result = true
                    end
                end
            end
        end

        if self.VPMenu_Others.getValue() then
            for i, minion in ipairs(self.OtherMinions.objects) do
                if minion.TeamId ~= myHero.TeamId and self:CheckCol(unit, minion, Position, delay, radius, range, speed, from, draw) then
                    if not draw then
                        return true
                    else
                        result = true
                    end
                end
            end
        end
    else
        if (1 + 1) == 2 then --lol
            for i, minion in ipairs(self.EnemyMinions.objects) do
                if self:CheckCol(unit, minion, Position, delay, radius, range, speed, from, draw) then
                    if not draw then
                        return true
                    else
                        result = true
                    end
                end
            end
        end

        if (1 + 1) == 2 then --lol
            for i, minion in ipairs(self.JungleMinions.objects) do
                if self:CheckCol(unit, minion, Position, delay, radius, range, speed, from, draw) then
                    if not draw then
                        return true
                    else
                        result = true
                    end
                end
            end
        end

        if (1 + 1) == 2 then --lol
            for i, minion in ipairs(self.OtherMinions.objects) do
                if minion.TeamId ~= myHero.TeamId and self:CheckCol(unit, minion, Position, delay, radius, range, speed, from, draw) then
                    if not draw then
                        return true
                    else
                        result = true
                    end
                end
            end
        end
    end

    --[[if self.ChampionCollision then
        for i, enemy in ipairs(GetEnemyHeroes()) do
            if self:CheckCol(unit, enemy, Position, delay, radius, range, speed, from, draw) then
                if not draw then
                    return true
                else
                    result = true
                end
            end
        end
    end]]

    --[[if draw then
        local Direction = Vector(Position - from):Perpendicular():Normalized()
        local Color = result and Lua_ARGB(175, 255, 0, 0) or Lua_ARGB(175, 0, 255, 0)
        local P1r = Vector(from) + radius * Vector(Direction)
        local P1l = Vector(from) - radius * Vector(Direction)
        local P2r = Vector(from) + radius * Direction - Vector(Direction):Perpendicular() * GetDistance(from, Position)
        local P2l = Vector(from) - radius * Direction - Vector(Direction):Perpendicular() * GetDistance(from, Position)

        self:DLine(P1r, P1l, Color)
        self:DLine(P1r, P2r, Color)
        self:DLine(P1l, P2l, Color)
        self:DLine(P2r, P2l, Color)
        --if not result and IsKeyDown(string.byte("T")) then
            --CastSpell(_Q, Position.x, Position.z)
        --end
    end]]

    return result
end

function VPrediction:GetCircularCastPosition(unit, delay, radius, range, speed, from, collision, excludeWaypoints)
    return self:GetBestCastPosition(unit, delay, radius, range, speed, from, collision, "circular")
end

                            --Added dmg param to increase minimum health predicted on collision if desired for champs such as Kalista Q; Or to increase buffer on predicted health by doing negative
function VPrediction:GetLineCastPosition(unit, delay, radius, range, speed, from, collision)
    return self:GetBestCastPosition(unit, delay, radius, range, speed, from, collision, "line")
end

function VPrediction:GetPredictedPos(unit, delay, speed, from, collision)
    return self:GetBestCastPosition(unit, delay, 1, math.huge, speed, from, collision, "circular")
end

--TODO: Recode this stuff and make it more readable :D
function VPrediction:GetCircularAOECastPosition(unit, delay, radius, range, speed, from, collision)
    --self.LastFocusedTarget = unit
    local CastPosition, HitChance, Position = self:GetBestCastPosition(unit, delay, radius, range, speed, from, collision, "circular")
    local points = {}
    local mainCastPosition, mainHitChance, mainPosition = CastPosition, HitChance, Position

    table.insert(points, Position)

    for i, target in ipairs(GetEnemyHeroes()) do
        if target.NetworkId ~= unit.NetworkId and ValidTarget(target, range * 1.5) then
            CastPosition, HitChance, Position = self:GetBestCastPosition(target, delay, radius, range, speed, from, collision, "circular")
            if GetDistance(from, Position) < (range + radius) and (HitChance ~= -1 or not collision) then
                table.insert(points, Position)
            end
        end
    end

    while #points > 1 do
        local Mec = MEC(points)
        local Circle = Mec:Compute()

        if Circle.radius <= radius + self:GetHitBox(unit) - 8 then
            return Circle.center, mainHitChance, #points
        end

        local maxdist = -1
        local maxdistindex = 0

        for i=2, #points do
            local d = GetDistanceSqr(points[i], points[1])
            if d > maxdist or maxdist == -1 then
                maxdistindex = i
                maxdist = d
            end
        end

        table.remove(points, maxdistindex)
    end

    return mainCastPosition, mainHitChance, #points, mainPosition
end

function VPrediction:GetLineAOECastPosition(unit, delay, radius, range, speed, from)
    --self.LastFocusedTarget = unit
    local CastPosition, HitChance, Position = self:GetBestCastPosition(unit, delay, radius, range, speed, from, false, "line")
    local points = {}
    local Positions = {}
    local mainCastPosition, mainHitChance = CastPosition, HitChance

    table.insert(Positions, {unit = unit, HitChance = HitChance, Position = Position, CastPosition = CastPosition})
    table.insert(points, Position)

    range = range and range - 4 or 20000
    radius = radius == 0 and 1 or (radius + self:GetHitBox(unit)) - 4
    from = from and Vector(from) or Vector(myHero)

    local function CircleCircleIntersection(C1, C2, R1, R2)
        local D = GetDistance(C1, C2)
        local A = (R1 * R1 - R2 * R2 + D * D ) / (2 * D)
        local H = math.sqrt(R1 * R1 - A * A);
        local Direction = (Vector(C2) - Vector(C1)):Normalized()
        local PA = Vector(C1) + A * Direction

        local S1 = PA + H * Direction:Perpendicular()
        local S2 = PA - H * Direction:Perpendicular()

        return S1, S2
    end

    local function GetPosiblePoints(from, pos, width, range)
        local middlepoint = (from + pos)/2
        local P1, P2 = CircleCircleIntersection(from, middlepoint, width, GetDistance(middlepoint, from))

        local V1 = (P1 - from)
        local V2 = (P2 - from)

        return from + range * (pos - V1 - from):Normalized(), from + range * (pos - V2 - from):Normalized()
    end

    local function CountHits(P1, P2, width, points)
        local hits = 0
        local hitt = {}
        width = width + 2
        for i, point in ipairs(points) do
            local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(P1, P2, point)
            if isOnSegment and GetDistanceSqr(pointSegment, point) <= width * width then
                hits = hits + 1
                table.insert(hitt, point)
            elseif i == 1 then
                return -1
            end
        end
        return hits, hitt
    end

    for i, target in ipairs(GetEnemyHeroes()) do
        if target.NetworkId ~= unit.NetworkId and ValidTarget(target, range * 1.5) then
            CastPosition, HitChance, Position = self:GetBestCastPosition(target, delay, radius, range, speed, from, false, "line")
            if GetDistance(from, Position) < (range + radius) then
                table.insert(points, Position)
                table.insert(Positions, {unit = target, HitChance = HitChance, Position = Position, CastPosition = CastPosition})
            end
        end
    end

    local MaxHit = 1
    local MaxHitPos

    if #points > 1 then
        for i, candidate in ipairs(points) do
            local C1, C2 = GetPosiblePoints(from, points[i], radius - 20, range)
            local hits, MPoints1 = CountHits(from, C1, radius, points)
            local hits2, MPoints2 = CountHits(from, C2, radius, points)
            if hits >= MaxHit then
                MaxHitPos = C1
                MaxHit = hits
                MaxHitPoints = MPoints1
            end
            if hits2 >= MaxHit then
                MaxHitPos = C2
                MaxHit = hits2
                MaxHitPoints = MPoints2
            end
        end
    end

    if MaxHit > 1 then
        --center the line
        local maxdist = -1
        local p1
        local p2
        for i, hitp in ipairs(MaxHitPoints) do
            for o, hitp2 in ipairs(MaxHitPoints) do
                local StartP, EndP = Vector(from), (Vector(hitp) + Vector(hitp2)) / 2
                local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(StartP, EndP, hitp)
                local pointSegment2, pointLine2, isOnSegment2 = VectorPointProjectionOnLineSegment(StartP, EndP, hitp2)

                local dist = GetDistanceSqr(hitp, pointLine) + GetDistanceSqr(hitp2, pointLine2)
                if dist >= maxdist then
                    maxdist = dist
                    p1 = hitp
                    p2 = hitp2
                end
            end
        end

        --[[if self.ReturnHitTable then
            for i = #Positions, 1, -1 do
                local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(Vector(from), (p1 + p2) / 2, Positions[i].Position)
                if (not isOnSegment) or (GetDistanceSqr(pointLine, Positions[i].Position) > (radius + 5)^2) then
                    table.remove(Positions, i)
                end
            end
        end]]

        return (p1 + p2) / 2, mainHitChance, MaxHit, Positions
    else
        return mainCastPosition, mainHitChance, 1, Positions
    end
end

function VPrediction:GetConeAOECastPosition(unit, delay, angle, range, speed, from)
    --self.LastFocusedTarget = unit
    range = range and range - 4 or 20000
    radius = 1
    from = from and Vector(from) or Vector(myHero)
    angle = (angle < math.pi * 2) and angle or (angle * math.pi / 180)

    local CastPosition, HitChance, Position = self:GetBestCastPosition(unit, delay, radius, range, speed, from, false, "line")
    local points = {}
    local mainCastPosition, mainHitChance = CastPosition, HitChance

    table.insert(points, Vector(Position) - Vector(from))

    local function CountVectorsBetween(V1, V2, points)
        local result = 0
        local hitpoints = {}
        for i, test in ipairs(points) do
                local NVector = Vector(V1):CrossProduct(test)
                local NVector2 = Vector(test):CrossProduct(V2)
                if NVector.y >= 0 and NVector2.y >= 0 then
                        result = result + 1
                        table.insert(hitpoints, test)
                elseif i == 1 then
                        return -1 --doesnt hit the main target
                end
        end
        return result, hitpoints
    end

    local function CheckHit(position, angle, points)
        local direction = Vector(position):Normalized()
        local v1 = Vector(position):Rotated(0, -angle / 2, 0)
        local v2 = Vector(position):Rotated(0, angle / 2, 0)
        return CountVectorsBetween(v1, v2, points)
    end

    for i, target in ipairs(GetEnemyHeroes()) do
        if target.NetworkId ~= unit.NetworkId and ValidTarget(target, range * 1.5) then
            CastPosition, HitChance, Position = self:GetBestCastPosition(target, delay, radius, range, speed, from, false, "line")
            if GetDistanceSqr(from, Position) < range * range then
                table.insert(points, Vector(Position) - Vector(from))
            end
        end
    end

    local MaxHitPos
    local MaxHit = 1
    local MaxHitPoints = {}

    if #points > 1 then
        for i, point in ipairs(points) do
            local pos1 = Vector(point):Rotated(0, angle / 2, 0)
            local pos2 = Vector(point):Rotated(0, - angle / 2, 0)

            local hits, points1 = CheckHit(pos1, angle, points)
            local hits2, points2 = CheckHit(pos2, angle, points)

            if hits >= MaxHit then
                MaxHitPos = C1
                MaxHit = hits
                MaxHitPoints = points1
            end
            if hits2 >= MaxHit then
                MaxHitPos = C2
                MaxHit = hits2
                MaxHitPoints = points2
            end
        end
    end

    if MaxHit > 1 then
        --Center the cone
        local maxangle = -1
        local p1
        local p2
        for i, hitp in ipairs(MaxHitPoints) do
                for o, hitp2 in ipairs(MaxHitPoints) do
                        local cangle = Vector():AngleBetween(hitp2, hitp)
                        if cangle > maxangle then
                                maxangle = cangle
                                p1 = hitp
                                p2 = hitp2
                        end
                end
        end


        return Vector(from) + range * (((p1 + p2) / 2)):Normalized(), mainHitChance, MaxHit
    else
        return mainCastPosition, mainHitChance, 1
    end
end

function VPrediction:OnTick()
    --[[Delete the old saved Waypoints]]
    if self.lastick == nil or self:GetTime() - self.lastick > 0.2 then
        self.lastick = self:GetTime()
        for i, enemy in pairs(GetEnemyHeroes()) do
            for i, tbl in pairs(PA[enemy.NetworkId]) do
                if os.clock() - 1.5 > tbl.t then
                    table.remove(PA[enemy.NetworkId], i)
                end
            end
        end
        for i, tbl in pairs(PA[myHero.NetworkId]) do
            if os.clock() - 1.5 > tbl.t then
                table.remove(PA[myHero.NetworkId], i)
            end
        end
        for NID, TargetWaypoints in pairs(self.TargetsWaypoints) do
            local i = 1
            while i <= #self.TargetsWaypoints[NID] do
                if self.TargetsWaypoints[NID][i]["time"] + self.WaypointsTime < self:GetTime() then
                    table.remove(self.TargetsWaypoints[NID], i)
                else
                    i = i + 1
                end
            end
        end
    end
end

--[[Drawing functions for debug: ]]
--[[function VPrediction:DrawSavedWaypoints(object, time, color, drawPoints)
    colour = color and color or Lua_ARGB(175, 0, 255, 0)
    local object.pathIndex = 1
    local object.pos = {x=object.x, y=object.y, z=object.z}
    for i = object.pathIndex, object.PathCount do
        if object.GetPath(i) and object.GetPath(i-1) then
            local pStart = i == object.pathIndex and object.pos or object.GetPath(i-1)
            self:DLine(pStart, object.GetPath(i), colour)
        end
    end
    if drawPoints then
        local Waypoints = self:GetCurrentWayPoints(object)
        for i, waypoint in ipairs(Waypoints) do
            Draw:Circle3D(waypoint.x, myHero.y, waypoint.z, 10, 2, 10, Lua_ARGB(175, 0,0, 255))
        end
    end
end]]

function VPrediction:DrawHitBox(object)
    Draw:Circle3D(object.x, object.y, object.z, self:GetHitBox(object), 1, 50, Lua_ARGB(255, 255, 255, 255))
end

function VPrediction:DLine(From, To, Color)
    Draw:Line3D(From.x, From.y, From.z, To.x, To.y, To.z, 2, Color)
end

function VPrediction:OnDraw()
    if self.VPMenu_Developers then
        if self.VPMenu_Debug.getValue() then
            --local listofminionpos = {}
            GetAllObjectAroundAnObject(myHero.Addr, 3000)
            for i, enemy in pairs(pObject) do
                local hold = enemy
                if IsChampion(enemy) and IsEnemy(enemy) then
                    hold = GetAIHero(enemy)
                    if hold.IsValid and not hold.IsDead and hold.IsVisible then
                        self:DrawHitBox(hold)
                    end
                --elseif IsMinion(enemy) and self.VPMenu_SC.getValue() then
                    --hold = GetUnit(enemy)
                end
            end
        end
    end
end

function VPrediction:GetHitBox(object)
    --local object = GetAIHero(object)
    if self.nohitboxmode and object.Type and object.Type == myHero.Type then
        return 0
    end
    --[[if self.VPMenu_Developers then
        if self.VPMenu_Debug.getValue() and (self.hitboxes[object.CharName] == nil or self.hitboxes[object.CharName] == 0) then
            print(string.format("[SDK]VPrediction: Object Name Not Found in Table for Proper Hitbox Calculation: [" .. tostring(Object.CharName) .. "]"))
        end
    end]]
    return (self.hitboxes[object.CharName] ~= nil and self.hitboxes[object.CharName] ~= 0) and self.hitboxes[object.CharName]  or object.HitBox
end

function VPrediction:GetProjectileSpeed(unit)
    --[[if self.VPMenu_Developers then
        if self.VPMenu_Debug.getValue() and (self.projectilespeeds[unit.CharName] == nil or self.projectilespeeds[unit.CharName] == 0) then
            print(string.format("[SDK]VPrediction: Projectile Name Not Found in Table for Proper Speed Calculation: [" .. tostring(unit.CharName) .. "]"))
        end
    end]]
    return self.projectilespeeds[unit.CharName] and self.projectilespeeds[unit.CharName] or math.huge
end

function VPrediction:CalcDamageOfAttack(source, target, spell, additionalDamage)
    -- read initial armor and damage values
    local armorPenPercent = 1
    local armorPen = source.ArmorPen
    local totalDamage = source.TotalDmg + (additionalDamage or 0)
    local damageMultiplier = spell.Name:find("CritAttack") and 2 or 1

    -- minions give wrong values for armorPen and armorPenPercent
    if source.Type == 1 or source.Type == 3 then
        armorPenPercent = 1
    elseif source.Type == 2 then
        armorPenPercent = 0.7
    end

    -- turrets ignore armor penetration and critical attacks
    if target.Type == 2 then
        armorPenPercent = 1
        armorPen = 0
        damageMultiplier = 1
    end

    -- calculate initial damage multiplier for negative and positive armor

    local targetArmor = (target.Armor * armorPenPercent) - armorPen
    if targetArmor < 0 then -- minions can't go below 0 armor.
        --damageMultiplier = (2 - 100 / (100 - targetArmor)) * damageMultiplier
        damageMultiplier = 1 * damageMultiplier
    else
        damageMultiplier = 100 / (100 + targetArmor) * damageMultiplier
    end

    -- use ability power or ad based damage on turrets
    if source.Type == myHero.Type and target.Type == 2 then
        totalDamage = math.max(source.TotalDmg, source.BaseDmg + 0.4 * source.MagicDmg)
    end

    -- minions deal less damage to enemy heros
    if source.Type == 1 and target.Type == myHero.Type then
        damageMultiplier = 0.60 * damageMultiplier
    end

    -- heros deal less damage to turrets
    if source.Type == myHero.Type and target.Type == 2 then
        damageMultiplier = 0.95 * damageMultiplier
    end

    -- minions deal less damage to turrets
    if source.Type == 1 and target.Type == 2 then
        damageMultiplier = 0.475 * damageMultiplier
    end

    -- siege minions and superminions take less damage from turrets
    if source.Type == 2 and (target.CharName == "Red_Minion_MechCannon" or target.CharName == "Blue_Minion_MechCannon") then
        damageMultiplier = 0.8 * damageMultiplier
    end

    -- caster minions and basic minions take more damage from turrets
    if source.Type == 2 and (target.CharName == "Red_Minion_Wizard" or target.CharName == "Blue_Minion_Wizard" or target.CharName == "Red_Minion_Basic" or target.CharName == "Blue_Minion_Basic") then
        damageMultiplier = (1 / 0.875) * damageMultiplier
    end

    -- turrets deal more damage to all units by default
    if source.Type == 2 then
        damageMultiplier = 1.05 * damageMultiplier
    end

    -- calculate damage dealt
    return damageMultiplier * totalDamage
end
--[[-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


                                                                                            Break Between Prediction Classes

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--/****** HPrediction ******/--


TODO:
---

]]

local function VectorPointProjectionOnLine(v1, v2, v)
    assert(IsVector(v1) and IsVector(v2) and IsVector(v), "VectorPointProjectionOnLine: wrong argument types (3 <Vector> expected)")
    local line = Vector(v2) - v1
    local t = ((-(v1.x * line.x - line.x * v.x + (v1.z - v.z) * line.z)) / line:Len2())
    return (line * t) + v1
end

local function IsNilOrFalse(condition)
  return not condition
end
_G.HPrediction_Version = 1.402

HPrediction = class()

function HPrediction:__init(menu)
  
  --self:Update()
  self:Variables()
  self:Menu(menu)
  self:Metatables()
  
  Callback.Add("Tick", function() self:OnTick() end)
  --Callback.Add("ProcessSpell", function(...) self:OnProcessAttack(...) end)
  Callback.Add("RemoveBuff", function(unit, buff) self:OnRemoveBuff(unit, buff) end)
  Callback.Add("UpdateBuff", function(unit, buff, stacks) self:OnUpdateBuff(unit, buff, stacks) end)
  --Callback.Add("PlayAnimation", function(...) self:OnAnimation(...) end)
end

function HPrediction:Variables()

  if myHero.CharName == "Xerath" then
    self.OnQ = false
    self.LastQ = 0
  end
  
  self.EnemyHeroes = GetEnemyHeroes()
  
  self.buffer = .02
  self.Draw = false
  --self.PredictionDamage = {}
  --self.ProjectileSpeed = {["SRU_OrderMinionRanged"] = 650, ["SRU_ChaosMinionRanged"] = 650, ["SRU_OrderMinionSiege"] = 1200, ["SRU_ChaosMinionSiege"] = 1200, ["SRUAP_Turret_Chaos1"] = 1200, ["SRUAP_Turret_Chaos2"] = 1200, ["SRUAP_Turret_Order1"] = 1200, ["SRUAP_Turret_Order2"] = 1200}
  
  self.EnemyMinions = minionManager(MINION_ENEMY, 2000, myHero, MINION_SORT_HEALTH_ASC)
  self.JungleMobs = minionManager(MINION_JUNGLE, 2000, myHero, MINION_SORT_MAXHEALTH_DEC)
  
end

---------------------------------------------------------------------------------

function HPrediction:Menu(menu)
    assert(menu, "HPrediction Initialization: Wrong argument types (<menu>) expected. Returned nil.")
    if menu then
        self.HPrediction_Menu = menu.addItem(SubMenu.new("<SDK> HPrediction"))
        self.HPMenu_Collision = self.HPrediction_Menu.addItem(SubMenu.new("Collision Settings"))
        self.HPMenu_Buffer = self.HPMenu_Collision.addItem(MenuSlider.new("Buffer Dist.", 10, 0, 20, 1))
        --self.HPMenu_Ignore = self.HPrediction_Menu.addItem(MenuBool.new("Ignore which will die", true))
        self.HPMenu_Credits = self.HPrediction_Menu.addItem(MenuSeparator.new("Ported By: Dewblackio2", true))
        self.HPMenu_Version = self.HPrediction_Menu.addItem(MenuSeparator.new("Version: " .. tostring(HPrediction_Version), true))
    end
end

---------------------------------------------------------------------------------

function HPrediction:Metatables()
  self.Presets = setmetatable({}, {__index = _G.HPrediction.Presets})
  --[[self.Presets = {}
  setmetatable(self.Presets,
  {
    __index = function(tbl, key) return _G.HPrediction.Presets[key] end,
    __metatable = function() end,
  })]]
end

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

function _G.Vector.HPred_angleBetween(self, v1, v2)

  if IsNilOrFalse(IsVector(v1) and IsVector(v2)) then
    error("HPrediction: HPred_angleBetween: wrong argument types (2 <Vector> expected)", 2)
  end
  
  local p1, p2 = (-self+v1), (-self+v2)
  local theta = p1:Polar()-p2:Polar()
  
  if theta < 0 then
    theta = theta+360
  elseif theta >= 360 then
    theta = theta-360
  end
  
  return theta
end

function _G.Vector.HPred_rotateYaxis(self, degree)

  if IsNilOrFalse(type(degree) == "number") then
    error("HPrediction: HPred_rotateYaxis: wrong argument types (expected <number> for degree)", 2)
  end
  
  local phi = (degree*math.pi)/180
  local c, s = math.cos(phi), math.sin(phi)
  local v = Vector(self.x*c+self.z*s, self.y, self.z*c-self.x*s)
  
  return v
end

function HPrediction:CircleIntersection(v1, v2, c, radius)

  if IsNilOrFalse(IsVector(v1) and IsVector(v2) and IsVector(c) and type(radius) == "number") then
    assert(v1.type == "vector" and v2.type == "vector" and c.type == "vector" and type(radius) == "number", "HPrediction:CircleIntersection: Wrong argument types (<vector>, <vector>, <vector>, <number>) expected.")
  end
  
  local x1, y1, x2, y2, x3, y3 = v1.x, v1.z or v1.y, v2.x, v2.z or v2.y, c.x, c.z or c.y
  local r = radius
  local xp, yp, xm, ym = nil, nil, nil, nil
  local IsOnSegment = nil
  
  if x1 == x2 then
  
    local B = math.sqrt(r^2-(x1-x3)^2)
    
    xp, yp, xm, ym = x1, y3+B, x1, y3-B
  else
  
    local m = (y2-y1)/(x2-x1)
    local n = y1-m*x1
    local A = x3-m*(n-y3)
    local B = math.sqrt(A^2-(1+m^2)*(x3^2-r^2+(n-y3)^2))
    
    xp, xm = (A+B)/(1+m^2), (A-B)/(1+m^2)
    yp, ym = m*xp+n, m*xm+n
  end
  
  if x1 <= x2 then
    IsOnSegment = x1 <= xp and xp <= x2
  else
    IsOnSegment = x2 <= xp and xp <= x1        
  end
  
  if IsOnSegment then
    return Vector(xp, myHero.y, yp)
  else
    return Vector(xm, myHero.y, ym)
  end
  
end

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

function HPrediction:OnTick()

  self.EnemyMinions:update()
  self.JungleMobs:update()
  
  --[[if self.HPMenu_Ignore.getValue() then

    for i, minion in ipairs(self.EnemyMinions.objects) do

      if self.PredictionDamage[minion.NetworkId] then

        local Delete = true

        for ctime, damage in pairs(self.PredictionDamage[minion.NetworkId]) do

          if GetTickCount() + GetLatency()/2000 < ctime - GetLatency()/2000 then
            Delete = false
            break
          end

        end

        if Delete then
          self.PredictionDamage[minion.NetworkId] = nil
        end

      end

    end

  end]]
  
  if myHero.CharName == "Xerath" then
  
    if self.OnQ then
    
      local Time = os.clock() - self.LastQ
      
      _G.HPrediction.Presets.Xerath.Q.range = math.min(1500, 750+500*(Time + GetLatency()/2000))
    else
      _G.HPrediction.Presets.Xerath.Q.range = 750
    end
    
  end
  
end

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

function HPrediction:GetPredict(HPskillshot, unit, from, noh)

  if IsNilOrFalse(HPskillshot) then
    error("GetPredict: HPskillshot is nil, for help please check HPred guide, or speak with Dewblackio2.", 2)
  end
  
  if IsNilOrFalse(unit) then
    error("GetPredict: unit is nil", 2)
  end
  
  if IsNilOrFalse(from) then
    error("GetPredict: from is nil", 2)
  end
  
  if HPskillshot == "Q" or HPskillshot == "W" or HPskillshot == "E" or HPskillshot == "R" then
    error("GetPredict: Do not declare HPskillshot as a string like \"_Q\" or \"Q\", please declare using HPSkillshot class.", 2)
  end
  
  local spell = HPskillshot.Properties and HPskillshot.Properties or nil
  if IsNilOrFalse(spell) then
    error("GetPredict: HPskillshot is nil, for help please check HPred guide, or speak with Dewblackio2.", 2)
  end
  local type = spell.type
  local delay = spell.delay
  local range = spell.range
  local speed = spell.speed
  local width = spell.width
  local addMyCollisionRadius = spell.addMyCollisionRadius
  local addUnitCollisionRadius = spell.addUnitCollisionRadius
  local radius = spell.radius
  local angle = spell.angle
  local IsLowAccuracy = spell.IsLowAccuracy
  local IsVeryLowAccuracy = spell.IsVeryLowAccuracy
  --__PrintTextGame("initialized spell")
  self.fromAddRange = from.CollisionRadius or myHero.CollisionRadius
  self.unitAddRange = unit.CollisionRadius
  self.unitSpeed = unit.MoveSpeed
  
  if type == "DelayCircle" or type == "PromptCircle" then
  
    if addMyCollisionRadius then
      radius = radius + self.fromAddRange
    end
    
    if addUnitCollisionRadius then
      radius = radius + self.unitAddRange
    end
    --__PrintTextGame("reached inner circle")
  end
  
  self.RT = .4
  
  if IsVeryLowAccuracy then
    self.RT = .6
  elseif IsLowAccuracy then
    self.RT = .5
  end
  
  self.RT_S = self.RT + .3
  
  local unitPredPos, unitPredPos_S, unitPredPos_E, unitPredPos_D, unitPredPos_C, CastPos, HitChance, NoH = nil, nil, nil, nil, nil, nil, 0, nil
  
  if unit.PathCount >= 2 then

    local unitIndexPos = Vector(unit.GetPath(GetPathIndex(unit)))
    --__PrintTextGame(tostring(unitIndexPos))
    if unitIndexPos == nil then
      unitIndexPos = Vector(unit.GetPath(GetPathIndex(unit)-1))
    end
    
    self.TotalDST = GetDistance(Vector(unitIndexPos), Vector(unit))
    
    local DST, DST_S, DST_D = GetDistance(Vector(unitIndexPos), Vector(unit)), GetDistance(Vector(unitIndexPos), Vector(unit)), GetDistance(Vector(unitIndexPos), Vector(unit))
    local ExDST, ExDST_S, ExDST_D = nil, nil, nil
    local LastIndex, LastIndex_S, LastIndex_D = nil, nil, nil
    
    for i = GetPathIndex(unit), unit.PathCount do
    
      local Path = Vector(unit.GetPath(i))
      local Path2 = Vector(unit.GetPath(i+1))
      
      if unit.PathCount == i then
        Path2 = Vector(unit.GetPath(i))
      end
      
      if LastIndex == nil and DST > self.RT * self.unitSpeed then
        LastIndex = i
        ExDST = DST - self.RT * self.unitSpeed
      end
      
      if LastIndex_S == nil and DST_S > self.RT_S * self.unitSpeed then
        LastIndex_S = i
        ExDST_S = DST_S - self.RT_S * self.unitSpeed
      end
      
      if range == 0 and delay < self.RT and LastIndex_D == nil and DST_D > delay * self.unitSpeed then
        LastIndex_D = i
        ExDST_D = DST_D-delay * self.unitSpeed
      end
      
      DST = DST + GetDistance(Vector(Path2), Vector(Path))
      DST_S = DST_S + GetDistance(Vector(Path2), Vector(Path))
      DST_D = DST_D + GetDistance(Vector(Path2), Vector(Path))
      self.TotalDST = self.TotalDST + GetDistance(Vector(Path2), Vector(Path))
    end
    
    if LastIndex_S ~= nil then
      LastIndexPos = Vector(unit.GetPath(LastIndex))
      LastIndexPos2 = Vector(unit.GetPath(LastIndex-1))
      unitPredPos = LastIndexPos+(LastIndexPos2-LastIndexPos):Normalized()*ExDST
      LastIndexPos_S = Vector(unit.GetPath(LastIndex_S))
      LastIndexPos_S2 = Vector(unit.GetPath(LastIndex_S-1))
      unitPredPos_S = LastIndexPos_S+(LastIndexPos_S2-LastIndexPos_S):Normalized()*ExDST_S
    elseif LastIndex ~= nil then
      LastIndexPos = Vector(unit.GetPath(LastIndex))
      LastIndexPos2 = Vector(unit.GetPath(LastIndex-1))
      unitPredPos = LastIndexPos+(LastIndexPos2-LastIndexPos):Normalized()*ExDST
    else
      unitPredPos_E = Vector(unit.GetPath(unit.PathCount))
    end
    
    if LastIndex_D ~= nil then
      LastIndexPos_D = Vector(unit.GetPath(LastIndex_D))
      LastIndexPos_D2 = Vector(unit.GetPath(LastIndex_D-1))
      unitPredPos_D = LastIndexPos_D+(LastIndexPos_D2-LastIndexPos_D):Normalized()*ExDST_D
    end
    
  else
    unitPredPos = Vector(unit.x, unit.y, unit.z)
    unitPredPos_S = Vector(unit.x, unit.y, unit.z)
    
    if range == 0 and delay < self.RT then
      unitPredPos_D = Vector(unit.x, unit.y, unit.z)
    end
    
  end
  
  if unitPredPos_S ~= nil then
    CastPos = unitPredPos_S
    
    local SRT_S = self:SpellReactionTime(unit, unitPredPos_S, from, type, delay, range, speed, width, radius, angle)
    
    if SRT_S <= self.RT_S then
    
      SRT_S = math.max(GetLatency()/1000 + self.buffer, SRT_S)
      
      if unit.PathCount >= 2 then
        HitChance = (self.RT_S - SRT_S) / self.RT_S + 1
      else
        HitChance = (self.RT_S - SRT_S) / self.RT_S + 0.5
      end
      
    end
    
  end
  
  if unitPredPos ~= nil then
  
    if unitPredPos_S == nil then
      CastPos = unitPredPos
    end
    
    local SRT = self:SpellReactionTime(unit, unitPredPos, from, type, delay, range, speed, width, radius, angle)
    
    if SRT <= self.RT then
    
      SRT = math.max(GetLatency()/1000+self.buffer, SRT)
      
      if unit.PathCount >= 2 then
        CastPos = unitPredPos
        HitChance = (self.RT-SRT)/self.RT+2
      else
        CastPos = unitPredPos
        HitChance = (self.RT-SRT)/self.RT+1.5
      end
      
    end
    
  end
  
  if unitPredPos_E ~= nil then
    CastPos = unitPredPos_E
    
    local SRT_E = self:SpellReactionTime(unit, unitPredPos_E, from, type, delay, range, speed, width, radius, angle)
    
    if SRT_E <= self.TotalDST/self.unitSpeed then
    
      SRT_E = math.max(GetLatency()/1000+self.buffer, SRT_E)
      
      HitChance = (self.TotalDST/self.unitSpeed-SRT_E)/(self.TotalDST/self.unitSpeed)+2
    end
    
  end
  
  if unitPredPos_D ~= nil and (unitPredPos_E == nil or delay <= self.TotalDST/self.unitSpeed) then
    CastPos = unitPredPos_D
    HitChance = 0
    
    local SRT_D = self:SpellReactionTime(unit, unitPredPos_D, from, type, delay, range, speed, width, radius, angle)
    
    if SRT_D <= delay then
    
      SRT_D = math.max(GetLatency()/1000+self.buffer, SRT_D)
      
      if unit.PathCount >= 2 then
        HitChance = (delay-SRT_D)/delay+2
      else
        HitChance = (delay-SRT_D)/delay+1.5
      end
      
    end
    
  end
  
  --if from.charName == "Xerath" and type == "PromptLine" and os.clock() < self.LastQ+1.5-GetLatency()/2000 and range+unit.boundingRadius < GetDistance(unit, from)+delay*unit.ms then
  if from.charName == "Xerath" and type == "PromptLine" and os.clock() < self.LastQ+1.5-GetLatency()/2000 and range < GetDistance(Vector(unit), Vector(from))+delay*unit.MoveSpeed then
    HitChance = 0
  end
  
  if self:SpellReactionTime(unit, unit, from, type, delay, range, speed, width, radius, angle) <= 0 or unit.Name == "SRU_Baron12.1.1" then
    CastPos = Vector(unit.x, unit.y, unit.z)
    HitChance = 3
  end
  
  if range == 0 then
  
    if GetDistance(Vector(CastPos), Vector(from)) > radius then
      HitChance = 0
    end
    
    CastPos = Vector(from.x, from.y, from.z)
  else
  
    if type == "DelayLine2" then
    
      if GetDistance(Vector(CastPos), Vector(from)) > range then
        HitChance = 0
        
        if GetDistance(Vector(unit), Vector(from)) <= range then
          unitPredPos_C = self:CircleIntersection(unit, CastPos, from, range)
        else
          return nil, 0, 0
        end
        
      end
      
    elseif GetDistance(Vector(CastPos), Vector(myHero)) > range then
      HitChance = 0
      
      if GetDistance(Vector(unit), Vector(myHero)) <= range then
        unitPredPos_C = self:CircleIntersection(unit, CastPos, myHero, range)
      else
        return nil, 0, 0
      end
      
    end
    
  end
  
  if unitPredPos_C ~= nil then
    CastPos = unitPredPos_C
    
    local SRT_C = self:SpellReactionTime(unit, unitPredPos_C, from, type, delay, range, speed, width, radius, angle)
    local Time_C = GetDistance(Vector(unitPredPos_C), Vector(unit))/self.unitSpeed
    
    if SRT_C <= Time_C then
    
      SRT_C = math.max(GetLatency()/1000+self.buffer, SRT_C)
      
      HitChance = (Time_C-SRT_C)/Time_C+1
    end
    
  end
  
  if CastPos and (spell.type == "DelayLine" or spell.type == "PromptLine") and self:CollisionStatus(HPskillshot, unit, from, CastPos, noh) then
    HitChance = -1
  end
  
  if noh then
    NoH = self:NumberofHits(HPskillshot, from, CastPos)
  end
  --__PrintTextGame(tostring(CastPos) .. " " .. tostring(HitChance))
  return CastPos, HitChance, NoH
end

---------------------------------------------------------------------------------

function HPrediction:PredictPos(unit, time)

  if IsNilOrFalse(unit) then
    error("PredictPos: unit is nil", 2)
  end
  
  if IsNilOrFalse(time) then
    error("PredictPos: time is nil", 2)
  end
  
  local unitPredPos
  
  if unit.PathCount >= 2 then
  
    local unitIndexPos = Vector(unit.GetPath(GetPathIndex(unit)))
    
    if unitIndexPos == nil then
      unitIndexPos = Vector(unit.GetPath(GetPathIndex(unit)-1))
    end
    
    local DST, ExDST, LastIndex = GetDistance(Vector(unitIndexPos), Vector(unit)), nil, nil
    
    for i = GetPathIndex(unit), unit.PathCount do
    
      local Path = Vector(unit.GetPath(i))
      local Path2 = Vector(unit.GetPath(i+1))
      
      if unit.PathCount == i then
        Path2 = Vector(unit.GetPath(i))
      end
      
      if LastIndex == nil and DST > time*unit.MoveSpeed then
        LastIndex = i
        ExDST = DST-time*unit.MoveSpeed
      end
      
      DST = DST+GetDistance(Vector(Path2), Vector(Path))
    end
    
    if LastIndex ~= nil then
      LastIndexPos = Vector(unit.GetPath(LastIndex))
      LastIndexPos2 = Vector(unit.GetPath(LastIndex-1))
      unitPredPos = LastIndexPos+(LastIndexPos2-LastIndexPos):Normalized()*ExDST
    end
    
  else
    unitPredPos = Vector(unit.x, unit.y, unit.z)
  end
  
  return unitPredPos
end

---------------------------------------------------------------------------------

function HPrediction:SpellReactionTime(unit, unitPredPos, from, type, delay, range, speed, width, radius, angle)

  local SRT = math.huge
  local from = Vector(from)
  
  if type == "DelayCircle" then
    SRT = delay+GetDistance(Vector(unitPredPos), Vector(from))/speed-radius/self.unitSpeed+GetLatency()/1000+self.buffer
  elseif type == "PromptCircle" then
    SRT = delay-radius/self.unitSpeed+GetLatency()/1000+self.buffer
    
    if range == 0 then
      SRT = SRT+GetDistance(Vector(unitPredPos), Vector(from))/self.unitSpeed
    end
    
  elseif type == "DelayLine" or type == "DelayLine2" then
  
    if unit.PathCount >= 2 then
    
      if speed >= self.unitSpeed then
        SRT = delay+math.max(0, GetDistance(Vector(unitPredPos), Vector(from))-self.unitAddRange)/(speed-self.unitSpeed)-(math.min(width/2, range-GetDistance(Vector(unitPredPos), Vector(from)), GetDistance(Vector(unitPredPos), Vector(from)))+self.unitAddRange)/self.unitSpeed+GetLatency()/1000+self.buffer
      else
        SRT = math.huge
      end
      
    else
      SRT = delay+math.max(0, GetDistance(Vector(unitPredPos), Vector(from))-self.unitAddRange)/speed-(math.min(width/2, range-GetDistance(Vector(unitPredPos), Vector(from)), GetDistance(Vector(unitPredPos), Vector(from)))+self.unitAddRange)/self.unitSpeed+GetLatency()/1000+self.buffer
    end
    
  elseif type == "PromptLine" then
    SRT = delay-(math.min(width/2, range-GetDistance(Vector(unitPredPos), Vector(from)), GetDistance(Vector(unitPredPos), Vector(from)))+self.unitAddRange)/self.unitSpeed+GetLatency()/1000+self.buffer
  elseif type == "DelayArc" or type == "CircularArc" then
  
    if angle >= 180 then
      __PrintTextGame("[SDK]HPrediction: please use the angle value below 180")
      return
    end
    
    local RotatedPos = from+(Vector(unitPredPos)-from):HPred_rotateYaxis(angle/2)
    local dist = GetDistance(Vector(unitPredPos), VectorPointProjectionOnLine(RotatedPos, from, unitPredPos))
    
    if unit.PathCount >= 2 then
    
      if speed >= self.unitSpeed then
        SRT = delay+math.max(0, GetDistance(unitPredPos, from)-self.unitAddRange)/(speed-self.unitSpeed)-(math.min(dist, range-GetDistance(unitPredPos, from), GetDistance(unitPredPos, from))+self.unitAddRange)/self.unitSpeed+GetLatency()/1000+self.buffer
      else
        SRT = math.huge
      end
      
    else
      SRT = delay+math.max(0, GetDistance(unitPredPos, from)-self.unitAddRange)/speed-(math.min(dist, range-GetDistance(unitPredPos, from), GetDistance(unitPredPos, from))+self.unitAddRange)/self.unitSpeed+GetLatency()/1000+self.buffer
    end
    
  elseif type == "PromptArc" then
  
    if angle >= 180 then
      __PrintTextGame("[SDK]HPrediction: please use the angle value below 180")
      return
    end
    
    local RotatedPos = from+(unitPredPos-from):HPred_rotateYaxis(angle/2)
    local dist = GetDistance(unitPredPos, VectorPointProjectionOnLine(RotatedPos, from, unitPredPos))
    
    SRT = delay-(math.min(dist, range-GetDistance(unitPredPos, from), GetDistance(unitPredPos, from))+self.unitAddRange)/self.unitSpeed+GetLatency()/1000+self.buffer
  elseif type == "Triangle" then
  
    if angle >= 180 then
      __PrintTextGame("[SDK]HPrediction: please use the angle value below 180")
      return
    end
    
    local RotatedPos = from+(unitPredPos-from):HPred_rotateYaxis(angle/2)
    local dist = GetDistance(unitPredPos, VectorPointProjectionOnLine(RotatedPos, from, unitPredPos))
    
    SRT = delay-(math.min(dist, range-GetDistance(unitPredPos, from), GetDistance(unitPredPos, from))+self.unitAddRange)/self.unitSpeed+GetLatency()/1000+self.buffer
  else
    __PrintTextGame("[SDK]HPrediction: please declare a valid Type of spell. For help please view the HPred reference or contact Dewblackio2.")
    return
  end
  
  return SRT
end

---------------------------------------------------------------------------------

function HPrediction:NumberofHits(HPskillshot, from, CastPos)

  if IsNilOrFalse(HPskillshot) then
    error("NumberofHits: HPskillshot is nil", 2)
  end
  
  if IsNilOrFalse(from) then
    error("NumberofHits: from is nil", 2)
  end
  
  if IsNilOrFalse(CastPos) then
    error("NumberofHits: CastPos is nil", 2)
  end
  
  local spell = HPskillshot.Properties and HPskillshot.Properties or nil
  if IsNilOrFalse(spell) then
    error("NumberofHits: HPskillshot is nil, for help please check HPred guide, or speak with Dewblackio2.", 2)
  end
  local type = spell.type
  local delay = spell.delay
  local speed = spell.speed
  local addMyCollisionRadius = spell.addMyCollisionRadius
  local addUnitCollisionRadius = spell.addUnitCollisionRadius
  local radius = spell.radius
  local angle = spell.angle
  
  local Enemies = {}
  
  if type == "DelayCircle" or type == "PromptCircle" then
  
    local HitTime = 0
    local fromAddRange = from.CollisionRadius or myHero.CollisionRadius
    
    if type == "DelayCircle" then
      HitTime = HitTime+delay+GetDistance(Vector(CastPos), Vector(from))/speed
    elseif type == "PromptCircle" then
      HitTime = HitTime+delay
    end
    
    for i, hero in ipairs(self.EnemyHeroes) do
    
      if not self:IsInvincible(hero, HitTime) then
      
        local heroAddRange = hero.CollisionRadius
        
        if type == "DelayCircle" or type == "PromptCircle" then
        
          if addMyCollisionRadius then
            radius = radius+fromAddRange
          end
          
          if addUnitCollisionRadius then
            radius = radius+heroAddRange
          end
          
        end
        
        local heroPredPos, heroPredPos_E = nil, nil
        local heroSpeed = hero.MoveSpeed
        
        if hero.PathCount >= 2 then
        
          local heroIndexPos = Vector(hero.GetPath(GetPathIndex(hero)))
          
          if heroIndexPos == nil then
            heroIndexPos = Vector(hero.GetPath(GetPathIndex(hero)-1))
          end
          
          local DST = GetDistance(Vector(heroIndexPos), Vector(hero))
          local ExDST = nil
          local LastIndex = nil
          
          for i = GetPathIndex(hero), hero.PathCount do
          
            local Path = Vector(hero.GetPath(i))
            local Path2 = Vector(hero.GetPath(i+1))
            
            if hero.PathCount == i then
              Path2 = Vector(hero.GetPath(i))
            end
            
            if LastIndex == nil and DST > HitTime*heroSpeed then
              LastIndex = i
              ExDST = DST-HitTime*heroSpeed
            end
            
            DST = DST+GetDistance(Path2, Path)
          end
          
          if LastIndex ~= nil then
            LastIndexPos = Vector(hero.GetPath(LastIndex))
            LastIndexPos2 = Vector(hero.GetPath(LastIndex-1))
            heroPredPos = LastIndexPos+(LastIndexPos2-LastIndexPos):Normalized()*ExDST
          else
            heroPredPos_E = Vector(hero.GetPath(hero.PathCount))
          end
          
        else
          heroPredPos = Vector(hero.x, hero.y, hero.z)
        end
        
        if heroPredPos_E ~= nil then
        
          if GetDistance(heroPredPos_E, CastPos) <= radius then
            table.insert(Enemies, hero)
          end
          
        else
        
          if GetDistance(heroPredPos, CastPos) <= radius then
            table.insert(Enemies, hero)
          end
          
        end
        
      end
      
    end
    
  elseif type == "DelayLine" or type == "DelayLine2" or type == "PromptLine" then
  
    for i, hero in ipairs(self.EnemyHeroes) do
      if not IsInvulnerable(hero.Addr) and self:SpellCollision(HPskillshot, hero, from, CastPos) then
        table.insert(Enemies, hero)
      end
      
    end
    
  elseif type == "DelayArc" or type == "CircularArc" then
    error("Get NoH of \"DelayArc\" is not supported yet", 2)
    --return
  elseif type == "PromptArc" then
    error("Get NoH of \"PromptArc\" is not supported yet", 2)
    --return
  elseif type == "Triangle" then
    error("Get NoH of \"Triangle\" is not supported yet", 2)
    --return
  end
  
  return #Enemies, Enemies
end

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

function HPrediction:CollisionStatus(HPskillshot, unit, from, to, noh)

  if IsNilOrFalse(HPskillshot) then
    error("CollisionStatus: HPskillshot is nil", 2)
  end
  
  if IsNilOrFalse(unit) then
    error("CollisionStatus: unit is nil", 2)
  end
  
  if IsNilOrFalse(from) then
    error("CollisionStatus: from is nil", 2)
  end
  
  if IsNilOrFalse(to) then
    error("CollisionStatus: to is nil", 2)
  end
  
  local spell = HPskillshot.Properties and HPskillshot.Properties or nil
  if IsNilOrFalse(spell) then
    error("CollisionStatus: HPskillshot is nil, for help please check HPred guide, or speak with Dewblackio2.", 2)
  end
  local collisionM = spell.collisionM
  local collisionH = spell.collisionH
  
  --[[if self.Menu.Draw.Collision then
    draw = true
  else
    draw = false
  end]]
  
  if collisionM and self:MinionCollisionStatus(HPskillshot, unit, from, to, draw) then
    return true
  end
  
  if not noh and collisionH and self:HeroCollisionStatus(HPskillshot, unit, from, to, draw) then
    return true
  end
  
  return false
end

---------------------------------------------------------------------------------

function HPrediction:MinionCollisionStatus(HPskillshot, unit, from, to, draw)

  for i, minion in ipairs(self.EnemyMinions.objects) do
  
    if self:EachCollision(HPskillshot, unit, from, to, minion) then
    
      if draw then
        self.Draw = true
      end
      
      return true
    end
    
  end
  
  for i, junglemob in ipairs(self.JungleMobs.objects) do
  
    if self:EachCollision(HPskillshot, unit, from, to, junglemob) then
    
      if draw then
        self.Draw = true
      end
      
      return true
    end
    
  end
  
  self.Draw = false
  return false
end

---------------------------------------------------------------------------------

function HPrediction:HeroCollisionStatus(HPskillshot, unit, from, to, draw)

  for i, hero in ipairs(self.EnemyHeroes) do
  
    if self:EachCollision(HPskillshot, unit, from, to, hero) then
    
      if draw then
        self.Draw = true
      end
      
      return true
    end
    
  end
  
  self.Draw = false
  return false
end

---------------------------------------------------------------------------------

function HPrediction:EachCollision(HPskillshot, unit, from, to, object)

  local spell = HPskillshot.Properties and HPskillshot.Properties or nil
  if IsNilOrFalse(spell) then
    error("EachCollision: HPskillshot is nil, for help please check HPred guide, or speak with Dewblackio2.", 2)
  end
  local type = spell.type
  local delay = spell.delay
  local speed = spell.speed
  local width = spell.width
  
  if type == "PromptLine" then
    speed = math.huge
  end
  
  local objectAddRange = object.CollisionRadius+self.HPMenu_Buffer.getValue()
  local objectSpeed = object.MoveSpeed
  local to = Vector(to)
  
  --local Ignore = self.HPMenu_Ignore.getValue() and self:PredictHealth(object, delay+(GetDistance(to, Vector(from))-objectAddRange)/speed) <= 0
  
  if unit.IsDead --[[or Ignore ]]or object.IsDead or unit.NetworkId == object.NetworkId or unit.Name == "SRU_Baron12.1.1" then
    return false
  end
  
  if object.PathCount >= 2 then
  
    local objectIndexPos = Vector(object.GetPath(GetPathIndex(object)))
    
    if objectIndexPos == nil then
      objectIndexPos = Vector(object.GetPath(GetPathIndex(object)-1))
    end
    
    if GetDistance(objectIndexPos, Vector(object)) >= 25 then
    
      local objectEndPos = Vector(object)+(Vector(objectIndexPos)-Vector(object)):Normalized()*100
      local fromL = Vector(from)+(Vector(to)-Vector(from)):Perpendicular():Normalized()*width/2
      local fromR = Vector(from)+(Vector(to)-Vector(from)):Perpendicular2():Normalized()*width/2
      local toL = Vector(to)+(Vector(to)-Vector(from)):Perpendicular():Normalized()*width/2
      local toR = Vector(to)+(Vector(to)-Vector(from)):Perpendicular2():Normalized()*width/2
      local Node = VectorIntersection(Vector(object), Vector(objectEndPos), Vector(from), Vector(to))
      local NodefromL = VectorIntersection(Vector(object), Vector(objectEndPos), Vector(to), Vector(fromL))
      local NodefromR = VectorIntersection(Vector(object), Vector(objectEndPos), Vector(to), Vector(fromR))
      local NodetoL = VectorIntersection(Vector(object), Vector(objectEndPos), Vector(from), Vector(toL))
      local NodetoR = VectorIntersection(Vector(object), Vector(objectEndPos), Vector(from), Vector(toR))
      local nodefromL = nil
      local nodefromR = nil
      local nodetoL = nil
      local nodetoR = nil
      local pointfrom = VectorPointProjectionOnLine(Vector(object), Vector(objectEndPos), Vector(from))
      local pointto = VectorPointProjectionOnLine(Vector(object), Vector(objectEndPos), Vector(to))
      
      if NodefromL then
        nodefromL = Vector(NodefromL.x, myHero.y, NodefromL.y)
        nodetoR = Vector(NodetoR.x, myHero.y, NodetoR.y)
      else
        nodefromL = Vector(math.huge, myHero.y, math.huge)
        nodetoR = Vector(math.huge, myHero.y, math.huge)
      end
      
      if NodefromR then
        nodefromR = Vector(NodefromR.x, myHero.y, NodefromR.y)
        nodetoL = Vector(NodetoL.x, myHero.y, NodetoL.y)
      else
        nodefromR = Vector(math.huge, myHero.y, math.huge)
        nodetoL = Vector(math.huge, myHero.y, math.huge)
      end
      
      local angle = nil
      local angle2 = Vector(object):HPred_angleBetween(objectEndPos, Vector(from))*math.pi/180
      local angle3 = Vector(from):HPred_angleBetween(Vector(from)+objectEndPos-Vector(object), to)*math.pi/180
      local angletoL = Vector(from):HPred_angleBetween(Vector(from)+objectEndPos-Vector(object), toL)*math.pi/180
      local angletoR = Vector(from):HPred_angleBetween(Vector(from)+objectEndPos-Vector(object), toR)*math.pi/180
      local anglefromL = to:HPred_angleBetween(to+objectEndPos-Vector(object), fromL)*math.pi/180
      local anglefromR = to:HPred_angleBetween(to+objectEndPos-Vector(object), fromR)*math.pi/180
      local node = nil
      
      if Node then
        node = Vector(Node.x, myHero.y, Node.y)
        angle = node:HPred_angleBetween(Vector(object), Vector(from))*math.pi/180
      elseif GetDistance(pointfrom, Vector(from)) > width/2+objectAddRange or GetDistance(Vector(object), pointfrom)-GetDistance(pointto, pointfrom)+math.cos(angle3)/math.abs(math.cos(angle3))*delay*objectSpeed > objectAddRange and speed >= objectSpeed then
        return false
      else
        return true
      end
      
      local t0 = GetDistance(node, Vector(object))/objectSpeed
      local T0 = GetDistance(node, Vector(from))/speed
      local ds = (width/2+objectAddRange)/math.abs(math.sin(angle))
      local Ds = (width/2+objectAddRange)/math.abs(math.tan(angle))
      
      if math.sin(angle) < 0 then
        t0 = -t0
      end
      
      if math.sin(angle2) > 0 then
        t0 = -t0
        T0 = -T0
      end
      
      if math.sin(angle3) < 0 then
        T0 = -T0
      end
      
      local ts = t0-ds/objectSpeed
      local te = 2*t0-ts
      local Ts = nil
      
      T0 = T0+delay
      
      if math.cos(angle3) > 0 then
        Ts = T0-Ds/speed
      elseif math.cos(angle3) < 0 then
        Ts = T0+Ds/speed
      end
      
      if Ts == nil then
        return true
      end
      
      local Te = 2*T0-Ts
      
      if GetDistance(Vector(object), pointto)-GetDistance(pointfrom, pointto) > width/2*math.abs(math.sin(angle))+objectAddRange+math.cos(angle3)/math.abs(math.cos(angle3))*delay*objectSpeed and speed*math.abs(math.cos(angle3)) >= objectSpeed or math.sin(angle2)*math.sin(angle3) >= 0 and math.min(objectAddRange/math.abs(math.sin(anglefromL)), objectAddRange/math.abs(math.sin(anglefromR))) < math.min(GetDistance(nodefromL, to)-GetDistance(fromL, to), GetDistance(nodefromR, to)-GetDistance(fromR, to)) or math.sin(angle2)*math.sin(angle3) < 0 and math.min(objectAddRange/math.abs(math.sin(angletoL)), objectAddRange/math.abs(math.sin(angletoR))) < math.min(GetDistance(nodetoL, Vector(from))-GetDistance(toL, Vector(from)), GetDistance(nodetoR, Vector(from))-GetDistance(toR, Vector(from))) or Ts < ts or Te > te or math.min(GetDistance(nodetoL, Vector(from))-GetDistance(toL, Vector(from)), GetDistance(nodetoR, Vector(from))-GetDistance(toR, Vector(from))) > math.min(objectAddRange/math.abs(math.sin(angletoL)), objectAddRange/math.abs(math.sin(angletoR))) then
        return false
      end
      
    end
    
  else
  
    local fromAdd = Vector(from)+(Vector(from)-to):Normalized()*objectAddRange
    local fromAddL = fromAdd+(to-Vector(from)):Perpendicular():Normalized()*(width/2+objectAddRange)
    local fromAddR = fromAdd+(to-Vector(from)):Perpendicular2():Normalized()*(width/2+objectAddRange)
    local toAdd = to+(to-Vector(from)):Normalized()*objectAddRange
    local toAddL = toAdd+(to-Vector(from)):Perpendicular():Normalized()*(width/2+objectAddRange)
    local toAddR = toAdd+(to-Vector(from)):Perpendicular2():Normalized()*(width/2+objectAddRange)
    local angleL = toAddL:HPred_angleBetween(fromAddL, Vector(object))
    local angleR = fromAddR:HPred_angleBetween(toAddR, Vector(object))
    local angleU = toAddR:HPred_angleBetween(toAddL, Vector(object))
    local angleD = fromAddL:HPred_angleBetween(fromAddR, Vector(object))
    
    if 0 < angleL and angleL < 180 or 0 < angleR and angleR < 180 or 0 < angleU and angleU < 180 or 0 < angleD and angleD < 180 then
      return false
    end
    
  end
  
  return true
end

---------------------------------------------------------------------------------

function HPrediction:SpellCollision(HPskillshot, object, from, to)

  if object.IsDead then
    return false
  end
  
  local spell = HPskillshot.Properties and HPskillshot.Properties or nil
  if IsNilOrFalse(spell) then
    error("SpellCollision: HPskillshot is nil, for help please check HPred guide, or speak with Dewblackio2.", 2)
  end
  local type = spell.type
  local delay = spell.delay
  local speed = spell.speed
  local width = spell.width
  
  local objectAddRange = object.boundingRadius+self.HPMenu_Buffer.getValue()
  local objectSpeed = object.MoveSpeed
  local to = Vector(to)
  
  if type == "PromptLine" then
    speed = math.huge
  end
  
  if object.PathCount >= 2 then
  
    local objectIndexPos = Vector(object.GetPath(GetPathIndex(object)))
    
    if objectIndexPos == nil then
      objectIndexPos = Vector(object.GetPath(GetPathIndex(object)-1))
    end
    
    if GetDistance(objectIndexPos, Vector(object)) >= 25 then
    
      local objectEndPos = Vector(object)+(Vector(objectIndexPos)-Vector(object)):Normalized()*100
      local fromL = Vector(from)+(to-Vector(from)):Perpendicular():Normalized()*width/2
      local fromR = Vector(from)+(to-Vector(from)):Perpendicular2():Normalized()*width/2
      local toL = to+(to-Vector(from)):Perpendicular():Normalized()*width/2
      local toR = to+(to-Vector(from)):Perpendicular2():Normalized()*width/2
      local Node = VectorIntersection(Vector(object), objectEndPos, Vector(from), to)
      local NodefromL = VectorIntersection(Vector(object), objectEndPos, to, fromL)
      local NodefromR = VectorIntersection(Vector(object), objectEndPos, to, fromR)
      local NodetoL = VectorIntersection(Vector(object), objectEndPos, Vector(from), toL)
      local NodetoR = VectorIntersection(Vector(object), objectEndPos, Vector(from), toR)
      local nodefromL = nil
      local nodefromR = nil
      local nodetoL = nil
      local nodetoR = nil
      local pointfrom = VectorPointProjectionOnLine(Vector(object), objectEndPos, Vector(from))
      local pointto = VectorPointProjectionOnLine(Vector(object), objectEndPos, to)
      
      if NodefromL then
        nodefromL = Vector(NodefromL.x, myHero.y, NodefromL.y)
        nodetoR = Vector(NodetoR.x, myHero.y, NodetoR.y)
      else
        nodefromL = Vector(math.huge, myHero.y, math.huge)
        nodetoR = Vector(math.huge, myHero.y, math.huge)
      end
      
      if NodefromR then
        nodefromR = Vector(NodefromR.x, myHero.y, NodefromR.y)
        nodetoL = Vector(NodetoL.x, myHero.y, NodetoL.y)
      else
        nodefromR = Vector(math.huge, myHero.y, math.huge)
        nodetoL = Vector(math.huge, myHero.y, math.huge)
      end
      
      local angle = nil
      local angle2 = Vector(object):HPred_angleBetween(objectEndPos, Vector(from))*math.pi/180
      local angle3 = Vector(from):HPred_angleBetween(Vector(from)+objectEndPos-Vector(object), to)*math.pi/180
      local angletoL = Vector(from):HPred_angleBetween(Vector(from)+objectEndPos-Vector(object), toL)*math.pi/180
      local angletoR = Vector(from):HPred_angleBetween(Vector(from)+objectEndPos-Vector(object), toR)*math.pi/180
      local anglefromL = to:HPred_angleBetween(to+objectEndPos-Vector(object), fromL)*math.pi/180
      local anglefromR = to:HPred_angleBetween(to+objectEndPos-Vector(object), fromR)*math.pi/180
      local node = nil
      
      if Node then
        node = Vector(Node.x, myHero.y, Node.y)
        angle = node:HPred_angleBetween(Vector(object), Vector(from))*math.pi/180
      elseif GetDistance(pointfrom, Vector(from)) > width/2+objectAddRange or GetDistance(Vector(object), pointfrom)-GetDistance(pointto, pointfrom)+math.cos(angle3)/math.abs(math.cos(angle3))*delay*objectSpeed > objectAddRange and speed >= objectSpeed then
        return false
      else
        return true
      end
      
      local t0 = GetDistance(node, Vector(object))/objectSpeed
      local T0 = GetDistance(node, Vector(from))/speed
      local ds = (width/2+objectAddRange)/math.abs(math.sin(angle))
      local Ds = (width/2+objectAddRange)/math.abs(math.tan(angle))
      
      if math.sin(angle) < 0 then
        t0 = -t0
      end
      
      if math.sin(angle2) > 0 then
        t0 = -t0
        T0 = -T0
      end
      
      if math.sin(angle3) < 0 then
        T0 = -T0
      end
      
      local ts = t0-ds/objectSpeed
      local te = 2*t0-ts
      local Ts = nil
      
      T0 = T0+delay
      
      if math.cos(angle3) > 0 then
        Ts = T0-Ds/speed
      elseif math.cos(angle3) < 0 then
        Ts = T0+Ds/speed
      end
      
      if Ts == nil then
        return false
      end
      
      local Te = 2*T0-Ts
      
      if GetDistance(Vector(object), pointto)-GetDistance(pointfrom, pointto) > width/2*math.abs(math.sin(angle))+objectAddRange+math.cos(angle3)/math.abs(math.cos(angle3))*delay*objectSpeed and speed*math.abs(math.cos(angle3)) >= objectSpeed or math.sin(angle2)*math.sin(angle3) >= 0 and math.min(objectAddRange/math.abs(math.sin(anglefromL)), objectAddRange/math.abs(math.sin(anglefromR))) < math.min(GetDistance(nodefromL, to)-GetDistance(fromL, to), GetDistance(nodefromR, to)-GetDistance(fromR, to)) or math.sin(angle2)*math.sin(angle3) < 0 and math.min(objectAddRange/math.abs(math.sin(angletoL)), objectAddRange/math.abs(math.sin(angletoR))) < math.min(GetDistance(nodetoL, Vector(from))-GetDistance(toL, Vector(from)), GetDistance(nodetoR, Vector(from))-GetDistance(toR, Vector(from))) or Ts < ts or Te > te or math.min(GetDistance(nodetoL, Vector(from))-GetDistance(toL, Vector(from)), GetDistance(nodetoR, Vector(from))-GetDistance(toR, Vector(from))) > math.min(objectAddRange/math.abs(math.sin(angletoL)), objectAddRange/math.abs(math.sin(angletoR))) then
        return false
      else
        return true
      end
      
    end
    
  else
  
    local fromAdd = Vector(from)+(Vector(from)-to):Normalized()*objectAddRange
    local fromAddL = fromAdd+(to-Vector(from)):Perpendicular():Normalized()*(width/2+objectAddRange)
    local fromAddR = fromAdd+(to-Vector(from)):Perpendicular2():Normalized()*(width/2+objectAddRange)
    local toAdd = to+(to-Vector(from)):Normalized()*objectAddRange
    local toAddL = toAdd+(to-Vector(from)):Perpendicular():Normalized()*(width/2+objectAddRange)
    local toAddR = toAdd+(to-Vector(from)):Perpendicular2():Normalized()*(width/2+objectAddRange)
    local angleL = toAddL:HPred_angleBetween(fromAddL, Vector(object))
    local angleR = fromAddR:HPred_angleBetween(toAddR, Vector(object))
    local angleU = toAddR:HPred_angleBetween(toAddL, Vector(object))
    local angleD = fromAddL:HPred_angleBetween(fromAddR, Vector(object))
    
    if (angleL == 0 or angleL >= 180) and (angleR == 0 or angleR >= 180) and (angleU == 0 or angleU >= 180) and (angleD == 0 or angleD >= 180) then
      return true
    end
    
  end
  
  return false
end

---------------------------------------------------------------------------------

function HPrediction:IsInvincible(enemy, time)

  if enemy and enemy.IsValid and enemy.TeamId ~= myHero.TeamId and not enemy.IsDead then
    GetAllBuffNameActive(enemy.Addr)
    for i,v in pairs(pBuffName) do
      if GetBuffType(enemy.Addr, tostring(v)) == 17 and GetTickCount() <= GetBuffTimeEnd(enemy.Addr, tostring(v))+(time or 0) then 
        return true
      end
    end 
  end
  
  return false
end

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

--[[function HPrediction:OnAnimation(unit, animation)

  if unit == nil then
    return
  end

  if self.HPMenu_Ignore.getValue() and unit.TeamId == myHero.TeamId and string.find(string.lower(tostring(animation)), "atta") then
    table.insert(self.ActiveAttacks, {Attacker = unit, pos = Vector(unit), Target = tar, animationTime = math.huge, damage = unit.TotalDmg, hittime=time, starttime = self:GetTime() - GetLatency()/2000, windUpTime = 0.393, projectilespeed = math.huge})
    
    if unit.spell.target.networkID < 100 and self.PredictionDamage[unit.spell.target.networkID] == nil then
      self.PredictionDamage[unit.spell.target.networkID] = {}
    end

    if self.PredictionDamage[unit.spell.target.networkID] then

      if unit.type ~= myHero.type and self.ProjectileSpeed[unit.charName] then

        local ctime = GetGameTimer()+unit.spell.windUpTime+GetDistance(unit.spell.target, unit)/self.ProjectileSpeed[unit.charName]

        self.PredictionDamage[unit.spell.target.networkID][ctime] = self:GetAADmg(unit.spell.target, unit)
      else

        local ctime = GetGameTimer()+unit.spell.windUpTime

        self.PredictionDamage[unit.spell.target.networkID][ctime] = self:GetAADmg(unit.spell.target, unit)
      end

    end

  end

end

---------------------------------------------------------------------------------

function HPrediction:OnProcessAttack(unit, spell)

  if unit == nil then
    return
  end

  if self.Menu.Ignore and unit.team == myHero.team and unit.type == myHero.type and spell.target and spell.name:find("BasicAttack") and self.ProjectileSpeed[unit.charName] then

    if spell.target.networkID < 100 and self.PredictionDamage[spell.target.networkID] == nil then
      self.PredictionDamage[spell.target.networkID] = {}
    end

    if self.PredictionDamage[spell.target.networkID] then

      local ctime = GetGameTimer()+GetDistance(spell.target, unit)/self.ProjectileSpeed[unit.charName]

      self.PredictionDamage[spell.target.networkID][ctime] = self:GetAADmg(spell.target, unit)
    end

  end

end

---------------------------------------------------------------------------------

function HPrediction:PredictHealth(unit, time)

  local health = unit.health

  if self.PredictionDamage[unit.networkID] then

    local Delete = true

    for ctime, damage in pairs(self.PredictionDamage[unit.networkID]) do

      if GetGameTimer()+GetLatency()/2000 < ctime-GetLatency()/2000 then
        Delete = false
        break
      end

    end

    if Delete then
      self.PredictionDamage[unit.networkID] = nil
    else

      for ctime, damage in pairs(self.PredictionDamage[unit.networkID]) do
      
        if GetGameTimer()+GetLatency()/2000 >= ctime-GetLatency()/2000 then
          self.PredictionDamage[unit.networkID][ctime] = nil
        elseif GetGameTimer()+GetLatency()/2000+time > ctime+0.09-GetLatency()/2000 then --Temp 0.075
          health = health-damage
        end

      end

    end

  end

  return health
end

---------------------------------------------------------------------------------

function HPrediction:GetAADmg(enemy, ally)

  local Armor = math.max(0, enemy.armor*ally.armorPenPercent-ally.armorPen)
  local ArmorPercent = Armor/(100+Armor)
  local TrueDmg = ally.totalDamage*(1-ArmorPercent)

  return TrueDmg
end]]

---------------------------------------------------------------------------------

function HPrediction:OnUpdateBuff(unit, buff, stacks)

  if unit.NetworkId ~= myHero.NetworkId then
    return
  end
  
  if buff.Name == "XerathArcanopulseChargeUp" then
    self.LastQ = os.clock() - GetLatency()/2000
    self.OnQ = true
  else
    --print("Buff: "..buff.Name)
  end
  
end

---------------------------------------------------------------------------------

function HPrediction:OnRemoveBuff(unit, buff)

  if unit.NetworkId ~= myHero.NetworkId then
    return
  end
  
  if buff.Name == "XerathArcanopulseChargeUp" then
    self.OnQ = false
  else
    --print("Delete: "..buff.Name)
  end
  
end

---------------------------------------------------------------------------------

function HPrediction:Level(spell)
  return GetSpellLevel(GetMyChamp(), spell)
end

---------------------------------------------------------------------------------

function HPrediction:NewSkillshot(SpellDataTable)
  return HPSkillshot(SpellDataTable)
end

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

HPSkillshot = class()

function HPSkillshot:__init(properties)

  assert(properties, self.ErrorMessage("Properties nil."))
  
  self.Properties = {}
  self.Properties.Raw = {}
  
  setmetatable(self.Properties, self:__CreateMetaTable())
  
  for name, value in pairs(properties) do
    self:SetProperty(name:lower(), value)
  end
  
end

---------------------------------------------------------------------------------

function HPSkillshot.ErrorMessage(text)
  return "<font color='FFC117'>HPSkillshot: </font><font color='FFFFFF'>"..text.."</font>"
end

---------------------------------------------------------------------------------

function HPSkillshot:__CreateMetaTable()

  local mtbl = {}
  
  function mtbl.__index(obj, key)
  
    key = key:lower()
    local value = self.Properties.Raw[key]
    
    if type(value) == "function" then
      return value()
    end
    
    return value
  end
  
  function mtbl.__newindex(obj, key, value)
    self:SetProperty(key, value)
  end
  
  function mtbl.__metatable()
  end
  
  return mtbl
end

---------------------------------------------------------------------------------

function HPSkillshot:SetProperty(name, value)

  assert(name, self.ErrorMessage("SetProperty field 'name' is nil."))
  
  if value == nil then
    assert(value, self.ErrorMessage("SetProperty field 'value' is nil."))
  end
  
  self.Properties.Raw[name:lower()] = value
end

---------------------------------------------------------------------------------

function HPSkillshot.__tostring()
  return self.Properties["Type"]
end

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

_G.HPrediction.Presets = {}

_G.HPrediction.Presets["Ahri"] = 
{
  ["Q"] = HPSkillshot({type = "DelayLine", delay = 0.25, range = 900, speed = 950, width = 200, IsVeryLowAccuracy = true}),
  ["E"] = HPSkillshot({type = "DelayLine", delay = 0.25, range = 1000, speed = 1570, collisionM = true, collisionH = true, width = 120})
}
_G.HPrediction.Presets["Blitzcrank"] = 
{
  ["Q"] = HPSkillshot({type = "DelayLine", delay = 0.25, range = 1050, speed = 1800, collisionM = true, collisionH = true, width = 140}),
  ["R"] = HPSkillshot({type = "PromptCircle", delay = 0.25, range = 0, radius = 600})
}
_G.HPrediction.Presets["Cassiopeia"] = 
{
  ["Q"] = HPSkillshot({type = "PromptCircle", delay = 0.7, range = 850, radius = 200}),
  ["W"] = HPSkillshot({type = "DelayCircle", delay = 0.25, range = 850, radius = 147, speed = 2500}),
  ["R"] = HPSkillshot({type = "Triangle", delay = 0.6, range = 825, angle = 80})
}
_G.HPrediction.Presets["Corki"] = 
{
  ["Q"] = HPSkillshot({type = "DelayCircle", delay = 0.75, range = 825, speed = 1500, radius = 270}),
  ["R"] = HPSkillshot({type = "DelayLine", delay = 0.25, range = 1300, speed = 2000, collisionM = true, collisionH = true, width = 80})
}
_G.HPrediction.Presets["DrMundo"] = 
{
  ["Q"] = HPSkillshot({type = "DelayLine", delay = 0.25, range = 1050, speed = 2000, collisionM = true, collisionH = true, width = 120})
}
_G.HPrediction.Presets["Evelynn"] = 
{
  ["R"] = HPSkillshot({type = "PromptCircle", delay = 0.25, range = 900, radius = 500})
}
_G.HPrediction.Presets["Ezreal"] = 
{
  ["Q"] = HPSkillshot({type = "DelayLine", delay = 0.25, range = 1200, speed = 2000, collisionM = true, collisionH = true, width = 120}),
  ["W"] = HPSkillshot({type = "DelayLine", delay = 0, range = 1050, speed = 1600, width = 160}),
  ["R"] = HPSkillshot({type = "DelayLine", delay = 1, range = math.huge, speed = 2000, width = 320, IsVeryLowAccuracy = true})
}
_G.HPrediction.Presets["Karthus"] = 
{
  ["Q"] = HPSkillshot({type = "PromptCircle", delay = 1.1, range = 875, radius = 200, IsLowAccuracy = true}),
  ["E"] = HPSkillshot({type = "PromptCircle", delay = 0, range = 0, radius = 550})
}
_G.HPrediction.Presets["Lux"] = 
{
  ["Q"] = HPSkillshot({type = "DelayLine", delay = 0.25, range = 1300, speed = 1200, collisionM = true, collisionH = true, width = 140}),
  ["E"] = HPSkillshot({type = "DelayCircle", delay = 0.25, range = 1100, speed = 1300, radius = 350}),
  ["E2"] = HPSkillshot({type = "PromptCircle", delay = 0, range = 0, radius = 350}),
  ["R"] = HPSkillshot({type = "PromptLine", delay = 1.012, range = 3300, width = 380})
}
_G.HPrediction.Presets["Morgana"] = 
{
  ["Q"] = HPSkillshot({type = "DelayLine", delay = 0.25, range = 1300, speed = 1200, collisionM = true, collisionH = true, width = 140}),
  ["W"] = HPSkillshot({type = "PromptCircle", delay = 0.25, range = 900, radius = 280})
}
_G.HPrediction.Presets["Nidalee"] = 
{
  ["Q"] = HPSkillshot({type = "DelayLine", delay = 0.25, range = 1500, speed = 1300, collisionM = true, collisionH = true, width = 80, IsLowAccuracy = true}),
  ["W"] = HPSkillshot({type = "PromptCircle", delay = 1.75, range = 900, radius = 80, IsVeryLowAccuracy = true})
}
_G.HPrediction.Presets["Orianna"] = 
{
  ["Q"] = HPSkillshot({type = "DelayCircle", delay = 0, range = 825, radius = 175, speed = 1200}),
  ["W"] = HPSkillshot({type = "PromptCircle", delay = 0, range = 0, radius = 225}),
  ["E"] = HPSkillshot({type = "DelayLine", delay = 0, speed = 1800, width = 80}),
  ["R"] = HPSkillshot({type = "PromptCircle", delay = 0.5, range = 0, radius = 350})
}
_G.HPrediction.Presets["Rengar"] = 
{
  ["W"] = HPSkillshot({type = "PromptCircle", delay = 0, range = 0, radius = 300})
}
_G.HPrediction.Presets["Riven"] = 
{
  ["R"] = HPSkillshot({type = "DelayArc", delay = 0.25, range = 1075, speed = 1600, angle = 45}) --idk
}
_G.HPrediction.Presets["Syndra"] = 
{
  ["Q"] = HPSkillshot({type = "PromptCircle", delay = 0.75--[[0.65]], range = 800, radius = 210}),
  ["W"] = HPSkillshot({type = "DelayCircle", delay = 0.25, range = 950, speed = 1450, radius = 200}),
  ["E"] = HPSkillshot({type = "DelayArc", delay = 0.25, range = 700, speed = 2500, angle = 20})
}
_G.HPrediction.Presets["Viktor"] = 
{
  ["W"] = HPSkillshot({type = "PromptCircle", delay = 1+0.6, range = 700, radius = function() return 325*(100/(100-(4*HPrediction:Level(_W)+24))) end, IsVeryLowAccuracy = true}),
  ["E"] = HPSkillshot({type = "DelayLine2", delay = 0, range = 700, speed = 790, width = 180})
}
_G.HPrediction.Presets["Vladimir"] = 
{
  ["E"] = HPSkillshot({type = "PromptCircle", delay = 0.25, range = 0, radius = 620})
}
_G.HPrediction.Presets["Xerath"] = 
{
  ["Q"] = HPSkillshot({type = "PromptLine", delay = 0.55, range = 750, width = 200}),
  ["W"] = HPSkillshot({type = "PromptCircle", delay = 0.8, range = 1000, radius = 275}),
  ["E"] = HPSkillshot({type = "DelayLine", delay = 0.25, range = 1125, speed = 1400, collisionM = true, collisionH = true, width = 140}),
  ["R"] = HPSkillshot({type = "PromptCircle", delay = 0.25, radius = 190})
}
_G.HPrediction.Presets["Zed"] = 
{
  ["Q"] = HPSkillshot({type = "DelayLine", delay = 0.25, range = 925, speed = 1700, width = 90})
}