--[[
        Vector: Class {
                Vector(...) - initial call:
                        local myVec = Vector(<table> or <number>, <number>, <number>)
                properties:
                        .x  ->  the x value
                        .y  ->  the y value
                        .z  ->  the z value
                functions:
                        :Set(x, y, z) -> sets x, y, z
                        :Clone() -> returns a new vector
                        :Unpack() -> returns x, y, z
                        :DistanceTo(Vector) -> returns distance to another vector
                        :Len() -> returns length
                        :Len2() -> returns squared length
                        :Normalize() -> normalizes a vector
                        :Normalized() -> creates a new vector, normalizes it and returns it
                        :Center(Vector) -> center between 2 vectors
                        :CrossProduct(Vector) -> cross product of 2 vectors
                        :DotProduct(Vector) -> dot product of 2 vectors
                        :ProjectOn(Vector) -> projects a vector on a vector
                        :MirrorOn(Vector) -> mirrors a vector on a vector
                        :Sin(Vector) -> calculates sin of 2 vector
                        :Cos(Vector) -> calculates cos of 2 vector
                        :Angle(Vector) -> calculates angle between 2 vectors
                        :AffineArea(Vector) -> calculates area between 2 vectors
                        :TriangleArea(Vector) -> calculates triangular area between 2 vectors
                        :RotateX(phi) -> rotates vector by phi around x axis
                        :RotateY(phi) -> rotates vector by phi around y axis
                        :RotateZ(phi) -> rotates vector by phi around z axis
                        :Rotate(phiX, phiY, phiZ) -> rotates vector
                        :Rotated(phiX, phiY, phiZ) -> creates a new vector, rotates it and returns it
                        :Polar() -> returns polar value
                        :AngleBetween(Vector, Vector) -> returns the angle formed from a vector to both input vectors
                        :Perpendicular() -> creates a new vector that is rotated 90° right
                        :Perpendicular2() -> creates a new vector that is rotated 90° left
                        :Extended(Vector, Distance) -> extends a vector towards a vector and returns it
        }
]]

--[[
  ____                  _ ____            
 / ___|  __ _ _ __   __| | __ )  _____  __
 \___ \ / _` | '_ \ / _` |  _ \ / _ \ \/ /
  ___) | (_| | | | | (_| | |_) | (_) >  < 
 |____/ \__,_|_| |_|\__,_|____/ \___/_/\_\
                                          
--]]


--Main functions
local assert = assert
local getmetatable = assert(getmetatable)
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

--Table Library
local t = {}
t.concat = assert(table.concat)
t.insert = assert(table.insert)
t.remove = assert(table.remove)
t.sort = assert(table.sort)

--String Library
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

--Math Library
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

--IO Library
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

--[[
 __     __        _             
 \ \   / /__  ___| |_ ___  _ __ 
  \ \ / / _ \/ __| __/ _ \| '__|
   \ V /  __/ (__| || (_) | |   
    \_/ \___|\___|\__\___/|_|   
                                
--]]

_G.Vector = classInstance()

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
        return "Vector(" .. self.x .. ", " .. self.y .. ", " .. self.z .. ")"
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
        return self:Len2(v) / sqrt(self:Len2() * v:Len2())
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
        local v2D = WorldToScreen(v.x, v.y, v.z)
        return Vector(v2D.x, v2D.y)
end
