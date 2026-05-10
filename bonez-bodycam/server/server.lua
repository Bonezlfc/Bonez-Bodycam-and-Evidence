-- ─────────────────────────────────────────────────────────────
--  server/server.lua  —  state tracking, proximity beep,
--                        Night Shifts dept sync, server time
-- ─────────────────────────────────────────────────────────────

-- [serverId] = { name = string }
local activeCams = {}

-- ── State sync ───────────────────────────────────────────────

-- Client fires this whenever its active state changes.
RegisterNetEvent('bodycam:setActive', function(active)
    local src = source
    if active then
        activeCams[src] = { name = GetPlayerName(src) or '' }
    else
        activeCams[src] = nil
    end
end)

-- ── Proximity beep ───────────────────────────────────────────

-- Client fires this periodically while the bodycam is active.
-- Server distance-filters and only sends to players within range.
RegisterNetEvent('bodycam:requestBeep', function()
    local src = source
    if not activeCams[src] then return end

    local srcCoords = GetEntityCoords(GetPlayerPed(src))
    local range     = (Config and Config.BeepRange) or 15.0

    for _, pidStr in ipairs(GetPlayers()) do
        local pid    = tonumber(pidStr) or 0
        local coords = GetEntityCoords(GetPlayerPed(pid))
        local dx     = srcCoords.x - coords.x
        local dy     = srcCoords.y - coords.y
        local dz     = srcCoords.z - coords.z
        if math.sqrt(dx*dx + dy*dy + dz*dz) <= range then
            TriggerClientEvent('bodycam:playBeep', pid,
                               srcCoords.x, srcCoords.y, srcCoords.z, range)
        end
    end
end)

-- ── Night Shifts department name sync ────────────────────────
--
-- ERS fires ErsIntegration::OnToggleShift whenever a player
-- starts or ends a shift.  We use that hook to query Night
-- Shifts for the player's department and push the short name
-- to the client, where it feeds the service-type fallback chain:
--   ERS service type → Night Shifts dept name → manual setting

RegisterServerEvent('ErsIntegration::OnToggleShift')
AddEventHandler('ErsIntegration::OnToggleShift', function(isOnShift, _)
    local src = source

    if not isOnShift then
        TriggerClientEvent('bonez-bodycam:setNightShiftsDept', src, nil)
        return
    end

    if GetResourceState('night_shifts_mdt') ~= 'started' then return end

    local ok, nsData = pcall(function()
        return exports['night_shifts_mdt']:GetUserShiftData(src)
    end)
    if not ok or type(nsData) ~= 'table' or not nsData.departmentId then
        TriggerClientEvent('bonez-bodycam:setNightShiftsDept', src, nil)
        return
    end

    local ok2, depts = pcall(function()
        return exports['night_shifts_mdt']:GetDepartments()
    end)
    if not ok2 or type(depts) ~= 'table' then
        TriggerClientEvent('bonez-bodycam:setNightShiftsDept', src, nil)
        return
    end

    for _, dept in ipairs(depts) do
        if dept.id == nsData.departmentId then
            local shortName = (dept.departmentShortName ~= nil
                               and dept.departmentShortName ~= '')
                               and dept.departmentShortName
                               or dept.departmentName
            TriggerClientEvent('bonez-bodycam:setNightShiftsDept', src,
                               shortName and shortName:upper() or nil)
            return
        end
    end

    TriggerClientEvent('bonez-bodycam:setNightShiftsDept', src, nil)
end)

-- ── Server time sync ─────────────────────────────────────────

RegisterNetEvent('bodycam:requestServerTime')
AddEventHandler('bodycam:requestServerTime', function()
    local src       = source
    local t_local   = os.date('*t')
    local t_utc     = os.date('!*t')
    local tz_offset = (t_local.hour * 3600 + t_local.min * 60 + t_local.sec)
                    - (t_utc.hour   * 3600 + t_utc.min   * 60 + t_utc.sec)
    if tz_offset >  43200 then tz_offset = tz_offset - 86400 end
    if tz_offset < -43200 then tz_offset = tz_offset + 86400 end
    TriggerClientEvent('bodycam:serverTime', src, os.time() + tz_offset)
end)

-- ── Search exports ───────────────────────────────────────────

-- Returns { serverId, name } for all players with an active bodycam.
exports('getActiveCams', function()
    local result = {}
    for sid, data in pairs(activeCams) do
        table.insert(result, { serverId = sid, name = data.name })
    end
    return result
end)

-- Returns the entry for the first active cam whose player name
-- contains the given string (case-insensitive), or nil.
exports('findCamByName', function(nameQuery)
    local q = tostring(nameQuery or ''):lower()
    for sid, data in pairs(activeCams) do
        if data.name:lower():find(q, 1, true) then
            return { serverId = sid, name = data.name }
        end
    end
    return nil
end)

-- ── Clean up on disconnect ───────────────────────────────────

AddEventHandler('playerDropped', function()
    activeCams[source] = nil
end)
