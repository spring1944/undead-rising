
function gadget:GetInfo()
	return {
		name      = "House placer",
		desc      = "Populates maps with houses for civilians",
		author    = "Nemo, built on work by FLOZi & Tobi",
		date      = "December 2009",
		license   = "CC by-nc, version 3.0",
		layer     = -1,
		enabled   = true  --  loaded by default?
	}
end

-- synced only
if (not gadgetHandler:IsSyncedCode()) then
	return false
end
VFS.Include("LuaRules/lib/easyMetal.lua")
VFS.Include("LuaRules/lib/spawnFunctions.lua")

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
local SetUnitAlwaysVisible					=	Spring.SetUnitAlwaysVisible
local SetUnitNoSelect						=	Spring.SetUnitNoSelect
-- constants

local BLOCK_SIZE							=	64	-- size of map to check at once
local METAL_THRESHOLD						=	1 -- Handy for creating profiles, set to just less than the lowest metal spot you want to include. ALWAYS REVERT TO 1
local PROFILE_PATH							=	"maps/" .. string.sub(Game.mapName, 1, string.len(Game.mapName) - 4) .. "_profile.lua"

local params = VFS.Include("LuaRules/header/sharedParams.lua")


local GAIA_TEAM_ID							= Spring.GetGaiaTeamID()

local HOUSE_FEATURE_CHECK_RADIUS			= params.HOUSE_FEATURE_CHECK_RADIUS
local CIV_SPAWN_WARNINGTIME					= params.CIV_SPAWN_WARNINGTIME
local OBJECTIVE_PHASE_LENGTH				= params.OBJECTIVE_PHASE_LENGTH
local SPAWN_BUFFER							= params.SPAWN_BUFFER

local FLAG_HOLD_POSITIONS					= params.FLAG_HOLD_POSITIONS

local ZOMBIE_COUNT 							= params.ZOMBIE_COUNT
local CIVILIAN_COUNT 						= params.CIVILIAN_COUNT
local RESPAWN_PERIOD						= params.RESPAWN_PERIOD

-- variables
local spots 								=	{} -- table of house/flag locations

local function randomHouse()
	local newHouse
	local pickHouse = math.random(1, 8)
	if (pickHouse == 1) then
		newHouse = "s44farmhouse1"
	elseif pickHouse == 2 then
		newHouse = "s44farmhouse2"
	elseif pickHouse == 3 then
		newHouse = "s44farmhouse3"
	elseif pickHouse == 4 then
		newHouse = "s44barn1"
	elseif pickHouse == 5 then
		newHouse = "oldfarmhouse1"
	elseif pickHouse == 6 then
		newHouse = "oldfarmhouse2"
	elseif pickHouse == 7 then
		newHouse = "oldfarmhouse3"
	elseif pickHouse == 8 then
		newHouse = "oldfarmhouse4"
	end
	return newHouse
end

local function PlaceHouse(spotX, spotZ)
	local udid = UnitDefNames["civilian"].id 
	for num, featureID in pairs(Spring.GetFeaturesInCylinder(spotX, spotZ, HOUSE_FEATURE_CHECK_RADIUS)) do
		local fdid = Spring.GetFeatureDefID(featureID)
		local fd = FeatureDefs[fdid]
		local civHouse = (fd.tooltip == "Farmhouse" or fd.tooltip == "Barn")
		if civHouse ~= true then
			Spring.DestroyFeature(featureID)
		end
	end
	if IsPositionValid(udid, spotX, spotZ) == true then
		CreateFeature(randomHouse(), spotX, 0, spotZ, 0)
	end
	
	local otherHouseSpots = {
		[0] = {x = spotX - 150, z = spotZ + 150}, 
		[1] = {x = spotX + 150, z = spotZ - 150}, 
		[2] = {x = spotX + 150, z = spotZ + 150}, 
		[3] = {x = spotX - 150, z = spotZ - 150}, 
	}
	for num, pos in ipairs(otherHouseSpots) do
		if IsPositionValid(udid, pos.x, pos.z) then
			CreateFeature(randomHouse(), pos.x, 0, pos.z, 0)
		end
	end
end

function gadget:GameFrame(n)
	if Spring.GetGameRulesParam("shopmode") == 1 then
		gadgetHandler:RemoveGadget()
		return
	end
	if n == 0 then
		local teamStartPos = {}
		for number, teamID in ipairs(Spring.GetTeamList()) do
			if teamID ~= GAIA_TEAM_ID then
				local x, _, z = Spring.GetTeamStartPosition(teamID)
				--Spring.Echo("team"..tostring(teamID).."has a start position at "..tostring(x)..","..tostring(z))
				teamStartPos[teamID] = {
				x = x,
				z = z,
				}
			end
		end
		-- HOUSE PLACEMENT
		Spring.Echo("placing houses!")
		if DEBUG then
			Spring.Echo(PROFILE_PATH)
		end
		if not VFS.FileExists(PROFILE_PATH) then
			Spring.Echo("Map House Profile not found. Autogenerating house positions.")
			spots = AnalyzeMetalMap()
			local spotsToRemove = {}
			for i=1, #spots do
				local notNearTeamStartCount = 0
				local sd = spots[i] --spot data
				for teamID, pos in pairs(teamStartPos) do
					--Spring.Echo("teamID, pos!", teamID, pos)
					if Distance(pos.x, pos.z, sd.x, sd.z, "team startpos buffer") > SPAWN_BUFFER then
						notNearTeamStartCount=notNearTeamStartCount+1
					end
				end

				--+1 because # doesn't count zero index
				if notNearTeamStartCount == #teamStartPos+1 then 
					PlaceHouse(sd.x, sd.z)
				else
					table.insert(spotsToRemove, i)
				end
			end
			
			--yes this is gross (and super slow if there are bazillions of spots)
			--and it'd be better to prevent them from being added to the 
			--table in the first place, but I don't want to muck with easyMetal code.
			
			--the "-(i-1)" is so that the saved indicies are updated as the size of the spots 
			--table changes due to previous removals.
			for i=1, #spotsToRemove do
				--Spring.Echo("removing spot #", spotsToRemove[i], spots[spotsToRemove[i]-(i-1)])
				--Spring.Echo("from position", spots[spotsToRemove[i]-(i-1)].x, spots[spotsToRemove[i]-(i-1)].z)
				table.remove(spots, spotsToRemove[i]-(i-1))
			end
			
			local spawnedFlags = 0
			while spawnedFlags < FLAG_HOLD_POSITIONS do
				local flagSpot = math.random(1, #spots)
				local sd = spots[flagSpot] --spot data
				if sd.hasFlag ~= true then
					local flagID = CreateUnit("flag", sd.x, GetGroundHeight(sd.x, sd.z), sd.z, 0, GAIA_TEAM_ID)
					SetUnitAlwaysVisible(flagID, true)
					SetUnitNoSelect(unitID, true)
					sd.hasFlag = true
					GG.flags[#GG.flags + 1] = {
						unitID = flagID,
						x = sd.x,
						z = sd.z,
					}
					spawnedFlags = spawnedFlags + 1
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
	--civilian and zombie periodical spawn
	--unitSpawnRandomPos(unitName, x, z, message, number to spawn, teamID, delay-in-frames)
	if n % RESPAWN_PERIOD < 0.1 and n < OBJECTIVE_PHASE_LENGTH then
		local warningTimeInSeconds = CIV_SPAWN_WARNINGTIME/30
		local civMessage = "Civilians coming out of hiding in "..warningTimeInSeconds.." seconds!"
		local civSpawnSpot = math.random(1, #spots)
		local civx, civz = spots[civSpawnSpot].x, spots[civSpawnSpot].z
		unitSpawnRandomPos("civilian", civx, civz, civMessage, CIVILIAN_COUNT, GAIA_TEAM_ID, CIV_SPAWN_WARNINGTIME)
		
		local zomSpawnSpot = math.random(1, #spots)
		local zomx, zomz = spots[zomSpawnSpot].x, spots[zomSpawnSpot].z
		unitSpawnRandomPos("zomsprinter", zomx, zomz, false, ZOMBIE_COUNT, GG.zombieTeamID, 0)
	end
end
