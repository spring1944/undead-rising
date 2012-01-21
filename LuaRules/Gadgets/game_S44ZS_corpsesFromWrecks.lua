function gadget:GetInfo()
	return {
		name      = "Corpses from wrecks",
		desc      = "Adds a few infantry corpses alongside vehicle wrecks.",
		author    = "Gnome, tweaked by Nemo",
		date      = "Jan 2012",
		license   = "GPL v2",
		layer     = 0,
		enabled   = true
	}
end

if (gadgetHandler:IsSyncedCode()) then

if (Spring.GetModOptions) then
  modOptions = Spring.GetModOptions()
end

local GetSideData				=	Spring.GetSideData
local GetGaiaTeamID				=	Spring.GetGaiaTeamID

local numCorpses		=	3

local function SpawnCorpses(x, y, z, side)
	local corpse = side.."soldier_dead"
	for i=1, math.random(2, numCorpses) do
		local x = math.random(-75, 75) + x
		local z = math.random(-75, 75) + z
		Spring.CreateFeature(corpse, x, Spring.GetGroundHeight(x, z), z)
	end
end
function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID)
	if attackerID ~= nil then
		local ud = UnitDefs[unitDefID]
		if ud.customParams then
			local udcp = ud.customParams
			if udcp.hasturnbutton or (udcp.maxammo and udcp.armor_front) then -- vehicle or 
				local side = GG.teamSide[teamID]
				local x, y, z = Spring.GetUnitPosition(unitID)
				SpawnCorpses(x, y, z, side)
			end
		end
	end	
end


end
