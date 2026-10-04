# RedFear Graphics

Original, client-only colour grading and highlight bloom for the current RedFear DayZ server. Separate resource: no core files, custom map, gameplay, weather or texture replacements required.

## Install

Upload redfear_graphics into /mods/deathmatch/resources/[dayz]/, then run:

refresh
start redfear_graphics

For automatic startup, add this alongside existing resources in mtaserver.conf:

<resource src="redfear_graphics" startup="1" protected="0" />

## Player commands

/graphics low — one texture sample per pixel, gentle colour/contrast, no bloom or vignette.
/graphics balanced — default; mildly reduced saturation, warmer daylight, subtle highlight bloom and vignette.
/graphics cinematic — stronger grading, bloom and vignette.
/graphics off — native graphics, graphics allocations released.
/fixgraphics — discard and recreate the capture/shader after a rendering problem.

Each player's selected preset is saved locally in the private graphics.xml file. No performance claim has been measured. Use Low or Off if FPS falls. Screen sources retain native resolution so the scene is not downscaled/blurred.

## Rendering safeguards

The pass uses onClientHUDRender before GTA HUD rendering and dxUpdateScreenSource(..., true), capturing the current world before drawing. There is no previous-frame feedback, additional render-target pipeline, world-texture wildcard or sky/fog/far-clip override. Grading pauses before login, on death, while cursor menus/pause/console are open, and during night vision or thermal vision. HUD and inventory render separately. Other third-party HUDRender shaders can still interact and need live testing.

Failed shader creation, texture binding, screen-source capture or drawing disables the effect and releases its elements, leaving normal rendering. Faults log once and do not repeatedly allocate each frame. Restore/Alt-Tab and resolution changes rebuild resources. Stopping the resource destroys its graphics elements. Private preference save failure is logged.

## Verification

Lua behaviour tests cover presets, pause conditions, immediate screen capture, resize/restore, failure fallback, cleanup and preset template generation. No MTA/Direct3D renderer was available here: HLSL compilation and visual quality still need testing on a live Windows client. Test outdoors in daylight/night, full map, inventory, login, death effect, night vision, Alt-Tab, and each preset. These are postprocess shaders, not new terrain textures, reflection systems, dynamic shadows or an ENB replacement.

API references:
https://wiki.multitheftauto.com/wiki/OnClientHUDRender
https://wiki.multitheftauto.com/wiki/DxUpdateScreenSource
https://wiki.multitheftauto.com/wiki/DxCreateShader
