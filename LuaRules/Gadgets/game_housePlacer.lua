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

local modOptions = Spring.GetModOptions()

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
local BLOCK_SIZE							=	64	-- size of map to check at once
local METAL_THRESHOLD						=	1 -- Handy for creating profiles, set to just less than the lowest metal spot you want to include. ALWAYS REVERT TO 1
local PROFILE_PATH							=	"maps/" .. string.sub(Game.mapName, 1, string.len(Game.mapName) - 4) .. "_profile.lua"

local featureCheckRadius					=	100
local houseFeatureCheckRadius				=	300 
local MAX_SPREAD							=	350
local SPREAD_MULT							=	1.025
local maxCivSpread							=	400

local SEARCH_LIMIT							=   500

local spawnBuffer							=	800
--mod Option defined values
local zombieCount 							= tonumber(modOptions.zombie_count) or 5
local civilianCount 						= tonumber(modOptions.civilian_count) or 15
local respawnPeriod							= (tonumber(modOptions.respawn_period) or 1) * 60 * 30 --minutes-> seconds-> frames

-- variables
local avgMetal								=	0	-- average metal per spot
local totalMetal							=	0 -- total metal found
local minMetalLimit 						=	0.5	-- minimum metal to place a flag at
local numSpots								=	0 -- number of spots found
local spots 								=	{} -- table of flag locations
local onlyHouseSpots						=   {}
local teamStartPos							=	{}
local initFrame


if (gadgetHandler:IsSyncedCode()) then
-- SYNCED

local function Distance(x1, z1, x2, z2, whocalled)
	local dist = math.sqrt((x2-x1)^2  + (z2-z1)^2)
	--Spring.Echo("distance from "..whocalled.."!", x1, z1, x2, z2, dist)
	return dist
end

local function IsPositionValid(unitDefID, x, z)
	-- Don't place units underwater. (this is also checked by TestBuildOrder
	-- but that needs proper maxWaterDepth/floater/etc. in the UnitDef.)
	local y = GetGroundHeight(x, z)
	if (y <= 0) then
		return false
	end
	-- Don't place units where it isn't be possible to build them normally.
	local test = Spring.TestBuildOrder(unitDefID, x, y, z, 0)
	if (test ~= 2) then
		return false
	end
	return true
end
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
	local spread = 100
	local udid = UnitDefNames["civilian"].id 
	for num, featureID in pairs(Spring.GetFeaturesInCylinder(spotX, spotZ, houseFeatureCheckRadius)) do
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

function gadget:Initialize()
	initFrame = Spring.GetGameFrame()
end

function gadget:GameStart()
	for number, teamID in ipairs(Spring.GetTeamList()) do
		if teamID ~= Spring.GetGaiaTeamID() then
			local x, _, z = Spring.GetTeamStartPosition(teamID)
			--Spring.Echo("team"..tostring(teamID).."has a start position at "..tostring(x)..","..tostring(z))
			teamStartPos[teamID] = {
			x = x,
			z = z,
			}
		end
	end
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
							local notNearTeamStartCount = 0
							for teamID, pos in pairs(teamStartPos) do
								--Spring.Echo("teamID, pos!", teamID, pos)
								if Distance(x, z, pos.x, pos.z, "team startpos buffer") > spawnBuffer then
									notNearTeamStartCount=notNearTeamStartCount+1
								end
							end
							--Spring.Echo(tostring(x)..","..tostring(z).." notNearTeamStart Count: "..tostring(notNearTeamStartCount))
							--Spring.Echo("entries in teamStartPos: "..tostring(#teamStartPos))
							if notNearTeamStartCount == #teamStartPos+1 then --+1 because # doesn't count zero index
								if #spots > 1 then
									if Distance(spots[#spots].x, spots[#spots].z, x, z, "spot overlap check") > 100 then
										spots[#spots + 1] = {x = x, z = z}
										PlaceHouse(x, z)
										numSpots = numSpots + 1
									end
								else
									spots[#spots + 1] = {x = x, z = z}
									PlaceHouse(x, z)
									numSpots = numSpots + 1
								end
							end
						end
					end
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
	if n % respawnPeriod < 0.1 and n > (initFrame+10) or n == (initFrame + 15) then
		local spawnSpread = 70
		local civSpawnSpot = math.random(1, #spots)
		local zombieSpawnSpot = math.random(1, #spots)
		local failsafe = 0
		local civcounter = 0
		while (civcounter < civilianCount and failsafe < SEARCH_LIMIT) do
			local dxciv = math.random(-spawnSpread, spawnSpread)
			local dzciv = math.random(-spawnSpread, spawnSpread)
			local xciv = spots[civSpawnSpot].x + dxciv
			local zciv = spots[civSpawnSpot].z + dzciv
			local yciv = GetGroundHeight(xciv, zciv)
			local udid = UnitDefNames["civilian"].id
			local featureClear = Spring.GetFeaturesInCylinder(xciv, zciv, featureCheckRadius)
			if #featureClear == 0 and IsPositionValid(udid, xciv, zciv) == true then
				local zombieSpawn = math.random(1,80)
					if (zombieSpawn == 10) then
					local teams = Spring.GetTeamList()
						if (teams[GG.zombieTeam[0]] ~= nil) then
						CreateUnit("zomsprinter", xciv, yciv, zciv, 0, GG.zombieTeam[0])
						failsafe = 0
						end
					else
					CreateUnit("civilian", xciv, yciv, zciv, 0, GAIA_TEAM_ID)
					failsafe = 0
					civcounter = civcounter + 1
					end
			end
			failsafe = failsafe + 1
			spawnSpread = spawnSpread * SPREAD_MULT
		end
		spawnSpread = 70
		failsafe = 0
		local zomcounter = 0
		while (zomcounter < zombieCount and failsafe < SEARCH_LIMIT) do
			local dxzom = math.random(-spawnSpread, spawnSpread)
			local dzzom = math.random(-spawnSpread, spawnSpread)
			local x = spots[zombieSpawnSpot].x + dxzom
			local z = spots[zombieSpawnSpot].z + dzzom
			local y = GetGroundHeight(x, z)
			local udid = UnitDefNames["zomsprinter"].id
			local featureClear = Spring.GetFeaturesInCylinder(x, z, featureCheckRadius)
			if #featureClear == 0 and IsPositionValid(udid, x, z) == true then
				CreateUnit("zomsprinter", x, y, z, 0, GG.zombieTeam[0])
				failsafe = 0
				zomcounter = zomcounter + 1
			end
			failsafe = failsafe + 1
			spawnSpread = spawnSpread * SPREAD_MULT
		end
	end
end

else
-- UNSYNCED
end
