Versus Mode 3.1.0
==================

Versus Mode lets players join the Heretic Forces and directly control
Darktide Specialists, Elites, and Bosses. The host remains authoritative
over spawning, combat, damage, navigation, and team allocation.

Versus Mode includes controllable Scab Gunners, Dreg Gunners, and
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
- The host and every participating Realms client must run Versus Mode 3.1.0.

Realms itself is not modified. Versus Mode uses its supported mod-networking
bridge and remains host-authoritative.


Installation
------------

1. Extract `VersusMode-3.1.0.zip` into the Darktide `mods` directory.
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
- Direct Combat controls using Darktide bindings or
  optional custom bindings.
- Automatic reinforcements, manual reinforcement selection, Hidden Deployment,
  deployment countdowns, and minimum-distance rules.
- Third-person possession camera, experimental first-person control, Sniper
  scope, death camera, Deployment View, and Operative spectating.
- Context-sensitive doors and optional authored climb, vault, and drop routes.
- Configurable Specialist, Elite, and Boss health multipliers.
- Confirmed and manual Boss assignment with configurable stagger and
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

Direct Combat exposes the breed's mapped actions on Primary Action, Secondary
Action, Weapon Special, and Combat Ability. Holding Weapon Swap (Q by default)
only toggles Target Lock for supported enemies, including bosses. It does not
change the attack layout. Adaptive Combat is disabled.

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
11. Repeat Gunner possession with a matching 3.1.0 Realms client and review
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
3.1.0 before comparing multiplayer behavior.

Local changes: expanded Heretic roster and nearest target
-----------------------------------------------------------
The Cycle / Unlock Target binding now selects the nearest valid target on
every press instead of cycling or clearing the lock. The host also applies
this behavior to remote clients. Existing manual-aim, free-aim, hound,
menu and attack-in-progress restrictions remain in effect.

The roster includes the existing gunners/specialists, Armored Hound, Scab Mauler,
Mutant and all ten boss breeds: Plague Ogryn, Chaos Spawn, Beast of Nurgle,
Houndmaster, both Daemonhosts, Scab/Dreg Captains and both Karnak twins.
The 28-card menu fits all 25 breeds plus the optional Sniper Netter variant.
Per-breed cooldowns and exact selection also apply to the added choices.
Newly spawned Daemonhosts start awake; existing map Daemonhosts keep their guards.
Map bosses are offered to Heretics through a Yes/No popup (15 seconds). Each eligible Heretic gets one independent 25% chance per boss; Captains and Havoc Lieutenants are offered to everyone eligible. Offers appear simultaneously. The first valid acceptance processed by the host wins and closes all other offers. Declining or timing out never rerolls that player's chance. Spawn-picker bosses do not trigger offers. The host can disable offers in Boss rules.
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
Cards use the game's existing enemy portraits, or original pixel portraits
drawn directly by the UI where this mod has no portrait mapping.
Install this same modified copy on both host and clients for direct selection.
The host validates each requested breed and variant against its allowed list.

Local changes: Gunner and Reaper crosshair aiming
------------------------------------------------
Scab Gunner, Dreg Gunner and Reaper are available for random respawns and
manual selection again. All three start with target lock OFF. Hold Q to
toggle target lock; with lock ON, tap Q to select the nearest valid target.
With lock OFF, shots follow the camera; Scab and Dreg use zero AI spread.
With lock ON, native aiming tracks the selected target. Weapon effects,
volley timing and melee attacks are retained.
The picker now has room for all ten breeds plus the optional Trapper variant.

Local changes: immediate controlled ranged fire
----------------------------------------------
In free aim, Scab Gunner, Dreg Gunner, Reaper, Trapper and Sniper skip AI preparation
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

Built-in night vision in 3.1.0
-------------------------------
Night vision runs only on the Heretic side and needs no extra mod.
Optics/ramp adapted from Wobin's Preysight: https://github.com/Wobin/Preysight
Press N to toggle it; starts OFF and resets when leaving the Heretic side.
Settings > Versus Mode > Night vision contains the rebindable key and sliders.
Default strength is 50/100, global fill intensity 4, green tint 0.
Six shadowless directional lights provide fill without distance attenuation.
Exposure is never changed, including legacy saved exposure values.
Strength scales the global fill from zero to full (50% is half).
Lighting remains local and is removed when disabled or leaving the Heretic view.
Visual brightness and GPU cost still need validation in-game.
Preysight and SimpleAssets must not be enabled for this setup.

Per-player Heretic cooldowns (3.1.0)
----------------------------------
Death locks that enemy breed for 60 seconds for its controller. Other players
keep their own timers; variants of the same breed share its cooldown.
Picker cards update the remaining seconds live and unlock automatically.
The existing general respawn delay still applies. The host enforces both
selection and spawn checks; install 3.1.0 on the host and all clients.

Psykhanium practice (3.1.0)
--------------------------
Enable Versus Mode and enter the local Psykhanium. Use the configured Heretic
roster-menu or enemy-selection key to open cards. Click an enemy to spawn and
control it without a respawn cooldown. Reopen the menu to choose another breed
or click Return to Operative. Esc only closes the menu. The possession key also
releases control. No Realms role assignment is needed; remote clients are not
supported by this local training path. Regular matches keep their cooldowns.

Heretic team HUD (3.1.0)
------------------------
A bottom-right panel displays human Heretic players with 100x100 imported portraits and
health, or respawn countdowns. Host snapshots update twice per second.
Install the matching version on host and clients to see the panel.

Developer checks
----------------
With Node.js installed, run npm install, then npm test in this directory.
Checks parse Lua 5.1 and execute extracted functions with mocked game services.
They cover cooldowns, packet age, exact spawning, training rollback, night fade,
HUD cache frequency and controlled Scab/Dreg crosshair shot arguments.
These checks do not replace host/client testing inside Darktide.

Melee aiming guide (3.1.0)
--------------------------
Settings > Versus Mode > Melee aiming guide has 23 independent enemy checkboxes,
all ON by default. Includes melee elites/bosses and kicks/bashes on ranged enemies.
The world marker shows command reach/direction or the centre of a local area attack.
Red point and translucent outlined circle mark the approximate impact area.
Circle radius uses native radius/half-width when available, otherwise 0.65 m.
The circle is projected onto nearby static ground; slopes remain approximate.
Idle preview uses the first melee command; an active melee command takes precedence.
Ranged commands, menus and release of possession hide the marker.
Weapon sweeps, moving targets and network delay can change the actual impact;
this guide does not predict the complete animation or guarantee damage.

Gunner burst counter (3.1.0)
----------------------------
Scab/Dreg Gunners and Reapers show remaining/total shots in the native burst.
Before the first burst is prepared, the display is unknown (-- / --).
The game's Reload action (normally R, respecting rebinding) stops the burst.
It interrupts a current ranged burst but does not interrupt melee or traversal.
The counter is shown below health in the controlled enemy portrait panel.
R enters a two-second weapon recovery; another attack is required afterwards.
Reload blocks primary fire only. Walking, locomotion animations and melee
remain available; no forced reload animation is played.
The next burst rolls its native shot count; no artificial magazine is added.
The host supplies client counters through the existing 0.15-second status updates.
Night vision remains key-operated; its 50% default now means half the full effect.

Hound charge lock (3.1.0)
-------------------------
In charge-based trajectory mode, hold Secondary (normally RMB) to grow the arc.
Press Primary (normally LMB) while holding Secondary to freeze the current charge.
You can still change direction; release Secondary to pounce with the locked charge.
Repeated Primary clicks keep the same charge. A new preview or cancellation resets it.
The HUD shows LOCKED and the charge percentage. Camera-pitch mode is unchanged.
Client jumps send the same existing charge-fraction field to the host.

Committed grenade trajectory (3.1.0)
--------------------------------------
During a throw, the arc and impact marker use the committed launch solution.
Camera movement cannot replace that path with the next throw's preview.
Clients hold their current preview while awaiting the host, then display the
host's committed points. An unconfirmed request expires after two seconds.
After the throw action ends, live aiming resumes for the next grenade.

Localization (3.1.0)
---------------------
All 634 localization keys include Russian and English. Literal percent signs in
night-vision settings are escaped for DMF's string.format-based localization.
npm test also checks duplicate keys, settings labels, literal localization calls,
matching format arguments across languages, and actual Lua string formatting.

Host Trapper/Sniper shot cooldown (3.1.0)
-----------------------------------------
The host balance settings include a shared 3-30 second shot cooldown slider.
Default: 3 seconds. Applies to Sniper, Trapper and Sniper Netter controls.
Changing it recalculates deadlines from the last shot and syncs client HUDs.
Client preferences do not change the authoritative cooldown.

Scab and Dreg Shotgunners (3.1.0)
---------------------------------
Both Shotgunners are selectable with the shared per-breed respawn cooldown.
Primary fires a native shotgun cycle; Heavy uses the native melee strike.
Free aim uses the camera point and matching weapon animation, retaining pellet spread.
Target lock uses native aiming. Each has a melee guide visibility checkbox.

Enemy portrait fallbacks (3.1.0)
--------------------------------
Seven native portrait materials are referenced by the game source.
Other breeds use original cached 32x32 pixel artwork built from UI rectangles.
The same renderer is used by selection cards, the team HUD and the health panel.
Missing materials and render errors fall back to drawn artwork. If a native
material silently shows a white square, enable Use drawn enemy icons in settings.
No custom texture loader or additional mod is required. All artwork uses relative paths.
Preview: artifacts/enemy-portraits.png. Artwork source: VersusMode_portraits.lua.

Death reinforcement selection (3.1.0)
------------------------------------
After a controlled Heretic dies, the host offers five distinct random non-boss
enemies. Ready breeds are preferred; any remaining cards keep their cooldowns.
The picker opens after the death camera. Respawn waits for a confirmed choice.
Closing and reopening the picker preserves the offer. Bosses are no longer
available as mission reinforcements: take over an existing boss. In the local Psykhanium, bosses remain selectable without cooldowns.

Operative health and damage feedback (3.1.0)

While possessing a Heretic, visible Operatives have health and toughness bars overhead.
Bonus toughness is gold and shows +N. Walls and stealth hide the indicators.
Floating damage numbers show your actual damage: health in red, toughness in blue.
Mixed hits show both numbers; rapid hits briefly combine. This works inside VersusMode
without Healthbars. The host and Heretic clients need this version for damage feedback.
Disable the feature in HUD settings: Operative health and toughness.
