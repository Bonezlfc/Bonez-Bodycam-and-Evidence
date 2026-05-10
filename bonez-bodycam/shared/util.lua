-- ─────────────────────────────────────────────────────────────
--  shared/util.lua  —  helpers available to all client modules
-- ─────────────────────────────────────────────────────────────

--- Returns two formatted strings: date ("YYYY-MM-DD") and time ("HH:MM:SS")
--- Uses GetLocalTime() — the FiveM-safe way to read the client's system clock.
--- (os.date is not available in FiveM's Lua sandbox)
function GetDateTimeStrings()
    local hour, minute, second, day, month, year = GetLocalTime()
    local date = string.format('%04d-%02d-%02d', year, month, day)
    local time = string.format('%02d:%02d:%02d', hour, minute, second)
    return date, time
end

--- Find the 1-based index of a value in an array, or return 1 if not found.
function IndexOf(tbl, value)
    for i, v in ipairs(tbl) do
        if v == value then return i end
    end
    return 1
end

--- Clamp a number between lo and hi.
function Clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end
