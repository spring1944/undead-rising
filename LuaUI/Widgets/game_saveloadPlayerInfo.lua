function widget:GetInfo()
  return {
    name      = "Player account data load/save for S44",
    desc      = "Manages player attributes (army units, money)",
    author    = "B. Tyler (Nemo), built on work by Evil4Zerggin",
    date      = "Jan 20, 2012",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end


----------------------------------------------------------------
--speedups
----------------------------------------------------------------
local GetUnitExperience		=	Spring.GetUnitExperience
local GetUnitHealth			=	Spring.GetUnitHealth
local GetUnitDefID			=	Spring.GetUnitDefID
local GetUnitRulesParam		=	Spring.GetUnitRulesParam
local GetGameRulesParam		=	Spring.GetGameRulesParam

local GetPlayerInfo			=	Spring.GetPlayerInfo
local GetAIInfo				=	Spring.GetAIInfo

local GetTeamUnits			=	Spring.GetTeamUnits
local GetTeamInfo			=	Spring.GetTeamInfo
local GetTeamList			=	Spring.GetTeamList

local GetMyPlayerID			=	Spring.GetMyPlayerID
local GetGaiaTeamID			=	Spring.GetGaiaTeamID
local GetTeamRulesParam		=	Spring.GetTeamRulesParam

local SendLuaRulesMsg		=	Spring.SendLuaRulesMsg

local MOD_NAME				=	Game.modName
local gameID				=	Game.gameID

local REQUIRED_MOD_SHORT_NAME = "A UNIQUE SHORTNAME"

local LOGFILE = "S44/playeraccounts.lua"

--stores the money/units for all active players
local playerTable	=	{} 

--these players are allowed to record data
local TRUSTEDNAMES = "[S44]Nemo".." ".."[S44]Autohost"

--decides if there's a trusted observer who is also a spec and allows data to be written if so
local okToSave = true

--this is what lets tables be written to strings or files and read back again
VFS.Include("LuaUI/lib/tableToString.lua")

----------------------------------------------------------------
--local functions
----------------------------------------------------------------

local function ProcessTeamUnits(teamID, playerName)
	local teamUnits = GetTeamUnits(teamID)
	playerTable[playerName].units = {}
	for i=1, #teamUnits do
		local unitID = teamUnits[i]
		
		local xp = GetUnitExperience(unitID)
		local health, maxHealth, _, _, buildProgress = GetUnitHealth(unitID)
		if xp and health and buildProgress == 1.0 then
			local unitDefID = GetUnitDefID(unitID)
			local unitDef = UnitDefs[unitDefID]
			local unitName = unitDef.name
			local ammo = UnitDefs[unitDefID].customParams.maxammo or -1
			local isShop = string.find(unitName, "shop")
			local isZombie = string.find(unitName, "zom")
			if unitName ~= "flag" and isShop == nil and isZombie == nil then
				--uses the global playerTable
				local playerUnitTable = playerTable[playerName].units 
				playerUnitTable[#playerUnitTable+1] = {
						name = unitName,
						xp = xp, 
						health = health,
						ammo = ammo,
					}
			end
		end
	end
end

local function SaveData()
	local masterSaveInfo = table.load(LOGFILE) or {} 
	local zombieTeamID = GetGameRulesParam("zombieteam")
	Spring.Echo(zombieTeamID)
	for playerName, playerData in pairs(playerTable) do	
		local teamID = playerData.teamID
		Spring.Echo("But "..playerName.."'s teamID is "..playerData.teamID)
		--teamID of 'inactive' means the team retreated or was killed
		--these teams update their tables on death or retreat
		if teamID ~= "inactive" and teamID ~= zombieTeamID then
		--this updates the player's units before saving them
			ProcessTeamUnits(teamID, playerName)
		end
		
	--go through and update the saved tables with the active player data now that the game is over
		local savePlayerData = masterSaveInfo[playerName]
		--if something bad happened and there's no team rules param for this team's money, 
		--just put save it at the level they had before the game started
		savePlayerData.money = GetTeamRulesParam(teamID, "money") or playerData.money
		
		--don't update unit tables for zombie teams (don't want to save zombies or lose old units)
		if teamID ~= zombieTeamID then
			Spring.Echo("updating saved unit info for teamID "..teamID)
			savePlayerData.units = playerData.units
		end
	end
	--save it baby
	table.save(masterSaveInfo, LOGFILE)
	return
end

local function NameToTeamID()
	for index, teamID in ipairs(GetTeamList()) do
		local _, leader, isDead, isAiTeam = GetTeamInfo(teamID)
		local playerName, _, spectator = GetPlayerInfo(leader)
		local addToPlayerTable = spectator --don't add specs
		Spring.Echo("Found a team in GetTeamList!", leader, teamID, playerName, spectator)
		if teamID ~= GetGaiaTeamID()  then
			if isAiTeam == true then
				local skirmishAAID, AIname, hostingPlayerID = GetAIInfo(teamID)
				playerName = AIname
				addToPlayerTable = true
			end
			Spring.Echo("added player to player table!", playerName)
			if addToPlayerTable == true then
				playerTable[playerName] = {
					teamID = teamID,
					money = "uninitialized",
					units = {},		
				}
			end
		end
	end
end

----------------------------------------------------------------
--callins
----------------------------------------------------------------

function widget:Initialize()
	--checks to see if we're good to go (right game, right info source)
	if (Game.modShortName ~= REQUIRED_MOD_SHORT_NAME) then
		okToSave = false
		widgetHandler:RemoveWidget()
		return
	end
	
	local myID = GetMyPlayerID()
	local name, _, spec = GetPlayerInfo(myID)

	if (string.find(TRUSTEDNAMES, name, 1, true) == nil) or (spec == false) then
		Spring.Echo("untrusted source of save info!")
		okToSave = false
		widgetHandler:RemoveWidget()
		return
	end
	
	--this is switched on if enough players are new or there was no bank account file
	local emergencyShopMode = false 
	
	--attaches names to teamIDs for active (non-spec) players	
	NameToTeamID()
	
	--table.load returns nil if the file is empty
	local masterSaveInfo = table.load(LOGFILE) or {} 
	
	--keep track of these in order to decide if we should actually boot shop mode instead of normal mode
	local numNewPlayers = 0
	local numActivePlayers = 0
	local zombieTeamID = GetGameRulesParam('zombieteam')
	--loop through all active players, get their info from the log file (or initialize it if they're new)
	for playerName, playerData in pairs(playerTable) do
		local playerHasAccount = masterSaveInfo[playerName] or false
		if playerHasAccount == false then
			numNewPlayers = numNewPlayers + 1
			playerData.units = {}
			-- the money handler gadget will take care of giving new players money
			playerData.money = "new player" 	
		else
			savedPlayerData = masterSaveInfo[playerName]
			playerData.units = savedPlayerData.units or {}
			playerData.money = savedPlayerData.money
		end	
		--if anybody doesn't have units (but is not the zombie team), flip to shop mode
		if #playerData.units == 0 and playerData.teamID ~= zombieTeamID then emergencyShopMode = true end
		numActivePlayers = numActivePlayers + 1
	end
	--wipe out this particular reference to the huge player account database
	--(we have data for the active players, that's all we care about)
	masterSaveInfo = nil
	
	--serialize and send the info!
	local stringPlayerTable = table.save(playerTable)
	SendLuaRulesMsg("ad:"..stringPlayerTable) --ad as in account data
	
	if emergencyShopMode == true then
		Spring.Echo("EMERGENCY SHOP MODE ACTIVATE!")
		SendLuaRulesMsg("shopmodeENABLE")
	end
end
function widget:Shutdown()
	if (okToSave == true) then
		SaveData()
	end
end

function widget:GameOver()
	widgetHandler:RemoveWidget()
end
