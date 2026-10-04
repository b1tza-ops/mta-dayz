# RedFear World Expansion 1.0

Original mapping for RedFear Romania DayZ, built from native GTA San Andreas objects. Adds three approximately 60x60m compounds to the existing San Andreas world; it does not replace the entire terrain. No downloaded third-party map, client model packs or database replacement.

## Locations

- Last Hope Refuge: east of Verdant Meadows, centre (415, 2475). Four open shelter cabins, lookout, communal yard, food and industrial supplies. Seven loot points.
- Checkpoint Vulture: western Verdant Meadows airfield, centre (-40, 2500). Native open military hangar, guard cabin, lookout, checkpoint barriers, wreck and supply depot. Five loot points.
- Sector 13 Quarantine: Los Santos airport, centre (1700, -2450). Four open isolation shelters with beds, intake yard, lookout, wreck, supplies and random medical supplements. Seven loot points.

Each perimeter has a wide entrance and secondary exit. Native collision objects are frozen. Structures are modular and have open fronts. Existing DayZ zombies and their variant rules continue to apply; no new survivor AI or mission changes are introduced. This first release does not have custom doors or new terrain.

## Installation

Requires the current RedFear DayZ branch including the progression/zombie update. Stop dayzepoch before replacing files. Upload BOTH included folders into /mods/deathmatch/resources/[dayz]/, merging the dayzepoch folder rather than deleting it. The patch contains only its manifest and a new bridge script, plus the separate redfear_world resource. Never delete your other resources, accounts or databases.

Server console:

refresh
restart dayzepoch
start redfear_world

For automatic startup, add this alongside your existing resources in mtaserver.conf:

<resource src="redfear_world" startup="1" protected="0" />

## Inspection

As an authenticated member of the MTA Admin ACL group:

/rfmap camp
/rfmap military
/rfmap quarantine
/rfmap back

Teleport requires being alive and outside a vehicle, has a 2-second cooldown, and returns to the previous position, interior and dimension. /rfmap with no argument prints help. Small coloured blips identify the compounds within 300m; entering each compound prints its name. The resource writes object and loot-point counts to the MTA debug/server log on start, and logs failed object creation.

Loot uses your existing random residential, farm, supermarket, industrial and military tables. Medical wards supplement three real medical item types by 0–2 each. Loot participates in the normal DayZ respawn; the bridge restores destroyed map loot within 60 seconds. Restarting the map also rerolls its loot, so do not routinely restart it as a farming mechanic.

## Live validation required

No MTA renderer or running game server was available during development. Inspect terrain height, native building conflicts, bed placement, every shelter entrance and tower access before announcing the map to players. Coordinates target flat airfield areas but have not been visually verified. Ground height is configurable per compound in locations.lua. Restart redfear_world after edits. Check the inventory at each loot point, then test a normal DayZ loot respawn and stopping/restarting the map.

To remove the expansion: stop redfear_world and remove its startup line. The bridge cleans its loot and displayed loot objects. Native resource shutdown removes all mapped objects, zones and blips. No world objects are removed, so the default world needs no restoration.

## Model references

Native IDs verified against the MTA IDE list: https://wiki.multitheftauto.com/wiki/IDE_List
Object creation API: https://wiki.multitheftauto.com/wiki/CreateObject
3095 native collision panel dimensions: https://dev.prineside.com/en/gtasa_samp_model_id/model/3095-a51_jetdoor/
3268 hangar dimensions: https://dev.prineside.com/gtasa_samp_model_id/model/3268-mil_hangar1_/
