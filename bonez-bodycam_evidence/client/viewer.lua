---@diagnostic disable: undefined-global, duplicate-set-field
-- bonez-bodycam_evidence | client/viewer.lua
-- NUI evidence viewer: direct player page open + clip hub browser.

Viewer = {}

local isOpen = false

-- ── Helpers ─────────────────────────────────────────────────────────────────

local function Notify(msg)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(msg)
    DrawNotification(false, false)
end

-- ── NUI callback — close button ─────────────────────────────────────────────
RegisterNUICallback('close', function(_, cb)
    Viewer.Close()
    cb({})
end)

-- ── NUI callback — get video presigned URL ───────────────────────────────────
local pendingPresignedUrlCb = nil

RegisterNUICallback('getVideoPresignedUrl', function(_, cb)
    pendingPresignedUrlCb = cb
    TriggerServerEvent('bonez-bodycam_evidence:requestVideoPresignedUrl')
end)

RegisterNetEvent('bonez-bodycam_evidence:videoPresignedUrlResult')
AddEventHandler('bonez-bodycam_evidence:videoPresignedUrlResult', function(url, err)
    if pendingPresignedUrlCb then
        if url then
            pendingPresignedUrlCb({ url = url })
        else
            pendingPresignedUrlCb({ error = err or 'Failed to get presigned URL' })
        end
        pendingPresignedUrlCb = nil
    end
end)

-- ── NUI callback — save video URL to DB ─────────────────────────────────────
RegisterNUICallback('saveVideoUrl', function(data, cb)
    if type(data.clipId) == 'string' and type(data.url) == 'string' then
        TriggerServerEvent('bonez-bodycam_evidence:saveVideoUrl', data.clipId, data.url)
    end
    cb({ ok = true })
end)

-- ── NUI callback — hub: search clips for a unit ─────────────────────────────
RegisterNUICallback('searchClips', function(data, cb)
    local unitId = tostring(data.unitId or '')
    if unitId ~= '' then
        TriggerServerEvent('bonez-bodycam_evidence:requestClips', unitId)
    end
    cb({ ok = true })
end)

-- ── NUI callback — hub: delete a clip ───────────────────────────────────────
RegisterNUICallback('deleteClip', function(data, cb)
    if type(data.clipId) == 'string' then
        TriggerServerEvent('bonez-bodycam_evidence:deleteClip', data.clipId)
    end
    cb({ ok = true })
end)

-- ── NUI callback — hub: export clip info to chat ────────────────────────────
RegisterNUICallback('exportToChat', function(data, cb)
    TriggerEvent('chat:addMessage', {
        color     = { 0, 200, 255 },
        multiline = true,
        args      = {
            'EVIDENCE',
            string.format(
                'Clip: %s | Unit: %s | Trigger: %s | Date: %s | Duration: %s | Service: %s | Frames: %s | Status: %s',
                data.clipId       or 'N/A',
                tostring(data.unitId or 'N/A'),
                data.trigger      or 'N/A',
                FormatTimestamp(data.startTime),
                FormatDuration(data.duration),
                data.serviceType  or 'N/A',
                tostring(data.totalFrames or 0),
                data.uploadStatus or 'N/A'
            )
        }
    })
    cb({ ok = true })
end)

-- ── Net event: server sends clip list (forward to NUI hub) ───────────────────
RegisterNetEvent('bonez-bodycam_evidence:receiveClips')
AddEventHandler('bonez-bodycam_evidence:receiveClips', function(clips)
    if isOpen then
        SendNUIMessage({ action = 'receiveClips', clips = clips or {} })
    else
        -- Viewer closed before results arrived — silently drop
        DebugPrint('CLIENT', 'receiveClips arrived but viewer is closed — dropped')
    end
end)

-- ── Net event: server confirms clip deleted (forward to NUI hub) ─────────────
RegisterNetEvent('bonez-bodycam_evidence:clipDeleted')
AddEventHandler('bonez-bodycam_evidence:clipDeleted', function(clipId, success, reason)
    if isOpen then
        SendNUIMessage({ action = 'clipDeleted', clipId = clipId, success = success, reason = reason })
    end
    if success then
        DebugPrint('CLIENT', 'Clip deleted: ' .. tostring(clipId))
    else
        Notify('~r~Delete failed: ' .. tostring(reason or 'unknown error'))
    end
end)

-- ── Public API ───────────────────────────────────────────────────────────────

-- Open the clip hub browser (keybind press)
function Viewer.OpenHub()
    if isOpen then Viewer.Close() end
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openHub' })
end

-- Open the player page directly for a known clip (e.g. after recording)
function Viewer.Open(fivemanageUrl, clipMeta)
    if isOpen then Viewer.Close() end
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action   = 'open',
        url      = fivemanageUrl,
        metadata = {
            clipId        = clipMeta.clipId       or 'N/A',
            unitId        = clipMeta.unitId       or 'N/A',
            trigger       = clipMeta.trigger      or 'N/A',
            startTime     = clipMeta.startTime    or 0,
            endTime       = clipMeta.endTime      or 0,
            duration      = clipMeta.duration     or 0,
            serviceType   = clipMeta.serviceType  or 'N/A',
            totalFrames   = clipMeta.totalFrames  or 0,
            uploadStatus  = clipMeta.uploadStatus or 'N/A',
        },
    })
end

function Viewer.Close()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

function Viewer.IsOpen()
    return isOpen
end
