--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local modOptions
if (Spring.GetModOptions) then
  modOptions = Spring.GetModOptions()
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--process ALL the units!

local shopOptions = {["us"] = {}, ["gb"]= {}, ["ge"] = {}, ["ru"]= {}, ["it"] = {}, ["jp"] = {}}
--local shopOptions = {}
local SHOP_UD = {}

for name, ud in pairs(UnitDefs) do
 
 --BEGIN UNIT PROCESSING
	
	if ud.name == "civilian" then
		ud.transportbyenemy = true
	else
		ud.transportbyenemy = false
	end
	
	if (ud.customparams) then
		if not ud.customparams.undead then
			ud.crushresistance = 99999999		
		else
			ud.crushresistance = 50
		end
	end
	
	if (ud.workertime and ud.maxvelocity and not ud.cloakcost) then
		ud["buildoptions"] = {"apminesign", "atminesign", "tankobstacle"}
	end
	ud.idleautoheal = 0.001
	if (ud.customparams) then
		if (ud.customparams.feartarget) then
			ud.idleautoheal = 0.5
		end
	end



	local side = string.sub(name, 1, 2)
	-- add the unit to gamemaster buildoptions
	if (not ud.canfly and tonumber(ud.maxvelocity or 0) > 0) and (not ud.floater) then
		local isInf = false
		if ud.customparams then
			if ud.customparams.feartarget then
				isInf = true
			end
		end
		if (isInf == false) then
			local acceptableUnit = (string.find(name, "sortie") == nil) and (string.find(name, "pontoon") == nil) and (string.find(name, "scout") == nil)
			if acceptableUnit and side ~= "zo" and side ~= "ci" then
				shopOptions[side][#shopOptions[side]+1] = name
			end
		end
	end
	if (ud.customparams) then
		if ud.customparams.shop then
			SHOP_UD[side] = ud
		end
	end	
	--MODOPTION UNIT EFFECTS
	if (modOptions) then
		if (modOptions.shop_mode or 0) == "1" then
			if ud.extractsmetal then
				ud.extractsmetal = 0
			end
			ud.sightdistance = 0
			ud.airsightdistance = 0
			ud.radardistance = 0
		end
	end

	--END MODOPTION UNIT EFFECTS
	
end

for side, ud in pairs(SHOP_UD) do
  ud["buildoptions"] = shopOptions[side]
end
