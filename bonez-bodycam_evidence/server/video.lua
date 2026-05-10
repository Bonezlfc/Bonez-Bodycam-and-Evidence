---@diagnostic disable: undefined-global
-- bonez-bodycam_evidence | server/video.lua
-- Video upload is handled entirely by the NUI (MediaRecorder → WebM → presigned URL).
-- This file now only exposes the delete helper used by storage cleanup.

Video = {}

function Video.DeleteFromFivemanage(remoteId, cb)
    Upload.Delete(remoteId, cb)
end
