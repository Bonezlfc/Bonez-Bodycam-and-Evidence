# bonez-bodycam

A FiveM bodycam overlay and court-evidence recording system, rebuilt as a fully standalone package.
No ESX, QB-Core, or Qbox required.

---

## MANDATORY DEPENDENCIES

These resources **MUST** be installed and running. The bodycam **will not function** without them.

| Resource | Version | Role |
|---|---|---|
| [**night_ers**](https://github.com/night-scripts/night_ers) | **1.8.8** | On-shift detection, service type, callout/tracking state |
| [**night_shifts_mdt**](https://github.com/night-scripts/night_shifts_mdt) | **1.4.0** | Police-shift gate, callsign, department name, rank permissions |
| [**RageUI**](https://github.com/ItsikNox/RageUI) | latest | In-game settings menu |

> **Do not use older versions.** The integration calls depend on specific export signatures introduced in night_ers 1.8.8 and night_shifts_mdt 1.4.0. Running earlier versions will cause silent failures or resource crashes.

---

## Optional Dependencies

| Resource | Role |
|---|---|
| **oxmysql** | Persistent MySQL clip storage — if absent the system falls back to server KVP |

---

## What Is Included

| Resource | Purpose |
|---|---|
| `bonez-bodycam` | On-screen overlay — three styles (Axon, Motorola, Generic), in-game settings menu via RageUI |
| `bonez-bodycam_evidence` | Automatic video recording triggered by ERS callout/tracking/weapon events; in-game evidence viewer hub |

---

## Access Control

Access is entirely job-gated through Night Shifts MDT — **no framework job system needed**.

- The bodycam overlay and settings menu are available **only while on a police shift** (`IsOnPoliceShift()`).
- The evidence hub requires either the `evidence_view` rank permission in Night Shifts **or** being on a police shift in a department listed in `Config.PoliceDepartmentIds`.
- Evidence deletion (admin) requires Night Shifts admin level ≥ 2, or txAdmin `command` ACE.
- Fire, EMS, tow, and civilian players cannot toggle the overlay or open the evidence hub.

---

## Installation

1. Copy `bonez-bodycam` and `bonez-bodycam_evidence` into your server `resources` directory.
2. Add the following to your `server.cfg` **in this order**:

```
ensure RageUI
ensure night_ers
ensure night_shifts_mdt
ensure oxmysql                 # optional — omit if not using MySQL
ensure bonez-bodycam           # must come before evidence
ensure bonez-bodycam_evidence
```

3. Configure `bonez-bodycam/config.lua`:
   - Set `Config.PoliceDepartmentIds` to your Night Shifts department IDs.
   - Adjust keybinds, overlay defaults, beep interval/range, and service type labels as needed.

4. Configure `bonez-bodycam_evidence/config.lua`:
   - Mirror `Config.PoliceDepartmentIds` to match the bodycam config.
   - Set `Config.EvidenceViewPermission` (default `'evidence_view'`) to match your Night Shifts rank permission string.
   - Set `Config.EvidenceAdminLevel` (default `2`) to the minimum Night Shifts admin level for deletion.
   - Add your Fivemanage API key to `bonez-bodycam_evidence/server/apiKeys.lua`.

5. In Night Shifts MDT, add `evidence_view` to the permissions list of any rank that should be able to view evidence clips.

---

## Default Keybinds

Players can rebind these under **FiveM Settings → Key Bindings**.

### bonez-bodycam

| Action | Default Key | Command |
|---|---|---|
| Open settings menu | `[` | `/bodycam` |
| Toggle overlay on/off | `]` | `/bodycamtoggle` |

### bonez-bodycam_evidence

| Action | Default Key | Command |
|---|---|---|
| Open evidence hub | `F9` | `/evidence` |
| Manual record start/stop | `F6` | `/evidencerec` |

---

## Unit ID Priority

The unit label shown on the overlay and stored with evidence clips resolves in this order:

1. Night Shifts MDT callsign (`GetPlayerCallsign()`)
2. Player's manually entered unit ID (set in the bodycam settings menu)
3. FiveM server ID

---

## Service Type Priority

The service/department label on the overlay and stored with clips resolves in this order:

1. ERS active service type (`getPlayerActiveServiceType()`)
2. Night Shifts MDT department short name (synced from server on shift toggle)
3. Player's manually selected service type (set in the bodycam settings menu)

---

## Evidence Recording Triggers

When `bonez-bodycam_evidence` is running, recordings are triggered automatically by:

| Trigger | Description |
|---|---|
| `CALLOUT` | Officer attaches to a callout in ERS |
| `TRACKING` | Officer begins tracking a unit in ERS; recording finalises after `Config.TrackingCooldown` seconds of idle |
| `WEAPON_FIRED` | Officer fires a weapon; records for `Config.WeaponClipDuration` seconds |
| `MANUAL` | Officer presses the manual record keybind (`F6` default) |

---

## Exports

### bonez-bodycam (client)

```lua
-- Toggle overlay visibility for the local player (session only, does not persist to KVP)
exports['bonez-bodycam']:setOverlayEnabled(true | false)

-- Play the recording start/stop audio cue for the active overlay style
exports['bonez-bodycam']:playRecordSound(true | false)

-- Returns the player's current unit ID (NS callsign → manual → server ID)
exports['bonez-bodycam']:getUnitId()

-- Returns the active service type string, or nil
exports['bonez-bodycam']:getActiveServiceType()
```

### bonez-bodycam (server)

```lua
-- Returns array of { serverId, name } for all players with an active bodycam
exports['bonez-bodycam']:getActiveCams()

-- Returns { serverId, name } for the first active cam whose player name contains the query, or nil
exports['bonez-bodycam']:findCamByName(nameQuery)
```

### bonez-bodycam_evidence (client)

```lua
-- Returns true when the evidence resource is actively recording
exports['bonez-bodycam_evidence']:isRecording()

-- Manually start / stop a recording (used by bonez-bodycam toggle command)
exports['bonez-bodycam_evidence']:startManualRecord()
exports['bonez-bodycam_evidence']:stopManualRecord()
```

---

## File Structure

```
bonez-bodycam/
  fxmanifest.lua
  config.lua
  shared/
    util.lua
  client/
    settings.lua          KVP-backed per-player settings
    ers.lua               night_ers polling + Night Shifts integration
    menu.lua              RageUI settings menu
    main.lua              keybinds, NUI sync, beep, server time sync
  server/
    server.lua            state tracking, proximity beep, NS dept sync
  html/
    index.html
    css/style.css
    fonts/
    img/
    sound/

bonez-bodycam_evidence/
  fxmanifest.lua
  config.lua
  shared/
    util.lua
  client/
    recorder.lua          recording state machine + ERS trigger polling
    viewer.lua            evidence hub NUI
    main.lua              keybinds, exports
  server/
    apiKeys.lua           Fivemanage API key (fill this in)
    upload.lua            Fivemanage upload provider
    storage.lua           oxmysql / KVP dual-backend
    video.lua             Fivemanage video helpers
    main.lua              Night Shifts auth layer + net event handlers
  html/
    index.html
    style.css
    script.js
    cfx_renderer.js
  module/                 Three.js renderer modules (bundled)
```

---

## Troubleshooting

**Overlay never appears**
- Confirm `night_ers` 1.8.8 and `night_shifts_mdt` 1.4.0 are both running.
- Confirm the player is on a police shift in Night Shifts MDT.
- Check F8 / txAdmin console for errors on resource start.

**Settings menu says "You must be on Police duty"**
- The player is not currently on a police shift in Night Shifts MDT.
- Verify the player's department ID is listed in `Config.PoliceDepartmentIds`.

**Evidence hub shows no clips / returns empty**
- Verify the player's rank has `evidence_view` permission in Night Shifts MDT, or that their department is in `Config.PoliceDepartmentIds`.
- If using MySQL, confirm `oxmysql` is running and the tables have been created.

**Evidence delete button does nothing**
- The player's `adminLevel` in Night Shifts MDT must be ≥ `Config.EvidenceAdminLevel` (default 2), or they must have the txAdmin `command` ACE.

**Unit ID shows server ID instead of callsign**
- Confirm Night Shifts MDT is running and the player has a callsign set in the MDT.
- As a fallback, players can set a manual unit ID in the bodycam settings menu.

---

## Credits

- **Bonez Workshop** — original script author
- Night Shifts integration, RageUI rebuild, evidence auth rewrite
- [RageUI](https://github.com/ItsikNox/RageUI) — in-game menu framework
- KlartextMono font — overlay typography
- Axon style inspired by the AXON Body 3 BWC
- Motorola style inspired by the Motorola Solutions BWC2
