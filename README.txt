Versus Mode 0.1.2
==================

Versus Mode lets players join the Heretic Forces and directly control
Darktide Specialists, Elites, and Bosses. The host remains authoritative
over spawning, combat, damage, navigation, and team allocation.

This 0.1.2 release adds controllable Scab Gunners, Dreg Gunners, and
Reapers to possession and Versus Mode. It uses the permanent VersusMode
mod identity introduced in 0.1.0.


IMPORTANT: upgrading from Versus Mode (Test) / BossControl
-----------------------------------------------------------

The internal mod identity has changed from BossControl to VersusMode. This is
an intentional clean break for the public release.

1. Close Darktide completely.
2. Remove the old `BossControl` entry from `mods/mod_load_order.txt`.
3. Remove or move the old `mods/BossControl` folder out of the mods directory.
4. Install this release as `mods/VersusMode`.
5. Add `VersusMode` to `mods/mod_load_order.txt`.

Do not load BossControl and VersusMode together. Saved BossControl options do
not carry over to the new DMF identity, so review Mod Options after installing.


Requirements
------------

- Darktide Mod Loader and Darktide Mod Framework.
- SoloPlay for locally hosted sessions.
- Realms for LAN sessions with remote human Heretic players.
- The host and every participating Realms client must run Versus Mode 0.1.2.

Realms itself is not modified. Versus Mode uses its supported mod-networking
bridge and remains host-authoritative.


Installation
------------

1. Extract `VersusMode-0.1.2.zip` into the Darktide `mods` directory.
2. Confirm this exact path exists:
   `mods/VersusMode/VersusMode.mod`
3. Add `VersusMode` once to `mods/mod_load_order.txt` after DMF-managed
   dependencies. Do not add `dmf` or `base` manually.
4. Start Darktide and confirm `Versus Mode` appears in Mod Options.
5. Fully restart every game client after installing or replacing the build.


Core features
-------------

- Host team menu for assigning human players and bots as Heretics while
  retaining at least one Operative.
- Direct control of supported Specialists, Elites, Bosses, and selected
  variants.
- Adaptive Combat and Direct Combat control layouts using Darktide bindings or
  optional custom bindings.
- Automatic reinforcements, manual reinforcement selection, Hidden Deployment,
  deployment countdowns, and minimum-distance rules.
- Third-person possession camera, experimental first-person control, Sniper
  scope, death camera, Deployment View, and Operative spectating.
- Context-sensitive doors and optional authored climb, vault, and drop routes.
- Configurable Specialist, Elite, and Boss health multipliers.
- Automatic and manual Boss assignment with configurable stagger and
  knockback scaling.
- English, Simplified Chinese, and Traditional Chinese UI text.
- A local attack-log option, disabled by default. Reinforcement, assignment,
  death, and error notices remain visible when attack logging is hidden.


Team awareness and targeting
----------------------------

- Other player-controlled Heretics have a green through-wall outline.
- Every visible, nonlocked Operative has a persistent white through-wall
  outline.
- The confirmed target changes to red and receives pulsing red LOCKED brackets.
- Invisible or otherwise unperceivable Operatives remain hidden.

Versus Mode owns the outline state and colors, but uses Darktide's authored
player-outline materials. Its contour, softness, and occlusion therefore remain
visually consistent with Darktide's native outline rendering.


Combat notes
------------

Adaptive Combat chooses a context-sensitive Primary Action and exposes a fixed
signature Secondary Action. Direct Combat exposes the breed's mapped actions on
Primary Action, Secondary Action, Weapon Special, and Combat Ability. Holding
Weapon Swap switches supported breeds between the two layouts.

Examples retained in this release include:

- Chaos Spawn Leap from 11 to 16 metres.
- Consecutive Scab and Dreg Flamer Kicks in Target Lock.
- Pox Hound pounce recovery that restores normal turning and movement after a
  miss, cancellation, landing, timeout, or completed pin.
- Poxburster Primary Action: Lunge through Darktide's native fuse sequence.
- Sniper Netter and supported controlled-enemy variants.
- Scab Gunner, Dreg Gunner, and Reaper shooting and melee commands. Use movement
  controls to strafe during a volley. Speed follows the native directional
  strafe values, scaled by the Movement speed setting.
- Gunner auto lock drops a survivor inside smoke beyond 4 metres unless the
  Gunner shares that smoke cloud. Free aim is unaffected.


Public 0.1.0 stabilization
--------------------------

- Migrates the complete runtime identity from BossControl to VersusMode:
  install folder, descriptor, DMF registration, script root, entry files,
  view/HUD namespace, setting namespace, and Realms RPC names.
- Keeps the persistent white/red Operative outline and green allied-Heretic
  outline validated in test 0.1.12.
- Keeps transition-only locomotion synchronization. Movement events are sent
  when locomotion changes and once after an attack, traversal, or diagnosed
  streaming transition; the old repeated animation heartbeat is removed.
- Keeps the exact-event fallback for a genuinely missed native animation RPC.
- Keeps the destroyed RemotePlayer disconnect guard for possession HUD cleanup.
- Prevents the Operative host from receiving Versus Mode's private remote
  Heretic assignment message. Third-party HUD mods are not altered.
- Keeps the Pox Hound pounce-to-pin handoff and steerable locomotion recovery.
- Seeds Deployment View from the current streaming anchor as soon as a saved
  pre-game Heretic assignment becomes active, before normal spectating begins.


Recommended compatibility checks
--------------------------------

1. Confirm the host can assign teams in Realms preparation and in mission.
2. Confirm each selected client receives the correct Heretic role after loading.
3. Confirm unlocked Operatives stay white with no crosshair target; lock one and
   confirm only that Operative becomes red, then returns to white when unlocked.
4. Move, stop, attack, and traverse with several Heretics on a Realms client;
   verify the third-person body never freezes or loses its walking animation.
5. Repeatedly pounce with a Pox Hound into open ground and Operatives; verify
   turning and ordinary movement always return.
6. Die, redeploy, change mission areas, and disconnect while possessing; verify
   camera, HUD, body visibility, outlines, and audio clean up.
7. Confirm the Operative host is not told which enemy a remote Heretic receives.
8. Test optional traversal on several maps and breeds. A prompt should appear
   only when the current breed can use the authored route.
9. Possess a Scab Gunner, Dreg Gunner, and Reaper through manual selection and
   Versus reinforcement; verify the correct body, camera, controls, and HUD.
10. For each Gunner, fire in Target Lock and free aim, strafe both directions
    during a volley, then use its melee actions. Check that shots follow the
    crosshair and commands work in cover.
11. Repeat Gunner possession with a matching 0.1.2 Realms client and review
    both host and client logs for selector, animation, or RPC errors.
12. Change Specialist camera distance, horizontal offset, and height. Compare
    a Specialist and a controlled Elite in third person; both should respond
    to the same settings while Boss camera settings remain separate.
13. Throw smoke around an Operative while controlling each Gunner. Auto lock
    should drop beyond 4 metres, return within 4 metres or inside the same
    smoke, and leave free aim available.


Known limitations
-----------------

- Realms team assignment, controlled traversal, first-person control, the Last
  Operative buff, and controlled variants remain experimental.
- Darktide owns final navigation, collision, animation, and attack validation;
  unsupported requests are rejected rather than forced.
- Authored traversal support varies by map and breed.
- The outline renderer intentionally retains Darktide's native visual style.
- Third-party HUDs such as SpecialsTracker may independently reveal spawned
  enemies; Versus Mode does not alter them.
- Darktide updates may require a compatibility update.


Reporting problems
------------------

When reporting an issue, include both host and client console logs when
available, the map, controlled breed, action being used, whether Target Lock was
active, and clear reproduction steps. Confirm every machine reports Versus Mode
0.1.2 before comparing multiplayer behavior.

Local changes: restricted Heretic roster and nearest target
-----------------------------------------------------------
The Cycle / Unlock Target binding now selects the nearest valid target on
every press instead of cycling or clearing the lock. The host also applies
this behavior to remote clients. Existing manual-aim, free-aim, hound,
menu and attack-in-progress restrictions remain in effect.

Random and manually cycled reinforcements are limited to Scab Sniper,
Scab Trapper, Scab Bomber, Dreg Tox Bomber, Pox Hound, Crusher and Poxburster.
The optional Sniper Netter variant is still a Trapper and remains available
when specialist variants are enabled. Automatic boss takeover is disabled
for this restricted roster, including when its old saved setting is enabled.
Ordinary AI enemies in missions are unaffected.

Restart Darktide to load these changes. Install this modified version on the
Realms host for authoritative selection; use the same copy on clients for
matching descriptions. Nearest-target distance is measured from the enemy
you control, not from the spectator camera.
Local changes: reinforcement icon picker
---------------------------------------
The existing Cycle next reinforcement binding (Space in this installation)
now opens a mouse menu while awaiting deployment. Each opening highlights
a random available card. Click any enemy card to select it and close the
menu immediately. Escape/Cancel keeps the previous reinforcement.
The respawn countdown is preserved; automatic deployment waits while the
menu is open. A lost client heartbeat expires after six seconds.
Cards use the mod's existing enemy portraits, or its neutral skull emblem
with the breed name where this mod has no portrait mapping.
Install this same modified copy on both host and clients for direct selection.
The host validates each requested breed and variant against its allowed list.

Local changes: Gunner and Reaper crosshair aiming
------------------------------------------------
Scab Gunner, Dreg Gunner and Reaper are available for random respawns and
manual selection again. All three always use the camera crosshair, like
the Trapper, in first and third person. Target lock is disabled for them;
their native weapon, spread, volley timing and melee attacks are retained.
The picker now has room for all ten breeds plus the optional Trapper variant.

Local changes: immediate controlled ranged fire
----------------------------------------------
Scab Gunner, Dreg Gunner, Reaper, Trapper and Sniper skip AI preparation
waits before firing under player control. Native shooting still creates
projectiles and handles weapon effects, burst cadence and cooldowns.
Sniper laser-only aim remains non-firing. Ordinary AI is unaffected.
Melee, grenade-throw, pounce and death animations are not shortened.
This removes preparation timers, not the next engine update or network delay.

Local changes: input, firing and controlled flinch fixes
------------------------------------------------------
Repeated quick-wield input no longer resets the Q hold timer. A long hold
switches targeting once; a short press still selects the nearest target.
Controlled Gunner volleys bypass AI entry cooldown, body-angle gating and
suppression delay while retaining native projectile and burst handling.
Living possessed enemies ignore suppression and stagger, including blast
reactions. Damage and death are not disabled; ordinary AI keeps its reactions.

Local changes: authoritative picker confirmation
-----------------------------------------------
Clicking a card now waits for the assigned breed and variant to match before
closing the picker. Sending a client request alone is not confirmation.
The existing NEXT REINFORCEMENT HUD uses this same authoritative assignment.
An unconfirmed request shows an error after five seconds and allows retry.
All module and asset paths remain relative; no machine-specific paths are used.
