# Changelog — bonez-bodycam

---

## v3.0.0 — 2026-05-10 — Full Rebuild

Complete ground-up rebuild. ESX, QB-Core, and Qbox removed entirely.
Integrated with Night Shifts MDT and night_ers as the sole authority for
access control, unit identification, and service type resolution.

---

### bonez-bodycam

#### `fxmanifest.lua`
- Bumped to v3.0.0
- Added `dependency 'RageUI'`
- Added `optional_dependency 'night_shifts_mdt'`
- Removed bundled `client/NativeUI.lua` from file list
- Removed `server/discord.lua` and `server/svConfig.lua` from file list

#### `config.lua`
- Removed `Config.AdminRoles` (Discord role gating deleted)
- Added `Config.PoliceDepartmentIds = {}` — Night Shifts department IDs that count as police; fill with your server's IDs

#### `server/discord.lua` — DELETED
#### `server/svConfig.lua` — DELETED
- Discord bot credentials and the entire Discord perms chain removed. Police access is now determined exclusively by Night Shifts MDT.

#### `server/server.lua`
- Removed `bodycam:checkPerms` and `bodycam:perms` events (Discord perms chain)
- Added `ErsIntegration::OnToggleShift` handler: when a player starts a shift, queries Night Shifts MDT for their department name and pushes it to the client via `bonez-bodycam:setNightShiftsDept`

#### `client/NativeUI.lua` — DELETED
- NativeUI (FrazzIe) removed. RageUI is the menu framework going forward.

#### `client/ers.lua`
- Added `local nightShiftsDeptName` — receives the department name pushed from the server on shift toggle
- Added `RegisterNetEvent('bonez-bodycam:setNightShiftsDept')` handler
- `IsPoliceOnShift()`: now calls `exports['night_shifts_mdt']:IsOnPoliceShift()` when Night Shifts is running; falls back to ERS on-shift state
- `IsRecording()`: unchanged — calls `exports['bonez-bodycam_evidence']:isRecording()`
- `GetUnitLabel(uid)`: priority now Night Shifts `GetPlayerCallsign()` → `Settings.manualUnitId` → server ID
- `GetActiveServiceType()`: priority now ERS service type → `nightShiftsDeptName` (from server sync) → `Settings.manualServiceType` → nil

#### `client/menu.lua` — full rewrite (NativeUI → RageUI)
- All NativeUI code removed
- `BodycamMenu.Open()` gates on `IsPoliceOnShift()` — fire, EMS, tow, and civilian players are blocked
- Menu auto-closes if the player goes off police shift while it is open
- Unit ID row: shows Night Shifts callsign as a read-only button when available; otherwise shows an editable button that hides the menu, opens the FiveM onscreen keyboard, saves the result, then re-opens the menu
- Service Type: always shows the list for manual selection; ERS / Night Shifts dept take priority at runtime
- Checkboxes: save only when `Active` is true AND the value actually changed (avoids redundant KVP writes)
- Lists: save on every index change while `Active`

#### `client/main.lua`
- Removed startup `TriggerServerEvent('bodycam:checkPerms')` call
- Removed `RegisterNetEvent('bodycam:perms')` handler
- Toggle command (`/bodycamtoggle`) now gates on `IsPoliceOnShift()` instead of raw `ERSState.onShift`
- All other functionality unchanged: NUI sync thread, proximity beep thread, server time sync, `setOverlayEnabled` export, `playRecordSound` export

---

### bonez-bodycam_evidence

#### `fxmanifest.lua`
- Bumped to v2.0.0
- Changed `dependency 'night_ers'` → `optional_dependency 'night_ers'` (prevents resource start failure if ERS is temporarily offline)
- Added `optional_dependency 'night_shifts_mdt'`

#### `config.lua`
- Removed `Config.AuthorizedJobs` (ESX/QB job list)
- Removed `Config.AdminJobs` (ESX/QB admin job list)
- Added `Config.EvidenceViewPermission = 'evidence_view'` — rank permission string in Night Shifts MDT that grants hub access
- Added `Config.EvidenceAdminLevel = 2` — minimum Night Shifts admin level required to delete clips
- Added `Config.PoliceDepartmentIds = {}` — fallback police check; keep in sync with `bonez-bodycam/config.lua`

#### `server/main.lua` — auth layer rewrite
- Removed `GetPlayerJob()` (ESX + QBCore dead code)
- Added `GetNightShiftsData(src)` — pcall-safe wrapper around `exports['night_shifts_mdt']:GetUserShiftData`
- Added `HasRankPermission(src, permStr, nsData)` — walks `GetRanksByDepartmentId` to check whether the player's rank includes the given permission string
- Added `IsPoliceOfficer(src, nsData)` — checks on-shift status and department ID against `Config.PoliceDepartmentIds`; if the list is empty, any on-shift player is accepted
- `IsAuthorized(src)`: txAdmin `command` ACE → `HasRankPermission(Config.EvidenceViewPermission)` → `IsPoliceOfficer`
- `IsAdmin(src)`: txAdmin `command` ACE → `nsData.adminLevel >= Config.EvidenceAdminLevel`
- All net event handlers and clip lifecycle logic unchanged

---

## Earlier history

For changes prior to this rebuild (original Bonez Workshop releases),
see the archived changelog at `../CHANGELOG.md`.
