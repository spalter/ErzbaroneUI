# ErzbaroneUI

A reduced World of Warcraft Forever Interface

## Usage

Extract the `ErzbaroneUI` directory from the release zip into the `World of Warcraft\_forever_\Interface\AddOns\` directory.
To open the configuration, select ErzbaroneUI in the minimap's AddOns menu, go to Game Menu → Options → AddOns → ErzbaroneUI or type `/eui`.

### Via CurseForge

The addon is available on CurseForge too, search for `ErzbaroneUI` or [on their website](https://www.curseforge.com/wow/addons/erzbaroneui).

## Features

- Auto sell grey items
- Auto repair
- Optional vignette effect
- HDR output toggle and HDR factor slider (1.0–2.0), using the game's console variables; HDR output is off by default and requires a supported monitor and render settings
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
- Hides the vertical action bars on the right until hovered, with matching main-bar borders, backdrops and textured button slots while this option is enabled
- Optional hold-to-open emote selection beside the mouse cursor, with 24 emote names in three columns
- Improved Main Actionbar Layout, with the menu next to the bags in the lower-right corner and Edit Mode selections aligned to the redesigned bars
- Hides the bag names in the bag windows
- Compact minimap: removes the header, places tracking, calendar, mail and addon buttons on the minimap border and shows the server time inside the minimap; the buttons can be hidden until the minimap is hovered

## Emote selection

Assign **Emote Quick Selection (Hold)** under **Options > Keybindings > AddOns > ErzbaroneUI**. No key is assigned by default.
The **Emotes** section in `/eui` shows the current binding and opens WoW's native Keybindings settings when clicked.
Its **Font Size** selector offers 10–24 in steps of two (default 12), saved between sessions.
Text, columns and hover rows resize immediately; no reload is needed.
Hold the key to open the text-only box beside the cursor, hover an emote name and release the key to perform it.
Releasing outside an entry, on the border or between columns cancels. Mouse clicks do not select, cancel or change pages.
The box stays visible near screen edges. Existing emote keybindings are preserved.

The box contains 24 common emotes, alphabetically arranged in three columns of eight:
Apologize, Beg, Bow, Bye, Cheer, Clap, Cry, Doh, Drink, Flex, Golfclap, Hi, Hug, Kiss, Kneel, Laugh,
Point, Roar, Rude, Salute, Shrug, Sleep, Thanks and Wave.
Only names are shown, using a dark brown backdrop, a bronze-tinted native WoW DiamondMetal dialog border with decorative corners, warm text and a golden highlight on the hovered row.
Doh uses the game's `BONK` token; emotes retain the game's normal targeting behavior.
The `EMOTES` list in `modules\emotes.lua` defines the names and tokens. Wheel textures are no longer used.

## Development

Run the layout regression tests with `lua tests\actionlayout_test.lua`.
They reject all Edit Mode profile API calls and writes to native secure button references. They check native button reuse and modeled clicks/paging, adaptive action/auxiliary-bar placement and stacking, stable stance/shapeshift, pet and possession button positions during native combat reanchoring, divider suppression, immediate XP resizing and marker updates, runtime restoration, resets, reloads and combat deferral.
Auxiliary buttons use stable anchors prepared outside combat while their native containers, visibility and click handlers remain unchanged. Grid and stacking changes during combat are applied after combat ends.
Gryphon anchors are maintained synchronously during native layout updates to avoid briefly reverting to their default positions; tests check this without flushing queued updates.
Actual combat protection still needs testing in the Forever client.

Run the AddOns menu integration test with `lua tests\config_test.lua`.

Run the vertical action-bar backdrop and mouseover fade tests with `lua tests\barfade_test.lua`.

Run the emote selection interaction tests with `lua tests\emotes_test.lua`.

## Screenshots

![ErzbaroneUI (UI)](docs/full.jpg)
![ErzbaroneUI (UI)](docs/settings.jpg)
![ErzbaroneUI (UI)](docs/actionbars.jpg)

## Credits

- [FiveSecondRule](https://github.com/smp4903/FiveSecondRule) and [WeaponSwingTimer](https://github.com/LeftHandedGlove/WeaponSwingTimerAddon) for the idea of the timer sparks on the power bar
- [wow-ui-source](https://github.com/Gethe/wow-ui-source) by Gethe, the Blizzard interface source used as reference
- [wow-ui-source-forever](https://github.com/Ketho/wow-ui-source-forever/tree/forever) by Ketho, the matching Forever FrameXML reference (upstream live sources differ)
- [Warcraft Wiki](https://warcraft.wiki.gg/wiki/World_of_Warcraft_API) for the API documentation
- [World of Warcraft Programming](https://wowprogramming.com/index.html)
