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
itemsAwards/
|-- Contents
|   `-- mods
|       `-- ItemsAwards
|           |-- media
|           |   |-- lua
|           |   |   |-- client
|           |   |   |   |-- UI
|           |   |   |   |   `-- awardsUI.lua
|           |   |   |   |-- awards.lua
|           |   |   |   `-- awardsOptions.lua
|           |   |   `-- shared
|           |   |       `-- Translate
|           |   |           |-- AR
|           |   |           |   |-- IG_UI_AR.txt
|           |   |           |   |-- Tooltip_AR.txt
|           |   |           |   `-- UI_AR.txt
|           |   |           |-- EN
|           |   |           |   |-- IG_UI_EN.txt
|           |   |           |   |-- Tooltip_EN.txt
|           |   |           |   `-- UI_EN.txt
|           |   |           `-- ES
|           |   |               |-- IG_UI_ES.txt
|           |   |               |-- Tooltip_ES.txt
|           |   |               `-- UI_ES.txt
|           |   `-- ui
|           |       `-- icons
|           |           `-- gift_regular_icon.png
|           `-- mod.info
|-- README.md
|-- preview.png
`-- workshop.txt

14 directories, 17 files
```

#### External link
* [Steam WorkShop](https://steamcommunity.com/sharedfiles/filedetails/?id=2911373802)

Greetings.
