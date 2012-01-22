local GetGroundHeight			=	Spring.GetGroundHeight
local GetUnitsInCylinder		=	Spring.GetUnitsInCylinder
local GetTeamStartPosition		=	Spring.GetTeamStartPosition
local GetSideData				=	Spring.GetSideData
local GetTeamInfo				=	Spring.GetTeamInfo
local GetTeamUnits				=	Spring.GetTeamUnits
--local GetGameRulesParam			=	Spring.GetGameRulesParam

local CreateUnit				=	Spring.CreateUnit
local GAIA_TEAM_ID				=	Spring.GetGaiaTeamID()

local MarkerErasePosition		=	Spring.MarkerErasePosition
local TestBuildOrder			=	Spring.TestBuildOrder

function Distance(x1, z1, x2, z2, whocalled)
	local dist = math.sqrt((x2-x1)^2  + (z2-z1)^2)
	--Spring.Echo("distance from "..whocalled.."!", x1, z1, x2, z2, dist)
	return dist
end

--borrowed/slightly modified from tobi/flozi's game_setup.lua
function GetStartUnit(teamID)
	-- get the team startup info
	local side = select(5, GetTeamInfo(teamID))
	local startUnit
	if (side == "") then
		-- startscript didn't specify a side for this team
		local sidedata = GetSideData()
		if (sidedata and #sidedata > 0) then
			startUnit = sidedata[1 + teamID % #sidedata].startUnit
		end
	else
		startUnit = GetSideData(side)
	end
	return startUnit
end

function unitSpawnRandomPos(unitname, x, z, message, count, teamID, delay)
	local featureCheckRadius = 50
	local searchLimit = 500
	local SPREAD_MULT = 1.01
	local spawnSpread = 10
	local unitIDList = {}
	local failsafe = 0
	local counter = 0
	local y = GetGroundHeight(x, z)
	while (counter < count and failsafe < searchLimit) do
		local dx = math.random(-spawnSpread, spawnSpread)
		local dz = math.random(-spawnSpread, spawnSpread)
		local xspwn = x + dx
		local zspwn = z + dz
		local yspwn = GetGroundHeight(xspwn, zspwn)
		local udid = UnitDefNames[unitname].id
		local featureClear = Spring.GetFeaturesInCylinder(xspwn, zspwn, featureCheckRadius)
		if #featureClear == 0 and IsPositionValid(udid, xspwn, zspwn) == true then
			if delay > 0 then
				GG.Delay.DelayCall(Spring.MarkerErasePosition, {x, y, z}, delay)
				GG.Delay.DelayCall(CreateUnit, {unitname, xspwn, yspwn, zspwn, 0, teamID}, delay)
			else
				local unitID = CreateUnit(unitname, xspwn, yspwn, zspwn, 0, teamID)	
				table.insert(unitIDList, unitID)
			end
			failsafe = 0
			counter = counter + 1
		end
		failsafe = failsafe + 1
		spawnSpread = spawnSpread * SPREAD_MULT
	end
	if failsafe == searchLimit then
		Spring.Echo("SPAWNER FAILED TO SPAWN UNIT: "..unitname)
	end
	if message ~= false then
		Spring.MarkerAddPoint(x, y, z, message)
	end
	return unitIDList
end

function SpawnStartUnit(teamID)
	local startUnit = GetStartUnit(teamID)
	if (startUnit and startUnit ~= "") then
		-- spawn the specified start unit
		local x,y,z = GetTeamStartPosition(teamID)
		-- Erase start position marker while we're here
		--MarkerErasePosition(x or 0, y or 0, z or 0)
		-- snap to 16x16 grid
		x, z = 16*math.floor((x+8)/16), 16*math.floor((z+8)/16)
		y = GetGroundHeight(x, z)
		-- facing toward map center	
		local unitID = CreateUnit(startUnit, x, y, z, "south", teamID)
	end
end

function IsPositionValid(unitDefID, x, z)
	-- Don't place units underwater. (this is also checked by TestBuildOrder
	-- but that needs proper maxWaterDepth/floater/etc. in the UnitDef.)
	local y = GetGroundHeight(x, z)
	if (y <= 0) then
		return false
	end
	-- Don't place units where it isn't be possible to build them normally.
	local test = TestBuildOrder(unitDefID, x, y, z, 0)
	if (test ~= 2) then
		return false
	end
	-- Don't place units too close together.
	local ud = UnitDefs[unitDefID]
	local units = GetUnitsInCylinder(x, z, 16)
	if (units[1] ~= nil) then
		return false
	end
	return true
end
--end stuff that was mostly borrowed from game_setup.lua (from S44 main)