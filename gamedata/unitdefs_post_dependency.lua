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
local squadDefs = VFS.Include("luarules/configs/squad_defs_loader.lua")

local sideUnits = {["us"] = {}, ["gb"]= {}, ["ge"] = {}, ["ru"]= {}, ["it"] = {}, ["jp"] = {}}
--local shopOptions = {}
local function canBuyInShop(name, ud)
    local realCost = (ud.buildcostmetal and tonumber(ud.buildcostmetal) > 1)
    local canBuy = realCost and (string.find(name, "sortie") == nil)
    canBuy = canBuy and (string.find(name, "pontoon") == nil) 
    canBuy = canBuy and (string.find(name, "scout") == nil)
    canBuy = canBuy and not ud.canfly
    canBuy = canBuy and tonumber(ud.maxvelocity or 0) > 0
    canBuy = canBuy and not ud.floater
    local isInf = false
    if ud.customparams then
        if ud.customparams.feartarget then
            isInf = true
        end
    end

    -- buy platoons, not individuals
    canBuy = canBuy and not isInf

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
	
    -- limit engineers to mines/tank obstacles
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
    local availableInShop = canBuyInShop(name, ud)
     
    local exportDef = {
        name = name,
        human_name = ud.name,
        health = ud.maxdamage,
        side = side,
        unitpic = ud.buildpic or name .. ".png",
        description = ud.description,
        cost = ud.buildcostmetal,
        available_in_shop  = availableInShop
    }

    if squadDefs[name] then
        exportDef.human_name = squadDefs[name].name
        exportDef.squad_members = squadDefs[name].members
        --exportDef.unitpic = squadDefs[name].buildPic
        --exportDef.cost = squadDefs[name].buildCostMetal
    end

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

    if side ~= "zo" and side ~= "ci" and sideUnits[side] ~= nil then
        sideUnits[side][#sideUnits[side]+1] = exportDef
    end
end

-- TODO: automate this at some point? one in X games set the option and update DB?
if false then
    Spring.Echo(json.encode(sideUnits));
end
