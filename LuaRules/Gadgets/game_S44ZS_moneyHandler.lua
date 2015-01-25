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

local params = VFS.Include("LuaRules/header/sharedParams.lua")

--vars
local playerFinances = {}

local function UpdatePlayerAccounts()
	for playerName, playerData in pairs(GG.activeAccounts) do
		local teamID = playerData.teamID
		if teamID ~= "inactive" then
			local currentMoney = GetTeamResources(teamID, "metal")
			playerData.money = currentMoney
			SetTeamRulesParam(teamID, "money", currentMoney)
		end
	end
end

--when the widget dies, it records the current money value from teamRulesParam
function gadget:GameFrame(n)
    if not GG.GameStarted then return end
    if n == GG.GameStarted then
        for playerName, playerData in pairs(GG.activeAccounts) do
            local playerMoney = playerData.money
            local teamID = playerData.teamID
            --Spring.Echo("moneyHandler teamID gameSTart", playerName, teamID)
            --Spring.Echo("Setting up the player's ingame money!", teamID)
            local amount = 0
            if playerMoney == "new player" then
                amount = INITIAL_CASH
            else
                amount = playerMoney
            end
            --Spring.Echo("this player has this much money!", amount)
        end
    end

	if n % (1*30) < 0.1 then
		UpdatePlayerAccounts()
	end
end

function gadget:GameOver()
	UpdatePlayerAccounts()
end


else --unsynced

end
