function gadget:GetInfo()
	return {
		name      = "House placer",
		desc      = "Populates maps with houses for civilians",
		author    = "Nemo, built on work by FLOZi & Tobi",
		date      = "December 2009",
		license   = "CC by-nc, version 3.0",
		layer     = -5,
		enabled   = true  --  loaded by default?
	}
end

-- function localisations
-- Synced Read
local AreTeamsAllied						=	Spring.AreTeamsAllied
local GetGroundInfo							=	Spring.GetGroundInfo
local GetGroundHeight						=	Spring.GetGroundHeight
local GetUnitsInCylinder					=	Spring.GetUnitsInCylinder
local GetUnitTeam							=	Spring.GetUnitTeam
local GetUnitDefID       					=	Spring.GetUnitDefID
local GetTeamInfo							=	Spring.GetTeamInfo
-- Synced Ctrl
local CreateFeature							=	Spring.CreateFeature
local CreateUnit							=	Spring.CreateUnit

-- constants
local GAIA_TEAM_ID							=	Spring.GetGaiaTeamID()
local BLOCK_SIZE							=	32	-- size of map to check at once
local METAL_THRESHOLD						=	1 -- Handy for creating profiles, set to just less than the lowest metal spot you want to include. ALWAYS REVERT TO 1
local PROFILE_PATH							=	"maps/" .. string.sub(Game.mapName, 1, string.len(Game.mapName) - 4) .. "_profile.lua"
local civilianMult							=	2 --# of civies per house
local rectDimMin							=	100
local rectDimMax							=	100 
local civilianCheckDist						=	200
local MAX_SPREAD							=	600
local SPREAD_MULT							=	1.01
local maxCivSpread							=	600
-- Minimum distance between any two spawned units/features.
local CLEARANCE								=	40

-- variables
local avgMetal								=	0	-- average metal per spot
local totalMetal							=	0 -- total metal found
local minMetalLimit 						=	0	-- minimum metal to place a flag at
local numSpots								=	0 -- number of spots found
local spots 								=	{} -- table of flag locations
local initFrame
local modOptions
if (Spring.GetModOptions) then
  modOptions = Spring.GetModOptions()
end

if (gadgetHandler:IsSyncedCode()) then
-- SYNCED
local function IsPositionValid(unitDefID, x, z)
	-- Don't place units underwater. (this is also checked by TestBuildOrder
	-- but that needs proper maxWaterDepth/floater/etc. in the UnitDef.)
	local y = Spring.GetGroundHeight(x, z)
	if (y <= 0) then
		return false
	end
	-- Don't place units where it isn't be possible to build them normally.
	local test = Spring.TestBuildOrder(unitDefID, x, y, z, 0)
	if (test ~= 2) then
		return false
	end
	-- Don't place units too close together.
	local ud = UnitDefs[unitDefID]
	local units = Spring.GetUnitsInCylinder(x, z, CLEARANCE)
	if (units[1] ~= nil) then
		return false
	end
	return true
end
	
local function PlaceHouse(spot)
	local spread = 100
	local civSpread = 70
	local udid = UnitDefNames["civilian"].id 
	local houseDensity = tonumber(modOptions.houseDensity) or 3
	local unitClear = GetUnitsInCylinder(spot.x, spot.z, civilianCheckDist)
	if (#unitClear == 0) then
		for i = 1, houseDensity do
			local pickHouse = math.random(1, 8)
			if (pickHouse == 1) then
				newHouse = "S44FarmHouse1"
			elseif pickHouse == 2 then
				newHouse = "S44Farmhouse2"
			elseif pickHouse == 3 then
				newHouse = "S44Farmhouse3"
			elseif pickHouse == 4 then
				newHouse = "S44Barn1"
			elseif pickHouse == 5 then
				newHouse = "OldFarmhouse1"
			elseif pickHouse == 6 then
				newHouse = "OldFarmhouse2"
			elseif pickHouse == 7 then
				newHouse = "OldFarmhouse3"
			elseif pickHouse == 8 then
				newHouse = "OldFarmhouse4"
			end
			
			while spread < MAX_SPREAD do
				local dx = math.random(-spread, spread)
				local dz = math.random(-spread, spread)
				local x = spot.x + dx
				local z = spot.z + dz
				local featureClear2 = Spring.GetFeaturesInRectangle(x - rectDimMin, z - rectDimMin, x + rectDimMin, z + rectDimMin)
				if #featureClear2 == 0 then
					CreateFeature(newHouse, x, 0, z, 0)
					local civilianCount = civilianMult * houseDensity
						--Spring.Echo("civilianCount", civilianCount)
					for i=1, civilianCount do
						local dxciv = math.random(-civSpread, civSpread)
						local dzciv = math.random(-civSpread, civSpread)
						local xciv = x + dxciv
						local zciv = z + dzciv
						y = GetGroundHeight(xciv, zciv)
						local zombieSpawn = math.random(1,80)
							if (zombieSpawn == 10) then
							local teams = Spring.GetTeamList()
								local zombieTeam = 1--modOptions.zombie_team or 1
								if (teams[zombieTeam] ~= nil) then
								CreateUnit("zomsprinter", xciv, y, zciv, 0, zombieTeam)
								end
							else
							CreateUnit("civilian", xciv, y, zciv, 0, GAIA_TEAM_ID)
							end
						civSpread = civSpread * SPREAD_MULT
					end
					break
				else
				spread = spread * SPREAD_MULT
				end
			end
		end
	end
end

function gadget:Initialize()
	initFrame = Spring.GetGameFrame()
end

function gadget:GameFrame(n)
	-- HOUSE PLACEMENT
	if n == (initFrame+10) then
		if DEBUG then
			Spring.Echo(PROFILE_PATH)
		end
		if not VFS.FileExists(PROFILE_PATH) then
			Spring.Echo("Map House Profile not found. Autogenerating house positions.")
			for z = 0, Game.mapSizeZ, BLOCK_SIZE do
				for x = 0, Game.mapSizeX, BLOCK_SIZE do
					if GetGroundHeight(x,z) > 0 then
						_, metal = GetGroundInfo(x, z)
						if metal >= METAL_THRESHOLD then
							table.insert(spots, {x = x, z = z, metal = metal})
							numSpots = numSpots + 1
							totalMetal = totalMetal + metal
						end
					end
				end
			end
			avgMetal = totalMetal / numSpots
			minMetalLimit = 0.75 * avgMetal
			local onlyHouseSpots = {}
			for _, spot in pairs(spots) do
				if spot.metal >= minMetalLimit then
					table.insert(onlyHouseSpots, {x = spot.x, z = spot.z})
					spots = onlyHouseSpots
					PlaceHouse(spot)							
				end
			end			
		else -- load the flag positions from profile
			Spring.Echo("Map Flag Profile found. Loading flag positions.")
			spots = VFS.Include(PROFILE_PATH)
			for _, spot in pairs(spots) do
				PlaceHouse(spot)
			end
		end
	end
end

else
-- UNSYNCED
end
