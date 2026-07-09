# AGENTS.md — Items Awards (Project Zomboid mod)

Guía para trabajar en este repo. Léela antes de tocar código: el mod soporta
Build 41 **y** Build 42, y la estructura de carpetas es la parte más importante
de entender.

## Qué hace el mod

Cada vez que un jugador mata a un zombi (`Events.OnZombieDead`), el servidor
tira un número aleatorio entre 1 y `maxDice` (configurable, default 100) con
`ZombRandBetween`. Si coincide con una entrada de la tabla de premios **y** el
jugador tiene suficientes kills acumulados, se le entrega un ítem (al inventario
o al cuerpo del zombi). El servidor notifica al cliente vía `sendServerCommand`
(o llamada directa en single-player) para mostrar un halo/mensaje de chat y
actualizar la UI. Cada ganador queda registrado en un log de texto plano del
lado del servidor.

Toda la lógica de negocio vive en el **servidor** (autoritativo). El cliente
solo pinta UI y no decide nada.

## Estructura de carpetas (el punto más importante)

Project Zomboid Build 41 lee el mod **directamente** desde
`Contents/mods/ItemsAwards/media/` (raíz). Build 42 usa un mecanismo de
"version merge": lee `common/media/` (base) y luego `42/media/` (overrides).

```
Contents/mods/ItemsAwards/
├── mod.info, media/...      ← B41 ÚNICAMENTE (código B41 nativo)
├── common/
│   ├── mod.info, media/...  ← B42 ÚNICAMENTE (código B42 nativo)
└── 42/
    ├── mod.info             ← marcador de compatibilidad B42
    └── itemsAwards.png
```

**B41 lee SOLO `media/` de la raíz. B42 lee SOLO `common/` + `42/`.
No hay código compartido entre las dos builds.**

Los archivos de cliente en `common/` empiezan con `if not PZAPI then return end`
para que B41 no los ejecute si escanea subdirectorios. Los archivos de
**servidor** en `common/` usan solo `if isClient() and not isServer() then return end`
— en el servidor PZAPI no está disponible, así que nunca poner ese guard en
archivos server-side.

## Diferencias B41 vs B42 — dónde vive cada cosa

| Tema | B41 (`media/`) | B42 (`common/`) |
|---|---|---|
| Opciones de mod | `awardsOptions.lua` con `ModOptions:getInstance()` | `awardsOptions.lua` con `PZAPI.ModOptions:create()` |
| `getText` con placeholders | `string.format(getText(key), ...)` con `%s/%d` | `getText(key, arg1, arg2)` variádico con `%1/%2` |
| Textura de ítem en la UI | `InventoryItemFactory.CreateItem(item):getTex()` | `getScriptManager():getItem(item):getNormalTexture()` |
| Traducciones | `.txt` tabla Lua en `media/lua/shared/Translate/{EN,ES,AR}/UI_EN.txt` etc. | `.json` en `common/media/lua/shared/Translate/{EN,ES,AR}/UI.json` |
| Sync de inv. al dar ítem | `sendAddItemToContainer(inv, item)` | no necesario (B42 lo maneja) |
| Guard de cliente en common/ | N/A | `if not PZAPI then return end` al inicio |

**Importante**: al agregar una clave de traducción, editá **ambos** archivos. Los formatos son distintos: B41 usa tabla Lua (`UI_ES = { key = "value" }`), B42 usa JSON puro (`{ "key": "value" }`). Los placeholders también difieren: B41 `%s`/`%d` con `string.format`, B42 `%1`/`%2` con `getText(key, arg)` — aunque si el código B42 usa `string.format` para armar el string antes de llamar `setText/setStatus`, los placeholders siguen siendo `%s`/`%d`.

Cada diferencia vive en el archivo nativo de su build, sin shims de
compatibilidad. Si necesitás cambiar algo en ambas builds, editá el archivo
correspondiente en `media/` **Y** el archivo correspondiente en `common/`.

## Módulos y carga

Todo cuelga del global `Awards`:

- **`Awards.Data`** — `awardsData.lua` (server-only). Carga, guarda y expone la
  tabla de premios (`getAll`, `add`, `update`, `remove`) y la config del dado
  máximo (`getMaxDice`, `setMaxDice`). Se inicializa antes que `awardsServer.lua`
  porque los archivos del mismo directorio se cargan en orden alfabético.

- **`Awards.Server`** — `awardsServer.lua` (server-only). Escucha
  `Events.OnZombieDead`, tira el dado, entrega ítems, registra ganadores en el
  log, y despacha comandos de cliente (`addAward`, `updateAward`, `deleteAward`,
  `reloadAwards`, `setMaxDice`, `getAwards`). Valida que el número esté dentro
  del rango `[1, maxDice]` antes de guardar.

- **`Awards.Client`** — `awardsClient.lua` (client-only). Dispatcher de comandos
  del servidor (`award`, `needKills`, `loser`, `awardsList`). Sin lógica de
  negocio. En single-player, `awardsServer.lua` llama a
  `Awards.Client.onServerCommand()` directamente.

- **`Awards.Options`** — `awardsOptions.lua` (client-only). Gestiona las opciones
  del jugador (`showNumberWhenLosing`, `showMessageInChat`, límites de lista).

- **UI del jugador** — `awardsUI.lua` (client-only). Panel `AwardsWelcomeUI` con
  listas de ganados/perdidos, botones de limpiar, botón de cerrar y botón de
  gestionar premios (solo admins). Incluye el botón HUD arrastrable con posición
  persistida en `ItemsAwards_hudButtonPos.txt`.

- **UI del admin** — `awardsAdminUI.lua` (client-only). Panel CRUD `AwardsAdminUI`
  con listado de premios, formulario de edición, validación de ítem y campo de
  dado máximo. Solo accesible para admins/moderadores (o en single-player). Se
  comunica con el servidor vía `sendClientCommand` en multijugador, o llama
  directamente a `Awards.Data` en single-player. Constantes de layout: `W=610`,
  `H=520`, `STATUS_H=56`, `COL_SEP=295`, `LIST_H=285`. Los premios con
  `Number > maxDice` se muestran en la lista con prefijo `!` y texto naranja/rojo
  (`drawRow` + `refreshList`). Los mensajes de estado/hint aparecen en una franja
  de ancho completo al pie del panel.

## Archivos generados en runtime (server-side)

Todos en `Zomboid/Lua/` (o carpeta equivalente del servidor):

| Archivo | Descripción |
|---|---|
| `ItemsAwards_awards.txt` | CSV de premios: `Item,Number,Count,zkills,onZombie` |
| `ItemsAwards_config.txt` | Config: `maxDice=100` |
| `ItemsAwards_winners_log.txt` | Log append-only de ganadores |
| `ItemsAwards_hudButtonPos.txt` | Posición XY del botón HUD (por cliente) |

Estos archivos se crean automáticamente al primer inicio si no existen.
`ItemsAwards_awards.txt` se inicializa con un premio de ejemplo (`Base.Money`).

## Formato del log de ganadores

Una línea por cada ganador, escrita con `getFileWriter(LOG_FILE, true, true)`
(modo append):

```
[2026-07-09 15:30:45] Player: JohnDoe               | Roll:  50/100 | Item: Base.Money                    x1   | Placement: Inventory    | Kills: 42 (min: 1)
```

Campos: timestamp real del sistema (`os.date`), username (`player:getUsername()`),
número sacado / dado máximo, ítem con cantidad, placement (`Inventory` o
`ZombieBody`), kills actuales del jugador y mínimo requerido por ese premio.
Solo se registran ganadores; los losers no generan entrada.

## Dado máximo configurable

`Awards.Data.getMaxDice()` / `Awards.Data.setMaxDice(n)` — persiste en
`ItemsAwards_config.txt`. El servidor lo usa en `ZombRandBetween(1, maxDice + 1)`.
El panel admin muestra el valor actual en la barra inferior y permite cambiarlo
con el botón **Aplicar**. Al recibir `awardsList` del servidor, el cliente
actualiza su copia local (`_maxDice`) para validar el formulario antes de enviar.

Validación en cascada:
1. Cliente: `readForm()` rechaza `number > _maxDice` con error específico.
2. Servidor: `addAward`/`updateAward` ignoran el comando si `number > getMaxDice()`.

## Flujo de comandos admin

```
Cliente (admin)                       Servidor
    |                                     |
    |-- sendClientCommand "getAwards" --> |
    |                                     |--> sendAwardsList(player)
    |<-- "awardsList" {awards, maxDice} --|
    |                                     |
    |-- sendClientCommand "addAward" ---> |-- validar número <= maxDice
    |                                     |--> Awards.Data.add(entry)
    |<-- "awardsList" (actualizado) ------|
    |                                     |
    |-- sendClientCommand "setMaxDice" -> |--> Awards.Data.setMaxDice(n)
    |<-- "awardsList" (con nuevo max) ----|
```

En single-player, el cliente llama directamente a `Awards.Data` (mismo proceso)
y refresca la UI sin pasar por red.

## Íconos de botones

Los íconos se aplican con `applyIcon(btn, tex)`, que parchea `btn.render` para
dibujar la textura a la izquierda del texto. Están en `media/ui/icons/` y en
`common/media/ui/icons/`:

| Archivo | Botón |
|---|---|
| `add.png` | Agregar (admin) |
| `edit.png` | Guardar/editar (admin) |
| `trash-solid.png` | Eliminar (admin) |
| `reload.png` | Recargar (admin) |
| `close.png` | Cerrar (admin y jugador) |
| `clean.png` | Limpiar ganados / perdidos (jugador) |
| `gift_regular_icon.png` | Botón HUD |

## Layout del panel del jugador

Los botones de `AwardsWelcomeUI` usan un layout de 2 filas × 2 columnas
(`halfW ≈ (width - PAD*3) / 2`):
- Fila 1: "Limpiar ganados" | "Limpiar perdidos"
- Fila 2: "Cerrar" | "Gestionar Premios" (solo admins/SP)

## Cómo probar cambios

No hay tests automatizados ni build step.

1. Cargar el mod en Project Zomboid (B41 y/o B42) y matar un zombi en
   single-player para verificar el roll y el mensaje de UI.
2. Revisar la consola del juego: ambos módulos imprimen
   `[ItemsAwards] ... loaded (B41/B42).` al cargar.
3. Verificar `Zomboid/Lua/ItemsAwards_winners_log.txt` para confirmar que el
   log se escribe correctamente al ganar.
4. Abrir el panel admin y probar: agregar un premio con número > maxDice (debe
   dar error), cambiar el maxDice, recargar la lista. Verificar que los premios
   con número mayor al nuevo maxDice aparecen con prefijo `!` y en naranja/rojo.
5. Si cambiás lógica de servidor, verificar que el cliente recibe el comando
   correcto (`award`, `needKills`, `loser`).

## Convenciones a respetar

- El servidor es la única fuente de verdad para si se gana o no; nunca muevas
  lógica de decisión al cliente.
- Cualquier string visible al jugador va a `Translate/<idioma>/...`, nunca
  hardcodeado en `.lua`. Hay que agregar la clave en los tres idiomas (AR/EN/ES)
  y en ambas carpetas de traducción (`media/` y `common/`).
- No elimines los guards de carga única (`Awards._serverLoaded`,
  `Awards._clientLoaded`, `Awards._dataLoaded`, `Awards._optionsLoaded`) ni el
  guard `isClient()/isServer()` al inicio de cada archivo de servidor.
- No elimines `if not PZAPI then return end` de los archivos de **cliente** en
  `common/`. No lo agregues a los archivos de **servidor** en `common/`.
- La carpeta `42/` solo tiene `mod.info` e `itemsAwards.png`. No agregar código
  ahí a menos que sea un override real de un archivo de `common/`.
- Si editás premios o config vía `Awards.Data`, siempre llamar `.save()` /
  `setMaxDice()` para persistir — nunca modificar `_awards` o `_maxDice`
  directamente.
