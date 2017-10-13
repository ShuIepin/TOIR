IncludeFile("Evelynn.lua")

local sleep = function(s)					
  	local ntime = os.clock() + s
  	repeat until os.clock() > ntime
end

__PrintTextGame("--> Injected LUA")
__PrintTextGame("--> Finish HotKey: END key")


while(true) do
	local bIsEndLua = IsEndLua()
	if bIsEndLua == 1 then
		SetLuaCombo(false)
		__PrintTextGame("--> Finished LUA")
		break
	end

	OnTick()
	sleep(0.001)
end

