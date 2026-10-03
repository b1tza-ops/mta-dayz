# MTA DAYZ Gamemode
Good, bug-free, lag-free, functional dayz gamemode.

# Installation
1. Place all the files in resource folder
2. Add this to ACL
```
<object name="resource.dayzepoch"></object>
<object name="resource.e_login"></object>
```
3. Add this to mtaserver.conf
```
<resource src="dayzepoch" startup="1" protected="0" />
<resource src="e_login" startup="1" protected="0" />
<resource src="dayzmap" startup="1" protected="0" />
<resource src="admin" startup="1" protected="0" />
<resource src="e_admin" startup="1" protected="0" />
<resource src="e_scoreboard" startup="1" protected="0" />
<resource src="e_downloader" startup="1" protected="0" />
<resource src="e_shop" startup="1" protected="0" />
<resource src="e_gps" startup="1" protected="0" />
<resource src="e_textures" startup="1" protected="0" />
<resource src="e_map" startup="1" protected="0" />
<resource src="e_radar" startup="1" protected="0" />
<resource src="e_dynamicsky" startup="1" protected="0" />
<resource src="particles" startup="1" protected="0" />
<resource src="noglitch" startup="1" protected="0" />
```
4. and you're done!

# Preview
![alt text](https://image.prntscr.com/image/lfkOVHKYRnmmGbiIRRdk1Q.png)
![alt text](https://image.prntscr.com/image/vf0X-utGQOqT9mKMILm_Gg.png)
![alt text](https://image.prntscr.com/image/aFyKtIRlTn21Ku86FsDFiQ.png)

# Security repair branch

Use **MTA 1.6.0 build r22815 or newer** on the server and clients. This version is required for the native element-data `deny` policy. Account initialization events are now server-only; remote actions use the actual `client` identity. The admin panel requires the authenticated account to belong to the `Admin` ACL group.

The shop uses a shared catalogue with a separate server copy and validates trader distance, prices, capacity and funds. Inventory transfers, ground pickups, dropping, vehicle parts, refuelling and ammunition are processed by the server. SQLite world snapshots are prepared before deletion and saved in explicit transactions with rollback and error reporting. Character data also autosaves every minute. See [administrator setup for b1tza](server-config/README.md).

## Validation

From the repository root, run `lua tests/security.lua` (Lua 5.1+) or `texlua tests/security.lua`. The tests use MTA API stubs to exercise rejected spoofed callers, valid purchases/transfers, duplicate pickups, capacity checks and failed database transactions. They do not run the MTA engine.

Before merging or opening a public server, use a private test server with backups of accounts and `dayzepoch/scripts/tools/backup.db`:

1. Start every resource and run `debugscript 3` in the client. Confirm no Lua errors.
2. Register, sign in, reconnect and restart; confirm position, inventory and character stats persist. Test wrong credentials and repeated sign-in attempts.
3. With two players, take the last item from one container simultaneously. Confirm only one receives it. Test dropping/picking up magazines, full backpacks, corpse loot, tents and safe-code access.
4. Buy items and vehicles at both traders. Test insufficient currency, full backpacks and blocked vehicle spawn areas. Confirm failed purchases do not charge the player.
5. Install/remove each vehicle part, fill canisters at fuel stations and refuel a nearly full vehicle. Fire each weapon type and throw grenades; check ammunition after reconnecting.
6. Equip/unequip weapons, backpacks, helmets and clothing; consume food/medicine; place and remove tents, safes and fences.
7. Sign in as account `b1tza` after applying its ACL entries. Test the O-key admin panel, duty mode, flight, item grants, vehicle commands and moderation. Confirm an ordinary account cannot invoke them.
8. Save vehicles/tents/safes, stop and restart the gamemode, then verify their contents. On a disposable database, introduce a write failure and confirm the previous snapshot is retained.

This is a repair of the reviewed paths, not a complete security audit. Legacy combat damage, zombie AI and group-management logic still contain client-driven state and need separate review and real multiplayer testing. Do not describe this legacy gamemode as cheat-proof or performance-tested.

MTA references: [script security](https://wiki.multitheftauto.com/wiki/Script_security), [protected element data](https://wiki.multitheftauto.com/wiki/SetElementData), [SQLite batching and transactions](https://wiki.multitheftauto.com/wiki/DbConnect).

## Admin test items
Log in to a DayZ character using an account in the server Admin ACL group.
Use `/dayzitems NAME` to search item IDs and `/dayzgive ITEM_ID AMOUNT` to add
items to your own inventory. For example: `/dayzitems M4`, `/dayzgive weapon11 1`,
and `/dayzgive mag5 100`. Quantities default to 1 and must be integers from 1
through 10000. Grants are server authorized, protected against client edits,
and recorded in the server debug log. Admin grants can exceed backpack capacity;
equip a suitable backpack before testing normal loot transfers.
You can also press O, select your player, and use the Give panel.

### Named item panel
Use `/dayzpanel` while logged in as an Admin to open the item catalogue directly.
Search readable item names, choose a category, enter the quantity and click
**Give to myself**. The O admin panel Items button opens the same catalogue.
The selected-player button uses the player selected in the main admin panel.

## Admin testing panel
Use `/dayztest` while logged in with an Admin ACL account. The panel provides:
- Teleport presets (LS/SF/LV airports and Area 69) and return to the previous position.
- Spawn 1-10 normal DayZ zombies nearby; up to 20 active test zombies per admin,
  respecting the global zombie limit. The normal five-zombie player cap does not block admin test batches.
- Trigger a populated test airdrop 7 metres ahead. It falls for 10 seconds,
  appears as an orange radar marker, and uses the normal DayZ loot menu after landing.
  Contents: M4A1 Holo, 120 rounds of matching ammo, food, bandages and an engine.
- Inspect the nearest vehicle within 12 metres: health, engine state, fuel,
  inventory capacity and installed/required parts. Inspection does not mutate vehicles.
- Clean up only your own active test zombies and airdrops.

Spawn on foot in dimension/interior 0 and on flat open ground. Test zombies expire
in 5 minutes; crates expire in 15 minutes. A maximum of two test crates per admin
is active at once. Cleanup, disconnect and resource stop remove temporary assets;
already looted items remain in players' inventories. These are manual testing
crates, not a scheduled public airdrop event. All actions are server authenticated,
throttled and logged. Engine gameplay validation is still required.

### AI survivor prototype

In `/dayztest`, choose **Spawn AI survivor**, then **Inspect my survivors** to see
state, health and remaining shells. Each admin can spawn three temporary survivors.
They patrol eight waypoints across an 80-by-80-metre area near their spawn, engage nearby zombies with a shotgun,
and retreat below 31 health or when their 40 shells run out. Cleanup, disconnect or
15 minutes removes them. Use a flat, open area; this is waypoint navigation, not
map-wide pathfinding. Blocked patrols try clear side directions, then switch waypoints after six
seconds without progress (or 45 seconds without reaching the waypoint). Beyond 180 metres from their owner they pause.

The owner's client controls movement and checks visibility. The server validates
ownership, target, range, world, shot cadence and ammo, and applies fixed combat
damage. Shot effects are illustrative rather than a ballistics simulation; zombie
contact damage is simulated on the server. Visibility trusts the admin controller,
so this prototype is not intended as a public NPC security boundary. Survivors do
not yet attack players. Existing
zombies retain their player-targeting AI. Test with zombies near the survivor.


Survivors now carry a 20-slot inventory containing their Winchester and remaining
shotgun shells. With no nearby threats they seek ordinary ground-loot containers,
landed airdrops or bodies within 35 metres. They collect shotgun shells (up to 70),
beans, soda and bandages (up to two each), one server-validated transfer every 1.5
seconds. Visibility comes from the admin controller, as with prototype combat.
Private safes, tents and vehicle inventories are excluded. Targets that cannot be
reached within 45 seconds are skipped temporarily. They consume carried supplies when safe. Inspection lists carried supplies and occupied slots. Death exposes the same
inventory as a lootable body; cleanup and the original 15-minute lifetime remove
both body and inventory. Shotgun ammo is consumed from that inventory on each shot.


Survivor needs update every ten seconds while their owner is nearby in the same
world. Food falls by 1 and water by 1.5; at 50 or below they use beans (+45 food)
and soda (+50 water). Zombie contact causes bleeding, which costs 2 health per
needs tick until a bandage is used. Medic kits restore 25/40/60 health depending on
size, and are used at 70 health or below. All uses take three seconds and consume
one carried item only when completed. Nearby zombies interrupt without consuming
that item. Empty food/water also damage health. Distant survivors pause needs.
Urgent medical, drink, food and ammo shortages take priority when choosing loot.

The admin panel's **Test survivor hunger, thirst and injuries** button affects only
your living test survivors: sets food 35, water 30, health 55 and bleeding on.
Test airdrops now include soda, small medic kits and shotgun shells in addition to
the existing food/bandages. Use the button near a landed drop without zombies,
then inspect to see bandaging, healing, drinking, eating and inventory changes.


Survivor navigation uses short, body-width collision probes and ground-height
checks. Blocked directions try side corridors with a short steering commitment to
reduce left/right oscillation. It avoids sharp climbs and drops and applies the
same steering to retreats. Inspection reports walking/detouring/blocked/waiting
and the current waypoint. This is local steering, not full map pathfinding; closed
rooms, mazes, interiors and large obstacles can still need authored routes.


### Survivor decision system and memory

Survivors score explore, restock, fight, retreat and recovery goals from server
observations. Spawn order cycles cautious scavenger, balanced survivor and bold
fighter personalities. They retreat at different health/crowd thresholds and when
ammo cannot cover nearby threats. Retreats choose a patrol destination with more
zombie clearance, then retain that goal briefly rather than instantly resuming a
fight. Recovery is allowed when threats are beyond 18 metres.

Nearby eligible loot sites are remembered for three minutes (maximum 64). Urgent
shortages can send them back to remembered supplies up to 80 metres away. Current
loot goals receive a commitment bonus to reduce switching. Failed loot approaches
and patrol waypoints are avoided for two minutes. Recently visited patrol points
receive lower exploration priority; danger areas remembered for a minute also
reduce destination scores (maximum 32 areas). Inspections show personality, goal,
reason, selected score, memory counts and nearby threat count. Server debug output
records goal changes. This is deterministic game AI with local steering, not an
LLM, full map pathfinding or player combat. The admin controller reports visible zombies; the server validates their range
and world before threat assessment. Visibility also gates firing and looting.


### Loot awareness

The admin controller runs a 360-degree loot visibility scan every 1.5 seconds,
within 50 metres of each survivor. Walls and intervening objects block detection;
the target crate itself is ignored. Empty containers and private inventories are
excluded. Batches rotate through nearby visible sites (maximum eight observations
per report). The server validates owner, container type, distance and world before
updating bounded memory; it no longer automatically discovers containers through
walls. Normal restocking works out to 50 metres, urgent remembered supplies to 80.
Inspection shows visible observations from the last scan and time since that scan.
As with shooting, the prototype trusts its authenticated admin controller's
visibility observation; this remains a local test NPC system.

Zombie awareness uses the same 1.5-second scan with line of sight, within 30 metres
and at most 16 visible threats. A new scan removes hidden threats immediately;
observations also expire after four seconds without refresh. Zombies behind walls
therefore no longer keep survivors stationary in combat. Existing retreat
commitment can continue briefly after sight is lost, then patrol/needs resume.
