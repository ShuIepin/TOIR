local assert            = assert
local V                 = assert( _VERSION )
local setmetatable      = assert( setmetatable )
local select            = assert( select )
local pairs             = assert( pairs )
local ipairs            = assert( ipairs )
local type              = assert( type )
local error             = assert( error )
local load              = assert( load )
local s_rep             = assert( string.rep )
local t_unpack          = assert( V == "Lua 5.1" and unpack or table.unpack )

local allowed_metamethods = {
        __add = true,
        __sub = true, 
        __mul = true, 
        __div = true,
        __mod = true,
        __pow = true, 
        __unm = true, 
        __concat = true,
        __len = true,
        __eq = true, 
        __lt = true, 
        __le = true,
        __call = true,
        __tostring = true, 
        __pairs = true, 
        __ipairs = true, 
        __gc = true,
        __newindex = true, 
        __metatable = true, 
        __idiv = true, 
        __band = true,
        __bor = true, 
        __bxor = true, 
        __bnot = true, 
        __shl = true,
        __shr = true,
}

local mode_k_meta = { __mode = "k" }

local classinfo = setmetatable( {}, mode_k_meta )

local function default_constructor( meta )
        return function()
                return setmetatable( {}, meta )
        end
end

local function init_constructor( meta, init )
        return function( _, ... )
                local o = setmetatable( {}, meta )
                init( o, ... )
                return o
        end
end

local function propagate_update( cls, key )
        local info = classinfo[ cls ]
        if info.members[ key ] ~= nil then
                info.o_meta.__index[ key ] = info.members[ key ]
        else
                for i = 1, #info.super do
                        local val = classinfo[ info.super[ i ] ].members[ key ]
                        if val ~= nil then
                                info.o_meta.__index[ key ] = val
                                return
                        end
                end
                info.o_meta.__index[ key ] = nil
        end
end

local function class_newindex( cls, key, val )
        local info = classinfo[ cls ]
        if allowed_metamethods[ key ] then
                assert( info.o_meta[ key ] == nil,
                        "overwriting metamethods not allowed" )
                info.o_meta[ key ] = val
        elseif key == "__init" then
                info.members.__init = val
                info.o_meta.__index.__init = val
                if type( val ) == "function" then
                        info.c_meta.__call = init_constructor( info.o_meta, val )
                else
                        info.c_meta.__call = default_constructor( info.o_meta )
                end
        else
                assert( key ~= "__class", "key '__class' is reserved" )
                info.members[ key ] = val
                propagate_update( cls, key )
                for sub in pairs( info.sub ) do
                        propagate_update( sub, key )
                end
        end
end

local function class_pairs( cls )
        return pairs( classinfo[ cls ].o_meta.__index )
end

local function class_ipairs( cls )
        return ipairs( classinfo[ cls ].o_meta.__index )
end

local function linearize_ancestors( cls, super, ... )
        local n = select( '#', ... )
        for i = 1, n do
                local pcls = select( i, ... )
                assert( classinfo[ pcls ], "invalid class" )
                super[ i ] = pcls
        end
        super.n = n
        local diff, newn = 1, n
        for i,p in ipairs( super ) do
                local pinfo = classinfo[ p ]
                local psuper, psub = pinfo.super, pinfo.sub
                if not psub[ cls ] then psub[ cls ] = diff end
                for i = 1, psuper.n do
                        super[ #super+1 ] = psuper[ i ]
                end
                newn = newn + psuper.n
                if i == n then
                        n, diff = newn, diff+1
                end
        end
end

local function create_class( _, name, ... )
        assert( type( name ) == "string", "class name must be a string" )
        local cls, index = {}, {}
        local o_meta = {
                __index = index,
                __name = name,
        }
        local info = {
                name = name,
                super = { n = 0 },
                sub = setmetatable( {}, mode_k_meta ),
                members = {},
                o_meta = o_meta,
                c_meta = {
                        __index = index,
                        __newindex = class_newindex,
                        __call = default_constructor( o_meta ),
                        __pairs = class_pairs,
                        __ipairs = class_ipairs,
                        __name = "class",
                        __metatable = false,
                },
        }
        linearize_ancestors( cls, info.super, ... )
        for i = #info.super, 1, -1 do
                for k,v in pairs( classinfo[ info.super[ i ] ].members ) do
                        if k ~= "__init" then index[ k ] = v end
                end
        end
        index.__class = cls
        classinfo[ cls ] = info
        return setmetatable( cls, info.c_meta )
end

local M = {}
setmetatable( M, { __call = create_class } )

function M.of( o )
        return type( o ) == "table" and o.__class or nil
end

function M.name( oc )
        if oc == nil then return nil end
        oc = type( oc ) == "table" and oc.__class or oc
        local info = classinfo[ oc ]
        return info and info.name
end

function M.is_a( oc, cls )
        if oc == nil then return nil end
        local info = assert( classinfo[ cls ], "invalid class" )
        oc = type( oc ) == "table" and oc.__class or oc
        if oc == cls then return 0 end
        return info.sub[ oc ]
end

function M.cast( o, newcls )
        local info = classinfo[ newcls ]
        if not info then
                error( "invalid class" )
        end
        setmetatable( o, info.o_meta )
        return o
end

local function make_delegate( cls, field, method )
        cls[ method ] = function( self, ... )
                local obj = self[ field ]
                return obj[ method ]( obj, ... )
        end
end

function M.delegate( cls, fieldname, ... )
        if type( (...) ) == "table" then
                for k,v in pairs( (...) ) do
                        if cls[ k ] == nil and k ~= "__init" and
                                type( v ) == "function" then
                                make_delegate( cls, fieldname, k )
                        end
                end
        else
                for i = 1, select( '#', ... ) do
                        local k = select( i, ... )
                        if cls[ k ] == nil and k ~= "__init" then
                                make_delegate( cls, fieldname, k )
                        end
                end
        end
        return cls
end

return M