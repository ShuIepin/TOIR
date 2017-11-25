--[[
  ____                  _ ____            
 / ___|  __ _ _ __   __| | __ )  _____  __
 \___ \ / _` | '_ \ / _` |  _ \ / _ \ \/ /
  ___) | (_| | | | | (_| | |_) | (_) >  < 
 |____/ \__,_|_| |_|\__,_|____/ \___/_/\_\
                                          
--]]

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

local function classInstance()
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

local myHero = GetMyHero()

--[[
   ____      _ _ _                _        
  / ___|__ _| | | |__   __ _  ___| | _____ 
 | |   / _` | | | '_ \ / _` |/ __| |/ / __|
 | |__| (_| | | | |_) | (_| | (__|   <\__ \
  \____\__,_|_|_|_.__/ \__,_|\___|_|\_\___/
                                           
--]]

local Keys = {}
local KeysActive = false
for i = 1, 255, 1 do
        Keys[i] = false
end

local Callback = classInstance()

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

--[[
   ____                                      
  / ___|___  _ __ ___  _ __ ___   ___  _ __  
 | |   / _ \| '_ ` _ \| '_ ` _ \ / _ \| '_ \ 
 | |__| (_) | | | | | | | | | | | (_) | | | |
  \____\___/|_| |_| |_|_| |_| |_|\___/|_| |_|
                                             
--]]

local function codeToString(code)
        if code >=48 and code<=90 then
                return string.char(code)
        elseif code==1 then
                return "mouseLeft"
        elseif code==2 then
                return "mouseRight"
        elseif code==4 then
                return "mouseMiddle"
        elseif code==5 then
                return "mouseX1"
        elseif code==6 then
                return "mouseX2"
        elseif code==6 then
                return "mouseMiddle"
        elseif code==13 then
                return "enter"
        elseif code==16 then
                return "shift"
        elseif code==8 then
                return "backspace"
        elseif code==9 then
                return "tab"
        elseif code==13 then
                return "enter"
        elseif code==16 then
                return "shift"
        elseif code==17 then
                return "ctrl"
        elseif code==18 then
                return "alt"
        elseif code==19 then
                return "pause"
        elseif code==20 then
                return "caps lock"
        elseif code==27 then
                return "escape"
        elseif code==32 then
                return "SPACE"
        elseif code==33 then
                return "pgUp"
        elseif code==34 then
                return "pgDn"
        elseif code==35 then
                return "end"
        elseif code==36 then
                return "home"
        elseif code==37 then
                return "left"
        elseif code==38 then
                return "up"
        elseif code==39 then
                return "right"
        elseif code==40 then
                return "down"
        elseif code==44 then
                return "printSc"
        elseif code==45 then
                return "insert"
        elseif code==46 then
                return "del"
        elseif code==47 then
                return "help"
        elseif code==91 then
                return "lWindow"
        elseif code==92 then
                return "rWindow"
        elseif code==93 then
                return "select"
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
        else return tostring(code) end
end

local function IsVector(v)
        return v and v.x and type(v.x) == "number" and ((v.y and type(v.y) == "number") or (v.z and type(v.z) == "number"))
end

--String
local function stripchars(s, chrs)
        return s:gsub("["..chrs.."]", ''):gsub("%[%]", "")
end

local function stripchars2(s, chrs)
        return s:gsub("%[%]")
end

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

function table.serialize2(tab, prefix)
        local index=1
                local buf = {}
                buf[index]="\n"
                index=index+1
                for key, value in pairs(tab) do
                        if type(key)=="number" then
                                buf[index]=prefix.."["..key.."]="
                        else
                                buf[index]=prefix..'["'..stripchars(key, "\n\a\b\f\r\t\v\"%[%]" )..'"]='
                        end
                        index=index+1
                        
                        local valtype=type(value)
                        if valtype=="number" then
                                buf[index]=value
                                index=index+1
                        elseif valtype=="table" then
                                buf[index]="{}"
                                index=index+1
                                if type(key)=="number" then
                                        buf[index]=table.serialize2(value, prefix.."["..key.."]")
                                else
                                        buf[index]=table.serialize2(value, prefix..'["'..stripchars(key, "\n\a\b\f\r\t\v\"%[%]" )..'"]')
                                end
                                index=index+1
                        elseif valtype=="string" then
                                buf[index]="[["..stripchars(value, "\n\a\b\f\r\t\v\"%[%]" ).."]]"
                                index=index+1
                        elseif valtype=="boolean" then
                                buf[index]=tostring(value)
                                index=index+1
                        else
                                buf[index]="type not supported"
                                index=index+1
                        end
                        buf[index]="\n"
                        index=index+1
                end
                return t.concat(buf)
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

local function print(...)
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

local function printDebug(...)
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

local function GetOrigin(unit)
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

local function GetPing()
        return GetLatency() / 1000
end

local function GetTrueAttackRange()
        return GetAttackRange(myHero.Addr) + GetOverrideCollisionRadius(myHero.Addr)
end

local function GetDistance(p1, p2)
        local p2 = p2 or GetOrigin(myHero)

        return GetDistance2D(p1.x, p1.z or p1.y, p2.x, p2.z or p2.y)
end

local function GetPercentHP(unit)
        return GetHealthPoint(unit) / GetHealthPointMax(unit) * 100
end

local function GetPercentMP(unit)
        return GetManaPoint(unit) / GetManaPointMax(unit) * 100
end

local function GetPredictionPos(unit)
        if type(unit) == "number" then
                return { x = GetPredictionPosX(unit), y = GetPredictionPosY(unit), z = GetPredictionPosZ(unit) }
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

local function IsValidTarget(unit, range)
        local range = range or m.huge
        return unit ~= 0 and not IsDead(unit) and not IsInFog(unit) and GetTargetableToTeam(unit) == 4 and IsEnemy(unit) and GetDistance(GetOrigin(unit)) <= range
end

local function WorldToScreenPos(x, y, z)
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

local function CircleCircleIntersection(c1, c2, r1, r2) 
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
local function DelayAction(func, delay, args)
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

local function DisableOrb(keyList)
        for i, key in pairs(keyList) do
                if type(key) == "table" then
                        if key.getValue() then
                                SetLuaCombo(true)
                                SetLuaBasicAttackOnly(true)
                                SetLuaMoveOnly(true)
                        else
                                SetLuaCombo(false)
                                SetLuaBasicAttackOnly(false)
                                SetLuaMoveOnly(false)
                        end
                end
        end
end

local function VPGetLineCastPosition(target, delay, speed)
        local distance = GetDistance(GetOrigin(target))
        local time = delay + distance / speed
        local realDistance = (time * GetMoveSpeed(target))
        if realDistance == 0 then return distance end
        return realDistance
end

local function GetCollision(target, width, range, distance)
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

local function IsAfterAttack()
        if CanMove() and not CanAttack() then
                return true
        else
                return false
        end
end

local function VectorPointProjectionOnLineSegment(v1, v2, v)
        local cx, cy, ax, ay, bx, by = v.x, (v.z or v.y), v1.x, (v1.z or v1.y), v2.x, (v2.z or v2.y)
        local rL = ((cx - ax) * (bx - ax) + (cy - ay) * (by - ay)) / ((bx - ax) ^ 2 + (by - ay) ^ 2)
        local pointLine = { x = ax + rL * (bx - ax), z = ay + rL * (by - ay) }
        local rS = rL < 0 and 0 or (rL > 1 and 1 or rL)
        local isOnSegment = rS == rL
        local pointSegment = isOnSegment and pointLine or { x = ax + rS * (bx - ax), z = ay + rS * (by - ay) }
        return pointSegment, pointLine, isOnSegment
end

local function GetEnemyHeroes()
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

local function GetEnemyHeroes()
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

local function HasSheenBuff()
        return myHero.HasBuff("sheen") or myHero.HasBuff("LichBane") or myHero.HasBuff("dianaarcready") or myHero.HasBuff("ItemFrozenFist") or myHero.HasBuff("sonapassiveattack")
end

local function HasSheen()
        return myHero.HasItem(3057) or myHero.HasItem(3078) or myHero.HasItem(3025) or myHero.HasItem(3100)
end

local function WriteFile(text, path, mode)
        local f = IO.open(path, mode or "w+")

        if not f then
                return false
        end

        f:write(text)
        f:close()
        return true
end

Callback.Add("Update", function()
        myHero = GetMyHero()
end)

--[[
 __     __        _             
 \ \   / /__  ___| |_ ___  _ __ 
  \ \ / / _ \/ __| __/ _ \| '__|
   \ V /  __/ (__| || (_) | |   
    \_/ \___|\___|\__\___/|_|   
                                
--]]

local Vector = classInstance()

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

local function GetMousePos()
        return { x = GetCursorPosX(), y = GetCursorPosY(), z = GetCursorPosZ() }
end

local function GetCursorPos()
        return Vector(WorldToScreenPos(GetMousePos()))
end

local Rectangle = classInstance()

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
        FilledRectD3DX(self.x,self.y,self.width, self.height, color or Lua_ARGB(255,255,255,255)) 
end

--[[
  ____             _ _ 
 / ___| _ __   ___| | |
 \___ \| '_ \ / _ \ | |
  ___) | |_) |  __/ | |
 |____/| .__/ \___|_|_|
       |_|             
--]]

local Spell = classInstance()

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

local Draw = classInstance()

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

--[[
   ____             __ _       
  / ___|___  _ __  / _(_) __ _ 
 | |   / _ \| '_ \| |_| |/ _` |
 | |__| (_) | | | |  _| | (_| |
  \____\___/|_| |_|_| |_|\__, |
                         |___/ 
--]]

local Config = classInstance()

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
        local buf = {[[local gConfig = {}]]}

        index = index + 1
        buf[index] = table.serialize2(self.config, "gConfig")
        index = index + 1
        buf[index] = [[return gConfig]]
        index = index + 1
        buf[index] = "\n"
        index = index + 1

        WriteFile(t.concat(buf), SCRIPT_PATH .. "\\Lib\\" .. self.fileName .. ".save")
end

gConfig = Config()
gConfig:Load()

--[[
  __  __                  
 |  \/  | ___ _ __  _   _ 
 | |\/| |/ _ \ '_ \| | | |
 | |  | |  __/ | | | |_| |
 |_|  |_|\___|_| |_|\__,_|
                          
--]]

local ITEMHEIGHT = 30
local ITEMWIDTH = 200
local TEXTXOFFSET = 0
local TEXTYOFFSET = -7
local TOGGLEWIDTH = 30
local MENUTEXTCOLOR = Lua_ARGB(255, 255, 255, 255)
local MENUBGCOLOR = Lua_ARGB(255, 0, 0, 0)
local MENUBGACTIVE = 4285098345
local MENUBORDERCOLOR = Lua_ARGB(255, 255, 255, 255)

--[[
  __  __       _         __  __                  
 |  \/  | __ _(_)_ __   |  \/  | ___ _ __  _   _ 
 | |\/| |/ _` | | '_ \  | |\/| |/ _ \ '_ \| | | |
 | |  | | (_| | | | | | | |  | |  __/ | | | |_| |
 |_|  |_|\__,_|_|_| |_| |_|  |_|\___|_| |_|\__,_|
                                                 
--]]

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

--[[
  ____        _       __  __                  
 / ___| _   _| |__   |  \/  | ___ _ __  _   _ 
 \___ \| | | | '_ \  | |\/| |/ _ \ '_ \| | | |
  ___) | |_| | |_) | | |  | |  __/ | | | |_| |
 |____/ \__,_|_.__/  |_|  |_|\___|_| |_|\__,_|
                                              
--]]

SubMenu = {}

function SubMenu.new(name)
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
                DrawTextD3DX(this.pos.x+this.rectangle.width-15, this.textY, ">", MENUTEXTCOLOR)
                DrawTextD3DX(this.pos.x+5, this.textY, this.name, MENUTEXTCOLOR)
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
                        this.activeRectangle:Draw(Lua_ARGB(255, 0, 120, 26))
                        DrawTextD3DX(this.pos.x+this.rectangle.width-25, this.textY, "On", MENUTEXTCOLOR)
                else
                        this.activeRectangle:Draw(Lua_ARGB(255, 255, 35, 35))
                        DrawTextD3DX(this.pos.x+this.rectangle.width-25, this.textY, "Off", MENUTEXTCOLOR)
                end
                FilledRectD3DX(this.activeRectangle.x-1,this.activeRectangle.y,1,this.activeRectangle.height,MENUBORDERCOLOR)
                DrawTextD3DX(this.pos.x+5, this.textY, this.name, MENUTEXTCOLOR)
                FilledRectD3DX(this.rectangle.x,this.rectangle.y,this.rectangle.width,1,MENUBORDERCOLOR)
        end
        function this.show()
        end
        
        function this.hide()

        end
        return this
end

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
                        --local x = Vector(Vector(GetCursorPos()) - Vector(this.rectangle))
                        local val = math.roundStep(Vector(Vector(GetCursorPos()) - Vector(this.rectangle)).x/this.rectangle.width*(this.max-this.min)+this.min, this.step)
                        if val<this.min then val=this.min end
                        if val>this.max then val=this.max end
                        this.value=val
                        this.updateSlider()
                end
                this.rectangle:Draw(MENUBGCOLOR)
                this.sliderRectangle:Draw(4278190335)
                DrawTextD3DX(this.pos.x+5, this.textY, this.name, MENUTEXTCOLOR)
                local textval=string.format("%."..this.places.."f", this.value)
                DrawTextD3DX(this.pos.x+this.rectangle.width-GetTextWidth(textval, 10), this.textY, textval, MENUTEXTCOLOR)
                
                FilledRectD3DX(this.rectangle.x,this.rectangle.y,this.rectangle.width,1,MENUBORDERCOLOR)
        end
        
        function this.show()
        end
        
        function this.hide()
        this.sliderActive=false
        end
        return this
end

MenuSeparator = {}
function MenuSeparator.new(name, center)
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
                DrawTextD3DX(textH, this.textY, this.name,MENUTEXTCOLOR)
                FilledRectD3DX(this.rectangle.x,this.rectangle.y,this.rectangle.width,1,MENUBORDERCOLOR)
        end
        
        function this.show()
        end
        
        function this.hide()
                this.dragging=false
        end
        
        return this
end

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
                        this.activeRectangle:Draw(0xFF008000)
                        DrawTextD3DX(this.pos.x+this.rectangle.width-24, this.textY, "On",MENUTEXTCOLOR)
                else
                        this.activeRectangle:Draw(0xFFFF0000)
                        DrawTextD3DX(this.pos.x+this.rectangle.width-24, this.textY, "Off",MENUTEXTCOLOR)
                end
                FilledRectD3DX(this.activeRectangle.x-1,this.activeRectangle.y,1,this.activeRectangle.height,MENUBORDERCOLOR)
                DrawTextD3DX(this.pos.x+5, this.textY, string.format("%s [%s]",this.name, this.keycodeString),MENUTEXTCOLOR)
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
                
                this.leftRectangle:Draw(4278190335)
                this.rightRectangle:Draw(4278190335)
                FilledRectD3DX(this.leftRectangle.x-2,this.leftRectangle.y,1,this.leftRectangle.height,MENUBORDERCOLOR)
                FilledRectD3DX(this.rightRectangle.x-2,this.rightRectangle.y,1,this.rightRectangle.height,MENUBORDERCOLOR)
                DrawTextD3DX(this.rightRectangle.x+10, this.textY, ">",MENUTEXTCOLOR)
                DrawTextD3DX(this.leftRectangle.x+10, this.textY, "<",MENUTEXTCOLOR)
                DrawTextD3DX(this.pos.x+5, this.textY, this.name,MENUTEXTCOLOR)
                DrawTextD3DX(this.leftRectangle.x-GetTextWidth(this.stringlist[this.selectedIndex], 5), this.textY, this.stringlist[this.selectedIndex], MENUTEXTCOLOR)
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

menuInst = MainMenu.new()
menuInst.addItem(MenuSeparator.new("ShulepinAIO", true))

Callback.Add("Draw", function()
        menuInst.onLoop()
end)

--[[
  _____                    _     ____       _           _             
 |_   _|_ _ _ __ __ _  ___| |_  / ___|  ___| | ___  ___| |_ ___  _ __ 
   | |/ _` | '__/ _` |/ _ \ __| \___ \ / _ \ |/ _ \/ __| __/ _ \| '__|
   | | (_| | | | (_| |  __/ |_   ___) |  __/ |  __/ (__| || (_) | |   
   |_|\__,_|_|  \__, |\___|\__| |____/ \___|_|\___|\___|\__\___/|_|   
                |___/                                                 
--]]

local TargetSelector = classInstance()

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
                self.tsMenu_mode = self.tsMenu.addItem(MenuStringList.new("Mode", {"Auto Priority", "Less Attack", "Less Cast", "Lowest HP", "Most AD", "Most AP", "Closest", "Closest to Mouse"}, 3))

                self.ts_prio = {}
                self.tsMenu.addItem(MenuSeparator.new("    Priority Settings", true))

                Callback.Add("Load", function()
                        for i, enemy in pairs(GetEnemyHeroes()) do
                                t.insert(self.ts_prio, { charName = GetAIHero(enemy).CharName, menu = self.tsMenu.addItem(MenuSlider.new(GetAIHero(enemy).CharName, self:GetDBPriority(GetAIHero(enemy).CharName), 1, 4, 1)) })
                        end
                end)
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
        local p2 = {"Aatrox", "Darius", "Elise", "Evelynn", "Galio", "Gangplank", "Gragas", "Irelia", "Jax", "Lee Sin", "Maokai", "Morgana", "Nocturne", "Pantheon", "Poppy", "Rengar", "Rumble", "Ryze", "Swain", "Trundle", "Tryndamere", "Udyr", "Urgot", "Vi", "XinZhao", "RekSai"}
        local p3 = {"Akali", "Diana", "Ekko", "Fiddlesticks", "Fiora", "Fizz", "Heimerdinger", "Jayce", "Kassadin", "Kayle", "Kha'Zix", "Lissandra", "Mordekaiser", "Nidalee", "Riven", "Shaco", "Vladimir", "Yasuo", "Zilean"}
        local p4 = {"Ahri", "Anivia", "Annie", "Ashe", "Azir", "Brand", "Caitlyn", "Cassiopeia", "Corki", "Draven", "Ezreal", "Graves", "Jinx", "Kalista", "Karma", "Karthus", "Katarina", "Kennen", "KogMaw", "Kindred", "Leblanc", "Lucian", "Lux", "Malzahar", "MasterYi", "MissFortune", "Orianna", "Quinn", "Sivir", "Syndra", "Talon", "Teemo", "Tristana", "TwistedFate", "Twitch", "Varus", "Vayne", "Veigar", "Velkoz", "Viktor", "Xerath", "Zed", "Ziggs", "Jhin", "Soraka"}
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

tsInst = TargetSelector(2000, 1, myHero, true, menuInst, true)
