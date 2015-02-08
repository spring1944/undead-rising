--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local modOptions
if (Spring.GetModOptions) then
  modOptions = Spring.GetModOptions()
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--process ALL the units!

local json = VFS.Include("LuaRules/lib/dkjson.lua")

local shopOptions = {["us"] = {}, ["gb"]= {}, ["ge"] = {}, ["ru"]= {}, ["it"] = {}, ["jp"] = {}}
--local shopOptions = {}
local function canBuyInShop(name, ud)
    local realCost = (ud.buildcostmetal and tonumber(ud.buildcostmetal) > 1)
    local canBuy = realCost and (string.find(name, "sortie") == nil)
    canBuy = canBuy and (string.find(name, "pontoon") == nil) 
    canBuy = canBuy and (string.find(name, "scout") == nil)
    return canBuy
end
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
			local acceptableUnit = canBuyInShop(name, ud)
            local exportDef = {
                name = name,
                unitpic = ud.buildpic or name .. ".png",
                description = ud.description,
                cost = ud.buildcostmetal,
            }

            if ud.customparams then
                if ud.customparams.maxammo then
                    exportDef.ammo = ud.customparams.maxammo
                end

                if ud.customparams.armor_front then
                    exportDef.armor_front = ud.customparams.armor_front
                end

                if ud.customparams.armor_side then
                    exportDef.armor_side = ud.customparams.armor_side
                end

                if ud.customparams.armor_rear then
                    exportDef.armor_rear = ud.customparams.armor_rear
                end

                if ud.customparams.armor_top then
                    exportDef.armor_top = ud.customparams.armor_top
                end
            end

			if acceptableUnit and side ~= "zo" and side ~= "ci" then
				shopOptions[side][#shopOptions[side]+1] = exportDef
			end
		end
	end
end

-- TODO: automate this at some point? one in X games set the option and update DB?
if false then
    Spring.Echo(json.encode(shopOptions));
end
