# ErzbaroneUI

A reduced World of Warcraft Forever Interface

## Usage

Extract the `ErzbaroneUI` directory from the release zip into the `World of Warcraft\_forever_\Interface\AddOns\` directory.
To open the configuration, go to Game Menu → Options → AddOns → ErzbaroneUI or type `/eui`.

### Via CurseForge

The addon is available on CurseForge too, search for `ErzbaroneUI` or [on their website](https://www.curseforge.com/wow/addons/erzbaroneui).

## Features

- Auto sell grey items
- Auto repair
- Optional vignette effect
- Five second rule timer on the player mana bar
- Optional swing timer spark on the player power bar for melee and ranged fighters
- Textured health and power bars on the unit frames (classic, smooth, skills or a custom `textures\statusbar` file), also selectable for the cast bars
- Class colored health bars for players and grey health bars for creatures tapped by others
- Optionally hides the large threat glow around the player, target and focus frames
- Cast count on action buttons (how often a mana spell can be cast with the current mana)
- Red tint on action buttons while the target is out of range
- Hides the button column left of the chat window
- Moves the chat window into the lower left corner
- Hides the chat tabs until the mouse is over the chat window
- Hides the vertical action bars on the right until hovered
- Improved Layout (Experimental, disabled by default): compact secure action bars and XP/reputation bars with an adjacent micro menu and corner bags; no Edit Mode profiles
- Hides the bag names in the bag windows
- Compact minimap: removes the header, places tracking, calendar, mail and addon buttons on the minimap border and shows the server time inside the minimap; the buttons can be hidden until the minimap is hovered

## Improved Layout (Experimental)

Enable **Improved Layout (Experimental)** under **Action Bars** in `/eui`.
The micro menu sits immediately left of the left gryphon with an 8 UI-unit gap and its bottom 12 UI units above the screen edge; the bag bar stays at the bottom right.
Both bars fade out independently until hovered and remain visible in Edit Mode.
The micro menu and bag bar retain 100% of their native size, preserving existing button scales and bag orientation.
The main bar and Action Bar 2 use 12-button rows, with Action Bar 3 arranged as two rows of six to their right. Custom secure containers host Blizzard's original button containers rather than copying the action buttons. Native click handlers, bindings, paging references and combat updates remain untouched.
Buttons 1-6 of Action Bar 3 use Blizzard's main-bar frame artwork behind their row while the redesign is enabled.
Those six buttons also show the main bar's individual slot backdrops; buttons 7-12 keep their native appearance. Disabling restores the original backdrops.
The complete block is centered with its background artwork meeting the bottom screen edge, with gryphons at its sides and XP/reputation bars shortened to its width between the rows.
Native main-bar dividers are suppressed while enabled. XP dividers and the rested-XP marker are recalculated whenever the status bars resize, including during startup.
XP/reputation runtime anchors are also reapplied after direct native positioning updates, including in combat while the containers are unprotected, so the bars stay aligned with the action block. Protected frame changes still wait until combat ends.
When Action Bar 3 is disabled, the main bar and Action Bar 2 form a narrower centered block, with XP/reputation bars and gryphon spacing adjusted to its width. If Action Bar 2 is also disabled, only the main action row remains, with the status bars directly above it. Re-enabling bars restores the wider layout automatically; changes during combat wait until combat ends. Actions, keybindings and bar visibility settings are preserved.
Stance/shapeshift, pet, possession and vehicle/flight-landing controls align with the block's left edge above its highest active action row (or the status bars in the main-row-only layout). Simultaneously visible auxiliary bars stack upward with a small gap. Their native visibility, buttons and click handlers remain unchanged; hidden controls are positioned in advance, and protected layout changes wait until combat ends.
In two-row layouts, the player cast bar is centered 32 UI units above the highest action row to leave room for its spell label. The main-row-only layout and disabling Improved Layout restore its original runtime position.
The micro menu is detached from its original container. Action bars and status bars use runtime anchors without changing saved Edit Mode settings.
No Edit Mode profile is created, selected, saved, restored or required. Enabling the option applies the custom bars directly, including after a reload.
Resetting Edit Mode or selecting another layout keeps the custom action bars enabled and leaves the selected profile untouched.
Chat size, buff placement, unit frames and other cast bars are not changed by Improved Layout; their separate addon settings still apply.
Disabling restores the native bars' runtime appearance and placement without switching profiles.
Profiles created by older versions are left untouched and can be selected or deleted manually in Edit Mode. The addon no longer uses them or their per-character saved state.
Changes requested in combat apply after combat ends. Fully restart the game after updating from the old implementation to clear existing taint.

## Development

Run the layout regression tests with `lua tests\actionlayout_test.lua`.
They reject all Edit Mode profile API calls and writes to native secure button references. They check native button reuse and modeled clicks/paging, adaptive action/auxiliary-bar placement and stacking, divider suppression, immediate XP resizing and marker updates, runtime restoration, resets, reloads and combat deferral.
Actual combat protection still needs testing in the Forever client.

## Screenshots

![ErzbaroneUI (UI)](docs/full.jpg)
![ErzbaroneUI (UI)](docs/settings.jpg)

## Credits

- [FiveSecondRule](https://github.com/smp4903/FiveSecondRule) and [WeaponSwingTimer](https://github.com/LeftHandedGlove/WeaponSwingTimerAddon) for the idea of the timer sparks on the power bar
- [wow-ui-source](https://github.com/Gethe/wow-ui-source) by Gethe, the Blizzard interface source used as reference
- [wow-ui-source-forever](https://github.com/Ketho/wow-ui-source-forever/tree/forever) by Ketho, the matching Forever FrameXML reference (upstream live sources differ)
- [Warcraft Wiki](https://warcraft.wiki.gg/wiki/World_of_Warcraft_API) for the API documentation
- [World of Warcraft Programming](https://wowprogramming.com/index.html)
