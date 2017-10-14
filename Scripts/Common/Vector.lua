--[[
	Vector: Class {
		
		Vector(...) - initial call

		properties:
			.x  ->  the x value
			.y  ->  the y value
			.z  ->  the z value

		functions:
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

	}
]]


--> Requirements

local Class = IncludeFile("Class.lua")

--> Vector Class

local Vector = Class("Vector")

--> Vector Class: Initialize

function Vector:__init(x, y, z)
	self.type = "Vector"

	if x < 20000 then
		self.x = x or 0
		self.y = y or 0
		self.z = z or 0
	else
		self.x = GetPosX(x) or 0
		self.y = GetPosY(x) or 0
		self.z = GetPosZ(x) or 0
	end
end

--> Vector Class: Operators

function Vector:__tostring()
	return "Vector(" .. self.x .. ", " .. self.y .. ", " .. self.z .. ")"
end

function Vector:__add()
	-- body
end

function Vector:__sub()
	-- body
end

function Vector:__mul()
	-- body
end

function Vector:__div()
	-- body
end

function Vector:__lt()
	-- body
end

function Vector:__le()
	-- body
end

function Vector:__eq()
	-- body
end

function Vector:__unm()
	-- body
end

--> Vector Class: Methods

function Vector:Clone()
	-- body
end

function Vector:Unpack()
	-- body
end

function Vector:DistanceTo()
	-- body
end

function Vector:Len()
	-- body
end

function Vector:Len2()
	-- body
end

function Vector:Normalize()
	-- body
end

function Vector:Normalized()
	-- body
end

function Vector:Center()
	-- body
end

function Vector:CrossProduct()
	-- body
end

function Vector:DotProduct()
	-- body
end

function Vector:ProjectOn()
	-- body
end

function Vector:MirrorOn()
	-- body
end

function Vector:Sin()
	-- body
end

function Vector:Cos()
	-- body
end

function Vector:Angle()
	-- body
end

function Vector:AffineArea()
	-- body
end

function Vector:TriangleArea()
	-- body
end

function Vector:RotateX()
	-- body
end

function Vector:RotateY()
	-- body
end

function Vector:RotateZ()
	-- body
end

function Vector:Rotate()
	-- body
end

function Vector:Rotated()
	-- body
end

function Vector:Polar()
	-- body
end

function Vector:AngleBetween()
	-- body
end

function Vector:Perpendicular()
	-- body
end

function Vector:Perpendicular2()
	-- body
end