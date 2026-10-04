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
  Contents roll on the server: food, drinks, bandages, healing supplies, a weapon
  with matching ammunition, a repair/fuel item and useful equipment. An 8% rare
  military roll upgrades the weapon and adds advanced medicine and premium gear.
- Inspect the nearest vehicle within 12 metres: health, engine state, fuel,
  inventory capacity and installed/required parts. Inspection does not mutate vehicles.
- Spawn fully fitted DayZ vehicles with fuel and all required parts.
- Clean up your own active test zombies, airdrops and vehicles.

Spawn on foot in dimension/interior 0 and on flat open ground. Test zombies expire
in 5 minutes; crates expire in 15 minutes. A maximum of two test crates per admin
is active at once. Cleanup, disconnect and resource stop remove temporary assets;
already looted items remain in players' inventories. These are manual testing
crates, not a scheduled public airdrop event. All actions are server authenticated,
throttled and logged. Engine gameplay validation is still required.

### Chat roles and channels

Chat uses `[GLOBAL] [Owner] b1tza: message` formatting on GLOBAL, LOCAL,
RADIO and TEAM channels. T sends local chat (15 metres, same dimension and
interior); X opens global chat. Existing `/globalchat`, `/radiochat` and
`/teamchat` commands remain available. Radio requires a radio and matching
frequency; team messages go only to your DayZ gang.

Roles come from the logged-in MTA account, in this order: configured owner
account `b1tza`, Owner ACL, Admin ACL, SuperModerator/Moderator ACL, VIP ACL,
then Player. Edit `ownerAccounts` in `scripts/chat_s.lua` to change the owner
account list. Names and client element data cannot grant a role. Chat labels
never grant permissions. Create a VIP ACL group and add `user.ACCOUNTNAME`
using your MTA ACL administration to label VIP accounts; a VIP group needs no
administrative rights. Mutes and a shared one-second cooldown cover all channels.

### Survival account screen

The login/register panel uses an olive/charcoal survival theme with a red DayZ
header, survivor briefing and responsive account forms. It keeps existing
accounts, masked native password inputs, saved usernames, language selection
and server authentication events. Enter submits the current form. Errors appear
inline; repeated requests have a short client cooldown in addition to the server
rate limit. No password is saved by this panel.

### Automatic public airdrops

While logged-in survivors are online in the main world, a public supply drop
arrives every 30 minutes with a two-minute warning. Locations rotate randomly
between the three airports and Area 69, without repeating the previous location.
An orange map marker guides players to the crate; it lands after 10 seconds and
expires 20 minutes after landing. Only one public drop can be active. Empty
servers reset the countdown. Public crates share the admin drop loot generator,
including its 8% rare military roll. Admin test cleanup does not remove public drops.

Use `/airdrops` for the current status. `/airdropnow` requires an Admin ACL account
or the server console (`airdropnow` without a slash). Timing and locations are
configured at the top of `scripts/public_airdrops_s.lua`. Restart the resource
after editing. Landing positions still require testing in the MTA game engine.

### Public helicopter crash sites

The crash scheduler replaces the original hourly crash generator. One wreck
appears every 45 minutes while living survivors are online in the main world,
at one of seven original countryside sites without an immediate location repeat.
A red map marker and announcement identify the location. Loot includes useful
supplies, a guaranteed random military weapon with matching ammo and premium gear.
Up to five ordinary DayZ zombies activate when a survivor comes within 70 metres,
respecting the global zombie cap. Killed guards are not repeatedly respawned.
The wreck, loot marker and surviving guards expire after 25 minutes.

Admin ACL accounts can use `/crashnow`; the console uses `crashnow`. Players can
use `/crashsites` for status. Edit timings and locations at the top of
`scripts/helicopter_crashes_s.lua`. Validate terrain placement in-game.

The full-screen map retains a compressed background texture, retries allocation
failures every five seconds and recreates it after a client restore. Failures
produce a diagnostic message instead of leaving transparent terrain with markers.

### RedFear PvP combat

PvP hit reports are sent by the victim; the server computes damage from the
attacker's equipped item and validates actor, native weapon, world, range and
report frequency. Client reports contain no damage amounts. Engine hit/body-part
detection remains client based; these checks are not a complete anticheat.
Existing NPC, zombie, fall, vehicle and explosion damage paths are retained.

`scripts/shared/combat.lua` sets base damage, full-damage distance, maximum range
and lethal headshot range per weapon. Ranges are RedFear tuning values, not a
copy of TOP-GTA's settings. Damage falls linearly to zero at maximum range.
Arms take 45%, legs 60%, and body part 4 takes 70% before armor reduction.
Existing helmet/vest reduction factors and sidearm humanity modifiers are retained.
Working helmets block lethal headshots unless the weapon base damage is 12000
or higher. Outside lethal range, a head hit applies normal calculated damage.

Armor condition is saved per player and armor type (inventory stacks do not
carry individual instance durability). Swapping types does not reset wear.
Each protected hit removes ceil(raw damage / 500) condition points, minimum 1.
The final hit receives protection, then zero-condition equipped armor is consumed;
a replacement begins at 100%. Unequipped inventory armor remains normal stacked
items. Inventory H/V percentages display condition, not damage reduction.

Incoming/outgoing numbers fade after 2.5 seconds, capped at five lines. `/damage`
toggles them for the current client session. Existing accounts receive 100%
condition defaults without a database migration. Validate PvP with two players,
including range boundaries, helmets, broken armor and death attribution.


### Survivor progression and zombie variants

`/progress` opens account-backed XP and cosmetic rewards. Zombie kills award civilian 10 XP, military 25 XP and fast 40 XP, with +5 for a headshot. XP survives death and is saved immediately to the MTA account. Levels 1–20 use cumulative thresholds `100 * level * (level - 1)`. Existing accounts begin at zero XP; historical kills are not converted.

Native spawns roll 75% civilian (10,000 blood), 20% military (18,000 blood) and 5% fast (7,000 blood). Military attacks deal 1.35x zombie damage and chase at 0.85x animation speed; fast attacks deal 1.1x and chase at 1.4x. Crash guards are military. Existing headshot instant kills remain. Admin panel test zombies grant no XP. Tune these values in `scripts/shared/progression.lua`.

Cosmetic titles unlock at levels 1/3/7/12/20; Scout/Ranger/Veteran outfits at 3/7/12; wave/cheer/dance at 1/5/10. Use the panel or `/title survivor`, `/outfit scout`, `/emote wave`; `/title none` and `/outfit none` reset selections. Outfits only overlay the player model: underlying clothing inventory, armor, damage and account skin remain unchanged. No gear, health or combat bonuses are granted.

Upload the patch's `dayzepoch` directory over the existing resource, then run `refresh` and `restart dayzepoch`. Do not replace databases or accounts. Smoke test natural zombie kills, logout/login XP, death persistence, locked rewards, outfit reset and variant movement. Client-reported zombie kills retain the existing mode's trust limitations; this is not a replacement anti-cheat.


### RedFear custom world expansion

`redfear_world` adds Last Hope Refuge, Checkpoint Vulture and Sector 13 Quarantine, with native buildings/collision structures and 19 DayZ loot points. Upload the separate resource and updated DayZ manifest/bridge, then `refresh`, `restart dayzepoch`, `start redfear_world`. Admin inspection: `/rfmap camp`, `/rfmap military`, `/rfmap quarantine`, `/rfmap back`. See `redfear_world/README.md` for startup configuration and live placement checks. Stop the resource to remove objects and its associated loot. No live engine/terrain validation was available.
