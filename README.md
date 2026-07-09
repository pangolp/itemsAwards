# Items Awards

[Español](README.es.md)

![20250424210041_1](https://github.com/user-attachments/assets/20568750-2f27-4635-8e4b-42f986b1a7c1)

A Project Zomboid mod compatible with **Build 41** and **Build 42**. Every time a player kills a zombie, the server rolls a random number between 1 and a configurable maximum (default 100). If it matches one of the configured prize numbers and the player has enough kills, they receive an item — either directly in their inventory or placed on the zombie's body for them to loot.

All reward logic runs on the **server** (authoritative). The client only displays notifications and a history panel.

## Features

- Prize table managed entirely via the in-game **admin panel** — no file editing required.
- **Configurable dice range**: admin can raise or lower the max roll value at any time.
- **Server-side winner log** automatically records every win to a plain-text file for auditing.
- HUD icon that opens a session history of wins and losses.
- The HUD icon is draggable and remembers its position between sessions.
- Options panel to control notification style and list limits.
- Chat or halo notification when a prize is won or lost.

## Player options

| Option | Description |
|---|---|
| Show dice when losing | Display the losing roll number in the notification |
| Show message in chat | Use chat bubble instead of halo note |
| Winning entries limit | How many wins to keep in the history panel (5 / 10 / 15 / 20) |
| Losing entries limit | How many losses to keep in the history panel (5 / 10 / 15 / 20) |

## Admin panel

Accessible to admins and moderators (always visible in single-player) via the **Manage Awards** button in the HUD panel.

### Award fields

| Field | Description |
|---|---|
| Item type | Full item type string (e.g. `Base.Axe`) — validated against the game's script manager |
| Number | The lucky roll (1 – max dice). Only one entry can own each number. |
| Count | How many copies to give |
| Min. kills | Minimum zombie kills the player must have before they can win |
| On zombie | Yes = item placed on zombie body to loot; No = goes directly to inventory |

### Configurable max dice

The bottom bar of the admin panel shows the current max dice value. Change the number and click **Apply** to save immediately. The server stores this in `ItemsAwards_config.txt` and will use it for all future rolls. Adding or editing an award number greater than the current max is blocked with an error.

Awards in the list whose number exceeds the current max are highlighted in orange/red and prefixed with `!` so they are easy to spot and correct.

## Winner log

The server appends one line to `ItemsAwards_winners_log.txt` every time a player wins an item:

```
[2026-07-09 15:30:45] Player: JohnDoe               | Roll:  50/100 | Item: Base.Money                    x1   | Placement: Inventory    | Kills: 42 (min: 1)
```

The file is never overwritten — only appended. Copy it manually to examine it. Losers are not recorded.

## Server-side data files

All files live in `Zomboid/Lua/` (or the equivalent folder on a dedicated server):

| File | Contents |
|---|---|
| `ItemsAwards_awards.txt` | Prize table CSV, edited via admin panel |
| `ItemsAwards_config.txt` | Max dice setting |
| `ItemsAwards_winners_log.txt` | Append-only winner log |
| `ItemsAwards_hudButtonPos.txt` | HUD button position (per client) |

## Folder structure

Build 41 reads directly from `media/` at the root. Build 42 uses a version-merge mechanism: it reads `common/` as the base layer, then `42/` for overrides. Both builds have **completely separate native code** — no compatibility shims.

```
Contents/mods/ItemsAwards/
|-- mod.info                    B41: root mod descriptor
|-- itemsAwards.png
|-- media/                      Build 41 only (native B41 code)
|   |-- lua/
|   |   |-- client/
|   |   |   |-- UI/awardsUI.lua         (player panel + HUD button)
|   |   |   |-- UI/awardsAdminUI.lua    (admin CRUD panel)
|   |   |   |-- awardsClient.lua
|   |   |   `-- awardsOptions.lua       (ModOptions legacy API)
|   |   |-- server/
|   |   |   |-- awardsData.lua          (prize table + config persistence)
|   |   |   `-- awardsServer.lua        (roll logic, commands)
|   |   `-- shared/Translate/
|   |       `-- AR | EN | ES  (*.txt)
|   `-- ui/icons/               (button icons)
|-- common/                     Build 42 only (native B42 code)
|   |-- mod.info
|   |-- itemsAwards.png
|   |-- media/
|   |   |-- lua/
|   |   |   |-- client/
|   |   |   |   |-- UI/awardsUI.lua
|   |   |   |   |-- UI/awardsAdminUI.lua
|   |   |   |   |-- awardsClient.lua
|   |   |   |   `-- awardsOptions.lua   (PZAPI.ModOptions)
|   |   |   |-- server/
|   |   |   |   |-- awardsData.lua
|   |   |   |   `-- awardsServer.lua
|   |   |   `-- shared/Translate/
|   |   |       `-- AR | EN | ES  (*.json)
|   |   `-- ui/icons/
`-- 42/                         Build 42 marker only
    |-- mod.info
    `-- itemsAwards.png
```

> If you add a translation key, do it in **both** `media/shared/Translate/` (B41, `.txt` Lua table format) and `common/media/lua/shared/Translate/` (B42, `.json` format). There is no sync step. B42 uses `%1`/`%2` placeholders; B41 uses `%s`/`%d` with `string.format`.

## Links

- [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=2911373802)
