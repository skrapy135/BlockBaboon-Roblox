# Block Baboon: Fuga Cúbica (Roblox Luau Edition)

Conversión completa en **Lua / Luau** para **Roblox Studio** basada en el proyecto `BlockBaboon`.

## Estructura del Proyecto (Rojo)

- `default.project.json`: Configuración de proyecto Rojo para compilar a `.rbxl` o sincronizar en vivo con Roblox Studio.
- `src/shared/` (`ReplicatedStorage/Shared`):
  - `GameConfig.luau`: Constantes de juego, rangos, arquetipos, estilos, biomas, bloques, recetas, power-ups, reliquias y logros.
  - `GameUtils.luau`: Generación determinista de obstáculos por bioma, ciclo día/noche, clima, santuarios de eclipse y rangos.
  - `RemoteEvents.luau`: Inicialización de `RemoteEvent`s cliente-servidor.
- `src/server/` (`ServerScriptService/Server`):
  - `GameServer.server.luau`: Bucle autoritativo del juego (Survival y Training), recolección de núcleos, barricadas, trampas, Eclipse Carmesí, Horda y Portal de Escape.
  - `BaboonAI.luau`: Modelo 3D Voxel del Scary Baboon y máquina de estados (`patrol`, `stalk`, `chase`, `smash`, `stunned`, `trapped`, `distracted`).
  - `WorldBuilder.luau`: Construcción procedural del mapa 3D, santuarios de luz, portal y bloques.
  - `DataStoreManager.luau`: Persistencia con `DataStoreService` y respaldo automático en memoria para pruebas locales en Roblox Studio.
- `src/client/` (`StarterPlayer/StarterPlayerScripts/Client`):
  - `ClientMain.client.luau`: Punto de entrada del cliente.
  - `HudGui.luau`: Interfaz completa (Menú/Lobby, HUD, Hotbar, Crafteo, Personalización, Bestiario, Logros y Clanes).
  - `AtmosphereController.luau`: Iluminación dinámica Día/Noche, Clima, Eclipse y Linterna.
  - `InputController.luau`: Controles de teclado (`1-7`, `F`, `X`, `Z`, `C`, `Q`, `L`, `Shift`, `G`).
  - `SoundController.luau`: Efectos de sonido en `SoundService`.

## Cómo ejecutar en Roblox Studio

### Opción 1: Con Rojo (Recomendado)
1. Instala [Rojo](https://rojo.space/) y su plugin en Roblox Studio.
2. En esta carpeta (`/home/antigravity/BlockBaboon-Roblox`), ejecuta:
   ```bash
   rojo build -o BlockBaboon.rbxl
   ```
   O para sincronizar en vivo:
   ```bash
   rojo serve
   ```
3. Abre `BlockBaboon.rbxl` en Roblox Studio y presiona **Play (F5)**.

### Opción 2: Importación manual en Roblox Studio
1. Crea una carpeta `Shared` en `ReplicatedStorage` y copia los `ModuleScript` de `src/shared/`.
2. Crea una carpeta `Server` en `ServerScriptService` y copia `GameServer.server.luau` (como `Script`) y los demás archivos de `src/server/` (como `ModuleScript`).
3. Crea una carpeta `Client` en `StarterPlayer/StarterPlayerScripts` y copia `ClientMain.client.luau` (como `LocalScript`) y los demás archivos de `src/client/` (como `ModuleScript`).
4. Presiona **Play (F5)**.
