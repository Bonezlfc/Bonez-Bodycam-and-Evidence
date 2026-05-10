---@diagnostic disable: duplicate-set-field
-- ─────────────────────────────────────────────────────────────
--  client/settings.lua  —  KVP-backed persistent player settings
-- ─────────────────────────────────────────────────────────────
--  Exposes a single global table:  Settings
--    Settings.Load()   — populate from KVP (or defaults)
--    Settings.Save()   — persist current values to KVP
--    Settings.Reset()  — revert to Config.Defaults and save
-- ─────────────────────────────────────────────────────────────

Settings = {}

local KVP_PREFIX = 'bonez-bodycam_'

-- ── helpers ──────────────────────────────────────────────────

local function Key(k)   return KVP_PREFIX .. k end

local function KvpBool(key, default)
    local v = GetResourceKvpString(Key(key))
    if v == nil then return default end
    return v == 'true'
end

local function KvpStr(key, default)
    local v = GetResourceKvpString(Key(key))
    if v == nil or v == '' then return default end
    return v
end

local function SaveBool(key, value)
    SetResourceKvp(Key(key), value and 'true' or 'false')
end

local function SaveStr(key, value)
    SetResourceKvp(Key(key), tostring(value))
end

-- ── public API ───────────────────────────────────────────────

function Settings.Load()
    local d = Config.Defaults
    Settings.enabled           = KvpBool('enabled',           d.enabled)
    Settings.style             = KvpStr ('style',              d.style)
    Settings.position          = KvpStr ('position',           d.position)
    Settings.scale             = KvpStr ('scale',              d.scale)
    Settings.showService       = KvpBool('showService',        d.showService)
    Settings.showCallout       = KvpBool('showCallout',        d.showCallout)
    Settings.showTracking      = KvpBool('showTracking',       d.showTracking)
    Settings.showUnit          = KvpBool('showUnit',           d.showUnit)
    Settings.manualUnitId      = KvpStr ('manualUnitId',       '')
    Settings.manualServiceType = KvpStr ('manualServiceType',  '')
end

function Settings.Save()
    SaveBool('enabled',           Settings.enabled)
    SaveStr ('style',             Settings.style)
    SaveStr ('position',          Settings.position)
    SaveStr ('scale',             Settings.scale)
    SaveBool('showService',       Settings.showService)
    SaveBool('showCallout',       Settings.showCallout)
    SaveBool('showTracking',      Settings.showTracking)
    SaveBool('showUnit',          Settings.showUnit)
    SaveStr ('manualUnitId',      Settings.manualUnitId)
    SaveStr ('manualServiceType', Settings.manualServiceType)
end

function Settings.Reset()
    local d = Config.Defaults
    Settings.enabled           = d.enabled
    Settings.style             = d.style
    Settings.position          = d.position
    Settings.scale             = d.scale
    Settings.showService       = d.showService
    Settings.showCallout       = d.showCallout
    Settings.showTracking      = d.showTracking
    Settings.showUnit          = d.showUnit
    Settings.manualUnitId      = ''
    Settings.manualServiceType = ''
    Settings.Save()
end
