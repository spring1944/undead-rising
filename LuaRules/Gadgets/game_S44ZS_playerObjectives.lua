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

local SetGameRulesParam			=	Spring.SetGameRulesParam

local GetTeamStartPosition		=	Spring.GetTeamStartPosition
local GetTeamList				= 	Spring.GetTeamList
local GetTeamUnits				=	Spring.GetTeamUnits

local params = VFS.Include("LuaRules/header/sharedParams.lua")

local CIVILIAN_SAVE_GOAL		= params.CIVILIAN_SAVE_GOAL
local HOT_ZONE_GOAL				= params.HOT_ZONE_GOAL
local FLAG_HOLD_GOAL			= params.FLAG_HOLD_GOAL
local OBJECTIVE_PHASE_LENGTH	= params.OBJECTIVE_PHASE_LENGTH --minutes
local REINFORCEMENT_DELAY		= params.REINFORCEMENT_DELAY --seconds

--[[
1 = civilian rescue
2 = hot zone purging
3 = territory control
]]--

local objectiveTeams = {[1] = {}, [2] = {}, [3] = {}}
local objectiveText = {
	[1] = "CIVILIAN RESCUE! Rescue "..CIVILIAN_SAVE_GOAL.." civilians!",
	[2] = "HOTZONE PURGE! Destroy "..HOT_ZONE_GOAL.." hot zones!",
	[3] = "SECURE TERRITORY! Hold the flags for "..FLAG_HOLD_GOAL.." seconds!"
}

local function teamWonObjRound(teamID)
	local playerName = GG.teamIDToPlayerName[teamID]
	local playerData = GG.activeAccounts[playerName]
	local side = GG.teamSide[teamID]
	--mark them as winners of the objective round so they get rewarded properly in game_end.lua
	--and so that game_end.lua doesn't try to remove this team once all their units get retreated
	playerData.objVictor = true
	SetGameRulesParam("obj_win_team", teamID)
	--save and remove all of their normal units (if not zombies)
	if teamID ~= GG.zombieTeamID then
		local teamUnits = GetTeamUnits(teamID)
		for i=1, #teamUnits do
			GG.Retreat(teamUnits[i], true)
		end
	else
		side = "zom"
	end

	
	--now spawn the huge flood of reinforcements
	local x, _, z = GetTeamStartPosition(teamID)
	for unitName, number in pairs(reinforcementDefs[side]) do
		Spring.Echo(unitName)
		--takes unitname, x, z, message, count, teamID, delay (in seconds!)
		unitSpawnRandomPos(unitName, x, z, false, number, teamID, REINFORCEMENT_DELAY)
	end
end

local function checkCivilianSaveObj()
	local successfulTeams = {}
	for playerName, playerData in pairs(GG.activeAccounts) do
		--Spring.Echo(playerName, playerData.rescuedCivilians)
		if playerData.rescuedCivilians >= CIVILIAN_SAVE_GOAL then
			--Spring.Echo("successful team!", playerName)
			table.insert(successfulTeams, playerData.teamID)
		end
	end
	return successfulTeams
end

function gadget:GameStart()
--assign teams to win conditions
--make sure they know? >_>
	--Spring.Echo(table.save(reinforcementDefs))
	local teams = GetTeamList()
	for i=1, #teams do
		local teamID = teams[i]
		local teamObj = math.random(1, 1) --replace this with #objectiveTeams once others are done
		table.insert(objectiveTeams[teamObj], teamID)
	end
end

function gadget:GameFrame(n)
	if Spring.GetGameRulesParam("shopmode") == 1 then
		gadgetHandler:RemoveGadget()
		return
	end
	if n == 50 then
		local teams = GetTeamList()
		for i=1, #teams do
			local teamID = teams[i]
			if teamID ~= GG.zombieTeamID then
				local teamObj = objectiveTeams[teamID]
				Spring.SendMessageToTeam(teamID, "\255\255\001\001CIVILIAN RESCUE! Rescue "..CIVILIAN_SAVE_GOAL.." civilians!") --todo: replace with dynamic
				Spring.SendMessageToTeam(teamID, "\255\001\255\001Objective phase is "..(OBJECTIVE_PHASE_LENGTH/30).." SECONDS!")
			end
		end
	end
	if n == OBJECTIVE_PHASE_LENGTH then
		local civWinningTeams = checkCivilianSaveObj()
		if #civWinningTeams ~= 1 then --either both teams got the objective, or none did.
			teamWonObjRound(GG.zombieTeamID)
			Spring.SendMessage("\255\255\001\001ZOMBIE TEAM HAS WON THE GAME! HORDE ARRIVING IN "..(REINFORCEMENT_DELAY/30).." SECONDS!")
		else
			local winningTeamID = civWinningTeams[1]
			teamWonObjRound(winningTeamID)
			Spring.SendMessage("\255\255\001\001"..GG.teamIDToPlayerName[winningTeamID].." has won the objective round! Reinforcements arriving in "..REINFORCEMENT_DELAY.." seconds.")
		end
	end
end