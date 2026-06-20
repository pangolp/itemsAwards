# Items Awards

![20250424210041_1](https://github.com/user-attachments/assets/20568750-2f27-4635-8e4b-42f986b1a7c1)

- The idea of ​​the mod is simple. Every time a person kills a zombie, a script is executed internally, which obtains a random number, currently between 1 and 500. If that number matches any of the winning prizes within the table, a message is displayed to the player and the item is left on the zombie's body (so the player has to search among the bodies).

In addition, we are actively working to improve the code and add new features. For example, we recently added two new features:

- The ability to configure some options, thanks to the "options" mode.
- A viewer with the history of items obtained during the session.

It's important to note that, for now, there are two options:

- View the losing dice
- Change the format in which this message is displayed.

(But we'll probably add more later)

Regarding the viewer, the history is currently maintained while the user is on the server.

When the user leaves, disconnects, or loses connection, the history is reset.

```
ItemsAwards/
|-- Contents
|   `-- mods
|       `-- ItemsAwards
|           |-- mod.info              (root copy, read directly by Build 41)
|           |-- itemsAwards.png
|           |-- media
|           |   `-- lua
|           |       |-- client
|           |       |   |-- UI
|           |       |   |   `-- awardsUI.lua
|           |       |   |-- awardsClient.lua
|           |       |   `-- awardsOptions.lua
|           |       |-- server
|           |       |   `-- awardsServer.lua
|           |       `-- shared
|           |           `-- Translate
|           |               |-- AR / EN / ES (*.txt)
|           |-- 42
|           |   |-- itemsAwards.png
|           |   |-- mod.info
|           |   `-- media
|           |       `-- lua
|           |           |-- client
|           |           |   |-- ModOptions.lua          (B42 override: PZAPI.ModOptions)
|           |           |   `-- UI
|           |           |       `-- awardsUI_b42patch.lua
|           |           `-- shared
|           |               `-- Translate (AR/EN/ES *.json)
|           `-- common
|               |-- itemsAwards.png
|               |-- mod.info
|               `-- media
|                   |-- lua
|                   |   |-- client
|                   |   |   |-- UI
|                   |   |   |   `-- awardsUI.lua
|                   |   |   |-- awardsClient.lua
|                   |   |   `-- awardsOptions.lua
|                   |   |-- server
|                   |   |   `-- awardsServer.lua
|                   |   `-- shared
|                   |       `-- Translate (AR/EN/ES *.txt)
|                   `-- ui
|                       `-- icons
|                           `-- gift_regular_icon.png
|-- README.md
|-- preview.png
`-- workshop.txt
```

> The root copy (`mod.info` + `media/`) is what Build 41 reads directly. `common/` + `42/` is the same content plus B42-only overrides, used by Build 42's own version-merge mechanism. Keep root and `common/` in sync manually — there is no build step that does it for you.

#### External link
* [Steam WorkShop](https://steamcommunity.com/sharedfiles/filedetails/?id=2911373802)

Greetings.
