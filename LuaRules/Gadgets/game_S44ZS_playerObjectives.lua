function gadget:GetInfo()
	return {
		name = "S44ZS Player Objectives",
		desc = "Assigns and evaluates player objectives (ie win conditions)",
		author = "Nemo",
		date = "21 January 2012",
		license = "GNU GPL v2",
		layer = 1,
		enabled = true
	}
end

-- synced only
if (not gadgetHandler:IsSyncedCode()) then
	return false
end

VFS.Include("LuaRules/lib/spawnFunctions.lua")



local reinforcementDefs = VFS.Include("LuaRules/Configs/reinforcementDefs.lua")

local SendMessage				=	Spring.SendMessage
local SendMessageToTeam			=	Spring.SendMessageToTeam
local MarkerAddPoint			=	Spring.MarkerAddPoint
local SetGameRulesParam			=	Spring.SetGameRulesParam

local GetGameRulesParam			=	Spring.GetGameRulesParam
local GetTeamStartPosition		=	Spring.GetTeamStartPosition
local GetTeamList				= 	Spring.GetTeamList
local GetTeamUnits				=	Spring.GetTeamUnits
local GetUnitDefID				=	Spring.GetUnitDefID

local params = VFS.Include("LuaRules/header/sharedParams.lua")

local CIVILIAN_SAVE_GOAL		= params.CIVILIAN_SAVE_GOAL
local HOT_ZONE_GOAL				= params.HOT_ZONE_GOAL
local FLAG_HOLD_GOAL			= params.FLAG_HOLD_GOAL
local OBJECTIVE_PHASE_LENGTH	= params.OBJECTIVE_PHASE_LENGTH --minutes
local REINFORCEMENT_DELAY		= params.REINFORCEMENT_DELAY --seconds

local GAIA_TEAM_ID				= Spring.GetGaiaTeamID()

local successfulTeams = {}
--[[
1 = civilian rescue
2 = territory control
3 = hot zone purging
]]--

local shortObjText = {"Civilian rescue!", "Hold flags!", "Purge hotzones!"}
local objectiveText = {
	[1] = "\255\255\001\001CIVILIAN RESCUE! Rescue "..CIVILIAN_SAVE_GOAL.." civilians!",
	[2] = "\255\255\001\001SECURE TERRITORY! Hold the flags for "..FLAG_HOLD_GOAL.." combined seconds!",
	[3] = "\255\255\001\001HOTZONE PURGE! Destroy "..HOT_ZONE_GOAL.." hot zones!"
}

local function teamWonObjRound(teamID)
	local playerName = GG.teamIDToPlayerName[teamID]
	local playerData = GG.activeAccounts[playerName]
	local side = GG.teamSide[teamID]
	--mark them as winners of the objective round so they get rewarded properly in game_end.lua
	--and so that game_end.lua doesn't try to remove this team once all their units get retreated
	SetGameRulesParam("obj_win_team", teamID)
	--save and remove all of their normal units (if not zombies)
	if teamID ~= GG.zombieTeamID then
		local teamUnits = GetTeamUnits(teamID)
		for i=1, #teamUnits do
			local unitID = teamUnits[i]
			local unitDefID = GetUnitDefID(unitID)
			local ud = UnitDefs[unitDefID]
			if not ud.customParams.flag then
				GG.Retreat(teamUnits[i], true)
			end
		end
	else
		side = "zom"
	end
	
	--now spawn the huge flood of reinforcements
	local x, _, z = GetTeamStartPosition(teamID)
    -- drop the first wave in right away so you can't spawn camp
	for unitName, number in pairs(reinforcementDefs[side].wave[1]) do
		--takes unitname, x, z, message, count, teamID, delay (in frames!)
		unitSpawnRandomPos(unitName, x, z, false, number, teamID, 0, true)
	end

	for unitName, number in pairs(reinforcementDefs[side].wave[2]) do
        --gradually spawn this over the course of the delay period
        for i = 1,number do 
            local spawnDelay = (REINFORCEMENT_DELAY/number) * i
            GG.Delay.DelayCall(unitSpawnRandomPos, {unitName, x, z, false, 1, teamID, spawnDelay, true})
        end
	end
end

local function checkFlagControlObj(playerData)
	if playerData.flagControlTime >= FLAG_HOLD_GOAL then
		return true
	end
	return false
end

local function checkHotzonePurgeObj(playerData)
	if playerData.purgedHotzones >= HOT_ZONE_GOAL then
		return true
	end
	return false
end

local function checkCivilianSaveObj(playerData)
	if playerData.rescuedCivilians >= CIVILIAN_SAVE_GOAL then
		return true
	end
	return false
end

--first class functions, weeeeee.
local objectiveCheckFunctions = {checkCivilianSaveObj, checkFlagControlObj, checkHotzonePurgeObj}

function gadget:TeamDied(deadTeamID)
    local filteredSuccessfulTeams = {}
    for index, teamID in ipairs(successfulTeams) do
        if teamID ~= deadTeamID then
            table.insert(filteredSuccessfulTeams, teamID)
        end
    end
    successfulTeams = filteredSuccessfulTeams
end

local assignedObjectives = false
function gadget:GameFrame(n)
    if (not GG.GameStarted) or (n < GG.GameStarted) then return end 

	if n == GG.GameStarted + 50 then
        --assign each team an objective
        for playerName, playerData in pairs(GG.activeAccounts) do
            playerData.objectiveID = math.random(1, 3)
        end
        assignedObjectives = true

		local teams = GetTeamList()
		for i=1, #teams do
			local teamID = teams[i]
			if teamID ~= GG.zombieTeamID and teamID ~= GAIA_TEAM_ID then
				local playerName = GG.teamIDToPlayerName[teamID]
				local pd = GG.activeAccounts[playerName] --playerData
				local x, y, z = GetTeamStartPosition(teamID)
				MarkerAddPoint(x, y, z, shortObjText[pd.objectiveID])
				SendMessageToTeam(teamID, objectiveText[pd.objectiveID])
				SendMessageToTeam(teamID, "\255\001\255\001Objective phase is "..(OBJECTIVE_PHASE_LENGTH/(60*30)).." minutes!")
			end
		end
	end

    -- gross gross gross!
    if not assignedObjectives then return end

    -- every five seconds
	if n % (30*5) == 0 then
		for playerName, playerData in pairs(GG.activeAccounts) do
			if playerData.teamID ~= GG.zombieTeamID and not playerData.achievedObjective then
				local objID = playerData.objectiveID
				local teamObjCheck = objectiveCheckFunctions[objID] --this is a function
				local achievedObj = teamObjCheck(playerData) --see? a function!
				if achievedObj == true then
                    playerData.achievedObjective = true
					table.insert(successfulTeams, playerData.teamID)

                    local objectivePhaseEnd = GG.GameStarted + OBJECTIVE_PHASE_LENGTH
                    local timeLeft = objectivePhaseEnd - n
                    local humanTime = string.format("%.1f", timeLeft / (60*30))
                    SendMessageToTeam(playerData.teamID, "\255\001\255\001You accomplished your objective! In order to win, prevent the other player from accomplishing their goal, and survive until the end of the objective phase: " .. humanTime .." minutes left!")
				end
			end
		end

    end

	if n == GG.GameStarted + OBJECTIVE_PHASE_LENGTH then
        Spring.Echo("OBJECTIVE OVER")
        local allUnits = Spring.GetAllUnits()
        -- game's over, take away the mystery
        for index, unitID in ipairs(allUnits) do
            Spring.SetUnitAlwaysVisible(unitID, true)
        end
		if #successfulTeams ~= 1 then --either both teams got the objective, or neither did.
			teamWonObjRound(GG.zombieTeamID)
			SendMessage("\255\255\001\001ZOMBIES WIN! HORDE ARRIVING IN "..(REINFORCEMENT_DELAY/30).." SECONDS!")
		else
			local winningTeamID = successfulTeams[1]
			teamWonObjRound(winningTeamID)
			SendMessage("\255\255\001\001"..GG.teamIDToPlayerName[winningTeamID].." has won the objective round! Reinforcements arriving in "..(REINFORCEMENT_DELAY/30).." seconds.")
		end
	end
end

function gadget:UnitCreated(unitID)
    local gameFrame = Spring.GetGameFrame()
    if not GG.GameStarted then return end
    -- newly spawned units need to be visible too, after game end
    if gameFrame > (GG.GameStarted + OBJECTIVE_PHASE_LENGTH) then
        Spring.SetUnitAlwaysVisible(unitID, true)
    end
end
