function gadget:GetInfo()
	return {
		name      = "spawner for persistent units in MP",
		desc      = "Spawns units; same units you ended the last game with!",
		author    = "B. Tyler, Tobi Vollebregt",
		date      = "December 13, 2010",
		license   = "CC BY-NC",
		layer     = -2,
		enabled   = true --  loaded by default?
	}
end

--these players are allowed to record data
local TRUSTEDNAMES = "[S44]Nemo".." ".."[S44]Autohost"

if (gadgetHandler:IsSyncedCode()) then
VFS.Include("LuaRules/lib/tableToString.lua")

local GetGroundHeight			=	Spring.GetGroundHeight
local GetUnitsInCylinder		=	Spring.GetUnitsInCylinder
local GetTeamStartPosition		=	Spring.GetTeamStartPosition
local GetSideData				=	Spring.GetSideData
local GetTeamInfo				=	Spring.GetTeamInfo
local GetTeamUnits				=	Spring.GetTeamUnits
local GetGameRulesParam			=	Spring.GetGameRulesParam
local GAIA_TEAM_ID				=	Spring.GetGaiaTeamID()

local SetGameRulesParam			=	Spring.SetGameRulesParam
local SetTeamResource			=	Spring.SetTeamResource
local SetUnitExperience			=	Spring.SetUnitExperience
local SetUnitHealth				=	Spring.SetUnitHealth
local SetUnitRulesParam			=	Spring.SetUnitRulesParam
local CreateUnit				=	Spring.CreateUnit

local MarkerErasePosition		=	Spring.MarkerErasePosition
local TestBuildOrder			=	Spring.TestBuildOrder

local MAX_SPREAD = 1000
local SPREAD_MULT = 1.025

local modOptions = Spring.GetModOptions()

--------------------------------------------------------------------------- 




local function SetStartResources(teamID)
	SetTeamResource(teamID, "es", tonumber(modOptions.logistics_reserve) or 5000)
	SetTeamResource(teamID, "e", tonumber(modOptions.logistics_reserve) or 5000)
end



--borrowed/slightly modified from tobi/flozi's game_setup.lua
local function GetStartUnit(teamID)
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

local function SpawnStartUnit(teamID)
	local startUnit = GetStartUnit(teamID)
	if (startUnit and startUnit ~= "") then
		-- spawn the specified start unit
		local x,y,z = GetTeamStartPosition(teamID)
		-- Erase start position marker while we're here
		MarkerErasePosition(x or 0, y or 0, z or 0)
		-- snap to 16x16 grid
		x, z = 16*math.floor((x+8)/16), 16*math.floor((z+8)/16)
		y = GetGroundHeight(x, z)
		-- facing toward map center	
		local unitID = CreateUnit(startUnit, x, y, z, "south", teamID)
	end
end
--end stuff that was mostly borrowed from game_setup.lua (from S44 main)

local function ShopModeSpawn(teams)
	for i, teamID in ipairs(teams) do
		if teamID ~= GAIA_TEAM_ID then
			Spring.Echo("SPAWNING SHOP UNIT!")
			SpawnStartUnit(teamID)
		end
	end
end

local function IsPositionValid(unitDefID, x, z)
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
	local units = GetUnitsInCylinder(x, z, 25)
	if (units[1] ~= nil) then
		return false
	end
	return true
end


--goes through each unit in the spawn table, spawns it to the appropriate team with the appropriate stats
local function SpawnArmies()
	for playerName, playerData in pairs(GG.activeAccounts) do
		local playerUnits = playerData.units
		local teamID = playerData.teamID
		local px, py, pz = GetTeamStartPosition(teamID)
		if teamID ~= GG.zombieTeam then
			for i=1, #playerUnits do
				local unitStats = playerUnits[i]
				local name = unitStats.name
				local health = unitStats.health
				local xp = unitStats.xp
				local ammo = unitStats.ammo
				--Spring.Echo(name, health, xp, ammo)
				local udid = UnitDefNames[name].id
				local spread = 100
				local unitID
				while (spread < MAX_SPREAD) do
					local x = px + math.random(-spread, spread)
					local z = pz + math.random(-spread, spread)
					if IsPositionValid(udid, x, z) then
							unitID = CreateUnit(name, x, py, z, 0, teamID)
						break
					end
					spread = spread * SPREAD_MULT
				end
				if unitID ~= nil then --they might not spawn; need better algo
					SetUnitHealth(unitID, health)
					SetUnitExperience(unitID, xp)
					if ammo ~= -1 then
						SetUnitRulesParam(unitID, "ammo", ammo)
					end
				end
			end
		else
			CreateUnit("zomsprinter", px, py, pz, 0, teamID)		
		end
	end
end

function gadget:RecvLuaMsg(msg, playerID)
	if string.sub(msg, 1, 4) == "tds:" then -- as in TrustedDataSource
		local trustedPID = tonumber(string.sub(msg, 5))
		SetGameRulesParam("trustedPID", trustedPID)
	else
		local trustedPID = GetGameRulesParam("trustedPID")
		if playerID == trustedPID then
			Spring.Echo("got a luamsg from a trustedPID!")
			if string.sub(msg, 1, 3) == "ad:" then -- as in AccountData
				GG.activeAccounts = table.load(string.sub(msg, 4))
			end
			-- half or more of the non-spec players didn't have entries in the database
			--so the widget decided we should be in shop mode instead of normal mode
			if string.sub(msg, 1, 14) == "shopmodeENABLE" then 
				Spring.Echo("Widget said shop mode!")
				SetGameRulesParam("shopmode", 1)
			end
		else
			Spring.Echo("untrustedPID: "..playerID)
		end
	end
end

function gadget:Initialize()
	GG.activeAccounts = {}
	if modOptions.shop_mode == "1" then
		SetGameRulesParam("shopmode", 1)
	else
		SetGameRulesParam("shopmode", 0)
	end
end

function gadget:GameStart()
	local teams = Spring.GetTeamList()	
	--Make a global list of the side for each team, because with random faction
	--it is not trivial to find out the side of a team using Spring's API.
	-- data set in GetStartUnit function. NB. The only use for this currently is flags
	GG.teamSide = {}
	local shopMode = (GetGameRulesParam("shopmode") == 1)
	for playerName, playerData in pairs(GG.activeAccounts) do
		local teamID = playerData.teamID
		SetStartResources(teamID)
		local side = select(5, GetTeamInfo(teamID))
		GG.teamSide[teamID] = side
	end
	
	if shopMode == false then
		GG.zombieTeam = 0
		-- spawn start units
		local zombiePick = math.random(0, #teams-2)
		Spring.Echo("zombie team is ", zombiePick)
		GG.zombieTeam = zombiePick
		SetGameRulesParam("zombieteam", zombiePick)
	else
		GG.zombieTeam = "shop mode active, no zombies"
	end
	
	SpawnArmies()
	

	if shopMode == true then
		ShopModeSpawn(teams)
	end
end

else -- UNSYNCED
function gadget:Initialize()
	local localPID = Spring.GetMyPlayerID()
	local instanceName = Script.GetName()
	local name, _, spec, teamID = Spring.GetPlayerInfo(localPID)
	Spring.Echo(name, spec, localPID)
	
	if (string.find(TRUSTEDNAMES, name, 1, true) == nil) or (spec == false) then
		Spring.Echo("untrusted source of save info: "..name)
	else
		Spring.SendLuaRulesMsg("tds:"..localPID)
	end
end


end
