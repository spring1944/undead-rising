function gadget:GetInfo()
	return {
		name = "Shop Money enforcer",
		desc = "Units can only be built if you have the money",
		author = "FLOZi (C. Lawrence), tweaked (that is, hacked with an axe) for S44ArmySave by Nemo",
		date = "30/01/2011",
		license = "GNU GPL v2",
		layer = 1,
		enabled = true
	}
end

if (gadgetHandler:IsSyncedCode()) then
--SYNCED

-- Localisations

-- Synced Read
local GetTeamResources		= Spring.GetTeamResources
local GetUnitCmdDescs 		= Spring.GetUnitCmdDescs
local GetUnitTeam 			= Spring.GetUnitTeam
local GetGameRulesParam		= Spring.GetGameRulesParam
local GetUnitIsBuilding		= Spring.GetUnitIsBuilding

-- Synced Ctrl
local SetUnitNoSelect		= Spring.SetUnitNoSelect
local SetUnitHealth			= Spring.SetUnitHealth
local SetUnitSensorRadius	= Spring.SetUnitSensorRadius
local EditUnitCmdDesc		= Spring.EditUnitCmdDesc
local FindUnitCmdDesc		= Spring.FindUnitCmdDesc
local SetUnitRulesParam  = Spring.SetUnitRulesParam

-- Variables
local shopUnits = {}

function gadget:AllowUnitCreation(unitDefID, builderID, teamID, x, y, z)
	if GetGameRulesParam("shopmode") == 1 then
		ud = UnitDefs[unitDefID]
		local money = GetTeamResources(teamID, "metal")
		local buildCost = ud.metalCost
		if buildCost > money then
			return false
		end
		return true
	end
end

function gadget:UnitCreated(unitID, unitDefID, teamID, builderID)
	if GetGameRulesParam("shopmode") == 1 then
		local ud = UnitDefs[unitDefID]
		local noSelect = true
		if ud.customParams.shop then
			shopUnits[#shopUnits+1] = unitID
			noSelect = false
		end
		if noSelect == true then
			SetUnitSensorRadius(unitID, "los", 0)
			SetUnitSensorRadius(unitID, "radar", 0)
			SetUnitSensorRadius(unitID, "airLos", 0)
			SetUnitNoSelect(unitID, true)
			SetUnitHealth(unitID, {paralyze = 100000})
		end
		if ud.customParams.maxammo then
			SetUnitRulesParam(unitID, "ammo", ud.customParams.maxammo)
		end
	end
end

function gadget:GameFrame(n)
	if n % 30 == 0 and n > 10 then
		if GetGameRulesParam("shopmode") == 1 then
			local teamsWhichAreDoneBuying = 0
			for i, unitID in ipairs(shopUnits) do
				local numDisabled = 0
				local teamID = GetUnitTeam(unitID)
				local money = GetTeamResources(teamID, "metal")
				local cmdDescs = GetUnitCmdDescs(unitID)
				local ud = UnitDefs[Spring.GetUnitDefID(unitID)]
				for cmdDescID = 1, #cmdDescs do
					local buildDefID = cmdDescs[cmdDescID].id
					if buildDefID < 0 then -- a build order
						local buildCost = UnitDefs[-buildDefID].metalCost
						if buildCost > money then
							numDisabled = numDisabled + 1
							EditUnitCmdDesc(unitID, cmdDescID, {disabled = true, params = {"X"}})
						else
							local disabled = GetUnitCmdDescs(unitID, cmdDescID, cmdDescID)[1]["disabled"]
							if disabled then
								numDisabled = numDisabled - 1
								EditUnitCmdDesc(unitID, cmdDescID, {disabled = false, params = {}})
							end
						end
					end

				end
				--Spring.Echo("numdisabled vs cmddescs", numDisabled, #ud["buildOptions"])
				if numDisabled == #ud["buildOptions"] and GetUnitIsBuilding(unitID) == nil then
					teamsWhichAreDoneBuying = teamsWhichAreDoneBuying + 1
				end
			end
			--Spring.Echo("teamsdonebuying vs team list-1", teamsWhichAreDoneBuying, #Spring.GetTeamList()-1)
			if (teamsWhichAreDoneBuying == #shopUnits) then
				Spring.GameOver({})
			end
		end
	end
end

else

-- UNSYNCED

end
