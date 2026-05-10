-- ─────────────────────────────────────────────────────────────
--  client/ers.lua  —  ERS polling + Night Shifts integration
-- ─────────────────────────────────────────────────────────────
--  Exposes:
--    ERSState             — cached ERS poll state
--    IsPoliceOnShift()    — true when on shift as police
--    IsRecording()        — true when evidence resource is recording
--    GetUnitLabel(uid)    — NS callsign → manual → server ID
--    GetActiveServiceType() — ERS → NS dept → manual → nil
-- ─────────────────────────────────────────────────────────────

ERSState = {
    available       = false,
    onShift         = false,
    serviceType     = nil,
    attachedCallout = false,
    trackingUnit    = false,
}

-- Night Shifts department name pushed from server on each shift toggle
local nightShiftsDeptName = nil

-- ── Night Shifts department name sync ────────────────────────

RegisterNetEvent('bonez-bodycam:setNightShiftsDept')
AddEventHandler('bonez-bodycam:setNightShiftsDept', function(deptName)
    nightShiftsDeptName = deptName
end)

-- ── ERS poll ─────────────────────────────────────────────────

local function PollERS()
    if GetResourceState('night_ers') ~= 'started' then
        ERSState.available       = false
        ERSState.onShift         = false
        ERSState.serviceType     = nil
        ERSState.attachedCallout = false
        ERSState.trackingUnit    = false
        return
    end

    ERSState.available = true

    local ok, val

    ok, val = pcall(function() return exports['night_ers']:getIsPlayerOnShift() end)
    ERSState.onShift = ok and (val == true) or false

    if ERSState.onShift then
        ok, val = pcall(function() return exports['night_ers']:getPlayerActiveServiceType() end)
        ERSState.serviceType = (ok and type(val) == 'string') and val or nil

        ok, val = pcall(function() return exports['night_ers']:getIsPlayerAttachedToCallout() end)
        ERSState.attachedCallout = ok and (val == true) or false

        ok, val = pcall(function() return exports['night_ers']:getIsPlayerTrackingUnit() end)
        ERSState.trackingUnit = ok and (val == true) or false
    else
        ERSState.serviceType     = nil
        ERSState.attachedCallout = false
        ERSState.trackingUnit    = false
    end
end

Citizen.CreateThread(function()
    while true do
        PollERS()
        Citizen.Wait(Config.ERSPollInterval)
    end
end)

-- ── Public helpers ────────────────────────────────────────────

-- Returns true when the player is on shift as a police officer.
-- Uses Night Shifts IsOnPoliceShift() when available; falls back
-- to ERS on-shift status if Night Shifts is not running.
function IsPoliceOnShift()
    if GetResourceState('night_shifts_mdt') == 'started' then
        local ok, result = pcall(function()
            return exports['night_shifts_mdt']:IsOnPoliceShift()
        end)
        if ok then return result == true end
    end
    return ERSState.onShift
end

-- Returns true when the evidence resource is actively recording.
function IsRecording()
    local ok, val = pcall(function()
        return exports['bonez-bodycam_evidence']:isRecording()
    end)
    return ok and val == true
end

-- Returns the display unit label.
-- Priority: Night Shifts callsign → manual unit ID → server ID.
function GetUnitLabel(uid)
    if GetResourceState('night_shifts_mdt') == 'started' then
        local ok, cs = pcall(function()
            return exports['night_shifts_mdt']:GetPlayerCallsign()
        end)
        if ok and type(cs) == 'string' and cs ~= '' then return cs end
    end
    if Settings and Settings.manualUnitId and Settings.manualUnitId ~= '' then
        return Settings.manualUnitId
    end
    return uid or tostring(GetPlayerServerId(PlayerId()))
end

-- Returns the active service-type label.
-- Priority: ERS service type → Night Shifts department → manual → nil.
function GetActiveServiceType()
    if ERSState.serviceType and ERSState.serviceType ~= '' then
        return ERSState.serviceType
    end
    if nightShiftsDeptName and nightShiftsDeptName ~= '' then
        return nightShiftsDeptName
    end
    if Settings and Settings.manualServiceType and Settings.manualServiceType ~= '' then
        return Settings.manualServiceType
    end
    return nil
end

-- ── Exports for bonez-bodycam_evidence ────────────────────────

-- Returns the player's current unit ID (NS callsign → manual → server ID).
exports('getUnitId', function()
    return GetUnitLabel(tostring(GetPlayerServerId(PlayerId())))
end)

-- Returns the active service type string, or nil if none.
exports('getActiveServiceType', function()
    return GetActiveServiceType()
end)
