
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

--Library includes!
--easymetal library for finding metal spots on the map.
VFS.Include("LuaRules/lib/easyMetal.lua")
--spawn function library, used here for its Distance function
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

local PROFILE_PATH							=	"maps/" .. string.sub(Game.mapName, 1, string.len(Game.mapName) - 4) .. "_profile.lua"

local params = VFS.Include("LuaRules/header/sharedParams.lua")


local GAIA_TEAM_ID							= Spring.GetGaiaTeamID()

local HOUSE_FEATURE_CHECK_RADIUS			= params.HOUSE_FEATURE_CHECK_RADIUS
local HSR									= params.HOUSE_SPOT_RADIUS

local SPAWN_BUFFER							= params.SPAWN_BUFFER

local FLAG_HOLD_POSITIONS					= params.FLAG_HOLD_POSITIONS

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
		local civHouse = (fd.customParams.house)
		if civHouse == nil then
			Spring.DestroyFeature(featureID)
		end
	end
	if IsPositionValid(udid, spotX, spotZ) == true then
		CreateFeature(randomHouse(), spotX, 0, spotZ, 0)
	end
	
	local otherHouseSpots = {
		--HSR = HOUSE_SPAWN_RADIUS, from sharedParams.lua
		[0] = {x = spotX - HSR, z = spotZ + HSR}, 
		[1] = {x = spotX + HSR, z = spotZ - HSR}, 
		[2] = {x = spotX + HSR, z = spotZ + HSR}, 
		[3] = {x = spotX - HSR, z = spotZ - HSR}, 
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
			--analyze metal map from easyMetal library, yields a table of metal spots
			spots = AnalyzeMetalMap()
			local spotsToRemove = {}
			for i=1, #spots do
				local notNearTeamStartCount = 0
				local sd = spots[i] --spot data
				for teamID, pos in pairs(teamStartPos) do
					--Distance from spawnFunctions library, just the 2d distance.
					if Distance(pos.x, pos.z, sd.x, sd.z, "team startpos buffer") > SPAWN_BUFFER then
						notNearTeamStartCount=notNearTeamStartCount+1
					end
				end

				-- +1 because # doesn't count zero index
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
				table.remove(spots, spotsToRemove[i]-(i-1))
			end

			
			local spawnedFlags = 0
			while spawnedFlags < FLAG_HOLD_POSITIONS do
				local flagSpot = math.random(1, #spots)
				local sd = spots[flagSpot] --spot data
				if sd.hasFlag ~= true then
					local flagID = CreateUnit("flag", sd.x, GetGroundHeight(sd.x, sd.z), sd.z, 0, GAIA_TEAM_ID)
					SetUnitAlwaysVisible(flagID, true)
					SetUnitNoSelect(flagID, true)
					sd.hasFlag = true
					sd.unitID = flagID
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
		--point the global houseSpots table to spots.
		GG.houseSpots = spots
		gadgetHandler:RemoveGadget()
	end
end
