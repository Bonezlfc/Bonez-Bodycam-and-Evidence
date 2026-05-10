---@diagnostic disable: undefined-global, duplicate-set-field, unused-local
-- bonez-bodycam_evidence | client/recorder.lua
-- Sends startCapture/stopCapture to the NUI, which uses CfxTexture + MediaRecorder.
-- No screenshot-basic, no GPU readback stall, no in-game stutter.

Recorder = {}

local captureActive = false
local currentClipId = nil

-- ── Public API ─────────────────────────────────────────────────────────────

function Recorder.Start(clipId, _trigger, _serviceType)
    captureActive = true
    currentClipId = clipId
    DebugPrint('CLIENT', 'Recorder START → ' .. tostring(clipId))

    SendNUIMessage({
        action = 'startCapture',
        clipId = clipId,
        width  = 1280,
        height = 720,
        fps    = 20,
    })
end

function Recorder.Stop()
    if not captureActive and not currentClipId then return end
    captureActive = false

    local clipId  = currentClipId
    currentClipId = nil

    DebugPrint('CLIENT', 'Recorder STOP → ' .. tostring(clipId))

    SendNUIMessage({
        action = 'stopCapture',
        clipId = clipId,
    })

    -- Tell the server capture is done. totalFrames=1 signals a real clip was made.
    -- The NUI handles encoding and uploading asynchronously; server just marks status.
    TriggerServerEvent('bonez-bodycam_evidence:clipCaptureComplete', clipId, 1)
end

function Recorder.GetFrameCount()
    return 0  -- not applicable in CfxTexture mode
end

function Recorder.IsActive()
    return captureActive
end
