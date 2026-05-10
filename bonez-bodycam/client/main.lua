-- ─────────────────────────────────────────────────────────────
--  client/main.lua  —  init, keybinds, NUI sync
-- ─────────────────────────────────────────────────────────────

Settings.Load()

-- ── [ key — open config menu ──────────────────────────────────

RegisterCommand(Config.MenuCommand, function()
    BodycamMenu.Open()
end, false)

RegisterKeyMapping(
    Config.MenuCommand,
    'Open Bodycam Settings Menu',
    'keyboard',
    Config.DefaultKey
)

-- ── ] key — toggle overlay on / off ──────────────────────────

RegisterCommand(Config.ToggleCommand, function()
    -- Block toggling on when not on police duty
    if not Settings.enabled and not IsPoliceOnShift() then
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(
            '~r~BODYCAM~s~: You must be on Police duty to enable the bodycam.'
        )
        EndTextCommandThefeedPostTicker(false, true)
        return
    end

    Settings.enabled = not Settings.enabled
    Settings.Save()

    if Settings.enabled then
        pcall(function() exports['bonez-bodycam_evidence']:startManualRecord() end)
    else
        pcall(function() exports['bonez-bodycam_evidence']:stopManualRecord() end)
    end

    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(
        Settings.enabled
            and '~g~BODYCAM~s~: ~g~ON ~s~— recording started'
            or  '~r~BODYCAM~s~: ~r~OFF ~s~— recording stopped'
    )
    EndTextCommandThefeedPostTicker(false, true)
end, false)

RegisterKeyMapping(
    Config.ToggleCommand,
    'Toggle Bodycam Overlay',
    'keyboard',
    Config.ToggleKey
)

-- ── NUI state sync + server state notification (every 500 ms) ──

local lastServerActive = nil

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)

        local uid       = tostring(GetPlayerServerId(PlayerId()))
        local active    = Settings.enabled and IsRecording()
        local unitLabel = GetUnitLabel(uid)

        SendNUIMessage({
            action       = 'setState',
            visible      = active,
            style        = Settings.style,
            position     = Settings.position,
            scale        = Settings.scale,
            uid          = uid,
            unitLabel    = unitLabel,
            showUnit     = Settings.showUnit,
            showService  = Settings.showService,
            showCallout  = Settings.showCallout,
            showTracking = Settings.showTracking,
            serviceType      = GetActiveServiceType()       or false,
            attachedCallout  = ERSState.attachedCallout     or false,
            trackingUnit     = ERSState.trackingUnit        or false,
        })

        if active ~= lastServerActive then
            TriggerServerEvent('bodycam:setActive', active)
            lastServerActive = active
        end
    end
end)

-- ── Periodic proximity beep ───────────────────────────────────

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.BeepInterval)
        if Settings.enabled and IsRecording() then
            TriggerServerEvent('bodycam:requestBeep')
        end
    end
end)

-- ── Exports for bonez-bodycam_evidence ───────────────────────

-- Session-only overlay toggle (does NOT persist to KVP).
exports('setOverlayEnabled', function(state)
    Settings.enabled = (state == true)
end)

-- Plays the audio feedback sound for the active overlay style.
exports('playRecordSound', function(recording)
    SendNUIMessage({
        action    = 'playRecordSound',
        recording = recording == true,
        style     = Settings.style,
        volume    = Config.RecordSoundVolume or 0.80,
    })
end)

-- ── Server time sync ─────────────────────────────────────────

RegisterNetEvent('bodycam:serverTime')
AddEventHandler('bodycam:serverTime', function(adjustedEpoch)
    SendNUIMessage({
        action       = 'syncServerTime',
        serverTimeMs = adjustedEpoch * 1000,
    })
end)

Citizen.CreateThread(function()
    Citizen.Wait(1000)
    while true do
        TriggerServerEvent('bodycam:requestServerTime')
        Citizen.Wait(300000)
    end
end)

-- ── Receive proximity beep ────────────────────────────────────

RegisterNetEvent('bodycam:playBeep', function(sx, sy, sz, range)
    local myCoords = GetEntityCoords(PlayerPedId())
    local dist     = #(vector3(sx, sy, sz) - myCoords)
    local vol      = math.max(0.0, math.min(1.0, (1.0 - (dist / range)) * (Config.BeepVolume or 1.0)))
    SendNUIMessage({ action = 'playBeep', volume = vol })
end)
