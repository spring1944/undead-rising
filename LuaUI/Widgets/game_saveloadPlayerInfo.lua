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

local CMD_RETREAT			=	35725

local REQUIRED_MOD_SHORT_NAME = "A UNIQUE SHORTNAME"

local LOGFILE = "S44/playeraccounts.lua"

--stores the money/units for all active players
--[[
example entry for player bob:
playerTable["bob"] = {
	teamID = 2,
	money = "uninitialized"/"new player"/50000,
	units = {[1] = unit stats, [2] = another unit's stats,...}
}

Note! the table that gets written to disc lacks the teamID entry. 
Otherwise it is the same (just with more player entries, probably)
]]--
local playerTable	=	{} 
local teamIDToName	=	{}

--these players are allowed to record data
local TRUSTEDNAMES = "[S44]Nemo".." ".."[S44]Autohost"

--decides if there's a trusted observer who is also a spec and allows data to be written if so
--note, there's also gadget-side protection, so this isn't as horribly insecure as it might seem >_>
--for more details, see the initialize gadget (its unsynced side checks for trusted names and only accepts 
--luarules messages from those playerIDs)
local okToSave = true

--this is what lets tables be written to strings or files and read back again
VFS.Include("LuaUI/lib/tableToString.lua")

----------------------------------------------------------------
--local functions
----------------------------------------------------------------

--expects a table with sequential numeric indices (ie [1] = x, [2] = x, etc) where
--each index corresponds to a unitID belonging to playerName
local function ProcessUnits(unitTable, playerName)
	for i=1, #unitTable do
		local unitID = unitTable[i]
		
		local xp = GetUnitExperience(unitID)
		local health, maxHealth, _, _, buildProgress = GetUnitHealth(unitID)
		if xp and health and buildProgress == 1.0 then
			local unitDefID = GetUnitDefID(unitID)
			local unitDef = UnitDefs[unitDefID]
			local unitName = unitDef.name
			local ammo = GetUnitRulesParam(unitID, "ammo") or -1
			local isShop = string.find(unitName, "shop")
			--while zombie teams don't get their units recorded, I guess they could try to give zombies to human players, so we check to make sure those don't get recorded
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
	
	--the team that won already retreated its units. so we update its money but not its units
	local winningTeamID = GetGameRulesParam("obj_win_team")
	for playerName, playerData in pairs(playerTable) do	
		local teamID = playerData.teamID
		local teamUnits = GetTeamUnits(teamID)
		--teamID of 'inactive' means the team retreated or was killed
		--these teams update their tables on death or retreat
		if teamID ~= "inactive" and teamID ~= zombieTeamID and teamID ~= winningTeamID then
			--wipe the active player's table of units and their stats and rebuild it
			--using the units that are still alive and their current states
			ProcessUnits(teamUnits, playerName)
		end
		
		--if the player doesn't have an account, create a spot to save their data
		if masterSaveInfo[playerName] == nil then
			masterSaveInfo[playerName] = {}
		end
		--go through and update the saved tables with the active player data now that the game is over
		local savePlayerData = masterSaveInfo[playerName]
		
		--if something bad happened and there's no team rules param for this team's money, 
		--just put it at the level they had before the game started
		savePlayerData.money = GetTeamRulesParam(teamID, "money") or playerData.money
		
		--don't update unit tables for zombie teams (don't want to save zombies or lose old units)
		if teamID ~= zombieTeamID then
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
		local playerName = GetPlayerInfo(leader)
		
		--note, I don't exclude zombie teams from the active player table because they can
		--earn money during the game.
		if teamID ~= GetGaiaTeamID()  then
			--get AI name so we can treat AIs just like human players
			if isAiTeam == true then
				local skirmishAAID, AIname = GetAIInfo(teamID)
				playerName = AIname
			end
			
			--only teamID really needs to be set here
			--I'm just putting in placeholder values for units and money (they get filled later)
			playerTable[playerName] = {
				teamID = teamID,
				money = "uninitialized",
				units = {},
			}
			teamIDToName[teamID] = playerName
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
	
	--this is switched on if sombody has no units (and isn't zombie team)
	--this also covers the case where the log file failed to load
	local emergencyShopMode = false 
	
	--attaches names to teamIDs for active (non-spec) players	
	NameToTeamID()
	
	--table.load returns nil if the file is empty
	local masterSaveInfo = table.load(LOGFILE) or {} 
	
	--this game rules param is set in the initialize gadget
	local zombieTeamID = GetGameRulesParam('zombieteam')
	
	--loop through all active players, get their info from the log file (or initialize it if they're new)
	for playerName, playerData in pairs(playerTable) do
		local playerHasAccount = masterSaveInfo[playerName] or false
		if playerHasAccount == false then
			playerData.units = {}
			-- the money handler gadget will take care of giving new players money
			playerData.money = "new player" 	
		else
			savedPlayerData = masterSaveInfo[playerName]
			playerData.units = savedPlayerData.units or {}
			playerData.money = savedPlayerData.money
		end	
		
		--these things are only used on the synced side (and aren't saved at the moment)
		--but this saves looping through the player table after sending it over to synced
		-- and adding these things (they're for the various win conditions)
		playerData.rescuedCivilians = 0
		playerData.flagControlTime = 0
		playerData.purgedHotzones = 0
		
		--if anybody doesn't have units (but is not the zombie team), flip to shop mode
		if #playerData.units == 0 and playerData.teamID ~= zombieTeamID then
			emergencyShopMode = true
		end
	end
	
	--wipe out this particular reference to the huge player account database
	--(we have data for the active players, that's all we care about)
	masterSaveInfo = nil
	
	--serialize and send the info!
	local stringPlayerTable = table.save(playerTable)
	SendLuaRulesMsg("ad:"..stringPlayerTable) --ad as in account data
	
	--now that the units have been passed into synced, no need to keep them here
	--but it shouldn't be nil, since it'll be filled up with units later as a player
	--retreats them or the game ends
	for player, playerData in pairs(playerTable) do
		playerData.units = {}
	end
	
	if emergencyShopMode == true then
		Spring.Echo("EMERGENCY SHOP MODE ACTIVATE!")
		SendLuaRulesMsg("shopmodeENABLE")
	end
end

function widget:UnitCommand(unitID, unitDefID, unitTeam, cmdID)
	if cmdID == CMD_RETREAT and unitTeam ~= GetGaiaTeamID() then
		ProcessUnits({[1] = unitID}, teamIDToName[unitTeam])	
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
