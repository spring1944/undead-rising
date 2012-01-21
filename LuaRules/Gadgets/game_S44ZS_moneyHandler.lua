function gadget:GetInfo()
	return {
		name      = "Money handler",
		desc      = "Handles player finances (in conjunction with the widget)",
		author    = "Nemo",
		date      = "January 2012",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

if (gadgetHandler:IsSyncedCode()) then

-- localisations
-- SyncedRead
local GetTeamResources			= Spring.GetTeamResources
-- SyncedCtrl
local CreateUnit				= Spring.CreateUnit
local SetTeamResource			= Spring.SetTeamResource
local SetTeamRulesParam			= Spring.SetTeamRulesParam

local modOptions = Spring.GetModOptions()

--vars
local playerFinances = {}

local function SetStartResources(teamID, amount)
	SetTeamResource(teamID, "ms", 100000)
	SetTeamResource(teamID, "m", amount)
end

function gadget:GameStart()
	Spring.Echo("buymode playerFinances loop! length this much: ", #playerFinances)
	for playerName, playerData in pairs(GG.activeAccounts) do		
		local playerMoney = playerData.money
		local teamID = playerData.teamID
		--Spring.Echo("moneyHandler teamID gameSTart", playerName, teamID)
		--Spring.Echo("Setting up the player's ingame money!", teamID)			
		local amount = 0
		if playerMoney == "new player" then
			amount = tonumber(modOptions.initial_cash) or 80000
		else
			amount = playerMoney
		end
		--Spring.Echo("this player has this much money!", amount)
		SetStartResources(teamID, amount)
		SetTeamRulesParam(teamID, "money", amount)
	end
end

--when the widget dies, it records the current money value from teamRulesParam
function gadget:GameFrame(n)
	if n % (1*30) < 0.1 then
		for playerName, playerData in pairs(GG.activeAccounts) do
			local teamID = playerData.teamID
			if teamID ~= "inactive" then --killed or retreated
				local currentMoney = GetTeamResources(teamID, "metal")
				playerData.money = currentMoney
				SetTeamRulesParam(teamID, "money", currentMoney)
			end
		end	
	end
end

else --unsynced



end