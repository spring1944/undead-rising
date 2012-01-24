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
local params = VFS.Include("LuaRules/header/sharedParams.lua")

local TRUSTED_NAMES = params.TRUSTED_NAMES 

if (gadgetHandler:IsSyncedCode()) then
VFS.Include("LuaRules/lib/tableToString.lua")
VFS.Include("LuaRules/lib/spawnFunctions.lua")

local GetTeamStartPosition		=	Spring.GetTeamStartPosition
local GetTeamInfo				=	Spring.GetTeamInfo
local GetGameRulesParam			=	Spring.GetGameRulesParam
local GetUnitDefID				=	Spring.GetUnitDefID
local GetUnitTeam				=	Spring.GetUnitTeam

local SetGameRulesParam			=	Spring.SetGameRulesParam
local SetTeamResource			=	Spring.SetTeamResource
local SetUnitExperience			=	Spring.SetUnitExperience
local SetUnitHealth				=	Spring.SetUnitHealth
local SetUnitRulesParam			=	Spring.SetUnitRulesParam
local CreateUnit				=	Spring.CreateUnit

local MarkerErasePosition		=	Spring.MarkerErasePosition

local MAX_MONEY					=	params.MAX_MONEY
local LOGISTICS_RESERVE			=	params.LOGISTICS_RESERVE

local GAIA_TEAM_ID				=	Spring.GetGaiaTeamID()

local modOptions = Spring.GetModOptions()

--------------------------------------------------------------------------- 

local function calculateNetWorth(playerName)
	local netWorth = 0
	local pd = GG.activeAccounts[playerName]
	netWorth = pd.money
	for i=1,#pd.units do
		local unitName = pd.units[i].name
		local ud = UnitDefNames[unitName]
		netWorth = netWorth + ud.metalCost
	end
return netWorth

end


local function SetStartResources(teamID)
	SetTeamResource(teamID, "es", LOGISTICS_RESERVE)
	SetTeamResource(teamID, "e", LOGISTICS_RESERVE)
end


local function ShopModeSpawn(playerData)
	local teamID = playerData.teamID
	--do they have at least one unit in their table? 
	if playerData.units[1] then
		local unitData = playerData.units[1]
		local unitName = unitData.name
		local side = string.sub(unitName, 1, 3)
		if string.sub(side, 1, 2) == "us" then
			side = "us"
		end
		SpawnStartUnit(teamID, side)
	else
		SpawnStartUnit(teamID)
	end
end

--goes through each player in (synced side of) active players, spawns their units and wipes their unit tables
--(we don't care about what happens to units during the game, only what condition they're in at 
--the end, and the widget will record that)
local function SpawnArmies()
	for playerName, playerData in pairs(GG.activeAccounts) do
		local playerUnits = playerData.units
		local teamID = playerData.teamID
		local px, py, pz = GetTeamStartPosition(teamID)
		if teamID ~= GG.zombieTeamID then
			for i=1, #playerUnits do
				local unitStats = playerUnits[i]
				local name = unitStats.name
				local health = unitStats.health
				local xp = unitStats.xp
				local ammo = unitStats.ammo
				--Spring.Echo(name, health, xp, ammo)
				local udid = UnitDefNames[name].id
				local unitID = unitSpawnRandomPos(name, px, pz, false, 1, teamID, 0)
				local unitID = unitID[1]
				if unitID ~= nil then
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
		playerData.units = nil
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
			-- someone had zero units, so the widget decided we should be in shop mode
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
	GG.teamIDToPlayerName = {}
	
	--the player with the lowest net worth (army value + money in the bank) is always zombies
	local poorestPlayerTeamID = 1
	local lowestNetWorthSeen = MAX_MONEY + 1
	local shopMode = (GetGameRulesParam("shopmode") == 1)
	for playerName, playerData in pairs(GG.activeAccounts) do
		local teamID = playerData.teamID
		SetStartResources(teamID)
		local side = select(5, GetTeamInfo(teamID))
		GG.teamSide[teamID] = side
		GG.teamIDToPlayerName[teamID] = playerName
		if shopMode == false then
			local playerNetWorth = calculateNetWorth(playerName)
			if playerNetWorth < lowestNetWorthSeen then
				poorestPlayerTeamID = teamID
				lowestNetWorthSeen = playerNetWorth
			end
		end
		if shopMode == true then
			ShopModeSpawn(playerData)
		end
	end
	
	if shopMode == false then
		GG.zombieTeamID = 0
		GG.zombieTeamID = poorestPlayerTeamID
		SetGameRulesParam("zombieteam", poorestPlayerTeamID)
	else
		GG.zombieTeamID = "shop mode active, no zombies"
	end
	
	SpawnArmies()
	

end

else -- UNSYNCED
function gadget:Initialize()
	local localPID = Spring.GetMyPlayerID()
	local instanceName = Script.GetName()
	local name, _, spec, teamID = Spring.GetPlayerInfo(localPID)
	--Spring.Echo(name, spec, localPID)
	
	if (string.find(TRUSTED_NAMES, name, 1, true) == nil) or (spec == false) then
		Spring.Echo("untrusted source of save info: "..name)
	else
		Spring.SendLuaRulesMsg("tds:"..localPID)
	end
end


end
