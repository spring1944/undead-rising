function gadget:GetInfo()
	return {
		name = "Game OVER!",
		desc = "Ends the game under appropriate conditions",
		author = "Nemo (shares a name but no code with the version in S44Main.sdd)",
		date = "22 January 2012",
		license = "GNU GPL v2",
		layer = 1,
		enabled = true
	}
end

-- synced only
if (not gadgetHandler:IsSyncedCode()) then
	return false
end

--synced ctrl
local KillTeam			=	Spring.KillTeam
local GameOver			=	Spring.GameOver
--synced read
local GetGameFrame		=	Spring.GetGameFrame
local GetTeamUnits		=	Spring.GetTeamUnits
local GetTeamList		=	Spring.GetTeamList
local GetTeamInfo		=	Spring.GetTeamInfo
local GetGameRulesParam	=	Spring.GetGameRulesParam

local SendMessage		=	Spring.SendMessage

--constants
local params 					= VFS.Include("LuaRules/header/sharedParams.lua")
local OBJECTIVE_PHASE_LENGTH	= params.OBJECTIVE_PHASE_LENGTH
local REINFORCEMENT_DELAY		= params.REINFORCEMENT_DELAY

local GAIA_TEAM_ID				= Spring.GetGaiaTeamID()

local retreatColor		= "\255\001\050\255"	--blue ish --
local humanDeathColor	= "\255\255\125\001"	--YELLOW-orange --
local zombieDeathColor	= "\255\051\001\102"	--purple

local teamUnitCounts = {}
local aliveTeams = {}

local retreatMessages = {
	[1] = "%s retreated from the battlefield!",
	[2] = "The last of %s's forces have withdrawn.",
	[3] = "%s strategically repositioned.",
}

local humanDeathMessages = {
	[1] = "%s was obliterated.",
	[2] = "%s has been neutralized.",
	[3] = "%s poses no further threat to mission objectives.",
}

local zombieDeathMessages = {
	[1] = "%s let the brainjuice spill out the headhole!",
	[2] = "%s, it's what's for dinner!",
	[3] = "OM NOM NOM %s",
	[4] = "%s says: 'braaaaains!'",
}

function CheckForGameEnd(deadTeamID)
    if not GG.GameStarted then return end
	if deadTeamID ~= GAIA_TEAM_ID then
        KillTeam(deadTeamID)
		local playerName = GG.teamIDToPlayerName[deadTeamID]
		local playerData = GG.activeAccounts[playerName]
		playerData.teamID = "inactive"
		aliveTeams[deadTeamID] = nil
		--need to adapt this to handle team games in the future
		local aliveCount = 0
		for teamID, isAlive in pairs(aliveTeams) do
            if isAlive then
                aliveCount = aliveCount + 1
            end
		end
		if aliveCount == 1 then
			--We have a winning team!
			--Note that winning team never gets its teamID set to "inactive"
			local winningTeamID = 0
			for teamID, isAlive in pairs(aliveTeams) do
				if teamID ~= GAIA_TEAM_ID then
					winningTeamID = teamID
				end
			end
			local gameFrame = GetGameFrame()
			local objWinTeamID = GetGameRulesParam("obj_win_team")

			local winningName = GG.teamIDToPlayerName[winningTeamID]
			if gameFrame > OBJECTIVE_PHASE_LENGTH and winningTeamID == objWinTeamID then
				SendMessage("\255\255\001\001 "..winningName.." achieved their objective and secured the area!")
				GG.Reward(winningTeamID, "wongame")
			elseif gameFrame < OBJECTIVE_PHASE_LENGTH and winningTeamID == GG.zombieTeamID then
				SendMessage("\255\255\001\001"..winningName.." drove away the humans!")
				GG.Reward(winningTeamID, "humansgone")
			elseif gameFrame > OBJECTIVE_PHASE_LENGTH and winningTeamID ~= objWinTeamID then
				SendMessage("\255\255\001\001EPIC WIN FOR "..winningName.."!")
				GG.Reward(winningTeamID, "epicwin")
			elseif gameFrame < OBJECTIVE_PHASE_LENGTH and winningTeamID ~= GG.zombieTeamID then
				Spring.Echo("ERROR! Humans can't win before objective round is over!")
			else
				Spring.Echo("ERROR! Only one team remains but no game over condition was triggered!")
				Spring.Echo("winningTeamID", winningTeamID, "objWinTeamID", objWinTeamID, "gameframe", gameFrame, "zombieTeamID", GG.zombieTeamID)
			end

			--teamID, leader, isDead, isAiTeam, side, allyTeam
			local _, _, _, _, _, winningAllyTeam = GetTeamInfo(winningTeamID)
			GG.Delay.DelayCall(GameOver, {{winningAllyTeam}}, 120)
			--gadgetHandler:RemoveGadget()
		end
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
	local ud = UnitDefs[unitDefID]
	--houses shouldn't be subtracted from zombie's unit count.
	if not ud.customParams.house and teamID ~= GAIA_TEAM_ID then
		teamUnitCounts[teamID] = teamUnitCounts[teamID] - 1
	end
	--Spring.Echo("team", teamID, "has", teamUnitCounts[teamID], "units!")
	if teamID ~= GAIA_TEAM_ID then
		--Spring.Echo("unit died, team units remaining:", #teamUnits-1)
		if teamUnitCounts[teamID] <= 0 then
			local removeTeam = true
			local gameFrame = GetGameFrame()
			local thisTeamWonObjRound = (GetGameRulesParam("obj_win_team") == teamID)
			local playerName = GG.teamIDToPlayerName[teamID]
			local OPL = OBJECTIVE_PHASE_LENGTH
			local OPLRD = OBJECTIVE_PHASE_LENGTH + REINFORCEMENT_DELAY
			if (teamID == GG.zombieTeamID and gameFrame < OPL) or (thisTeamWonObjRound and gameFrame < OPLRD + 5) then
				removeTeam = false
			end
			if removeTeam == true then

				local messageNum = 1

				if attackerID == nil then --retreated
					messageNum = math.random(1, #retreatMessages)
					SendMessage("\n\n"..retreatColor.." "..string.format(retreatMessages[messageNum], playerName))
				elseif attackerTeamID == GG.zombieTeamID then --eaten by zombies!
					messageNum = math.random(1, #zombieDeathMessages)
					SendMessage("\n\n"..zombieDeathColor.." "..string.format(zombieDeathMessages[messageNum], playerName))
				else -- killed by a human player
					messageNum = math.random(1, #humanDeathMessages)
					SendMessage("\n\n"..humanDeathColor.." "..string.format(humanDeathMessages[messageNum], playerName))
				end
				CheckForGameEnd(teamID)
			end
		end
	end
end

function gadget:UnitCreated(unitID, unitDefID, teamID)
	local ud = UnitDefs[unitDefID]
	--houses shouldn't prevent the game from ending
	if not ud.customParams.house and teamID ~= GAIA_TEAM_ID then
		teamUnitCounts[teamID] = teamUnitCounts[teamID] + 1
	end
end

function gadget:Initialize()
	local teams = GetTeamList()
	for i=1, #teams do
		local teamID = teams[i]
        if teamID ~= GAIA_TEAM_ID then
            teamUnitCounts[teamID] = 0
            aliveTeams[teamID] = true
        end
	end
end
