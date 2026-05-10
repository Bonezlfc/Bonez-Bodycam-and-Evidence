---@diagnostic disable: undefined-global
-- bonez-bodycam_evidence | server/upload.lua
-- Upload adapter layer — routes video uploads and deletes to the configured provider.
--
-- Provider is set via Config.UploadMethod.Video in config.lua.
-- API keys are read from ApiKeys (defined in server/apiKeys.lua).
-- This file NEVER exposes keys or URLs to clients.

Upload = {}

-- ── Provider: Fivemanage ──────────────────────────────────────────────────
-- Video upload is handled entirely by the NUI (MediaRecorder → WebM → presigned URL).
-- The server only needs to delete clips by their Fivemanage remote ID.

local function FivemanageDelete(remoteId, cb)
    if not remoteId or remoteId == '' then
        if cb then cb(true) end
        return
    end
    DebugPrint('SERVER', 'Fivemanage DELETE → remote id: ' .. tostring(remoteId))
    PerformHttpRequest(
        'https://api.fivemanage.com/api/v3/file/' .. remoteId,
        function(status)
            local ok = status == 200 or status == 204
            if ok then
                DebugPrint('SERVER', 'Fivemanage DELETE OK → ' .. tostring(remoteId))
            else
                print('^1[BCE] Fivemanage DELETE HTTP ' .. tostring(status) .. ' for id ' .. tostring(remoteId) .. '^7')
            end
            if cb then cb(ok) end
        end,
        'DELETE',
        '',
        { ['Authorization'] = ApiKeys.Fivemanage }
    )
end

-- ── Public API ─────────────────────────────────────────────────────────────

-- Delete a previously uploaded clip by its provider-assigned remote ID.
-- cb(success)
function Upload.Delete(remoteId, cb)
    FivemanageDelete(remoteId, cb)
end
