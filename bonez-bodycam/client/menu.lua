---@diagnostic disable: undefined-global, lowercase-global
-- Bonez-Bodycam | client/menu.lua
-- Bodycam settings menu using RageUI.
-- Restricted to players on shift as a police officer.

BodycamMenu = {}

-- ── Labels / keys ─────────────────────────────────────────────

local STYLE_LABELS = { 'Axon', 'Motorola', 'Generic' }
local STYLE_KEYS   = { 'axon', 'motorola', 'generic' }
local POS_LABELS   = { 'Top Left', 'Top Right', 'Bottom Left', 'Bottom Right' }
local POS_KEYS     = { 'topleft',  'topright',  'bottomleft',  'bottomright'  }
local SCALE_LABELS = { 'Small', 'Medium', 'Large' }
local SCALE_KEYS   = { 'small', 'medium', 'large' }

local SVC_LABELS, SVC_KEYS = {}, {}
for _, v in ipairs(Config.ServiceTypes or {}) do
    table.insert(SVC_LABELS, (v == '') and '(None)' or v)
    table.insert(SVC_KEYS,   v)
end
if #SVC_KEYS == 0 then
    SVC_LABELS = { '(None)' }
    SVC_KEYS   = { '' }
end

-- ── Public API (defined early so main.lua never errors on Open()) ──

local bodycamMenu = nil  -- assigned below once RageUI init succeeds

function BodycamMenu.Open()
    if not bodycamMenu then
        print('^1[BODYCAM] Settings menu failed to initialize — verify RageUI is installed and running.^7')
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName('~r~BODYCAM~s~: Settings menu unavailable — check server console.')
        EndTextCommandThefeedPostTicker(false, true)
        return
    end
    if not IsPoliceOnShift() then
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(
            '~r~BODYCAM~s~: You must be on Police duty to access settings.'
        )
        EndTextCommandThefeedPostTicker(false, true)
        return
    end
    RageUI.Visible(bodycamMenu, true)
end

-- ── Menu init (pcall so a RageUI error doesn't leave Open() undefined) ────

local function GetKeyboardInput(title, defaultVal, maxLen)
    AddTextEntry('BC_KB_INPUT', title)
    DisplayOnscreenKeyboard(1, 'BC_KB_INPUT', '', defaultVal or '', '', '', '', maxLen or 12)
    while UpdateOnscreenKeyboard() == 0 do
        DisableAllControlActions(0)
        Citizen.Wait(0)
    end
    EnableAllControlActions(0)
    if UpdateOnscreenKeyboard() == 1 then
        return GetOnscreenKeyboardResult()
    end
    return nil
end

local menuInitOk, menuInitErr = pcall(function()
    bodycamMenu = RageUI.CreateMenu('BODYCAM', 'Configure settings')

    RageUI.CreateWhile(0, function()

        if RageUI.Visible(bodycamMenu) and not IsPoliceOnShift() then
            RageUI.Visible(bodycamMenu, false)
        end

        if not RageUI.Visible(bodycamMenu) then return end

        RageUI.DrawContent({ header = true, glare = true, instructionalButton = true }, function()

            -- ── Status (read-only display) ─────────────────────────
            local unitLabel = GetUnitLabel(tostring(GetPlayerServerId(PlayerId())))
            local recState  = IsRecording() and '~g~REC' or '~r~OFF'
            RageUI.Button('Status', 'Live bodycam state',
                { RightLabel = unitLabel .. '  |  ' .. recState }, false,
                function() end)

            -- ── Unit ID ────────────────────────────────────────────
            local nsCallsign = nil
            if GetResourceState('night_shifts_mdt') == 'started' then
                local ok, cs = pcall(function()
                    return exports['night_shifts_mdt']:GetPlayerCallsign()
                end)
                if ok and type(cs) == 'string' and cs ~= '' then nsCallsign = cs end
            end

            if nsCallsign then
                RageUI.Button('Unit ID', 'Callsign set in Night Shifts MDT — open MDT to change.',
                    { RightLabel = nsCallsign }, false,
                    function() end)
            else
                local uid = Settings.manualUnitId ~= '' and Settings.manualUnitId
                            or ('SID ' .. tostring(GetPlayerServerId(PlayerId())))
                RageUI.Button('Unit ID', 'Your badge / callsign shown on the overlay.',
                    { RightLabel = uid }, true,
                    function(_, _, Selected)
                        if not Selected then return end
                        RageUI.Visible(bodycamMenu, false)
                        Citizen.SetTimeout(150, function()
                            local input = GetKeyboardInput(
                                'Unit ID (badge / callsign)',
                                Settings.manualUnitId,
                                12
                            )
                            if input ~= nil then
                                Settings.manualUnitId = input:gsub('^%s+', ''):gsub('%s+$', '')
                                Settings.Save()
                            end
                            RageUI.Visible(bodycamMenu, true)
                        end)
                    end)
            end

            -- ── Service Type ───────────────────────────────────────
            local svcIdx = IndexOf(SVC_KEYS, Settings.manualServiceType)
            RageUI.List('Service Type', SVC_LABELS, svcIdx,
                'Manual fallback. ERS / MDT take priority when on shift.',
                {}, true,
                function(_, Active, _, Index)
                    if Active then
                        Settings.manualServiceType = SVC_KEYS[Index]
                        Settings.Save()
                    end
                end)

            -- ── Appearance ─────────────────────────────────────────
            RageUI.List('Camera Style', STYLE_LABELS, IndexOf(STYLE_KEYS, Settings.style),
                'Visual style of the overlay.',
                {}, true,
                function(_, Active, _, Index)
                    if Active then
                        Settings.style = STYLE_KEYS[Index]
                        Settings.Save()
                    end
                end)

            RageUI.List('Position', POS_LABELS, IndexOf(POS_KEYS, Settings.position),
                'Screen corner for the overlay.',
                {}, true,
                function(_, Active, _, Index)
                    if Active then
                        Settings.position = POS_KEYS[Index]
                        Settings.Save()
                    end
                end)

            RageUI.List('Scale', SCALE_LABELS, IndexOf(SCALE_KEYS, Settings.scale),
                'Overlay text size.',
                {}, true,
                function(_, Active, _, Index)
                    if Active then
                        Settings.scale = SCALE_KEYS[Index]
                        Settings.Save()
                    end
                end)

            -- ── Visibility toggles ─────────────────────────────────
            RageUI.Checkbox('Show Overlay', 'Toggle the bodycam overlay on / off.',
                Settings.enabled, { Style = RageUI.CheckboxStyle.Tick },
                function(_, _, Active, Checked)
                    if Active and Settings.enabled ~= Checked then
                        Settings.enabled = Checked
                        Settings.Save()
                    end
                end)

            RageUI.Checkbox('Show Unit ID', 'Display your unit ID on the overlay.',
                Settings.showUnit, { Style = RageUI.CheckboxStyle.Tick },
                function(_, _, Active, Checked)
                    if Active and Settings.showUnit ~= Checked then
                        Settings.showUnit = Checked
                        Settings.Save()
                    end
                end)

            RageUI.Checkbox('Show Service Badge', 'Display your service / department badge.',
                Settings.showService, { Style = RageUI.CheckboxStyle.Tick },
                function(_, _, Active, Checked)
                    if Active and Settings.showService ~= Checked then
                        Settings.showService = Checked
                        Settings.Save()
                    end
                end)

            RageUI.Checkbox('Show Callout Badge', 'Show CALLOUT badge when attached to a callout.',
                Settings.showCallout, { Style = RageUI.CheckboxStyle.Tick },
                function(_, _, Active, Checked)
                    if Active and Settings.showCallout ~= Checked then
                        Settings.showCallout = Checked
                        Settings.Save()
                    end
                end)

            RageUI.Checkbox('Show Tracking Badge', 'Show TRACKING badge when tracking a unit.',
                Settings.showTracking, { Style = RageUI.CheckboxStyle.Tick },
                function(_, _, Active, Checked)
                    if Active and Settings.showTracking ~= Checked then
                        Settings.showTracking = Checked
                        Settings.Save()
                    end
                end)

            -- ── Actions ────────────────────────────────────────────
            RageUI.Button('Reset Defaults', 'Restore all settings to defaults.',
                {}, true,
                function(_, _, Selected)
                    if Selected then Settings.Reset() end
                end)

            RageUI.Button('Close', 'Close this menu.',
                {}, true,
                function(_, _, Selected)
                    if Selected then RageUI.Visible(bodycamMenu, false) end
                end)

        end, function()
            -- no panels
        end)

    end, 1)
end)

if not menuInitOk then
    print('^1[BODYCAM] RageUI menu init failed: ' .. tostring(menuInitErr) .. '^7')
end
