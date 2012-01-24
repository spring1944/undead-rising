--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local modOptions
if (Spring.GetModOptions) then
  modOptions = Spring.GetModOptions()
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function disableunits(unitlist)
	for name, ud in pairs(UnitDefs) do
	    if (ud.buildoptions) then
	      for _, toremovename in ipairs(unitlist) do
	        for index, unitname in pairs(ud.buildoptions) do
	          if (unitname == toremovename) then
	            table.remove(ud.buildoptions, index)
	          end
	        end
	      end
	    end
	end
end

local function tobool(val)
  local t = type(val)
  if (t == 'nil') then
    return false
  elseif (t == 'boolean') then
    return val
  elseif (t == 'number') then
    return (val ~= 0)
  elseif (t == 'string') then
    return ((val ~= '0') and (val ~= 'false'))
  end
  return false
end

--process ALL the units!

local shopOptions = {["us"] = {}, ["gb"]= {}, ["ge"] = {}, ["ru"]= {}}
--local shopOptions = {}
local SHOP_UD = {}

for name, ud in pairs(UnitDefs) do
 
 --BEGIN UNIT PROCESSING
	--army save specific
	
	if ud.name == "civilian" then
		ud.transportbyenemy = true
	else
		ud.transportbyenemy = false
	end
	
	if (ud.customparams) then
		if (not ud.customparams.flagcaprate) then
			if (ud.customparams.flag or ud.weapons ~= nil) then
				ud.customparams.flagcaprate = 1
			end
		end
	end
	
	if (ud.customparams) then
		if not ud.customparams.undead then
			ud.crushresistance = 99999999		
		else
			ud.crushresistance = 50
		end
	end
	
	if (ud.workertime and ud.maxvelocity and string.find(ud.name, "commando") == nil) then
		ud["buildoptions"] = {"apminesign", "atminesign", "tankobstacle"}
	end
	ud.idleautoheal = 0.001
	if (ud.customparams) then
		if (ud.customparams.feartarget) then
			ud.idleautoheal = 0.5
		end
	end

	--end army save specific

	--new sensor stuff!
	if (ud.seismicdistance) and (tonumber(ud.seismicdistance) > 0) then
		if tonumber(ud.sightdistance ) > 600 then
			ud.sightdistance = 650
			ud.radardistance = 950
		else
			ud.radardistance = 800
		end
		ud.seismicdistance = 1400
		ud.activatewhenbuilt = true

	end
	--end first chunk of new sensor stuff!
	
	--more new sensor stuff
	if not ud.maxvelocity then
		ud.stealth = false
		if (ud.customparams) then
			if (ud.customparams.hiddenbuilding == '1') then
			    ud.stealth = true
			end
		end
	end
	--end more new sensor stuff
	
	if ud.floater then
		ud.turninplace = false
		ud.turninplacespeedlimit = (tonumber(ud.maxvelocity) or 0) * 0.5
		--new sensor stuff
		ud.stealth = false
		ud.sightdistance = 650
		ud.radardistance = 950
		ud.activatewhenbuilt = true
		--end new sensor stuff
	end
	-- ammo storage
	if (ud.energystorage) then
		-- this is to exclude things like builders having 0.01 storage
		if tonumber(ud.energystorage)>1 then
			if not (ud.description) then
				ud.description = "log. storage: "..ud.energystorage
			end
			ud.description = ud.description.." (log. storage: "..ud.energystorage..")"
		end
	end
	-- ammo users, add ammo-related description
	if (ud.customparams) then
		if (ud.customparams.weaponcost) and (ud.customparams.maxammo) then
			local newDescrLine = "max. ammo: "..ud.customparams.maxammo..", log. per shot: "..ud.customparams.weaponcost..", total: "..(ud.customparams.weaponcost*ud.customparams.maxammo)
			if not (ud.description) then
				ud.description = newDescrLine
			end
			ud.description = ud.description.." ("..newDescrLine..")"
			
		end
		if ud.customparams.armor_front and (tonumber(ud.maxvelocity) or 0) > 0 then
			ud.usepiececollisionvolumes = true
		end
	end
	-- Make all vehicles push resistant, except con vehicles, so they vacate build spots
	if tonumber(ud.maxvelocity or 0) > 0 and (not ud.canfly) and tonumber(ud.footprintx) > 1 and (not ud.builder) then
		--Spring.Echo(name)
		ud.crushstrength = ud.mass
		ud.pushresistant = true
		--new sensor stuff
		ud.stealth = false
		ud.sightdistance = tonumber(ud.sightdistance) * 0.5
		ud.radardistance = 950
		ud.activatewhenbuilt = true
		--end new sensor stuff
		
		--local seisSig = tonumber(ud.mass) / 1000 -- 10x smaller than default
		--if seisSig < 1 then seisSig = 1 end
		ud.seismicsignature = 1 --seisSig
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
