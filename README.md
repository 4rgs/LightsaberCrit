# LightsaberCrit

WoW Classic Era addon that plays lightsaber-inspired sounds on melee events (e.g., swings, crits, procs).

## Install

- Copy the folder `LightsaberCrit` into your WoW `Interface/AddOns/` directory.
  - Example (macOS): `/Applications/World of Warcraft/_classic_era_/Interface/AddOns/LightsaberCrit`
- Restart the game and enable the addon from the AddOns menu.

## Files

- `LightsaberCrit.toc` – Addon manifest (loads the Lua and sound assets)
- `LightsaberCrit.lua` – Main addon logic
- `sounds/` – Sound assets used by the addon

## Usage

- Enable the addon in-game from the AddOns menu.
- Open options via Interface Options -> AddOns -> LightsaberCrit, `/lsaber config`, or the minimap icon.
- Play and enjoy the saber vibes on eligible events.

## Development

- Edit `LightsaberCrit.lua` and assets under `sounds/`.
- Typical structure for a simple addon. No external libraries required.

## Notes

- Built and tested for WoW Classic Era.
- Contributions and suggestions are welcome.

---

# Español

Addon para WoW Classic Era que reproduce sonidos estilo sable de luz en eventos de combate (p. ej., golpes, críticos, procs).

## Instalación

- Copia la carpeta `LightsaberCrit` dentro de `Interface/AddOns/` de tu WoW.
  - Ejemplo (macOS): `/Applications/World of Warcraft/_classic_era_/Interface/AddOns/LightsaberCrit`
- Reinicia el juego y activa el addon en el menú AddOns.

## Archivos

- `LightsaberCrit.toc` – Manifiesto del addon
- `LightsaberCrit.lua` – Lógica principal del addon
- `sounds/` – Archivos de sonido

## Uso

- Activa el addon dentro del juego desde el menú AddOns.
- Abre la configuracion en Interface Options -> AddOns -> LightsaberCrit, `/lsaber config`, o el icono del minimapa.
- Juega y disfruta los sonidos en los eventos correspondientes.

## Desarrollo

- Edita `LightsaberCrit.lua` y los sonidos en `sounds/`.
- No requiere librerías externas.



## Changelog
  fix: avoid PlaySound hooks and mute SFX via CVar to prevent logout taint

  Replaces global PlaySound/PlaySoundFile overrides with temporary SFX CVar mute
  and restores SFX on logout.
