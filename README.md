# Items Awards

[Español](README.es.md)

![20250424210041_1](https://github.com/user-attachments/assets/20568750-2f27-4635-8e4b-42f986b1a7c1)

A Project Zomboid mod compatible with **Build 41** and **Build 42**. Every time a player kills a zombie, the server rolls a random number between 1 and 100. If it matches one of the configured prize numbers and the player has enough kills, they receive an item — either directly in their inventory or placed on the zombie's body for them to loot.

All reward logic runs on the **server** (authoritative). The client only displays notifications and a history panel.

## Features

- Configurable prize table (item, required kills, delivery method).
- HUD icon that opens a session history of wins and losses.
- The HUD icon is draggable and remembers its position between sessions.
- Options panel to control notification style and list limits.
- Chat or halo notification when a prize is won or lost.

## Options

| Option | Description |
|---|---|
| Show dice when losing | Display the losing roll number in the notification |
| Show message in chat | Use chat bubble instead of halo note |
| Winning entries limit | How many wins to keep in the history panel (5/10/15/20) |
| Losing entries limit | How many losses to keep in the history panel (5/10/15/20) |

## Folder structure

Build 41 reads directly from `media/` at the root. Build 42 uses a version-merge mechanism: it reads `common/` as the base layer, then `42/` for overrides. Both builds have **completely separate native code** — no compatibility shims.

```
Contents/mods/ItemsAwards/
|-- mod.info                    B41: root mod descriptor
|-- itemsAwards.png
|-- media/                      Build 41 only (native B41 code)
|   `-- lua/
|       |-- client/
|       |   |-- UI/awardsUI.lua         (InventoryItemFactory texture API)
|       |   |-- awardsClient.lua
|       |   `-- awardsOptions.lua       (ModOptions legacy API)
|       |-- server/
|       |   `-- awardsServer.lua        (string.format + getText, %s/%d)
|       `-- shared/Translate/
|           `-- AR | EN | ES  (*.txt)
|-- common/                     Build 42 only (native B42 code)
|   |-- mod.info
|   |-- itemsAwards.png
|   `-- media/lua/
|       |-- client/
|       |   |-- UI/awardsUI.lua         (getScriptManager texture API)
|       |   |-- awardsClient.lua
|       |   `-- awardsOptions.lua       (PZAPI.ModOptions)
|       |-- server/
|       |   `-- awardsServer.lua        (variadic getText, %1/%2)
|       `-- shared/Translate/
|           `-- AR | EN | ES  (*.json)
`-- 42/                         Build 42 marker only
    |-- mod.info
    `-- itemsAwards.png
```

> If you edit a prize or add a translation key, do it in **both** `media/` (B41) and `common/` (B42). There is no sync step.

## Customizing prizes

Open `awardsServer.lua` in both `media/lua/server/` and `common/lua/server/` and edit the `itemsAwards` table:

```lua
local itemsAwards = {
    {Item = "Base.Money", Number = 50, Count = 1, zkills = 1, onZombie = false},
}
```

| Field | Description |
|---|---|
| `Item` | Full item type string (e.g. `"Base.Axe"`) |
| `Number` | The lucky roll (1–100). Only one entry can own each number. |
| `Count` | How many copies to give |
| `zkills` | Minimum zombie kills the player must have |
| `onZombie` | `true` = item placed on zombie body; `false` = goes to inventory |

## Links

- [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=2911373802)
