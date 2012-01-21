function gadget:GetInfo()
	return {
		name = "Reward",
		desc = "Global function for rewarding a team for doing good things (like saving civilians)",
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
--[[
prizes in order of size:
1) epic win: staying on map after failing to achieve objectives but defeating (down to a man) the
huge flood of reinforcements
2) won game: achieved objectives and then cleaned up with their reinforcements
3) rescued a civilian
4) destroyed a 'hotzone' feature group (a place where zombies got a reinforcement wave at some point)
5) killed a zombie

]]--
local prizes = {
	["epicwin"] = 20000,
	["wongame"] = 5000, 
	["civiliansave"] = 200, 
	["hotzonepurge"] = 200,
	["zombiekill"] = 100,
	["humankill"] = 0
}

function GG.Reward(teamID, achievement, bounty)
	local bounty = bounty
	if bounty == nil then 
		bounty = 0 
	end
	
	local playerName = GG.teamIDToPlayerName[teamID]
	local pd = GG.activeAccounts[playerName]
	if pd then
		if pd.teamID ~= "inactive" then		
			if prizes[achievement] ~= nil then
				--Spring.Echo("Reward for "..achievement.." for team "..teamID.."!")
				local currentMoney = Spring.GetTeamResources(teamID, "metal")
				Spring.SetTeamResource(teamID, "m", currentMoney + prizes[achievement] + bounty)
				
				if achievement == "civiliansave" then
					pd.rescuedCivilians = pd.rescuedCivilians + 1
					Spring.SendMessage("\255\255\001\001"..playerName.." has rescued "..pd.rescuedCivilians .." civvies!")
					--Spring.Echo(saviorPlayerName, pd.rescuedCivilians)
				end
			else
				Spring.Echo("BAD ACHIEVEMENT PARAM TO GG.Reward - "..achievement)
			end
		end
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
	local ud = UnitDefs[unitDefID]
	if ud.customParams then
		if ud.customParams.undead then
			GG.Reward(attackerTeamID, "zombiekill")
		end
	end
	if attackerTeamID == GG.zombieTeamID then
		GG.Reward(GG.zombieTeamID, "humankill", ud.metalCost)
	end
end