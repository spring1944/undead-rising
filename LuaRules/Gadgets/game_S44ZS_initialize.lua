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

if (gadgetHandler:IsSyncedCode()) then
VFS.Include("LuaRules/lib/tableToString.lua")
VFS.Include("LuaRules/lib/spawnFunctions.lua")
local json = VFS.Include("LuaRules/lib/dkjson.lua")

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
local INITIAL_CASH				= params.INITIAL_CASH


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

local function findPoorestPlayer()
	local lowestNetWorthSeen = MAX_MONEY + 1
	local poorestPlayerTeamID = 0
	for playerName, playerData in pairs(GG.activeAccounts) do
		local playerNetWorth = calculateNetWorth(playerName)
        -- activeAccounts are randomly ordered, so <= works out fine
		if playerNetWorth <= lowestNetWorthSeen then
			poorestPlayerTeamID = playerData.teamID
			lowestNetWorthSeen = playerNetWorth
		end
	end
	return poorestPlayerTeamID
end

local function SetStartResources(teamID, amount)
	SetTeamResource(teamID, "es", LOGISTICS_RESERVE)
	SetTeamResource(teamID, "e", LOGISTICS_RESERVE)

	SetTeamResource(teamID, "ms", MAX_MONEY)
    if amount == 'new player' then
        amount = INITIAL_CASH
    end

	SetTeamResource(teamID, "m", amount)
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
local function SpawnArmies(shopMode)
	for playerName, playerData in pairs(GG.activeAccounts) do
        if shopMode then
            ShopModeSpawn(playerData)
        end
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

local function StartGame(shopMode)
	if shopMode == false then
		--the player with the lowest net worth (army value + money in the bank) is always zombies
        local poorestPlayerTeamID = findPoorestPlayer()
		GG.zombieTeamID = poorestPlayerTeamID
		SetGameRulesParam("zombieteam", poorestPlayerTeamID)
	else
		GG.zombieTeamID = "shop mode active, no zombies"
	end
    GG.GameStarted = Spring.GetGameFrame()
	SpawnArmies(shopMode)
end


local readyPlayers = 0
local numPlayers = 0
local unitlessPlayers = 0

local function SpawnTeam(cmd, line, wordlist, playerID)
    --Spring.Echo("cmd", cmd)
    --Spring.Echo("playerID", playerID)
    --Spring.Echo("line", line)
    --Spring.Echo("wordlist", wordlist)

    if playerID ~= 255 then Spring.Echo("it wasn't 255 that sent it") return end
    --local data = VFS.ZlibDecompress(line)
    local player = json.decode(line)

    -- serialization is a blast
    local teamID = tonumber(player.teamID)
    local side = select(5, GetTeamInfo(teamID))

    GG.activeAccounts[player.name] = { 
        teamID = tonumber(player.teamID), 
        name = player.name, 
        money = tonumber(player.money), 
        units = player.units,
        rescuedCivilians = 0,
		flagControlTime = 0,
		purgedHotzones = 0
    }

    local playerData = GG.activeAccounts[player.name]
    GG.teamSide[teamID] = side
    GG.teamIDToPlayerName[teamID] = player.name
    local unitCount = 0
    for _, unitInfo in pairs(player.units) do
        unitCount = unitCount + 1
    end
    if unitCount == 0 then unitlessPlayers = unitlessPlayers + 1 end

    SetStartResources(teamID, playerData.money)
    readyPlayers = readyPlayers + 1
    if readyPlayers == numPlayers then
        local shopMode = (GetGameRulesParam("shopmode") == 1)
        if unitlessPlayers > 1 then
            shopMode = true
            SetGameRulesParam("shopmode", 1)
        end
        StartGame(shopMode)
    end

end

function gadget:Initialize()
    local success = gadgetHandler:AddChatAction('spawn-team', SpawnTeam, '')
end

function gadget:GameStart()
	--Make a global list of the side for each team, because with random faction
	--it is not trivial to find out the side of a team using Spring's API.
	-- data set in GetStartUnit function. NB. The only use for this currently is flags
	GG.teamSide = {}
	GG.teamIDToPlayerName = {}
	GG.activeAccounts = {}
	GG.houseSpots = {}

	if modOptions.shop_mode == "1" then
		SetGameRulesParam("shopmode", 1)
	else
		SetGameRulesParam("shopmode", 0)
	end

	for index, teamID in ipairs(Spring.GetTeamList()) do
        local _, leader, isDead, isAiTeam = GetTeamInfo(teamID)
        local playerName, active, spectator = Spring.GetPlayerInfo(leader)
        if isAiTeam then
            local _, aiName = Spring.GetAIInfo(teamID)
            playerName = aiName
        end

        -- spec might be running bots
        if (not spectator or isAiTeam) and teamID ~= GAIA_TEAM_ID then
            numPlayers = numPlayers + 1
            if not GG.activeAccounts[playerName] then
                Spring.SendCommands('wbynum 255 team-ready ' .. playerName .. '|' .. teamID)
            end
        end
    end
end

local function processUnitsForExport(units)
    local ret = {}
	for index, unitID in ipairs(units) do
		local xp = Spring.GetUnitExperience(unitID)
		local health, maxHealth, _, _, buildProgress = Spring.GetUnitHealth(unitID)
		if xp and health and buildProgress == 1.0 then
			local unitDefID = Spring.GetUnitDefID(unitID)
			local unitDef = UnitDefs[unitDefID]
			local unitName = unitDef.name
			if string.find(unitName, "stationary") or string.find(unitName, "sandbag") then
				unitName = morphDefs[unitName].into
				local morphUD = UnitDefNames[unitName]
				local morphMaxHealth = morphUD.health
				local healthMult = health/maxHealth
				health = healthMult * morphMaxHealth
			end
			local ammo = Spring.GetUnitRulesParam(unitID, "ammo") or -1
			local isShop = string.find(unitName, "shop")
			--while zombie teams don't get their units recorded, I guess they could try to give zombies to human players, so we check to make sure those don't get recorded
			local isZombie = string.find(unitName, "zom")
			if unitName ~= "flag" and isShop == nil and isZombie == nil then
				ret[#ret+1] = {
						name = unitName,
						xp = xp,
						health = health,
						ammo = ammo,
					}
			end
		end
	end
    return ret
end

function GG.Money(teamID, amount)
    local currentMoney = Spring.GetTeamResources(teamID, "metal")
    local playerName = GG.teamIDToPlayerName[teamID]
    Spring.SetTeamResource(teamID, "m", currentMoney + amount)
    Spring.SendCommands('wbynum 255 reward ' .. json.encode({name = playerName, amount = amount}))
end

local function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function GG.LeaveBattlefield(units, teamID, survive)
    local info = {}
    local unitsForExport = processUnitsForExport(units)
    local playerName = GG.teamIDToPlayerName[teamID]
    for i=1, #unitsForExport do
        local unitInfo = unitsForExport[i]
        --ffffffffffffuuuuu??????
        --unitInfo.health = round(unitInfo.health, 2)
        --unitInfo.xp = round(unitInfo.xp, 2)
        Spring.SendCommands('wbynum 255 save-unit ' .. json.encode({name = playerName, unit = unitInfo}))
    end

    for i=1, #units do
        local unitID = units[i]
        if not survive then
            Spring.DestroyUnit(unitID, false, true) --unitID, self-d, reclaimed (ie silent)
        end
    end
end

function gadget:GameOver(winningAllyTeams)
    --[[
    local teams = Spring.GetTeamList()
    for i=1, #teams do
        local teamID = teams[i]
        if teamID ~= GAIA_TEAM_ID then
            local units = Spring.GetTeamUnits(teamID)
            #GG.LeaveBattlefield(units, teamID)
        end
    end
    ]]--
end


end
