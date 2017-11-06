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
local open 		= assert( io.open )
local close  		= assert( io.close )

--> Globals

SCRIPT_PATH = GetScriptPath()

--> IO

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

function printDebug(...)
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
		__PrintDebug("[TOIR_DEBUG]" .. concat(t)) 
	end
end

--> String (lua.org)

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

--> Math (lua.org)

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

--> Table (lua.org)

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

