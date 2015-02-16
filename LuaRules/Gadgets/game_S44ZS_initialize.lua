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
		local unitName = pd.units[i].stats.name
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

        local unitCount = 0
        if playerData.units then
            for _, unitInfo in pairs(playerData.units) do
                unitCount = unitCount + 1
            end
        end

        -- activeAccounts are randomly ordered, so <= works out fine
		if playerNetWorth <= lowestNetWorthSeen or unitCount == 0 then
			poorestPlayerTeamID = playerData.teamID
			lowestNetWorthSeen = playerNetWorth
		end
	end
	return poorestPlayerTeamID
end

local function sendToAutohost(command, data)
    --Spring.SendCommands('wbynum 255 ' .. command .. ' ' .. json.encode(data))
    Spring.SendLuaRulesMsg(json.encode( { command = command, data = data }))
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
                -- TODO: factor this bit out to a chunk that's clearly only
                -- dealing with massaging data from the server
				local unitStats = playerUnits[i]
				local name = unitStats.stats.name
				local health = unitStats.stats.health
				local xp = unitStats.stats.experience
				local ammo = unitStats.stats.ammo
				local hqID = unitStats.id
				--Spring.Echo(name, health, xp, ammo)
				local udid = UnitDefNames[name].id
				local unitID = unitSpawnRandomPos(name, px, pz, false, 1, teamID, 0)
				local unitID = unitID[1]
				if unitID ~= nil then
					SetUnitHealth(unitID, health)
					SetUnitExperience(unitID, xp)
					if ammo and ammo ~= -1 then
						SetUnitRulesParam(unitID, "ammo", ammo)
					end
					if hqID then
                        --Spring.Echo('spawning a unit with HQID!!', hqID, unitID, name)
						SetUnitRulesParam(unitID, "hqID", hqID)
					end
				end
			end
		else
			CreateUnit("zomsprinter", px, py, pz, 0, teamID)		
		end
		playerData.units = nil
	end
end

local function StartGame()
    --the player with the lowest net worth (army value + money in the bank) is always zombies
    local poorestPlayerTeamID = findPoorestPlayer()
    GG.zombieTeamID = poorestPlayerTeamID
    SetGameRulesParam("zombieteam", poorestPlayerTeamID)
    GG.GameStarted = Spring.GetGameFrame()
	SpawnArmies()
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
    if player.units then
        for _, unitInfo in pairs(player.units) do
            unitCount = unitCount + 1
        end
    end
    if unitCount == 0 then unitlessPlayers = unitlessPlayers + 1 end

    SetStartResources(teamID, playerData.money)
    readyPlayers = readyPlayers + 1
    if readyPlayers == numPlayers then
        if unitlessPlayers > 1 then
            Spring.Echo("hey! the game started but more than one person totally lacks units. this is a bug, should never happen, is awful, etc., please leave an issue at: https://github.com/spring1944/ud-spads-plugin");
            Spring.GameOver({})
        else 
            StartGame()
        end
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
                sendToAutohost('team-ready', {name = playerName, teamID = teamID})
            end
        end
    end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam, _, _, _, _, attackerID)
    local hqID = Spring.GetUnitRulesParam(unitID, 'hqID')
    local playerName = GG.teamIDToPlayerName[unitTeam]
    -- don't kill morph units (hence attacker ID) (TODO: handle morphs better)
    if hqID ~= '' and playerName and attackerID then
        sendToAutohost('remove-unit', {owner = playerName, hq_id = hqID})
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
			--while zombie teams don't get their units recorded, I guess they could try to give zombies to human players, so we check to make sure those don't get recorded
			local isZombie = string.find(unitName, "zom")
			local hqID = Spring.GetUnitRulesParam(unitID, "hqID") or -1
			if unitName ~= "flag" and isZombie == nil then
				ret[#ret+1] = {
                        -- unitID is included so that the message
                        -- de-duplication logic doesn't eliminate identical
                        -- units (ie, I have 5 Tiger IIs that all retreat at once)
                        spring_unitID = unitID,
                        hq_id = hqID,
						name = unitName,
                        -- no point adding precision to 0
						experience = not xp and string.format('%.3f', xp) or 0,
						health = string.format('%.0f', health),
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
    -- need to differentiate otherwise identical messages
    local gameFrame = Spring.GetGameFrame()
    Spring.SetTeamResource(teamID, "m", currentMoney + amount)
    sendToAutohost('reward', {name = playerName, amount = amount, n = gameFrame})
end

function GG.LeaveBattlefield(units, teamID, survive)
    local info = {}
    local unitsForExport = processUnitsForExport(units)
    local playerName = GG.teamIDToPlayerName[teamID]
    for i=1, #unitsForExport do
        local unitInfo = unitsForExport[i]
        --ffffffffffffuuuuu??????
        sendToAutohost('save-unit', {name = playerName, unit = unitInfo})
    end

    for i=1, #units do
        local unitID = units[i]
        if not survive then
            SetUnitRulesParam(unitID, 'hqID', '')
            Spring.DestroyUnit(unitID, false, true) --unitID, self-d, reclaimed (ie silent)
        end
    end
end

end
