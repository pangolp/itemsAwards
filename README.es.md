# Items Awards

[English](README.md)

![20250424210041_1](https://github.com/user-attachments/assets/20568750-2f27-4635-8e4b-42f986b1a7c1)

Mod para Project Zomboid compatible con **Build 41** y **Build 42**. Cada vez que un jugador mata a un zombi, el servidor tira un número aleatorio entre 1 y 100. Si coincide con uno de los números de premio configurados y el jugador tiene suficientes kills, recibe un ítem — ya sea directamente en su inventario o colocado en el cuerpo del zombi para que lo saquee.

Toda la lógica de premios corre en el **servidor** (autoritativo). El cliente solo muestra notificaciones y un panel de historial.

## Características

- Tabla de premios configurable (ítem, kills requeridos, forma de entrega).
- Icono HUD que abre un historial de ganados y perdidos durante la sesión.
- El icono HUD es arrastrable y recuerda su posición entre sesiones.
- Panel de opciones para controlar el estilo de notificación y los límites de listas.
- Notificación por chat o halo cuando se gana o pierde un premio.

## Opciones

| Opción | Descripción |
|---|---|
| Mostrar dado al perder | Muestra el número perdedor en la notificación |
| Mostrar mensaje en el chat | Usa burbuja de chat en lugar de nota halo |
| Límite de ganados | Cuántos ganados mantener en el historial (5/10/15/20) |
| Límite de perdidos | Cuántos perdidos mantener en el historial (5/10/15/20) |

## Estructura de carpetas

Build 41 lee directamente desde `media/` en la raíz. Build 42 usa un mecanismo de "version merge": lee `common/` como capa base, luego `42/` como overrides. Ambas builds tienen **código nativo completamente separado** — sin shims de compatibilidad.

```
Contents/mods/ItemsAwards/
|-- mod.info                    B41: descriptor del mod en la raíz
|-- itemsAwards.png
|-- media/                      Solo Build 41 (código nativo B41)
|   `-- lua/
|       |-- client/
|       |   |-- UI/awardsUI.lua         (API de texturas: InventoryItemFactory)
|       |   |-- awardsClient.lua
|       |   `-- awardsOptions.lua       (ModOptions API legacy)
|       |-- server/
|       |   `-- awardsServer.lua        (string.format + getText, %s/%d)
|       `-- shared/Translate/
|           `-- AR | EN | ES  (*.txt)
|-- common/                     Solo Build 42 (código nativo B42)
|   |-- mod.info
|   |-- itemsAwards.png
|   `-- media/lua/
|       |-- client/
|       |   |-- UI/awardsUI.lua         (API de texturas: getScriptManager)
|       |   |-- awardsClient.lua
|       |   `-- awardsOptions.lua       (PZAPI.ModOptions)
|       |-- server/
|       |   `-- awardsServer.lua        (getText variádico, %1/%2)
|       `-- shared/Translate/
|           `-- AR | EN | ES  (*.json)
`-- 42/                         Solo marcador para Build 42
    |-- mod.info
    `-- itemsAwards.png
```

> Si editás un premio o agregás una clave de traducción, hacelo en **ambos**: `media/` (B41) y `common/` (B42). No hay ningún paso de sincronización automática.

## Personalizar premios

Abrí `awardsServer.lua` en `media/lua/server/` y en `common/lua/server/`, y editá la tabla `itemsAwards`:

```lua
local itemsAwards = {
    {Item = "Base.Money", Number = 50, Count = 1, zkills = 1, onZombie = false},
}
```

| Campo | Descripción |
|---|---|
| `Item` | Tipo de ítem completo (ej. `"Base.Axe"`) |
| `Number` | El número ganador (1–100). Cada número puede pertenecer a un solo ítem. |
| `Count` | Cuántas copias entregar |
| `zkills` | Kills mínimos que debe tener el jugador |
| `onZombie` | `true` = el ítem aparece en el cuerpo del zombi; `false` = va al inventario |

## Enlaces

- [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=2911373802)
