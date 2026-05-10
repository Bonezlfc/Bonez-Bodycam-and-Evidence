Config = {}

-- ─────────────────────────────────────────────────────────────
--  KEYBINDS / COMMANDS
-- ─────────────────────────────────────────────────────────────

-- [ = open the configuration menu
Config.MenuCommand = 'bodycam'
Config.DefaultKey  = 'LBRACKET'

-- ] = toggle the overlay on / off
Config.ToggleCommand = 'bodycamtoggle'
Config.ToggleKey     = 'RBRACKET'

-- ─────────────────────────────────────────────────────────────
--  DEFAULT OVERLAY SETTINGS
-- ─────────────────────────────────────────────────────────────

Config.Defaults = {
    enabled      = true,
    style        = 'axon',        -- 'axon' | 'motorola' | 'generic'
    position     = 'topright',    -- 'topleft' | 'topright' | 'bottomleft' | 'bottomright'
    scale        = 'medium',      -- 'small' | 'medium' | 'large'
    showService  = true,
    showCallout  = true,
    showTracking = true,
    showUnit     = true,
}

-- ─────────────────────────────────────────────────────────────
--  ACCESS CONTROL
-- ─────────────────────────────────────────────────────────────
--  Night Shifts MDT department IDs that are considered police.
--  Only players on shift in one of these departments can use
--  the bodycam overlay and evidence system.
--
--  To find your IDs:
--    Open Night Shifts MDT as Super Admin → Departments
--    Each department row has a numeric ID — add police IDs here.
--    Leave empty ({}) to allow ALL on-shift players (not recommended).
-- ─────────────────────────────────────────────────────────────

Config.PoliceDepartmentIds = {
    -- e.g. 1, 3, 5
}

-- ─────────────────────────────────────────────────────────────
--  PERFORMANCE
-- ─────────────────────────────────────────────────────────────

Config.ERSPollInterval = 300   -- ms between ERS export polls

-- ─────────────────────────────────────────────────────────────
--  LAYOUT
-- ─────────────────────────────────────────────────────────────

Config.Padding       = 0.012   -- safe-area gap from screen edge
Config.BlinkInterval = 900     -- REC blink period (ms)

-- ─────────────────────────────────────────────────────────────
--  PROXIMITY SOUND
-- ─────────────────────────────────────────────────────────────

Config.BeepInterval = 120000  -- ms between proximity beeps (2 minutes)
Config.BeepRange    = 15.0    -- metres at which beep can be heard
Config.BeepVolume   = 0.25    -- volume multiplier (distance-faded)

-- ─────────────────────────────────────────────────────────────
--  SERVICE TYPES (manual fallback when ERS + MDT unavailable)
-- ─────────────────────────────────────────────────────────────
--  Shown in the settings menu as a manual fallback.
--  ERS and Night Shifts MDT automatically provide this at runtime
--  and take priority over the manual selection.
-- ─────────────────────────────────────────────────────────────

Config.ServiceTypes = {
    '',
    'POLICE',
    'FIRE',
    'EMS',
    'SAR',
    'RANGER',
    'SHERIFF',
    'HIGHWAY PATROL',
}

-- ─────────────────────────────────────────────────────────────
--  RECORDING TOGGLE SOUNDS
-- ─────────────────────────────────────────────────────────────

Config.RecordSoundVolume = 0.80   -- 0.0 – 1.0
