# AGENTS.md — Items Awards (Project Zomboid mod)

Guía para trabajar en este repo. Léela antes de tocar código: el mod soporta
Build 41 **y** Build 42, y la estructura de carpetas es la parte más importante
de entender.

## Qué hace el mod

Cada vez que un jugador mata a un zombi (`Events.OnZombieDead`), el servidor
tira un número aleatorio 1-100 (`ZombRandBetween`). Si coincide con una entrada
de la tabla `itemsAwards` (hardcodeada en `awardsServer.lua`), y el jugador
tiene suficientes kills acumulados, se le entrega un ítem (al inventario o al
cuerpo del zombi). El servidor notifica al cliente vía `sendServerCommand`
(o llamada directa en single-player) para mostrar un halo/mensaje de chat y
actualizar una UI con historial de ganados/perdidos.

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

Cada archivo en `common/` comienza con `if not PZAPI then return end` como
guardia de seguridad, por si B41 escanea subdirectorios y alcanza esos archivos.
Si PZAPI es nil (B41), el archivo retorna inmediatamente sin ejecutar nada.

## Diferencias B41 vs B42 — dónde vive cada cosa

| Tema | B41 (`media/`) | B42 (`common/`) |
|---|---|---|
| Opciones de mod | `awardsOptions.lua` con `ModOptions:getInstance()` | `awardsOptions.lua` con `PZAPI.ModOptions:create()` |
| `getText` con placeholders | `string.format(getText(key), ...)` con `%s/%d` | `getText(key, arg1, arg2)` variádico con `%1/%2` |
| Textura de ítem en la UI | `InventoryItemFactory.CreateItem(item):getTex()` | `getScriptManager():getItem(item):getNormalTexture()` |
| Traducciones | `.txt` con tablas Lua (`UI_EN = {...}`) | `.json` plano |
| Sync de inv. al dar ítem | `sendAddItemToContainer(inv, item)` | no necesario (B42 lo maneja) |

Cada diferencia vive en el archivo nativo de su build, sin shims de
compatibilidad. Si necesitás cambiar algo en ambas builds, editá el archivo
correspondiente en `media/` Y el archivo correspondiente en `common/`.

## Módulos y carga

Todo cuelga del global `Awards`:

- `Awards.Server` — `media/server/awardsServer.lua` (B41) y
  `common/server/awardsServer.lua` (B42). Solo corre si `isServer()`.
  Cada uno tiene guard `Awards._serverLoaded` por si el archivo se carga dos
  veces; los archivos de `common/` también tienen `if not PZAPI then return end`.
- `Awards.Client` — `media/client/awardsClient.lua` (B41) y
  `common/client/awardsClient.lua` (B42). Solo corre en contexto de cliente.
  Dispatcher de comandos del servidor; sin lógica de negocio.
- `Awards.Options` — `media/client/awardsOptions.lua` (B41, `ModOptions` legacy)
  o `common/client/awardsOptions.lua` (B42, `PZAPI.ModOptions`).
- UI — `media/client/UI/awardsUI.lua` (B41, `InventoryItemFactory`) y
  `common/client/UI/awardsUI.lua` (B42, `getScriptManager`). El panel
  `AwardsWelcomeUI` + el botón HUD arrastrable están en ambos.

## La tabla de premios (lo que el usuario quiere poder editar)

Vive hardcodeada en ambos `awardsServer.lua` (línea ~35):

```lua
local itemsAwards = {
    {Item = "Base.Money", Number = 50, Count = 1, zkills = 1, onZombie = false},
}
```

Si agregás un premio, editalo en AMBOS archivos (B41 y B42). Hoy no hay UI
ni archivo de configuración externo.

## Cómo probar cambios

No hay tests automatizados ni build step.

1. Cargar el mod en Project Zomboid (B41 y/o B42) y matar un zombi en
   single-player para ver el guard `ZombKilled` y el mensaje de UI.
2. Revisar la consola del juego: ambos módulos imprimen
   `[ItemsAwards] ... loaded (B41/B42).` al cargar.
3. Si cambiás lógica de servidor, verificar que el cliente recibe el
   comando correcto (`award`, `needKills`, `loser`).

## Convenciones a respetar

- El servidor es la única fuente de verdad para si se gana o no; nunca muevas
  lógica de decisión al cliente.
- Cualquier string visible al jugador va a `Translate/<idioma>/...`, nunca
  hardcodeado en `.lua`. Hay dos formatos (`.txt` para B41 en `media/`, `.json`
  para B42 en `common/`) con las mismas claves — si agregás una clave, va en
  ambos formatos y en los tres idiomas (AR/EN/ES).
- No elimines los guards de carga única (`Awards._serverLoaded`,
  `Awards._clientLoaded`, `Awards._optionsLoaded`) ni el guard
  `isClient()/isServer()` al inicio de cada archivo.
- No elimines `if not PZAPI then return end` de los archivos en `common/` —
  es la guardia que impide que B41 ejecute código B42.
- La carpeta `42/` solo tiene `mod.info` e `itemsAwards.png`. No agregar código
  ahí a menos que sea un override real de un archivo de `common/`.
