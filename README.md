# LightsaberCrit

World of Warcraft addon that plays lightsaber-inspired sounds on melee events (e.g., swings, crits, procs).
Supports Classic Era, Classic Anniversary/BCC, MoP, and Retail.

## Install

- Copy the folder `LightsaberCrit` into your WoW `Interface/AddOns/` directory.
  - Example (macOS): `/Applications/World of Warcraft/_classic_era_/Interface/AddOns/LightsaberCrit`
- Restart the game and enable the addon from the AddOns menu.

## Files

- `LightsaberCrit.toc` – Addon manifest (loads the Lua and sound assets)
- `LightsaberCrit_Compat.lua` – Compatibility helpers (timers/math)
- `LightsaberCrit_Profiles.lua` – Profile management (class/spec/role/manual)
- `LightsaberCrit_Sounds.lua` – Sound playback and SFX mute logic
- `LightsaberCrit_UI.lua` – Options UI and minimap icon
- `LightsaberCrit.lua` – Core addon logic and events
- `sounds/` – Sound assets used by the addon

## Usage

- Enable the addon in-game from the AddOns menu.
- Open options via Interface Options -> AddOns -> LightsaberCrit, `/lsaber config`, or the minimap icon.
- Play and enjoy the saber vibes on eligible events.

## Development

- Edit `LightsaberCrit_*.lua` modules and assets under `sounds/`.
- Typical structure for a simple addon. No external libraries required.
- If `LibDataBroker-1.1` and `LibDBIcon-1.0` are present, the minimap icon uses them.
- If `LibSharedMedia-3.0` is present, you can select custom sounds in the config.
- Profiles: you can auto-select by class/spec/role or set a manual profile in the config.

## Notes

- Built and tested for WoW Classic Era.
- Contributions and suggestions are welcome.

---

# Español

Addon para World of Warcraft que reproduce sonidos estilo sable de luz en eventos de combate (p. ej., golpes, críticos, procs).
Soporta Classic Era, Classic Anniversary/BCC, MoP y Retail.

## Instalación

- Copia la carpeta `LightsaberCrit` dentro de `Interface/AddOns/` de tu WoW.
  - Ejemplo (macOS): `/Applications/World of Warcraft/_classic_era_/Interface/AddOns/LightsaberCrit`
- Reinicia el juego y activa el addon en el menú AddOns.

## Archivos

- `LightsaberCrit.toc` – Manifiesto del addon
- `LightsaberCrit_Compat.lua` – Helpers de compatibilidad (timers/math)
- `LightsaberCrit_Profiles.lua` – Perfiles (clase/especializacion/rol/manual)
- `LightsaberCrit_Sounds.lua` – Sonidos y mute de SFX
- `LightsaberCrit_UI.lua` – UI de opciones e icono del minimapa
- `LightsaberCrit.lua` – Logica principal y eventos
- `sounds/` – Archivos de sonido

## Uso

- Activa el addon dentro del juego desde el menú AddOns.
- Abre la configuracion en Interface Options -> AddOns -> LightsaberCrit, `/lsaber config`, o el icono del minimapa.
- Juega y disfruta los sonidos en los eventos correspondientes.

## Desarrollo

- Edita los modulos `LightsaberCrit_*.lua` y los sonidos en `sounds/`.
- No requiere librerías externas.
- Si `LibDataBroker-1.1` y `LibDBIcon-1.0` están presentes, el icono del minimapa usa esas librerías.
- Si `LibSharedMedia-3.0` está presente, puedes elegir sonidos personalizados en la configuracion.
- Perfiles: puedes auto-seleccionar por clase/especializacion/rol o usar un perfil manual en la configuracion.



## Changelog
- change: config UI labels in English
- fix: adjust profile controls spacing in config window
- add: profile system with auto selection and manual override
- add: LibSharedMedia sound selection per sound type
- add: combat-only toggle and sound volume slider
- add: sound test dropdown in config
- refactor: split addon logic into modules
- add: multi-client .toc interface tags (Classic Era/BCC/MoP/Retail)
- add: LDB/DBIcon minimap icon integration with manual fallback
- fix: timer and combat log fallbacks for older clients
- fix: avoid PlaySound hooks and mute SFX via CVar to prevent logout taint
