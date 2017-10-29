local assert            = assert
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
local pairs		= assert( pairs )
local ipairs		= assert( ipairs )
local rawget 		= assert( rawget ) 
local rawset 		= assert( rawset )

-------------------------------------------------------------

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
                        :Extend(Vector, Distance) -> extends a vector towards a vector and returns it
                        :RotateAroundPoint(Vector, Angle) -> creates a new vector that is rotated around point
		Examples:
			local Player = function() return GetMyChamp() end
			function OnTick()
  				local myHeroPos = { GetPosX(Player()), GetPosY(Player()), GetPosZ(Player()) }
  				local mousePos = { GetCursorPosX(), GetCursorPosY(), GetCursorPosZ() }
  				local vec1 = Vector(myHeroPos)
  				local vec2 = Vector(mousePos)
  				local vecAdd = vec1 + vec2
  				local vecSub = vec2 - vec1
  				local vecMult = vec1 * 10
  				local vecDiv = vec / 10
  				__PrintTextGame( tostring( vec1 ) )
			end
	}
]]

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
  	return {x = self.x or 0, y = self.y or 0, z = self.z or 0}
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

function Vector:Polar()
	if math.close(self.x, 0, 0) then
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

setmetatable(Vector, Vector.meta2)

-------------------------------------------------------------

Point 		= {}
Point.meta1 	= {}
Point.meta2 	= {}

function Point.New(x, y, z)
  	local this = {}

  	if type(x) == 'table' then
    		this.x = x.x or x[1] or 0
    		this.y = (x.z and x.z ~= 0 and x.z < 999999 and x.z or x.y) or (x[3] and x[3] ~= 0 and x[3] < 999999 and x[3] or x[2])
  	else
    		this.x = x
            	this.y = z and z ~= 0 and z < 999999 and z or y
  	end

  	this.type 		= "Point"

  	this.Clone 		= Point.Clone
  	this.Addition 		= Point.Addition
  	this.Substract  	= Point.Substract
  	this.Multiply		= Point.Multiply
  	this.Divide		= Point.Divide
  	this.Equal 		= Point.Equal
  	this.ToString 		= Point.ToString
  	this.Len2 		= Point.Len2
  	this.Len 		= Point.Len
  	this.DistanceTo		= Point.DistanceTo

  	setmetatable(this, Point.meta1)

  	return this
end

function Point.meta2.__call(t, x, y, z)
  	return Point.New(x, y, z)
end

function Point.meta1:__index(k)
  	if type(k) == 'number' then
    		if k == 1 then 
    			return self.x
    		elseif k == 2 then
    			return self.y
    		end
  	end

  	rawget(self, k)
end

function Point.meta1:__newindex(k, v)
  	if type(k) == 'number' then
    		if k == 1 then
    			self.x = v
    		elseif k == 2 then
    			self.y = v
    		end
  	else
    		rawset(self, k, v)
  	end
end

function Point.meta1:__add(v)
  	return Point.Addition(Point.Clone(self), v)
end

function Point.meta1:__sub(v)
  	return Point.Substract(Point.Clone(self), v)
end

function Point.meta1:__unm()
  	return Point.New(-self.x, -self.y)
end

function Point.meta1:__mul(n)
	return Point.Multiply(Point.Clone(self), n)
end

function Point.meta1:__div(n)
  	return Point.Divide(Point.Clone(self), n)
end

function Point.meta1:__eq(v)
  	return Point.Equal(self, v)
end

function Point.meta1:__tostring()
  	return Point.ToString(self)
end

function Point:Clone()
  	return Point.New(self.x, self.y)
end

function Point:Addition(x, y)
  	if type(x) == 'table' then
    		self.x = self.x + (x.x or x[1] or 0)
    		self.y = self.y + (x.y or x[2] or 0)
    		return self
  	end

  	self.x = self.x + (x or 0)
  	self.y = self.y + (y or 0)
  	return self
end

function Point:Substract(x, y)
	if type(x) == 'table' then
    		self.x = self.x - (x.x or x[1] or 0)
    		self.y = self.y - (x.y or x[2] or 0)
    		return self
  	end

  	self.x = self.x - (x or 0)
  	self.y = self.y - (y or 0)
  	return self
end

function Point:Multiply(n)
  	self.x = self.x * (n or 0)
  	self.y = self.y * (n or 0)
  	return self
end

function Point:Divide(n)
  	self.x = self.x / (n or 0)
  	self.y = self.y / (n or 0)
  	return self
end

function Point:Equal(x, y)
  	local a, b

  	if type(x) == 'table' then
    		a = x.x or x[1] or 0
      		b = x.y or x[2] or 0
  	else
    		a = x or 0
    		b = y or 0
  	end

  	return self.x == a and self.y == b
end

function Point:ToString()
  	return "Point(" .. self.x .. ", " .. self.y .. ")"
end

function Point:Len2(p)
	local p = p and Point.New(p) or Point.Clone(self)
	return self.x * p.x + self.y * p.y
end

function Point:Len()
	return sqrt(Point.Len2(self))
end

function Point:DistanceTo(obj)
	if obj.type == "Point" then
		return (Point.Clone(self) - obj):Len()
	elseif obj.type == "Line" then
		return obj:DistanceTo(self)
	end
end

setmetatable(Point, Point.meta2)

-------------------------------------------------------------

Line 		= {}
Line.meta1 	= {}
Line.meta2 	= {}

function Line.New(p1, p2)
  	local this = {}

  	local a, b = p1, p2

  	if p1.type ~= "Point" then
  		a = Point(p1)
  	end

  	if p2.type ~= "Point" then
  		b = Point(p2)
  	end

  	this.type 		= "Line"
  	this.points 		= { a, b }

  	this.GetLineSegments 		= Line.GetLineSegments
  	this.Equal 			= Line.Equal
  	this.DistanceTo 		= Line.DistanceTo

  	setmetatable(this, Line.meta1)

  	return this
end

function Line.meta2.__call(t, x, y, z)
  	return Line.New(x, y, z)
end

function Line.meta1:__index(k)
  	if type(k) == 'number' then
    		if k == 1 then 
    			return self.p1
    		elseif k == 2 then
    			return self.p2
    		end
  	end

  	rawget(self, k)
end

function Line.meta1:__newindex(k, v)
  	if type(k) == 'number' then
    		if k == 1 then
    			self.p1 = v
    		elseif k == 2 then
    			self.p2 = v
    		end
  	else
    		rawset(self, k, v)
  	end
end

function Line.meta1:__eq(v)
  	return Line.Equal(self, v)
end

function Line:Equal(l)
	--
end

function Line:DistanceTo(obj)
	if obj.type == "Point" then
		local d = self.points[2].x - self.points[1].x

		if d == 0 then
			return abs(obj.x - self.points[2].x)
		end

		local m = (self.points[2].y - self.points[1].y) / d
		return abs((m * obj.x - obj.y + (self.points[1].y - m * self.points[1].x)) / sqrt(m * m + 1))
	elseif obj.type == "Line" then
		local d1 = self.points[1]:DistanceTo(obj)
		local d2 = self.points[2]:DistanceTo(obj)

		if d1 ~= d2 then
                	return 0 
            	else
                	return d1
            	end
	end
end

function Line:GetLineSegments()
	return { self }
end

setmetatable(Line, Line.meta2)

-------------------------------------------------------------

Spell 		= {}
Spell.meta1 	= {}
Spell.meta2 	= {}

function Spell.New(slot, range)
	local this = {}

	this.slot = slot
	this.range = range

	this.IsReady			= Spell.IsReady
	this.SetSkillShot		= Spell.SetSkillShot
	this.SetTargetted		= Spell.SetTargetted
	this.VPGetLineCastPosition	= Spell.VPGetLineCastPosition
	this.VPGetCircularCastPosition  = Spell.VPGetCircularCastPosition
	this.GetCollision		= Spell.GetCollision
	this.Cast 			= Spell.Cast

	setmetatable(this, Spell.meta1)

	return this
end

function Spell.meta2.__call(t, slot, range)
  	return Spell.New(slot, range)
end

function Spell.meta1:__index(k)
  	if type(k) == 'number' then
    		if k == 1 then 
    			return self.slot
    		elseif k == 2 then
    			return self.range
    		end
  	end

  	rawget(self, k)
end

function Spell.meta1:__newindex(k, v)
  	if type(k) == 'number' then
    		if k == 1 then
    			self.slot = v
    		elseif k == 2 then
    			self.range = v
    		end
  	else
    		rawset(self, k, v)
  	end
end

function Spell:IsReady()
	return CanCast(self.slot)
end

function Spell:SetSkillShot(delay, width, speed, type, collision)
	self.delay = delay or 0.25
	self.width = width or 0
	self.speed = speed or huge
	self.type = type or 0
	self.collision = collision or false
	self.isSkillshot = true
end

function Spell:SetTargetted(delay, speed)
	self.delay = delay or 0.25
	self.speed = speed or huge
	self.isTargetted = true
end

function Spell:VPGetLineCastPosition(target)
	local distance = GetDistance(target)
	local timeMissile = self.delay + distance / self.speed
	local realDistance = timeMissile * GetMoveSpeed(target)

	if realDistance == 0 then 
		return distance 
	end

	return realDistance
end

function Spell:VPGetCircularCastPosition(target)
	local distance = GetDistance(target)
	local timeMissile = self.delay
	local realDistance = timeMissile * GetMoveSpeed(target)

	if realDistance == 0 then
		if distance - self.width / 2 > 0 then
			return distance - self.width / 2
		end

		return distance
	end

	if realDistance - self.width / 2 > 0 then
		return realDistance - self.width / 2
	end
	
	return realDistance
end

function Spell:GetCollision(target, distance)
	local castPos = self.type == 0 and self:VPGetLineCastPosition(target) or self:VPGetCircularCastPosition(target)
	local distance = distance or castPos

	if self.collision then
		local count = 0
		local predPos = { x = GetPredictionPosX(target, distance), z = GetPredictionPosZ(target, distance) }
		local myPos = GetPos(UpdateHeroInfo())
		local targetPos = GetPos(target)

		if predPos.x ~= 0 and predPos.z ~= 0 then
			count = CountObjectCollision(0, target, myPos.x, myPos.z, predPos.x, predPos.z, self.width, self.range, 10)
		else
			count = CountObjectCollision(0, target, myPos.x, myPos.z, targetPos.x, targetPos.z, self.width, self.range, 10)
		end

		if count == 0 then
			return false
		end

		return true
	end

	return false
end

function Spell:Cast(target)
	if self.isSkillshot then
		local castPos = self.type == 0 and self:VPGetLineCastPosition(target) or self:VPGetCircularCastPosition(target)

		if castPos > 0 and castPos < self.range then
			if self.collision then
				if not self:GetCollision(target) then
					CastSpellToPredictionPos(target, self.slot, castPos)
				end
			else
				CastSpellToPredictionPos(target, self.slot, castPos)
			end
		end
	elseif self.isTargetted then
		CastSpellTarget(target, self.slot)
	else
		CastSpellTarget(target ~= 0 and target or UpdateHeroInfo(), self.slot)
	end
end

setmetatable(Spell, Spell.meta2)

-------------------------------------------------------------

function UpdateHeroInfo()
    	return GetMyChamp()
end

function print(...)
    	local t, len = {}, select("#", ...)

    	for i = 1, len do
        	local value = select(i, ...)
        	local type = type(value)

        	if type == "string" then 
        		t[i] = value
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

--> String

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

--> Math 

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

--> Table

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

--[[
	@GetPos (<function> : return <table>)
]]

function GetPos(unit)
	return Vector( GetPosX(unit), GetPosY(unit), GetPosZ(unit) ):ToArray()
end

--[[
	@GetCursorPos (<function> : return <table>)
]]

function GetCursorPos() 
	return Vector( GetCursorPosX(), GetCursorPosY(), GetCursorPosZ() ):ToArray()
end

--[[
	@GetDistance (<function> : return <number>): {

		@Arguments: {
			* p1 (<number> or <table>)
			* p2 [optional] (<number> or <table>)
		}

		@Example: {
			local pObj = GetEnemyChampCanKillFastest(1500)

			if pObj ~= 0 then
				print( GetDistance( pObj ) ) --> Will return the distance between pObj and your champion

				print( GetDistance( pObj, GetCursorPos() ) ) --> Will return the distance between pObj and your cursor position
			end
		}
	}

]]

function GetDistance(p1, p2)
	local p2 = p2 or UpdateHeroInfo()

	local x1, z1 = 0, 0

	if type(p1) == "number" then
		x1 = GetPosX(p1)
		z1 = GetPosZ(p1)
	elseif type(p1) == "table" then
		x1 = p1[1] or p1.x
		z1 = (p1[3] or p1[2]) or (p1.z or p1.y)
	end

	local x2, z2 = 0, 0

	if type(p2) == "number" then
		x2 = GetPosX(p2)
		z2 = GetPosZ(p2)
	elseif type(p2) == "table" then
		x2 = p2[1] or p2.x
		z2 = (p2[3] or p2[2]) or (p2.z or p2.y)
	end

	return GetDistance2D(x1, z1, x2, z2)
end

--[[
	@GetPercentHP (<function> : return <number>): {
		
		@Arguments: {
			* unit (<number>)
		}
	}
]]

function GetPercentHP(unit)
	return GetHealthPoint(unit) / GetHealthPointMax(unit) * 100
end

--[[
	@GetPercentMP (<function> : return <number>): {
		
		@Arguments: {
			* unit (<number>)
		}
	}
]]

function GetPercentMP(unit)
	return GetManaPoint(unit) / GetManaPointMax(unit) * 100
end

--[[
	@IsValidTarget (<function> : return <boolean>): {

		@Arguments: {
			* unit (<number>)
			* range [optional] (<number>)
		}

		@Example: {
			local pObj = GetEnemyChampCanKillFastest(1500)

			if pObj ~= 0 then
				print( IsValidTarget( pObj, 1500 ) ) --> Will return true if pObj is valid in 1500 range or false if not
			end 
		}
	}

]]

function IsValidTarget(unit, range)
	local range = range or huge
	return unit ~= 0 and not IsDead(unit) and not IsInFog(unit) and GetTargetableToTeam(unit) == 4 and IsEnemy(unit) and GetDistance(unit) <= range
end

--[[
	@IsUnderEnemyTurret (<function> : return <boolean>): {

		@Arguments: {
			* unit (<number>)
			* searchRange [optional] (<number>)
		}
	}
]]

function IsUnderEnemyTurret(unit, searchRange)
	local searchRange = searchRange or 20000
	GetAllObjectAroundAnObject(UpdateHeroInfo(), searchRange)

	local objects = pObject	
	for i, object in pairs(objects) do
		if IsTurret(object) and not IsDead(object) and IsEnemy(object) and GetTargetableToTeam(object) == 4 then
			if GetDistance( object, unit ) <= 915 then
				return true
			end	
		end
	end

	return false
end

--[[
	@IsUnderaAllyTurret (<function> : return <boolean>): {

		@Arguments: {
			* unit (<number>)
			* searchRange [optional] (<number>)
		}
	}
]]

function IsUnderAllyTurret(unit, searchRange)
	local searchRange = searchRange or 20000
	GetAllObjectAroundAnObject(UpdateHeroInfo(), searchRange)

	local objects = pObject	
	for i, object in pairs(objects) do
		if IsTurret(object) and not IsDead(object) and IsAlly(object) and GetTargetableToTeam(object) == 4 then
			if GetDistance( object, unit ) <= 915 then
				return true
			end	
		end
	end

	return false
end

--[[

local W = Spell(0, 950)
W:SetSkillShot(0.25, 100, 1500, 0, true)


function OnTick()

	local myPoint1 = Point( GetPos( UpdateHeroInfo() ) )
	local myPoint2 = Point( GetCursorPos() )

	local myPoint3 = Point( GetPos( UpdateHeroInfo() ) ) + { x = 5000, y = 150 }
	local myPoint4 = Point( GetCursorPos() ) - { x = 500, y = 150 }

	local myLine1 = Line( myPoint1, myPoint2 ) 
	local myLine2 = Line( myPoint3, myPoint4 ) 

	print( myLine1:DistanceTo(myLine2) )

end ]]
