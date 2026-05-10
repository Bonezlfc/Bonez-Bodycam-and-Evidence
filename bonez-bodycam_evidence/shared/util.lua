-- bonez-bodycam_evidence | shared/util.lua
-- UUID generation, time formatting, heading helper, debug print

-- ── Debug print ────────────────────────────────────────────────────────────
-- side: 'CLIENT' | 'SERVER' | any label
-- Only prints when Config.Debug == true
function DebugPrint(side, msg)
    if not Config or not Config.Debug then return end
    print(string.format('^3[BCE | %s]^7 %s', tostring(side):upper(), tostring(msg)))
end

-- ── UUID v4 ────────────────────────────────────────────────────────────────
function GenerateUUID()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

-- ── Timestamp formatting ───────────────────────────────────────────────────
-- Server-side: os.time() is available; client-side: use GetLocalTime() native.
-- This function is intended for server use.
function FormatTimestamp(ts)
    if os and os.date then
        return os.date('%Y-%m-%d %H:%M:%S', ts)
    end
    return tostring(ts)
end

-- Returns a human-readable duration string e.g. "4m 12s"
function FormatDuration(seconds)
    seconds = math.floor(seconds or 0)
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    if m > 0 then
        return string.format('%dm %ds', m, s)
    else
        return string.format('%ds', s)
    end
end

-- Returns short human-readable timestamp from Unix epoch (server-side only)
function ShortDate(ts)
    if os and os.date then
        return os.date('%Y-%m-%d %H:%M', ts)
    end
    return tostring(ts)
end

-- ── Heading to cardinal direction ──────────────────────────────────────────
function HeadingToCardinal(heading)
    heading = heading % 360
    local dirs = {'N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'}
    local idx = math.floor((heading + 22.5) / 45) % 8 + 1
    return dirs[idx]
end

-- ── Table shallow-copy ─────────────────────────────────────────────────────
function ShallowCopy(t)
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = v
    end
    return copy
end

-- ── Safe JSON encode with fallback ────────────────────────────────────────
-- json global is provided by FiveM runtime
function SafeJsonEncode(t)
    local ok, result = pcall(json.encode, t)
    if ok then return result end
    return '{}'
end

function SafeJsonDecode(s)
    if not s or s == '' then return nil end
    local ok, result = pcall(json.decode, s)
    if ok then return result end
    return nil
end
