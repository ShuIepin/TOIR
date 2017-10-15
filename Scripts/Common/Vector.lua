--[[
	Vector: Class {
		
		Vector(...) - initial call

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

-------------------------------------------------------------

Vector 		= {}  
Vector.meta1 	= {}          
Vector.meta2  	= {}      

-------------------------------------------------------------

local assert            = assert
local type 		= assert( type )   
local setmetatable 	= assert( setmetatable )
local getmetatable 	= assert( getmetatable )
local mathsqrt 		= assert( math.sqrt ) 
local mathsin 		= assert( math.sin ) 
local mathacos 		= assert( math.acos ) 
local rawget 		= assert( rawget ) 
local rawset 		= assert( rawset )

-------------------------------------------------------------

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
	return mathsqrt(Vector.Len2(self))
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
	local l = Vector.Len2(v) / Vector.Len2(self)
	return Vector.New(v * l)
end

function Vector:MirrorOn(v)
	return Vector.ProjectOn(self, v) * 2
end

function Vector:Sin(v)
	local c = Vector.CrossProduct(self, v)
	return mathsqrt(Vector.Len2(c) / ( Vector.Len2(self) * Vector.Len2(v) ))
end

function Vector:Cos(v)
	return Vector.Len2(self, v) / mathsqrt( Vector.Len2(self) * Vector.Len2(v) )
end

function Vector:Angle(v)
	return mathacos( Vector.Cos(self, v) )
end

function Vector:AffineArea(v)
	local c = Vector.CrossProduct(self, v)
	return mathsqrt( Vector.Len2(c) )
end

function Vector:TriangleArea(v)
	return Vector.AffineArea(self, v) / 2
end

function Vector:RotateX(phi)
	local cos, sin = mathcos(phi), mathsin(phi)
	self.y, self.z = self.y * cos - self.z * sin, self.z * cos + self.y * sin
end

function Vector:RotateY(phi)
	local cos, sin = mathcos(phi), mathsin(phi)
	self.x, self.z = self.x * cos + self.z * sin, self.z * cos - self.x * sin
end

function Vector:RotateZ(phi)
	local cos, sin = mathcos(phi), mathsin(phi)
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
	--
end

function Vector:AngleBetween(v1, v2)
	--
end

function Vector:Perpendicular()
	return Vector.New(-self.z, self.y, self.x)
end

function Vector:Perpendicular2()
	return Vector.New(self.z, self.y, -self.x)
end

-------------------------------------------------------------

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

-------------------------------------------------------------

setmetatable(Vector, Vector.meta2)

-------------------------------------------------------------
