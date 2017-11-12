local assert = assert
local type 		= assert( type ) 
local next		= assert( next )
local select 		= assert( select )
local setmetatable 	= assert( setmetatable )
local getmetatable 	= assert( getmetatable )
local huge		= assert( math.huge )
local floor		= assert( math.floor )
local ceil 		= assert( math.ceil )
local abs           	= assert( math.abs )
local deg           	= assert( math.deg )
local atan          	= assert( math.atan )
local sqrt 		= assert( math.sqrt ) 
local sin 		= assert( math.sin ) 
local cos 		= assert( math.cos ) 
local acos 		= assert( math.acos ) 
local max 		= assert( math.max )
local min 		= assert( math.min )
local format		= assert( string.format )
local concat      	= assert( table.concat )
local insert 		= assert( table.insert )
local remove 		= assert( table.remove )
local pairs		= assert( pairs )
local ipairs		= assert( ipairs )
local rawget 		= assert( rawget ) 
local rawset 		= assert( rawset )
local open 		= assert( io.open )
local close  		= assert( io.close )
local unpack 		= assert( unpack )

----------------</GLOBALS>----------------

_G.myHero = GetMyHero()

----------------</CALLBACKS>----------------

Callback = {}

local Callbacks = {
	["Load"] 	 = {},
	["Tick"] 	 = {},
	["Update"] 	 = {},
	["Draw"] 	 = {},
	["UpdateBuff"]   = {},
	["RemoveBuff"]   = {},
	["ProcessSpell"] = {},
	["CreateObject"] = {},
	["DeleteObject"] = {},
}

Callback.Add = function(type, cb) insert(Callbacks[type], cb) end
Callback.Del = function(type, id) remove(Callbacks[type], id or 1) end

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
			cb(unit, {
				addr = spell,
				name = GetName_Casting(spell),
				owner = GetOwnerID_Casting(spell),
				target = GetTargetID_Casting(spell),
				startPos = { x = GetSrcPosX_Casting(spell), y = GetSrcPosY_Casting(spell), z = GetSrcPosZ_Casting(spell) },
				endPos = { x = GetDestPosX_Casting(spell), y = GetDestPosY_Casting(spell), z = GetDestPosZ_Casting(spell) },
				cursorPos = { x = GetCursorPosX_Casting(spell), y = GetCursorPosY_Casting(spell), z = GetCursorPosZ_Casting(spell) },
				delay = GetDelay_Casting(spell),
				time = GetTimeGame()
			})
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

----------------</STRING>----------------

function string.join(arg, del)
	return concat(arg, del)
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

----------------</MATH>----------------

function math.round(num, idp)
	local mult = 10 ^ (idp or 0)

	if num >= 0 then 
		return floor(num * mult + 0.5) / mult
	else 
		return ceil(num * mult - 0.5) / mult
	end
end

function math.close(a, b, eps)
	eps = eps or 1e-9
	return abs(a - b) <= eps
end

function math.limit(val, min, max)
	return min(max, max(min, val))
end

----------------</TABLE>----------------

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
		    	return format("%q", ts)
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

					      local fname = format("%s[%s]", name, k)
					      field = format("[%s]", k)
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

----------------</VECTOR>----------------

Vector 		= {}
Vector.meta1 	= {}
Vector.meta2  	= {}

function Vector.New(x, y, z)
  	local this = {}

  	if type(x) == 'table' then
    		if Vector.IsVector(x) then
      			this.x = x.x or 0
      			this.y = x.y or 0
      			this.y = x.z or 0
    		else
      			this.x = x[1] or 0
      			this.y = x[2] or 0
      			this.z = x[3] or 0
    		end
  	else
    		this.x = x or 0
    		this.y = y or 0
    		this.z = z or 0
  	end

  	this.Set 		= Vector.Set
  	this.Type 		= Vector.Type
  	this.Clone 		= Vector.Clone
  	this.Unpack 		= Vector.Unpack
  	this.ToString 		= Vector.ToString
  	this.ToArray 		= Vector.ToArray
  	this.Addition 		= Vector.Addition
  	this.Substract 		= Vector.Substract
  	this.Multiply 		= Vector.Multiply
  	this.Divide		= Vector.Divide
  	this.Equal 		= Vector.Equal
  	this.LessThan 		= Vector.LessThan
  	this.LessOrEqual	= Vector.LessOrEqual
  	this.Len 		= Vector.Len
  	this.Len2 		= Vector.Len2
  	this.DistanceTo         = Vector.DistanceTo
  	this.Normalize          = Vector.Normalize
  	this.Normalized         = Vector.Normalized
  	this.Center             = Vector.Center
  	this.CrossProduct	= Vector.CrossProduct
  	this.DotProduct 	= Vector.DotProduct
  	this.ProjectOn		= Vector.ProjectOn
  	this.MirrorOn		= Vector.MirrorOn
  	this.Sin 		= Vector.Sin
  	this.Cos 		= Vector.Cos
  	this.Angle 		= Vector.Angle
  	this.AffineArea 	= Vector.AffineArea
  	this.TriangleArea       = Vector.TriangleArea
  	this.RotateX		= Vector.RotateX
  	this.RotateY		= Vector.RotateY
  	this.RotateZ		= Vector.RotateZ
  	this.Rotate 		= Vector.Rotate
  	this.Rotated 		= Vector.Rotated
  	this.Polar 		= Vector.Polar
  	this.AngleBetween 	= Vector.AngleBetween
  	this.Perpendicular  	= Vector.Perpendicular
  	this.Perpendicular2 	= Vector.Perpendicular2
        this.Extend             = Vector.Extend
        this.RotateAroundPoint  = Vector.RotateAroundPoint

  	setmetatable(this, Vector.meta1)

  	return this
end

function Vector:Set(x, y, z)
  	if type(x) == 'table' then
    		if Vector.IsVector(x) then
      			self.x = x.x or 0
      			self.y = x.y or 0
      			self.y = x.z or 0
      			return self
    		end

    		self.x = x[1] or 0
    		self.y = x[2] or 0
    		self.z = x[3] or 0
    		return self
  	end

  	self.x = x or 0
  	self.y = y or 0
  	self.z = z or 0
  	return self
end

function Vector:Type()
	return "vector"
end

function Vector:Clone()
  	return Vector.New(self.x, self.y, self.z)
end

function Vector:Unpack()
	return self.x, self.y, self.z
end

function Vector:ToString()
  	return "Vector(" .. self.x .. ", " .. self.y .. ", " .. self.z .. ")"
end

function Vector:ToArray()
  	return {self.x or 0, self.y or 0, self.z or 0}
end

function Vector.IsVector(self)
  	return getmetatable(self) == getmetatable(Vector)
end

function Vector:Addition(x, y, z)
  	if type(x) == 'table' then
    		if Vector.IsVector(x) then
      			self.x = self.x + (x.x or 0)
      			self.y = self.y + (x.y or 0)
      			self.y = self.y + (x.z or 0)
      			return self
    		end

    		self.x = self.x + (x[1] or 0)
    		self.y = self.y + (x[2] or 0)
    		self.z = self.z + (x[3] or 0)
    		return self
  	end

  	self.x = self.x + (x or 0)
  	self.y = self.y + (y or 0)
  	self.z = self.z + (z or 0)
  	return self
end

function Vector:Substract(x, y, z)
  	if type(x) == 'table' then
    		if Vector.IsVector(x) then
      			self.x = self.x - (x.x or 0)
      			self.y = self.y - (x.y or 0)
      			self.z = self.z - (x.z or 0)
      			return self
    		end

    		self.x = self.x - (x[1] or 0)
    		self.y = self.y - (x[2] or 0)
    		self.z = self.z - (x[3] or 0)
    		return self
  	end

  	self.x = self.x - (x or 0)
  	self.y = self.y - (y or 0)
  	self.z = self.z - (z or 0)
  	return self
end

function Vector:Multiply(n)
  	self.x = self.x * (n or 0)
  	self.y = self.y * (n or 0)
  	self.z = self.z * (n or 0)
  	return self
end

function Vector:Divide(n)
  	self.x = self.x / (n or 0)
  	self.y = self.y / (n or 0)
  	self.z = self.z / (n or 0)
  	return self
end

function Vector:Exponentiation(n)
  	self.x = self.x ^ (n or 0)
  	self.y = self.y ^ (n or 0)
  	self.z = self.z ^ (n or 0)
  	return self
end

function Vector:Equal(x, y, z)
  	local a, b, c

  	if type(x) == 'table' then
    		if Vector.IsVector(x) then
      			a = x.x or 0
      			b = x.y or 0
      			c = x.z or 0
    		else
      			a = x[1] or 0
      			b = x[2] or 0
      			c = x[3] or 0
    		end
  	else
    		a = x or 0
    		b = y or 0
    		c = z or 0
  	end

  	return self.x == a and self.y == b and self.z == c
end

function Vector:LessThan(x, y, z)
  	if type(x) == 'table' then
    		return Vector.Len(self) < Vector.Len(x)
  	end

  	return Vector.Len(self) < x
end

function Vector:LessOrEqual(x, y, z)
  	if type(x) == 'table' then
    		return Vector.Len(self) <= Vector.Len(x)
  	end

  	return Vector.Len(self) <= x
end

function Vector:Len2(v)
	local v = v and Vector.New(v) or Vector.Clone(self)
	return self.x * v.x + self.y * v.y + self.z * v.z
end

function Vector:Len()
	return sqrt(Vector.Len2(self))
end

function Vector:DistanceTo(v)
	local d = Vector.Clone(self) - v
	return d:Len()
end

function Vector:Normalize()
	local l = Vector.Len(self)
	Vector.Divide(self, l)
end

function Vector:Normalized()
	local v = Vector.Clone(self)
	v:Normalize()
	return v
end

function Vector:Center(v)
	local c = Vector.Clone(self)

	return Vector.New((c + v) / 2)
end

function Vector:CrossProduct(v)
	return Vector.New(self.y * v.z - self.z * v.y, self.z * v.x - self.x * v.z, self.x * v.y - self.y * v.x)
end

function Vector:DotProduct(v)
	return self.x * v.x + self.y * v.y + self.z * v.z
end

function Vector:ProjectOn(v)
	local l = Vector.Len2(self, v) / Vector.Len2(v)
	return Vector.New(v * l)
end

function Vector:MirrorOn(v)
	return Vector.ProjectOn(self, v) * 2
end

function Vector:Sin(v)
	local c = Vector.CrossProduct(self, v)
	return sqrt(Vector.Len2(c) / ( Vector.Len2(self) * Vector.Len2(v) ))
end

function Vector:Cos(v)
	return Vector.Len2(self, v) / sqrt( Vector.Len2(self) * Vector.Len2(v) )
end

function Vector:Angle(v)
	return acos( Vector.Cos(self, v) )
end

function Vector:AffineArea(v)
	local c = Vector.CrossProduct(self, v)
	return sqrt( Vector.Len2(c) )
end

function Vector:TriangleArea(v)
	return Vector.AffineArea(self, v) / 2
end

function Vector:RotateX(phi)
	local cos, sin = cos(phi), sin(phi)
	self.y, self.z = self.y * cos - self.z * sin, self.z * cos + self.y * sin
end

function Vector:RotateY(phi)
	local cos, sin = cos(phi), sin(phi)
	self.x, self.z = self.x * cos + self.z * sin, self.z * cos - self.x * sin
end

function Vector:RotateZ(phi)
	local cos, sin = cos(phi), sin(phi)
	self.x, self.y = self.x * cos - self.z * sin, self.y * cos + self.x * sin
end

function Vector:Rotate(phiX, phiY, phiZ)
	if phiX ~= 0 then Vector.RotateX(self, phiX) end
    	if phiY ~= 0 then Vector.RotateY(self, phiY) end
    	if phiZ ~= 0 then Vector.RotateZ(self, phiZ) end
end

function Vector:Rotated(phiX, phiY, phiZ)
	local v = Vector.Clone(self)
	v:Rotate(phiX, phiY, phiZ)
	return v
end

local epsilon = 1e-9
local function Close(a, b, eps)
        if abs(eps) < epsilon then
                eps = 1e-9
        end

        return abs(a - b) <= eps
end

function Vector:Polar()
	if Close(self.x, 0, 0) then
                if self.z or self.y > 0 then
                        return 90
                end

                return (self.z or self.y) < 0 and 270 or 0
        end

        local theta = deg(atan((self.z or self.y) / self.x))

        if self.x < 0 then
                theta = theta + 180
        end

        if theta < 0 then
                theta = theta + 360
        end

        return theta
end

function Vector:AngleBetween(v1, v2)
        local p1, p2 = (-self + v1), (-self + v2)
	local theta = Vector.Polar(p1) - Vector.Polar(p2)

        if theta < 0 then
                theta = theta + 360
        end

        if theta > 180 then
                theta = 360 - theta
        end

        return theta
end

function Vector:Perpendicular()
	return Vector.New(-self.z, self.y, self.x)
end

function Vector:Perpendicular2()
	return Vector.New(self.z, self.y, -self.x)
end

function Vector:Extend(to, distance)
        return self + Vector.Normalized(to - self) * distance
end

function Vector:RotateAroundPoint(v, angle)
        local cos, sin = cos(angle), sin(angle)
        local x = ((self.x - v.x) * cos) - ((v.y - self.y) * sin) + v.x
        local y = ((v.y - self.y) * cos) + ((self.x - v.x) * sin) + v.y
        return Vector.New(x, y, self.z or 0)
end

function Vector.meta2.__call(t, x, y, z)
  	return Vector.New(x, y, z)
end

function Vector.meta1:__index(k)
  	if type(k) == 'number' then
    		if k == 1 then return
			self.x
    		elseif k == 2 then
    			return self.y
    		elseif k == 3 then
    			return self.z
    		end
  	end

  	rawget(self, k)
end

function Vector.meta1:__newindex(k, v)
  	if type(k) == 'number' then
    		if k == 1 then
    			self.x = v
    		elseif k == 2 then
    			self.y = v
    		elseif k == 3 then
    			self.z = v
    		end
  	else
    		rawset(self, k, v)
  	end
end

function Vector.meta1:__add(v)
  	return Vector.Addition(Vector.Clone(self), v)
end

function Vector.meta1:__sub(v)
  	return Vector.Substract(Vector.Clone(self), v)
end

function Vector.meta1:__unm()
  	return Vector.New(-self.x, -self.y, -self.z)
end

function Vector.meta1:__mul(n)
  	return Vector.Multiply(Vector.Clone(self), n)
end

function Vector.meta1:__div(n)
  	return Vector.Divide(Vector.Clone(self), n)
end

function Vector.meta1:__pow(n)
  	return Vector.Exponentiation(Vector.Clone(self), n)
end

function Vector.meta1:__eq(v)
  	return Vector.Equal(self, v)
end

function Vector.meta1:__lt(v)
  	return Vector.LessThan(self, v)
end

function Vector.meta1:__le(v)
  	return Vector.LessOrEqual(self, v)
end

function Vector.meta1:__tostring()
  	return Vector.ToString(self)
end

setmetatable(Vector, Vector.meta2)

----------------</COMMON>----------------

function FileExists(path)
	local f = open(path, "r")

	if f then 
		close(f) 
		return true 
	else 
		return false 
	end
end

function WriteFile(text, path, mode)
	local f = open(path, mode or "w+")

	if not f then
		return false
	end

	f:write(text)
	f:close()
	return true
end

function ReadFile(path)
	local f = open(path, "r")

	if not f then
		return "WRONG PATH"
	end

	local text = f:read("*all")
	f:close()
	return text
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
		insert(delayedActions[time], { func = func, args = args })
	else 
		delayedActions[time] = { { func = func, args = args } }
	end
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
	local t, len = {}, select("#", ...)

	for i = 1, len do
	    	local value = select(i, ...)
	    	local type = ctype(value)

	    	if type == "string" then 
		    	t[i] = value
		elseif type == "vector" then
			t[i] = tostring(value)
	    	elseif type == "number" then 
		    	t[i] = tostring(value)
	    	elseif type == "table" then 
		    	t[i] = table.serialize(value)
	    	elseif type == "boolean" then 
		    t[i] = value and "true" or "false"
	    	else 
		    t[i] = "<" .. type .. ">"
		end
	end

	if len > 0 then 
		__PrintTextGame(concat(t)) 
	end
end 

function printDebug(...)
	local t, len = {}, select("#", ...)

	for i = 1, len do
	    	local value = select(i, ...)
	    	local type = ctype(value)

	    	if type == "string" then 
		    	t[i] = value
		elseif type == "vector" then
			t[i] = tostring(value)
	    	elseif type == "number" then 
		    	t[i] = tostring(value)
	    	elseif type == "table" then 
		    	t[i] = table.serialize(value)
	    	elseif type == "boolean" then 
		    t[i] = value and "true" or "false"
	    	else 
		    t[i] = "<" .. type .. ">"
		end
	end

	if len > 0 then 
		__PrintDebug("[TOIR_DEBUG]" .. concat(t)) 
	end
end

function IsAfterAttack()
        if CanMove() and not CanAttack() then
                return true
        else
                return false
        end
end

function GetPredictionPos(unit)
        if type(unit) == "number" then
                return { x = GetPredictionPosX(unit), y = GetPredictionPosY(unit), z = GetPredictionPosZ(unit) }
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
        return GetLatency()/1000
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

function IsValidTarget(unit, range)
	local range = range or huge
	return unit ~= 0 and not IsDead(unit) and not IsInFog(unit) and GetTargetableToTeam(unit) == 4 and IsEnemy(unit) and GetDistance(GetOrigin(unit)) <= range
end

function WorldToScreen(x, y, z)
	local scrX, scrY = 0, 0

	if type(x) == "table" then
		scrX = GetScreenPosX_FromWolrdPos(x.x, x.y, x.z)
		scrY = GetScreenPosY_FromWolrdPos(x.x, x.y, x.z)
	else
		scrX = GetScreenPosX_FromWolrdPos(x, y, z)
		scrY = GetScreenPosY_FromWolrdPos(x, y, z)
	end

	return { x = scrX, y = scrY }
end

function GetMousePos()
	return { x = GetCursorPosX(), y = GetCursorPosY(), z = GetCursorPosZ() }
end

function GetCursorPos()
	return WorldToScreen(GetMousePos())
end

local function GetHeroes()
	SearchAllChamp()
	local t = pObjChamp
	return t
end

function GetEnemyHeroes()
	local t = {}
	local h = GetHeroes()
	for k, v in pairs(h) do
		if IsEnemy(v) and IsChampion(v) then
			insert(t, v)
		end
	end
	return t
end

function GetAllyHeroes()
	local t = {}
	local h = GetHeroes()
	for k, v in pairs(h) do
		if IsAlly(v) and IsChampion(v) then
			insert(t, v)
		end
	end
	return t
end

function GetAllHeroes()
        local t = {}
        local h = GetHeroes()
        for k, v in pairs(h) do
                if IsChampion(v) then
                        insert(t, v)
                end
        end
        return t
end

----------------</DRAW>----------------

local function DrawLines(t, c)
	for i = 1, #t - 1 do
		if t[i].x > 0 and t[i].y > 0 and t[i+1].x > 0 and t[i+1].y > 0 then
			DrawLineD3DX(t[i].x, t[i].y, t[i+1].x, t[i+1].y, c)
		end
	end
end

function DrawCircle(x, y, z, radius, color)
	if type(x) == "table" then
		local pos = GetOrigin(x)
		local radius = y or 250
		local color = z or Lua_ARGB(255, 255, 255, 255)
		return DrawCircleGame(pos.x, pos.y, pos.z, radius, color)
	elseif type(x) == "number" then
		local radius = radius or 250
		local color = color or Lua_ARGB(255, 255, 255, 255)
		return DrawCircleGame(x, y, z, radius, color)
	end
end

function DrawCircle2D(x, y, radius, quality,color)
	local quality, radius = quality and 2 * math.pi / quality or 2 * math.pi / 20, radius or 50
	local points = {}
	for theta = 0, 2 * math.pi + quality, quality do
		points[#points + 1] = Vector(x + radius * math.cos(theta), y - radius * math.sin(theta))
	end
	DrawLines(points, color or Lua_ARGB(255, 255, 255, 255))
end

function DrawCircle3D(x, y, z, radius, quality, color)
	local radius = radius or 300
	local quality = quality and 2 * math.pi / quality or 2 * math.pi / (radius / 5)
	local points = {}
	for theta = 0, 2 * math.pi + quality, quality do
		local c = WorldToScreen(x + radius * math.cos(theta), y, z - radius * math.sin(theta))
		points[#points + 1] = Vector(c.x, c.y)
	end
	DrawLines(points, color or Lua_ARGB(255, 255, 255, 255))
end

----------------</UPDATE>----------------

Callback.Add("Draw", function()
	_G.myHero = GetMyHero()
end)

