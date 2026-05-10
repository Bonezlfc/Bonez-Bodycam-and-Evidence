# Bonez-Bodycam

A FiveM bodycam overlay resource with three visual styles. Integrates with **night_ers** for automatic on-shift detection — the overlay only appears while a player is on duty.

Pair it with [bonez-bodycam_evidence](../bonez-bodycam_evidence/README.md) to add court-grade automatic video recording and an in-game evidence viewer.

---

## Features

- Three overlay styles: **Axon**, **Motorola**, and **Generic (Watchdog)**
- Configurable screen corner, text scale, and visible info lines
- In-game settings menu — players can adjust everything without touching files
- Per-player settings saved via KVP (persist across sessions and reconnects)
- Proximity beep: nearby players hear a soft beep while your bodycam is active
- Discord role-gated settings menu (optional — leave `Config.AdminRoles` empty to allow all)
- NUI (HTML/CSS) rendering — sharp at any resolution
- NativeUI (FrazzIe) is bundled — no separate NativeUI resource needed
- OneSync compatible

---

## Requirements

- **FiveM** server (OneSync Legacy or Infinity)
- [**night_ers**](https://github.com/night-scripts/night_ers) — controls on-shift detection

---

## Installation

1. Drop the `Bonez-Bodycam` folder into your server's `resources` directory.
2. Add `ensure Bonez-Bodycam` to your `server.cfg`.
3. Edit `config.lua` to set your preferences (see [Configuration](#configuration) below).
4. If you want Discord role-based menu permissions, also fill in `server/svConfig.lua` (see [Discord Setup](#discord-setup)).
5. Restart your server or run `refresh` + `ensure Bonez-Bodycam` in the console.

---

## Default Keybinds

Players can rebind these in **FiveM Settings → Key Bindings → Bonez-Bodycam**.

| Action | Default Key | Command |
|---|---|---|
| Open settings menu | `[` (Left Bracket) | `/bodycam` |
| Toggle overlay on/off | `]` (Right Bracket) | `/bodycamtoggle` |

To change the server-side defaults, edit `Config.DefaultKey` and `Config.ToggleKey` in `config.lua`.

---

## Configuration

All options are in `config.lua`.

```lua
-- Default overlay appearance (players can override via in-game menu)
Config.Defaults = {
    enabled      = true,
    style        = 'axon',      -- 'axon' | 'motorola' | 'generic'
    position     = 'topright',  -- 'topleft' | 'topright' | 'bottomleft' | 'bottomright'
    scale        = 'medium',    -- 'small' | 'medium' | 'large'
    showService  = true,        -- show ERS service type (FIRE, EMS, etc.)
    showCallout  = true,        -- show CALLOUT badge when attached to a callout
    showTracking = true,        -- show TRACKING badge
    showUnit     = true,        -- show server ID as UNIT: X
}

-- How often the bodycam emits a proximity beep (milliseconds)
Config.BeepInterval = 120000   -- 2 minutes

-- Maximum distance (metres) at which the beep can be heard
Config.BeepRange    = 15.0

-- Volume of the beep (0.0 = silent, 1.0 = full)
Config.BeepVolume   = 0.25

-- Discord role IDs allowed to open the settings menu.
-- Leave as an empty table {} to allow ALL players.
Config.AdminRoles = {
    -- "YOUR_ROLE_ID_HERE",
}
```

---

## Discord Setup

Discord role permissions are **optional**. If `Config.AdminRoles` is empty, every player can open the settings menu — skip this section.

If you want to restrict the settings menu to specific Discord roles:

### 1. Create a Discord Bot

1. Go to [discord.com/developers/applications](https://discord.com/developers/applications) and click **New Application**.
2. Open the **Bot** tab → **Add Bot**.
3. Under **Privileged Gateway Intents**, enable **Server Members Intent**.
4. Copy the bot token — paste it into `server/svConfig.lua` as `bot_token`.

### 2. Invite the Bot to Your Server

Use this URL (replace `YOUR_CLIENT_ID` with your application's Client ID from the General Information tab):

```
https://discord.com/oauth2/authorize?client_id=YOUR_CLIENT_ID&scope=bot&permissions=0
```

### 3. Get Your Server ID and Role IDs

- Enable **Developer Mode** in Discord: User Settings → Advanced → Developer Mode.
- Right-click your server icon → **Copy Server ID** → paste into `server/svConfig.lua` as `server_id`.
- Right-click each role in Server Settings → Roles → **Copy Role ID** → add to `Config.AdminRoles` in `config.lua`.

### 4. Fill in svConfig.lua

```lua
-- server/svConfig.lua
configS.bot_token = "YOUR_BOT_TOKEN_HERE"
configS.server_id = "YOUR_DISCORD_SERVER_ID_HERE"
```

> **Never share your bot token publicly.** If it leaks, regenerate it immediately in the Discord developer portal.

---

## In-Game Menu

Open with the menu keybind (default `[`). The menu lets players configure:

- Enable / disable the overlay
- Overlay style, position, and scale
- Which info lines are visible
- Reset everything to server defaults
- Live ERS status indicator (Active / Not Detected)

Changes take effect immediately and persist across sessions.

---

## Integration with bonez-bodycam_evidence

[bonez-bodycam_evidence](../bonez-bodycam_evidence/README.md) is an optional addon that adds automatic video recording and an in-game evidence viewer. When installed alongside this resource:

- **Bonez-Bodycam** handles the on-screen overlay and exposes the player's unit ID
- **bonez-bodycam_evidence** monitors ERS events and weapon discharge; when a recording trigger fires, it enables the overlay via `exports['Bonez-Bodycam']:setOverlayEnabled(true)`, then restores the normal ERS-driven state when recording ends

### server.cfg load order (with evidence addon)

```
ensure Bonez-Bodycam           # must come first
ensure night_ers
ensure NativeUI
ensure oxmysql                 # optional — enables persistent MySQL clip storage
ensure bonez-bodycam_evidence  # must come after Bonez-Bodycam
```

No extra configuration is needed in `Bonez-Bodycam` itself — all recording and evidence settings live in `bonez-bodycam_evidence/config.lua`.

---

## Exports

Other resources (including bonez-bodycam_evidence) can toggle the overlay programmatically:

```lua
-- Enable or disable the overlay for the local player
-- Session-only — does not save to KVP
exports['Bonez-Bodycam']:setOverlayEnabled(true)
exports['Bonez-Bodycam']:setOverlayEnabled(false)
```

---

## File Structure

```
Bonez-Bodycam/
  config.lua              -- server-side defaults and tunables
  fxmanifest.lua
  shared/
    util.lua              -- shared helper functions
  client/
    settings.lua          -- KVP-backed per-player settings
    ers.lua               -- night_ers polling thread
    NativeUI.lua          -- bundled FrazzIe NativeUI library
    menu.lua              -- settings menu
    main.lua              -- entry point, keybinds, NUI sync, beep logic
  server/
    svConfig.lua          -- Discord bot credentials (fill this in)
    discord.lua           -- Discord API helpers
    server.lua            -- state tracking + proximity beep routing
  html/
    index.html            -- NUI overlay (all three styles)
    css/style.css
    fonts/KlartextMonoBold.ttf
    img/logo.png
    sound/beep.wav
```

---

## Troubleshooting

**Overlay never appears**
- Confirm `night_ers` is running and the player is on shift.
- Check the server console for errors on resource start.

**Discord connection failed**
- Verify `bot_token` and `server_id` in `server/svConfig.lua` are correct.
- Confirm Server Members Intent is enabled on the bot.
- Make sure the bot has been invited to your Discord server.

**Settings menu says "no permission"**
- Check that your Discord role ID is listed in `Config.AdminRoles`.
- Make sure your Discord account is linked in FiveM (identifiers must include `discord:XXXX`).
- If you don't need role gating, set `Config.AdminRoles = {}`.

**Position or scale changes don't apply immediately**
- The overlay only updates while visible (while on shift). Changes save immediately and apply when the overlay is next shown.

---

## Credits

- **Bonez Workshop** — script author
- [FrazzIe/NativeUILua](https://github.com/FrazzIe/NativeUILua) — bundled NativeUI library
- KlartextMono font — overlay typography
- Axon style inspired by the AXON Body 3 BWC
- Motorola style inspired by the Motorola Solutions BWC2
