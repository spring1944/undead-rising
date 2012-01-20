--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function gadget:GetInfo()
  return {
    name      = "Command Radius",
    desc      = "May only issue orders to units within a 'command radius' around certain units.",
    author    = "B. Tyler",
    date      = "July 8th, 2009",
    license   = "LGPL v2 or later",
    layer     = 0,
    enabled   = false  --  loaded by default?
  }
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local SetUnitRulesParam = Spring.SetUnitRulesParam
--------------------------------------------------------------------------------
--  COMMON
--------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then
--------------------------------------------------------------------------------
--  SYNCED
--------------------------------------------------------------------------------
local SetUnitNoSelect = GG.SetUnitNoSelect --uses game_noselect gadget
local GiveOrderToUnit = GG.GiveOrderToUnitDisregardingNoSelect
local GetUnitSeparation  = Spring.GetUnitSeparation

local commandUnits = {}
local infantry = {}

local initFrame
local modOptions

if (Spring.GetModOptions) then
  modOptions = Spring.GetModOptions()
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function findCommander(unitID)
    local closestCommander
    local closestDistance = math.huge
    local allyTeam = GetUnitAllyTeam(vehicleID)
    for commanderID in pairs(commandUnits) do
        local cmdAllyTeam = GetUnitAllyTeam(commanderID)
        local cmdTeam = GetUnitTeam(commanderID)
        if allyTeam == cmdAllyTeam or cmdTeam == GAIA_TEAM_ID then
            local separation = GetUnitSeparation(vehicleID, commanderID, true)
            local commanderDefID = GetUnitDefID(commanderID)
            local commandRadius = tonumber(UnitDefs[commanderDefID].customParams.commandradius)
            if separation < closestDistance and separation <= commandRadius then
                closestCommander = commanderID
                closestDistance = separation
            end
        end
    end
    return closestCommander
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
    local ud = UnitDefs[unitDefID]
    if ud.customParams.radio then
    if ud.customParams.commandRadius then
        commandUnits[unitID] = commandRadius
    end
    if ud.customParams.feartarget and not(ud.canfly) then
        infantry[unitID] = true
    end
	end
end


function gadget:UnitDestroyed(unitID)
    commandUnits[unitID] = nil
    infantry[unitID] = nil
end

function gadget:GameFrame(n)

    if (n == initFrame + 5) then
        for _, unitID in ipairs(Spring.GetAllUnits()) do
            local teamID = Spring.GetUnitTeam(unitID)
            local unitDefID = Spring.GetUnitDefID(unitID)    
            local ud = UnitDefs[unitDefID]
            if ud.customParams.commandRadius then
                commandUnits[unitID] = true
            end
        end
    end
    if n > (initFrame+5) then
        if n % (1*30) < 0.1 then
            for unitID in pairs(infantry) do
                local unitDefID = GetUnitDefID(unitID)
                local teamID = Spring.GetUnitTeam(unitID)
                local commanderID = findCommander(unitID)
                if commanderID then
                    SetUnitNoSelect(unitID, false)
                else
                    SetUnitNoSelect(unitID, true)
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
--  SYNCED
--------------------------------------------------------------------------------
else
--  UNSYNCED
--------------------------------------------------------------------------------
end

