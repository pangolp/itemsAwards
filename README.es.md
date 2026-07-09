# Items Awards

[English](README.md)

![20250424210041_1](https://github.com/user-attachments/assets/20568750-2f27-4635-8e4b-42f986b1a7c1)

Mod para Project Zomboid compatible con **Build 41** y **Build 42**. Cada vez que un jugador mata a un zombi, el servidor tira un número aleatorio entre 1 y un máximo configurable (por defecto 100). Si coincide con uno de los números de premio configurados y el jugador tiene suficientes kills, recibe un ítem — ya sea directamente en su inventario o colocado en el cuerpo del zombi para que lo saquee.

Toda la lógica de premios corre en el **servidor** (autoritativo). El cliente solo muestra notificaciones y un panel de historial.

## Características

- Tabla de premios gestionada completamente desde el **panel de administración** en el juego — sin necesidad de editar archivos.
- **Dado máximo configurable**: el admin puede subir o bajar el rango del dado en cualquier momento.
- **Log de ganadores del lado del servidor**: registra automáticamente cada ganador en un archivo de texto plano para auditoría.
- Icono HUD que abre un historial de ganados y perdidos durante la sesión.
- El icono HUD es arrastrable y recuerda su posición entre sesiones.
- Panel de opciones para controlar el estilo de notificación y los límites de listas.
- Notificación por chat o halo cuando se gana o pierde un premio.

## Opciones del jugador

| Opción | Descripción |
|---|---|
| Mostrar dado al perder | Muestra el número perdedor en la notificación |
| Mostrar mensaje en el chat | Usa burbuja de chat en lugar de nota halo |
| Límite de ganados | Cuántos ganados mantener en el historial (5 / 10 / 15 / 20) |
| Límite de perdidos | Cuántos perdidos mantener en el historial (5 / 10 / 15 / 20) |

## Panel de administración

Accesible para admins y moderadores (siempre visible en single-player) mediante el botón **Gestionar Premios** en el panel HUD.

### Campos de un premio

| Campo | Descripción |
|---|---|
| Tipo de ítem | Tipo completo del ítem (ej. `Base.Axe`) — validado contra el script manager del juego |
| Número | El número ganador (1 – dado máximo). Solo un premio puede tener cada número. |
| Cantidad | Cuántas copias entregar |
| Kills mín. | Kills mínimos que debe tener el jugador para poder ganar |
| En zombi | Sí = ítem en el cuerpo del zombi para saquear; No = va directo al inventario |

### Dado máximo configurable

La barra inferior del panel de administración muestra el valor actual del dado máximo. Cambiá el número y hacé clic en **Aplicar** para guardarlo inmediatamente. El servidor lo persiste en `ItemsAwards_config.txt` y lo usa en todos los rolls siguientes. Intentar agregar o editar un número de premio mayor al máximo actual es bloqueado con un mensaje de error.

## Log de ganadores

El servidor agrega una línea a `ItemsAwards_winners_log.txt` cada vez que un jugador gana un ítem:

```
[2026-07-09 15:30:45] Player: JohnDoe               | Roll:  50/100 | Item: Base.Money                    x1   | Placement: Inventory    | Kills: 42 (min: 1)
```

El archivo nunca se sobreescribe — solo se agrega al final. Copialo manualmente para examinarlo. Los perdedores no se registran.

## Archivos de datos del servidor

Todos los archivos viven en `Zomboid/Lua/` (o la carpeta equivalente en un servidor dedicado):

| Archivo | Contenido |
|---|---|
| `ItemsAwards_awards.txt` | Tabla de premios en CSV, editada desde el panel admin |
| `ItemsAwards_config.txt` | Configuración del dado máximo |
| `ItemsAwards_winners_log.txt` | Log de ganadores (solo append) |
| `ItemsAwards_hudButtonPos.txt` | Posición del botón HUD (por cliente) |

## Estructura de carpetas

Build 41 lee directamente desde `media/` en la raíz. Build 42 usa un mecanismo de "version merge": lee `common/` como capa base, luego `42/` como overrides. Ambas builds tienen **código nativo completamente separado** — sin shims de compatibilidad.

```
Contents/mods/ItemsAwards/
|-- mod.info                    B41: descriptor del mod en la raíz
|-- itemsAwards.png
|-- media/                      Solo Build 41 (código nativo B41)
|   |-- lua/
|   |   |-- client/
|   |   |   |-- UI/awardsUI.lua         (panel del jugador + botón HUD)
|   |   |   |-- UI/awardsAdminUI.lua    (panel CRUD del admin)
|   |   |   |-- awardsClient.lua
|   |   |   `-- awardsOptions.lua       (ModOptions API legacy)
|   |   |-- server/
|   |   |   |-- awardsData.lua          (persistencia de premios y config)
|   |   |   `-- awardsServer.lua        (lógica de roll, comandos)
|   |   `-- shared/Translate/
|   |       `-- AR | EN | ES  (*.txt)
|   `-- ui/icons/               (íconos de botones)
|-- common/                     Solo Build 42 (código nativo B42)
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
|   |   |       `-- AR | EN | ES  (*.txt)
|   |   `-- ui/icons/
`-- 42/                         Solo marcador para Build 42
    |-- mod.info
    `-- itemsAwards.png
```

> Si agregás una clave de traducción, hacelo en **ambos**: `media/shared/Translate/` (B41) y `common/media/lua/shared/Translate/` (B42). No hay ningún paso de sincronización automática.

## Enlaces

- [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=2911373802)
