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


local modOptions = Spring.GetModOptions()

local SetGameRulesParam			=	Spring.SetGameRulesParam

local GetTeamStartPosition		=	Spring.GetTeamStartPosition
local GetTeamList				= 	Spring.GetTeamList
local GetTeamUnits				=	Spring.GetTeamUnits

local UPDATEFREQ			= 5 --seconds
local civilianSaveGoal		= tonumber(modOptions.civilian_goal) or 50
local hotZoneGoal			= 5
local flagHoldGoal			= 100
local objectivePhaseLength	= tonumber(modOptions.objective_phase_length) or 1 --minutes
local reinforcementDelay	= 60 --seconds

--[[
1 = civilian rescue
2 = hot zone purging
3 = territory control
]]--

local objectiveTeams = {[1] = {}, [2] = {}, [3] = {}}
local objectiveText = {
	[1] = "CIVILIAN RESCUE! Rescue "..civilianSaveGoal.." civilians!",
	[2] = "HOTZONE PURGE! Destroy "..hotZoneGoal.." hot zones!",
	[3] = "SECURE TERRITORY! Hold the flags for "..flagHoldGoal.." seconds!"
}

local function teamWonObjRound(teamID)
	local playerName = GG.teamIDToPlayerName[teamID]
	local playerData = GG.activeAccounts[playerName]
	local side = GG.teamSide[teamID]
	--save and remove all of their normal units (if not zombies)
	if teamID ~= GG.zombieTeamID then
		local teamUnits = GetTeamUnits(teamID)
		for i=1, #teamUnits do
			GG.Delay.DelayCall(GG.Retreat, {teamUnits[i]}, reinforcementDelay*30 + 2)
		end
	else
		side = "zom"
	end
	--give them a prize for winning objective round
	GG.Reward(teamID, "wongame")
	playerData.teamID = "inactive"
	SetGameRulesParam("obj_win_team", teamID)

	--now spawn the huge flood of reinforcements
	local x, _, z = GetTeamStartPosition(teamID)
	for unitName, number in pairs(reinforcementDefs[side]) do
		Spring.Echo(unitName)
		--takes unitname, x, z, message, count, teamID, delay (in seconds!)
		unitSpawnRandomPos(unitName, x, z, false, number, teamID, reinforcementDelay)
	end
end

local function checkCivilianSaveObj()
	local successfulTeams = {}
	for playerName, playerData in pairs(GG.activeAccounts) do
		--Spring.Echo(playerName, playerData.rescuedCivilians)
		if playerData.rescuedCivilians >= civilianSaveGoal then
			--Spring.Echo("successful team!", playerName)
			table.insert(successfulTeams, playerData.teamID)
		end
	end
	return successfulTeams
end

function gadget:GameStart()
--assign teams to win conditions
--make sure they know? >_>
	Spring.Echo(table.save(reinforcementDefs))
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
				Spring.SendMessageToTeam(teamID, "\255\255\001\001CIVILIAN RESCUE! Rescue "..civilianSaveGoal.." civilians!") --todo: replace with dynamic
			end
		end
	end
	if n == (30*60*objectivePhaseLength) then
		local civWinningTeams = checkCivilianSaveObj()
		if #civWinningTeams ~= 1 then --either both teams got the objective, or none did.
			teamWonObjRound(GG.zombieTeamID)
			Spring.SendMessage("\255\255\001\001ZOMBIE TEAM HAS WON THE GAME! HORDE ARRIVING IN "..reinforcementDelay.." SECONDS!")
		else
			local winningTeamID = civWinningTeams[1]
			teamWonObjRound(winningTeamID)
			Spring.SendMessage("\255\255\001\001"..GG.teamIDToPlayerName[winningTeamID].." has won the objective round! Reinforcements arriving in "..reinforcementDelay.." seconds.")
		end
	end
end