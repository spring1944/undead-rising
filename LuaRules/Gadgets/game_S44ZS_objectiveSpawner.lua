function gadget:GetInfo()
	return {
		name      = "Objective Spawner",
		desc      = "Spawns zombies (and hotzones) and civilians on a regular basis.",
		author    = "Nemo",
		date      = "Feb 1 2012",
		license   = "GPL v2",
		layer     = 2,
		enabled   = true  --  loaded by default?
	}
end

-- synced only
if (not gadgetHandler:IsSyncedCode()) then
	return false
end

--library includes
	--spawn functions, used here for spawning civilians and zombies
VFS.Include("LuaRules/lib/spawnFunctions.lua")

--function initializations
	--synced read
local GetFeaturesInCylinder		= Spring.GetFeaturesInCylinder
local GetFeatureDefID			= Spring.GetFeatureDefID
local GetFeaturePosition		= Spring.GetFeaturePosition

	--synced ctrl
local CreateUnit				= Spring.CreateUnit
local DestroyFeature			= Spring.DestroyFeature
local SetUnitNoSelect			= Spring.SetUnitNoSelect
--constants
local GAIA_TEAM_ID				= Spring.GetGaiaTeamID()

local params = VFS.Include("LuaRules/header/sharedParams.lua")

local CIV_SPAWN_WARNINGTIME		= params.CIV_SPAWN_WARNINGTIME
local OBJECTIVE_PHASE_LENGTH	= params.OBJECTIVE_PHASE_LENGTH
local ZOMBIE_COUNT 				= params.ZOMBIE_COUNT
local CIVILIAN_COUNT 			= params.CIVILIAN_COUNT
local RESPAWN_PERIOD			= params.RESPAWN_PERIOD
local HOUSE_SPOT_RADIUS			= params.HOUSE_SPOT_RADIUS

--variables
local houseIDToSpotIndex		= {}

--local functions
local function transformIntoHotzone(houseIndex)
	GG.houseSpots[houseIndex].hotZone = true
	local sd = GG.houseSpots[houseIndex]
	
	local hotZoneHouseCounter = 0
	local nearbyFeatures = GetFeaturesInCylinder(sd.x, sd.z, HOUSE_SPOT_RADIUS + 100)
	for i=1, #nearbyFeatures do
		local fid = nearbyFeatures[i]
		local fdid = GetFeatureDefID(fid)
		local fd = FeatureDefs[fdid]
		if fd.customParams.house then
			--this table is used so unitDestroyed can update a hotspot's features (or remove the hotspot and reward the player if needed)
			local x, y, z = GetFeaturePosition(fid)
			local name = fd.name
			DestroyFeature(fid)
			local houseUnitID = CreateUnit(name, x, y, z, 0, GG.zombieTeamID)
			SetUnitNoSelect(houseUnitID, true)
			houseIDToSpotIndex[houseUnitID] = houseIndex
			hotZoneHouseCounter = hotZoneHouseCounter + 1
			--TODO add some graphical thing to these houses so they stand out.
		end
	end
	GG.houseSpots[houseIndex].hotZoneHouseCount = hotZoneHouseCounter
end

--callins

function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
	local ud = UnitDefs[unitDefID]
	if ud.customParams.house then
		local spotNum = houseIDToSpotIndex[unitID]
		if spotNum ~= nil then --this covers /given house units
			local spotData = GG.houseSpots[spotNum]
			if spotData.hotZone then
				spotData.hotZoneHouseCount = spotData.hotZoneHouseCount - 1
			end
			if spotData.hotZoneHouseCount == 0 then
				spotData.hotZone = nil
				GG.Reward(attackerTeamID, "hotzonepurge")
			end
		end
	end
end

function gadget:GameFrame(n)
	--civilian and zombie periodical spawn
	
	if n % RESPAWN_PERIOD < 0.1 and n < OBJECTIVE_PHASE_LENGTH then
		local warningTimeInSeconds = CIV_SPAWN_WARNINGTIME/30
		local civMessage = "Civilians coming out of hiding in "..warningTimeInSeconds.." seconds!"
		local civSpawnSpot = math.random(1, #GG.houseSpots)
		local civx, civz = GG.houseSpots[civSpawnSpot].x, GG.houseSpots[civSpawnSpot].z
		--unitSpawnRandomPos(unitName, x, z, message, number to spawn, teamID, delay-in-frames)
		unitSpawnRandomPos("civilian", civx, civz, civMessage, CIVILIAN_COUNT, GAIA_TEAM_ID, CIV_SPAWN_WARNINGTIME)
		
		local newPossibleHotzones = {}
		for i=1, #GG.houseSpots do
			local sd = GG.houseSpots[i]
			if not sd.hotZone then 
				newPossibleHotzones[#newPossibleHotzones+1] = {
					houseIndex = i,
					spotData = sd,
					}
			else --it's a hotzone!
				unitSpawnRandomPos("zomsprinter", sd.x, sd.z, false, ZOMBIE_COUNT, GG.zombieTeamID, 0)
			end
		end
		
		--the new hotzone:
		if #newPossibleHotzones > 0 then
			local newHotzoneMessage = "New hotzone spotted!"
			local zomSpawnSpot = math.random(1, #newPossibleHotzones)
			local sd = newPossibleHotzones[zomSpawnSpot].spotData
			local houseIndex = newPossibleHotzones[zomSpawnSpot].houseIndex
			unitSpawnRandomPos("zomsprinter", sd.x, sd.z, newHotzoneMessage, ZOMBIE_COUNT, GG.zombieTeamID, 0)
			transformIntoHotzone(houseIndex)
		end		
	end
end