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

local prizes = {["wongame"] = 5000, ["civiliansave"] = 200, ["zombiekill"] = 100}

function GG.Reward(teamID, achievement)
	if prizes[achievement] ~= nil then
		Spring.Echo("Reward for "..achievement.." for team "..teamID.."!")
		local currentMoney = Spring.GetTeamResources(teamID, "metal")
		Spring.SetTeamResource(teamID, "m", currentMoney + prizes[achievement])
		
		if achievement == "civiliansave" then
			local saviorPlayerName = GG.teamIDToPlayerName[teamID]
			local pd = GG.activeAccounts[saviorPlayerName]
			pd.rescuedCivilians = pd.rescuedCivilians + 1
		end
	else
		Spring.Echo("BAD ACHIEVEMENT PARAM TO GG.Reward - "..achievement)
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
	local ud = UnitDefs[unitDefID]
	if ud.customParams then
		if ud.customParams.undead then
			GG.Reward(attackerTeamID, "zombiekill")
		end
	end
end