# AGENTS.md — Items Awards (Project Zomboid mod)

Guía para trabajar en este repo. Léela antes de tocar código: el mod soporta
Build 41 **y** Build 42 a la vez mediante una estructura de carpetas algo
inusual, y eso afecta cómo hay que editar cada archivo.

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
`Contents/mods/ItemsAwards/` (mod.info + media/ en la raíz). Build 42 usa un
mecanismo de "version merge": lee `common/` (base) y luego `42/` (overrides
específicos de B42) y los combina.

```
Contents/mods/ItemsAwards/
├── mod.info, media/...      ← copia para B41 (raíz, leída directo)
├── common/
│   ├── mod.info, media/...  ← MISMO contenido que la raíz, fuente real
└── 42/
    ├── mod.info, media/...  ← overrides SOLO para B42
```

**`media/` en la raíz y `common/media/` son copias byte-a-byte idénticas.**
No hay build step que las sincronice: si editás una y olvidás la otra, B41 y
B42 quedan con comportamiento distinto sin que nada te avise. Verificalo con:

```bash
diff -rq Contents/mods/ItemsAwards/media Contents/mods/ItemsAwards/common/media
```

Si esto imprime algo, hay drift entre las dos copias.

**Regla práctica:** edita siempre `common/media/...` primero, y replicá el
cambio a `media/...` en el mismo commit. (Una de las cosas más valiosas que
se podría hacer en este repo es eliminar esta duplicación manual — ver el
plan de mejora.)

## Diferencias B41 vs B42 y cómo están resueltas hoy

| Tema | B41 | B42 | Archivo(s) |
|---|---|---|---|
| Opciones de mod | `ModOptions:getInstance()` (legado) | `PZAPI.ModOptions` | `common/.../client/awardsOptions.lua` vs `42/.../client/ModOptions.lua` — **dos tablas de opciones casi idénticas mantenidas a mano** |
| `getText` con placeholders | `string.format(getText(key), ...)` con `%s/%d` | variádico, `getText(key, arg1, arg2)` con `%1/%2` | `safeGetText()` en `awardsServer.lua` (server/awardsServer.lua:63) — intenta el estilo B42 y cae al de B41 |
| Textura de ítem para la lista de premios | `InventoryItemFactory.CreateItem(item):getTex()` | `getScriptManager():getItem(item):getNormalTexture()` | `common/.../UI/awardsUI.lua` (`addAwardMessage`) parcheado por `42/.../UI/awardsUI_b42patch.lua` vía monkey-patch en `OnGameBoot` |
| Traducciones | `.txt` con tablas Lua (`UI_EN = {...}`) | `.json` | mismas claves, dos formatos, mantenidos a mano en `AR/EN/ES` × 3 archivos (`UI`, `IG_UI`, `Tooltip`) |

Cada una de estas diferencias está resuelta con un patrón distinto (detección
de API, archivo separado, monkeypatch, formato de archivo duplicado). Esto es
exactamente lo que hace que cueste "conectar" con el código: no hay un único
lugar al que mirar para entender "qué pasa en B42 vs B41" para una feature
dada.

## Módulos y carga

Todo cuelga del global `Awards`:

- `Awards.Server` — `common/.../server/awardsServer.lua`. Solo corre si
  `isServer()` (incluye host de single-player). Tiene guard
  `Awards._serverLoaded` porque el mismo archivo físico puede cargarse dos
  veces (raíz + common en B41).
- `Awards.Client` — `common/.../client/awardsClient.lua`. Solo corre si hay
  contexto de cliente. Dispatcher de comandos del servidor
  (`Awards.Client.onServerCommand`), sin lógica de negocio.
- `Awards.Options` — config de opciones de usuario (no confundir con la tabla
  de premios). Poblado por `awardsOptions.lua` (B41) o `ModOptions.lua` (B42).
- UI — `common/.../client/UI/awardsUI.lua`: panel `AwardsWelcomeUI` (historial
  ganados/perdidos) + `AwardsHUDButton` (icono arrastrable, persiste posición
  en `ItemsAwards_hudButtonPos.txt`). `awardsUI_b42patch.lua` la parchea para
  B42.

Todos los archivos tienen guards de "cargar una sola vez" (`Awards._xLoaded`)
— es deliberado, no lo quites al refactorizar.

## La tabla de premios (lo que el usuario quiere poder editar)

Vive hardcodeada en `awardsServer.lua` (server/awardsServer.lua:35-37):

```lua
local itemsAwards = {
    {Item = "Base.Money", Number = 50, Count = 1, zkills = 1, onZombie = false},
}
```

Hoy, la única forma de añadir/cambiar un premio es editar este literal Lua y
redistribuir el mod. No hay UI ni archivo de configuración aparte, ni en
multiplayer (admin del server) ni en single-player/coop. Esto es la
limitación funcional más importante señalada por el usuario — ver plan.

## Cómo probar cambios

No hay tests automatizados ni build step. Verificación manual:

1. `diff -rq` entre `media/` y `common/media/` para confirmar que no quedó
   drift (ver arriba).
2. Cargar el mod en Project Zomboid (B41 y, si es posible, B42) y matar un
   zombi en single-player para ver el guard `ZombKilled` y el mensaje de UI.
3. Revisar la consola del juego: ambos módulos imprimen
   `[ItemsAwards] ... loaded.` al cargar; usalo para confirmar que no se
   duplicó la carga de un módulo (los guards `Awards._xLoaded` deberían
   evitarlo).

## Convenciones a respetar

- El servidor es la única fuente de verdad para si se gana o no; nunca muevas
  lógica de decisión al cliente.
- Cualquier string visible al jugador va a `Translate/<idioma>/...`, nunca
  hardcodeado en `.lua`. Recordá que hoy existen dos formatos (`.txt` para
  B41, `.json` para B42) con las mismas claves — si agregás una clave, va en
  ambos formatos y en los tres idiomas (AR/EN/ES).
- No elimines los guards de carga única (`Awards._serverLoaded`,
  `Awards._clientLoaded`, `Awards._optionsLoaded`) ni el guard
  `isClient()/isServer()` al inicio de cada archivo — existen porque B41 carga
  el mismo archivo dos veces (raíz + common).
