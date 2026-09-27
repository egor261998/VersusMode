const fs=require('fs'),path=require('path'),parse=require('luaparse').parse;
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('fengari');
const root=path.resolve(__dirname,'..'),base=path.join(root,'scripts/mods/VersusMode');
const source=fs.readFileSync(path.join(base,'VersusMode.lua'),'utf8');
const ast=parse(source,{luaVersion:'5.1',ranges:true});
const id=n=>n.type==='Identifier'?n.name:id(n.base)+'.'+n.identifier.name;
const fn=name=>{const n=ast.body.find(n=>n.type==='FunctionDeclaration'&&n.identifier&&id(n.identifier)===name);if(!n)throw Error(name);return source.slice(...n.range)};
const startAttack=fn('start_attack_burst');
run('Beast F releases a consumed player without a new aim target',`
local Specialist={};local now=20;local wakes=0
local function gameplay_time()return now end
local function valid_player_target(u)return u=='player' end
local function safe_extension_call(ext,method,value)assert(method=='set_brain_enabled' and value);wakes=wakes+1 end
${fn('Specialist.request_beast_spit_out')}
local s={breed={name='chaos_beast_of_nurgle'},blackboard={behavior={}},perception_component={}}
assert(not Specialist.request_beast_spit_out(s,'special'))
s.blackboard.behavior.consumed_unit='player'
assert(not Specialist.request_beast_spit_out(s,'primary'))
assert(Specialist.request_beast_spit_out(s,'special'))
assert(s.blackboard.behavior.force_spit_out and s.requested_attack.targetless and s.requested_attack.action_name=='spit_out')
assert(s.perception_component.aggro_state=='aggroed' and s.attack_deadline==25 and wakes==1)
now=21;assert(Specialist.request_beast_spit_out(s,'special') and wakes==1 and s.attack_deadline==25)
s.breed.name='chaos_spawn';assert(not Specialist.request_beast_spit_out(s,'special'))
`);
run('Shotgunners restore ranged animation after melee without AI turn poses',`
local Specialist={free_aim=function(s)return s.free end}
local VersusModeState={shotgun_breeds={renegade_shocktrooper=true,cultist_shocktrooper=true}}
table.clone=function(t)local c={};for k,v in pairs(t)do c[k]=v end;return c end
${fn('Specialist.shotgun_aim_animation')}
for _,name in ipairs({'renegade_shocktrooper','cultist_shocktrooper'})do
 local events={};local pad={current_aim_anim_event='old_melee',animation_extension={anim_event=function(_,e)events[#events+1]=e end}}
 local data={shoot_turn_anims={left='turn'},aim_anim_events={'hip_fire'}}
 local s={unit=1,breed={name=name},attack_deadline=10,requested_attack={shotgun_combat_range='close'},free=true}
 local directed=Specialist.shotgun_aim_animation(s,1,pad,data)
 assert(events[1]=='to_ranged' and pad.current_aim_anim_event==nil)
 assert(directed.shoot_turn_anims==nil and data.shoot_turn_anims.left=='turn' and directed.aim_anim_events==data.aim_anim_events)
 s.free=false;assert(Specialist.shotgun_aim_animation(s,1,pad,data)==data)
 s.requested_attack.shotgun_combat_range='melee';local count=#events
 assert(Specialist.shotgun_aim_animation(s,1,pad,data)==data and #events==count)
 assert(Specialist.shotgun_aim_animation(nil,1,pad,data)==data)
end
`);
const resetTree=startAttack.slice(startAttack.indexOf('    if attack.summon_hounds\n') < 0 ? startAttack.indexOf('    if attack.summon_hounds\r\n') : startAttack.indexOf('    if attack.summon_hounds\n'),startAttack.indexOf('    if state.breed.name == SNIPER_BREED_NAME'));
run('Both shotgunners reset retained tree links before the next command',`
local VersusModeState={shotgun_breeds={renegade_shocktrooper=true,cultist_shocktrooper=true}}
local HOUND_BREEDS={};local Specialist={};local attack={}
table.clear=function(t)for k in pairs(t)do t[k]=nil end end
for _,breed in ipairs({'renegade_shocktrooper','cultist_shocktrooper','renegade_gunner'})do
 local brain={_scratchpad={stale=true},_running_child_nodes={old=true},_old_running_child_nodes={old=true},_running_leaf_node='old',_running_state_node='old'}
 local state={breed={name=breed},behavior={_brain=brain}}
 ${resetTree}
 if VersusModeState.shotgun_breeds[breed]then
  assert(next(brain._scratchpad)==nil and next(brain._running_child_nodes)==nil and next(brain._old_running_child_nodes)==nil)
  assert(brain._running_leaf_node==nil and brain._running_state_node==nil and brain._evaluate_utility)
 else assert(brain._scratchpad.stale and brain._running_leaf_node=='old')end
end
`);
run('Shotgun commands preserve native weapon transitions',`
local Specialist={}
local function safe_extension_call(ext,method)return true,ext.slot end
${fn('Specialist.prepare_shotgun_range')}
local state={breed={name='renegade_shocktrooper'},visual_loadout={slot='slot_ranged_weapon'},
 blackboard={behavior={combat_range='close'},weapon_switch={}}}
assert(Specialist.prepare_shotgun_range(state,{shotgun_combat_range='melee'}))
assert(state.blackboard.weapon_switch.is_switching_weapons)
assert(state.blackboard.weapon_switch.wanted_weapon_slot=='slot_melee_weapon')
assert(state.blackboard.behavior.combat_range=='close')
state.visual_loadout.slot='slot_melee_weapon';state.blackboard.behavior.combat_range='melee'
assert(Specialist.prepare_shotgun_range(state,{shotgun_combat_range='close'}))
assert(state.blackboard.weapon_switch.wanted_weapon_slot=='slot_ranged_weapon')
assert(state.blackboard.behavior.combat_range=='melee')
state.breed.name='cultist_shocktrooper';state.blackboard.weapon_switch=nil
assert(Specialist.prepare_shotgun_range(state,{shotgun_combat_range='close'}))
assert(state.blackboard.behavior.combat_range=='close')
assert(Specialist.prepare_shotgun_range(state,{shotgun_combat_range='melee'}))
assert(state.blackboard.behavior.combat_range=='melee')
`);
run('View preflight rejects failed definitions and retries safely',`
local result=false;local raises=false;local loads=0;local errors=0
local mod={_view_definitions={},io_dofile=function()loads=loads+1;if raises then error('load error')end;return result end,
error=function()errors=errors+1 end}
${fn('mod.prepare_versus_view')}
assert(not mod.prepare_versus_view('versus_mode_spawn_view'))
assert(mod._view_definitions.versus_mode_spawn_view==nil)
raises=true;assert(not mod.prepare_versus_view('versus_mode_spawn_view'));raises=false
result={};assert(not mod.prepare_versus_view('versus_mode_spawn_view'))
result={scenegraph_definition={},widget_definitions={}}
assert(mod.prepare_versus_view('versus_mode_spawn_view'));assert(loads==4 and errors==3)
assert(mod.prepare_versus_view('versus_mode_spawn_view') and loads==4)
assert(not mod.prepare_versus_view('inventory_view') and loads==4)
`);
run('Spawn definitions survive unavailable portrait modules',`
local icon_module;local mod={};function get_mod()return mod end
function require(name)
 if name:find('ui_widget',1,true)then return {create_definition=function(passes,scene,content)return {passes=passes}end}end
 return {body={}}
end
table.clone=function(t)local copy={};for k,v in pairs(t)do copy[k]=v end;return copy end
local function build() ${fs.readFileSync(path.join(base,'ui/versus_spawn_view_definitions.lua'),'utf8')} end
for _,value in ipairs({false,{}, {draw=false},{draw=function()end}})do
 mod._portraits=value;local definitions=build()
 assert(definitions.max_cards==28)
 local portrait=definitions.widget_definitions.enemy_1.passes[4]
 assert(portrait.pass_type==(type(value)=='table' and type(value.draw)=='function' and 'logic' or 'texture'))
end
mod._portraits=nil;assert(build().widget_definitions.enemy_1.passes[4].pass_type=='texture')
`);
const stateTable=ast.body.find(n=>n.type==='LocalStatement'&&n.variables.some(v=>v.name==='VersusModeState')).init[0];
const roster=stateTable.fields.find(f=>f.key.name==='respawn_breeds').value;
run('Expanded roster fits all cards and preserves unique choices',`
local VersusModeState={respawn_breeds=${source.slice(...roster.range)},breeds={},specialist_variants_enabled=function()return false end}
local seen={};for _,entry in ipairs(VersusModeState.respawn_breeds)do assert(not seen[entry.name]);seen[entry.name]=true;VersusModeState.breeds[entry.name]={} end
assert(#VersusModeState.respawn_breeds==25)
for _,name in ipairs({'chaos_armored_hound','renegade_executor','cultist_mutant','chaos_plague_ogryn','chaos_spawn','chaos_beast_of_nurgle','chaos_ogryn_houndmaster','chaos_daemonhost','chaos_mutator_daemonhost','renegade_captain','cultist_captain','renegade_twin_captain','renegade_twin_captain_two'})do assert(seen[name],name) end
${fn('VersusModeState.available_spawn_choices')}
assert(#VersusModeState.available_spawn_choices()==25)
VersusModeState.breeds.chaos_armored_hound=nil;assert(#VersusModeState.available_spawn_choices()==24)
`);
if(!/local MAX_CARDS = 28/.test(fs.readFileSync(path.join(base,'ui/versus_spawn_view_definitions.lua'),'utf8')))throw Error('Roster plus variant must fit 28 cards');
const shotHook=source.slice(source.indexOf('mod:hook(MinionAttack, "shoot_hit_scan"'),source.indexOf('mod:hook(MinionAttack, "get_attack_delay"'));
const aimHook=source.slice(source.indexOf('mod:hook(MinionAttack, "aim_at_target"'),source.indexOf('-- Player-controlled gunners do not need'));
const manualDeclaration=ast.body.find(n=>n.type==='LocalStatement'&&n.variables.some(v=>v.name==='MANUAL_AIM_BREEDS'));
const aimModes=`
${source.slice(...manualDeclaration.range)}
local HOUND_BREEDS={chaos_hound=true}
local Specialist={casual_supported=function()return false end}
local function is_specialist_breed(b)return b.tags and b.tags.special end
VersusModeState.controlled_elite_breeds={renegade_gunner=true,cultist_gunner=true,chaos_ogryn_gunner=true}
${fn('Specialist.target_mode_supported')}
${fn('Specialist.free_aim')}
`;
run('Controlled Scab and Dreg shot direction and native isolation',`
local current;local ray='crosshair';local callback;local MinionAttack={}
local mod={hook=function(_,_,_,f)callback=f end}
local VersusModeState={gunner_breeds={renegade_gunner=true,cultist_gunner=true,chaos_ogryn_gunner=true},control_for_unit=function()return current end}
${aimModes}
local function camera_aim_ray()return ray end
${fn('VersusModeState.controlled_gunner_shot')}
${shotHook}
local template={spread=4};local action={};local perception={};local expected_position,expected_spread
local function native(w,p,u,t,item,fx,pos,st,spread,pc,ad)
 assert(w=='world' and p=='physics' and u=='unit' and t=='target' and item=='weapon' and fx=='muzzle')
 assert(pos==expected_position and spread==expected_spread)
 assert(st==template and pc==perception and ad==action and template.spread==4)
 return 'endpoint'
end
local function fire(pos,spread)
 expected_position=pos;expected_spread=spread
 assert(callback(native,'world','physics','unit','target','weapon','muzzle','ai_dodge',template,3,perception,action)=='endpoint')
end
for _,breed in ipairs({'renegade_gunner','cultist_gunner'})do
 current={possessed=true,unit='unit',attack_deadline=10,breed={name=breed},requested_attack={gunner_combat_range='far'},grenadier_target_lock=false}
 fire('crosshair',0)
 current.grenadier_target_lock=true;fire('ai_dodge',3);current.grenadier_target_lock=false
 ray='moved_crosshair';fire('moved_crosshair',0);ray='crosshair'
 current.possessed=false;fire('ai_dodge',3);current.possessed=true
 current.requested_attack.gunner_combat_range='close';fire('ai_dodge',3)
 current.requested_attack.gunner_combat_range='far';ray=nil;fire('ai_dodge',3);ray='crosshair'
end
current.breed.name='chaos_ogryn_gunner';fire('ai_dodge',3)
VersusModeState.shotgun_breeds={renegade_shocktrooper=true,cultist_shocktrooper=true}
for _,breed in ipairs({'renegade_shocktrooper','cultist_shocktrooper'})do
 VersusModeState.controlled_elite_breeds[breed]=true
 current.breed.name=breed;current.requested_attack={shotgun_combat_range='close'}
 current.grenadier_target_lock=false;fire('crosshair',3)
 current.grenadier_target_lock=true;fire('ai_dodge',3)
 current.requested_attack.shotgun_combat_range='melee';fire('ai_dodge',3)
end
current=nil;fire('ai_dodge',3)
local function state_look_direction()return nil,'forward' end
local visual_aim
VersusModeState.sync_gunner_visual_aim=function(_,_,p)visual_aim=p end
${aimHook}
for _,breed in ipairs({'renegade_gunner','cultist_gunner','chaos_ogryn_gunner'})do
 current={possessed=true,unit='unit',attack_deadline=10,breed={name=breed},requested_attack={gunner_combat_range='far'},grenadier_target_lock=false}
 local stored;local scratch={current_aim_position={store=function(_,p)stored=p end}}
 local calls=0;local function native_aim()calls=calls+1;return 'native_lock' end
 assert(callback(native_aim,'unit',scratch,0,{},current.breed)==true and stored=='crosshair' and calls==0)
 assert(visual_aim=='crosshair','animation must use the shot point')
 current.grenadier_target_lock=true;stored=nil
 assert(callback(native_aim,'unit',scratch,0,{},current.breed)=='native_lock' and stored==nil and calls==1)
 assert(visual_aim==nil,'lock must restore native target animation')
end
`);
run('Gunner visual aim drives animation and body rotation',`
local VersusModeState={};local stored,rotation,released
local Vector3={flat=function(v)return v end}
local function live_world_position()return 2 end
local function vector3_length(v)return math.abs(v)end
local function vector3_normalize(v)return v/math.abs(v)end
local function vector3_up()return 'up'end
local Quaternion={look=function(v,up)assert(up=='up');return v end}
local function safe_extension_call(_,method,value)assert(method=='set_wanted_rotation');rotation=value end
local MinionMovement={set_anim_rotation_driven=function(s,value)released=value;s.is_anim_rotation_driven=value end}
${fn('VersusModeState.sync_gunner_visual_aim')}
local aim={controlled_aim_position={store=function(_,v)stored=v end}}
local state={unit='gunner',blackboard={aim=aim}};local scratch={is_anim_rotation_driven=true}
VersusModeState.sync_gunner_visual_aim(state,scratch,10)
assert(aim.controlled_aiming and stored==10 and rotation==1 and released==false)
VersusModeState.sync_gunner_visual_aim(state,scratch,-10);assert(rotation==-1 and stored==-10)
rotation=nil;VersusModeState.sync_gunner_visual_aim(state,scratch,2);assert(rotation==nil,'zero horizontal aim must not normalize')
VersusModeState.sync_gunner_visual_aim(state,scratch,nil);assert(not aim.controlled_aiming)
`);
run('Gunner lock toggles, HUD capabilities and client forwarding',`
local VersusModeState={};${aimModes}
local sent;VersusModeState.send_client_action=function(action)sent=action end
local function control_input_ui_gated()return false end
local function set_status(s,message)s.status=message end
local function set_locked_target(s,target)s.locked_target=target end
local function nearest_attack_target()return 'nearest' end
local function target_name(t)return t end
local function destroy_grenade_preview()end
Specialist.destroy_hound_preview=function()end
local function update_manual_aim_preview()end
${fn('Specialist.toggle_target_lock')}
${fn('VersusModeState.target_hud_capabilities')}
for _,breed in ipairs({'renegade_gunner','cultist_gunner','chaos_ogryn_gunner'})do
 local s={possessed=true,breed={name=breed},grenadier_target_lock=false}
 assert(Specialist.free_aim(s))
 local cycle,lock=VersusModeState.target_hud_capabilities(s);assert(cycle and lock)
 Specialist.toggle_target_lock(s);assert(s.grenadier_target_lock and s.locked_target=='nearest' and not Specialist.free_aim(s))
 Specialist.toggle_target_lock(s);assert(s.grenadier_target_lock==false and s.locked_target==nil and Specialist.free_aim(s))
 s.attack_deadline=10;Specialist.toggle_target_lock(s);assert(s.grenadier_target_lock==false)
 s.attack_deadline=nil;s.remote_client=true;Specialist.toggle_target_lock(s);assert(sent=='target_lock' and s.grenadier_target_lock==false)
end
assert(Specialist.free_aim({breed={name='renegade_sniper'}}))
assert(not Specialist.target_mode_supported({breed={name='renegade_netgunner'}}))
Specialist.casual_supported=function()return true end
for _,name in ipairs({'chaos_spawn','chaos_plague_ogryn','chaos_beast_of_nurgle','chaos_daemonhost','renegade_captain','renegade_twin_captain'})do
 local s={possessed=true,breed={name=name,is_boss=true},casual_combat=true,grenadier_target_lock=true,locked_target='old'}
 assert(Specialist.target_mode_supported(s))
 Specialist.toggle_target_lock(s)
 assert(not s.casual_combat and s.grenadier_target_lock==false and s.locked_target==nil and Specialist.free_aim(s))
 Specialist.toggle_target_lock(s)
 assert(s.casual_combat and s.grenadier_target_lock and s.locked_target=='nearest' and not Specialist.free_aim(s))
 s.remote_client=true;Specialist.toggle_target_lock(s);assert(sent=='target_lock' and s.grenadier_target_lock)
end
`);
function run(name,code){const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);if(lauxlib.luaL_dostring(L,to_luastring(code))!==lua.LUA_OK)throw Error(name+': '+to_jsstring(lua.lua_tostring(L,-1)));console.log(name+' passed');}
run('Committed grenade HUD and authoritative arc roundtrip',`
local now=1;local function gameplay_time()return now end
local mod={};local VersusModeState={};local GRENADE_PREVIEW_MAX_POINTS=129
local Vector3=setmetatable({x=function(v)return v[1]end,y=function(v)return v[2]end,z=function(v)return v[3]end},{__call=function(_,x,y,z)return {x,y,z}end})
local function Vector3Box(v)return {unbox=function()return v end}end
${fn('VersusModeState.grenade_arc_payload')}
${fn('VersusModeState.decode_grenade_arc')}
local original={valid=true,points={Vector3Box({1,2,3}),Vector3Box({4,5,6})},bounce_segments={true},impact_position=Vector3Box({4,5,6}),area_radius=5}
local payload=VersusModeState.grenade_arc_payload(original)
assert(VersusModeState.grenade_arc_payload(original)==payload,'immutable path should reuse its network representation')
local decoded=VersusModeState.decode_grenade_arc(payload)
assert(decoded.points[2]:unbox()[3]==6 and decoded.bounce_segments[1] and decoded.area_radius==5)
assert(VersusModeState.decode_grenade_arc({points={{1,2,3},{1,0/0,3}}})==nil)
local huge={};for i=1,130 do huge[i]={1,2,3}end;assert(VersusModeState.decode_grenade_arc({points=huge})==nil)
local HOUND_BREEDS={};local GRENADIER_BREEDS={renegade_grenadier=true,cultist_grenadier=true}
${source.slice(source.indexOf('mod.grenade_trajectory_hud_data = function()'),source.indexOf('mod.controlled_enemy_status_data = function()'))}
local live={points={1,2}};local moved={points={3,4}}
for breed in pairs(GRENADIER_BREEDS)do
 local s={possessed=true,breed={name=breed},grenadier_target_lock=false,grenade_preview_solution=live};mod._control=s
 assert(mod.grenade_trajectory_hud_data()==live)
 s.attack_deadline=10;s.grenade_committed_solution=original;s.grenade_preview_solution=moved
 assert(mod.grenade_trajectory_hud_data()==original,'camera movement must not replace committed arc')
 s.grenade_committed_solution=nil;assert(mod.grenade_trajectory_hud_data()==nil,'do not show a different arc on interruption')
 s.remote_client=true;s.grenade_authoritative_arc=decoded
 assert(mod.grenade_trajectory_hud_data()==decoded)
 s.grenade_authoritative_arc=nil;s.attack_deadline=nil;s.grenade_pending_arc=original;s.grenade_pending_arc_until=2
 now=1;assert(mod.grenade_trajectory_hud_data()==original)
 now=3;assert(mod.grenade_trajectory_hud_data()==moved,'unconfirmed request must expire')
end
`);
run('Hound charge lock and primary input consumption',`
local now=0;local mode='charge';local math_max,math_min=math.max,math.min
local function gameplay_time()return now end
local function setting()return mode end
local HOUND_BREEDS={chaos_hound=true,chaos_armored_hound=true,chaos_hound_mutator=true}
local Specialist={hound_charge_duration=2}
${['hound_charge_fraction','hound_uses_charge_mode','lock_hound_charge','destroy_hound_preview'].map(n=>fn('Specialist.'+n)).join('\n')}
local mod={};local VersusModeState={uses_custom_enemy_keybinds=function()return true end}
local attacks=0;local updates=0;local gated=false
local function configured_keybind_should_fire(_,pressed)return pressed==false end
local function control_input_ui_gated()return gated end
local function update_manual_aim_preview()updates=updates+1 end
local function request_attack_for_state()attacks=attacks+1 end
${source.slice(source.indexOf('mod.primary_attack = function'),source.indexOf('mod.heavy_attack = function'))}
for breed in pairs(HOUND_BREEDS)do
 local s={possessed=true,breed={name=breed},hound_pounce_preview_active=true,hound_pounce_charge_started_at=0}
 mod._control=s;now=.8;mod.primary_attack(true,true)
 assert(s.hound_pounce_locked_fraction==.4 and attacks==0)
 now=5;assert(Specialist.hound_charge_fraction(s,now)==.4)
 mod.primary_attack(true,true);assert(s.hound_pounce_locked_fraction==.4)
 Specialist.destroy_hound_preview(s);assert(s.hound_pounce_locked_fraction==nil)
 s.hound_pounce_preview_active=true;s.hound_pounce_charge_started_at=5
 now=5.5;mod.primary_attack(true,false);assert(s.hound_pounce_locked_fraction==.25)
 Specialist.destroy_hound_preview(s)
 mod.primary_attack(true,true);assert(attacks==0,'generic long-hold dispatcher must not attack')
 mod.primary_attack(false,false);assert(attacks==0 and mod._hound_primary_release_consumed==nil)
end
local s={possessed=true,breed={name='chaos_hound'},hound_pounce_preview_active=true,hound_pounce_charge_started_at=now};mod._control=s
gated=true;mod.primary_attack(true,true);assert(s.hound_pounce_locked_fraction==nil)
gated=false;mode='camera_pitch';assert(not Specialist.lock_hound_charge(s))
`);
run('Native burst counter and reload interruption',`
local VersusModeState={gunner_breeds={renegade_gunner=true,cultist_gunner=true,chaos_ogryn_gunner=true}}
${fn('VersusModeState.record_gunner_burst')}
local s={};local scratch={num_shots=12.5,shots_fired=0}
VersusModeState.record_gunner_burst(s,scratch,false);assert(s.burst_total==13 and s.burst_remaining==13)
scratch.shots_fired=4;VersusModeState.record_gunner_burst(s,scratch,false);assert(s.burst_remaining==9)
VersusModeState.record_gunner_burst(s,scratch,false);assert(s.burst_remaining==9,'no additional decrement on a non-shot update')
scratch.shots_fired=0;VersusModeState.record_gunner_burst(s,scratch,true);assert(s.burst_remaining==0,'native reset on last shot must not refill HUD')
scratch.num_shots=8;VersusModeState.record_gunner_burst(s,scratch,false);assert(s.burst_remaining==8 and s.burst_total==8)
local gated=false;local paused=0;local requested=0;local sent
local now=10;local event
local ALIVE=setmetatable({},{__index=function()return true end})
local function gameplay_time()return now end
local function stop_manual_motion()end
local function safe_anim_event(_,name)event=name end
local Unit={has_animation_event=function(_,name)return name=='gun_jam_start' end}
${fn('VersusModeState.gunner_reloading')}
local function control_input_ui_gated()return gated end
local function pause_brain(state)paused=paused+1;state.attack_deadline=nil end
local function request_attack_for_state(_,slot)assert(slot=='primary');requested=requested+1 end
VersusModeState.send_client_action=function(action)sent=action end
${fn('VersusModeState.restart_gunner_burst')}
for _,breed in ipairs({'renegade_gunner','cultist_gunner','chaos_ogryn_gunner'})do
 s={possessed=true,breed={name=breed},attack_deadline=10,requested_attack={gunner_combat_range='far'}}
 local before=requested;VersusModeState.restart_gunner_burst(s);assert(requested==before)
 assert(not s.attack_deadline and s.gunner_reload_until==12 and event==nil)
 assert(VersusModeState.gunner_reloading(s));now=11
 VersusModeState.restart_gunner_burst(s);assert(s.gunner_reload_until==12,'repeat R must not extend recovery')
 now=12;assert(not VersusModeState.gunner_reloading(s));now=10;s.gunner_reload_until=nil
 s.attack_deadline=10;s.requested_attack.gunner_combat_range='melee'
 VersusModeState.restart_gunner_burst(s);assert(requested==before,'do not cancel melee')
 s.remote_client=true;VersusModeState.restart_gunner_burst(s);assert(sent=='restart_burst' and requested==before)
end
assert(paused==3)
gated=true;sent=nil;VersusModeState.restart_gunner_burst(s);assert(sent==nil)
gated=false;s={possessed=true,breed={name='renegade_gunner'}}
Unit.has_animation_event=function(_,name)return name=='out_of_aim' end
VersusModeState.restart_gunner_burst(s);assert(event==nil,'reload must not force an animation')
${fn('request_attack_for_state')}
request_attack_for_state(s,'primary') -- must return before any attack setup
`);
for(const name of ['update_manual_movement','VersusModeState.update_remote_authoritative_movement','VersusModeState.refresh_control_animation']){
 if(fn(name).includes('gunner_reloading'))throw Error('Reload must not block locomotion: '+name);
}
run('Melee guide attack selection, geometry and individual settings',`
local VersusModeState={}
${fn('VersusModeState.is_preview_melee')}
${fn('VersusModeState.melee_preview_attack')}
local melee={action_name='melee_attack',label='Strike',range_max=4,free_aim_melee=true}
local shoot={action_name='shoot',label='Fire'}
assert(VersusModeState.melee_preview_attack({}, {primary=shoot,heavy=melee})==melee)
assert(VersusModeState.melee_preview_attack({attack_deadline=1,requested_attack=shoot},{heavy=melee})==nil)
assert(VersusModeState.melee_preview_attack({attack_deadline=1,remote_client=true,remote_attack_label='Strike'},{heavy=melee})==melee)
assert(VersusModeState.melee_preview_attack({attack_deadline=1,remote_client=true,remote_attack_label='Unknown'},{heavy=melee})==nil)
local mt={};local function Vector3(x,y,z)return setmetatable({x=x,y=y,z=z},mt)end
mt.__add=function(a,b)return Vector3(a.x+b.x,a.y+b.y,a.z+b.z)end
mt.__sub=function(a,b)return Vector3(a.x-b.x,a.y-b.y,a.z-b.z)end
mt.__mul=function(a,b)return Vector3(a.x*b,a.y*b,a.z*b)end
mt.__div=function(a,b)return Vector3(a.x/b,a.y/b,a.z/b)end
mt.__unm=function(a)return Vector3(-a.x,-a.y,-a.z)end
local make_vector=Vector3
Vector3=setmetatable({flat=function(v)return make_vector(v.x,v.y,0)end},{__call=function(_,...)return make_vector(...)end})
local function vector3_up()return Vector3(0,0,1)end
local function vector3_length(v)return math.sqrt(v.x*v.x+v.y*v.y+v.z*v.z)end
local math_min,math_sin,math_cos=math.min,math.sin,math.cos
local settings={};local mod={get=function(_,k)return settings[k]end,localize=function(_,k)return k end}
local function get_mod()return mod end
local data=(function()${fs.readFileSync(path.join(base,'VersusMode_data.lua'),'utf8')} end)()
local count=0;for _,g in ipairs(data.options.widgets)do if g.setting_id=='melee_marker_group'then
 for _,w in ipairs(g.sub_widgets)do assert(w.type=='checkbox' and w.default_value==true);count=count+1 end
end end;assert(count==23)
local s={possessed=true,unit='enemy',breed={name='chaos_ogryn_executor'},yaw=0,pitch=1.2};mod._control=s
local ALIVE={enemy=true};local menu=false;local Managers={ui={has_active_view=function()return menu end}}
local positions={enemy=Vector3(0,0,0),target=Vector3(2,0,0)}
local function live_world_position(u)return positions[u]end
local attacks={primary=melee};local function resolved_attacks_for_state()return attacks end
local free=true;local Specialist={free_aim=function()return free end}
VersusModeState.locked_target_for_state=function()return 'target'end
local function nearest_attack_target()return nil end
VersusModeState.physics_world=function()return {}end
local blocked=false;local PhysicsWorld={raycast=function()return blocked,blocked and Vector3(0,2,1)end}
local BreedActions={chaos_ogryn_executor={melee_attack={width=2}}}
${fn('VersusModeState.melee_preview_area')}
${source.slice(source.indexOf('mod.melee_marker_hud_data = function()'),source.indexOf('mod.target_lock_marker_hud_data = function()'))}
local p=mod.melee_marker_hud_data();assert(p.position.y==4 and p.position.z==1 and p.kind=='reach','flat melee must ignore camera pitch')
assert(p.area_radius==1 and p.area_position.y==4)
BreedActions.chaos_ogryn_executor.melee_attack.width=0/0
assert(mod.melee_marker_hud_data().area_radius==0.65,'invalid width must use finite guide radius')
BreedActions.chaos_ogryn_executor.melee_attack.width=2
s.attack_deadline=1;s.requested_attack=melee;s.command_aim_yaw=math.pi/2
p=mod.melee_marker_hud_data();assert(math.abs(p.position.x-4)<.001,'windup must preserve command direction')
s.attack_deadline=nil;s.command_aim_yaw=nil
blocked=true;p=mod.melee_marker_hud_data();assert(p.position.y==2 and p.kind=='contact');blocked=false
free=false;p=mod.melee_marker_hud_data();assert(p.position.x==2 and p.kind=='target')
positions.target=Vector3(8,0,0);p=mod.melee_marker_hud_data();assert(p.position.x==4 and p.kind=='reach')
settings.melee_marker_chaos_ogryn_executor=false;assert(mod.melee_marker_hud_data()==nil)
s.breed.name='chaos_ogryn_bulwark';assert(mod.melee_marker_hud_data()~=nil,'toggles must be independent')
menu=true;assert(mod.melee_marker_hud_data()==nil);menu=false
s.possessed=false;assert(mod.melee_marker_hud_data()==nil)
`);
run('Melee circle uses GUI X/Z coordinates for both fill and outline',`
local mt={};local function Vector3(x,y,z)return setmetatable({x=x,y=y,z=z},mt)end
mt.__add=function(a,b)return Vector3(a.x+b.x,a.y+b.y,a.z+b.z)end
mt.__sub=function(a,b)return Vector3(a.x-b.x,a.y-b.y,a.z-b.z)end
local data={position=Vector3(0,0,0),area_position=Vector3(0,0,0),area_radius=1}
local mod={melee_marker_hud_data=function()return data end}
local function get_mod()return mod end
local function class()return {}end
local function Color(...)return {...}end
local Managers={free_flight={is_in_free_flight=function()return true end,camera=function()return {}end}}
local visible=true
local Camera={inside_frustum=function()return visible and 1 or -1 end,
world_to_screen=function(_,p)return Vector3(800+p.x*100,700+p.y*50,0.25),1 end}
local fills,edges,rects=0,0,0
local Gui={triangle=function(_,a,b,c,layer)
 for _,p in ipairs({a,b,c})do assert(p.y==0 and p.z>640 and p.z<760,'screen Y must become GUI Z, not camera depth')end
 if layer==10 then assert(a.x==800 and a.z==700);fills=fills+1 else assert(layer==11);edges=edges+1 end
end,rect=function(_,p)assert(p.y>680 and p.y<720);rects=rects+1 end}
local hud=(function()${fs.readFileSync(path.join(base,'VersusMode_melee_hud.lua'),'utf8')} end)()
hud.draw({_draw_layer=10},0,0,{gui={}})
assert(fills==48 and edges==96 and rects==5)
visible=false;hud.draw({_draw_layer=10},0,0,{gui={}});assert(fills==48 and edges==96 and rects==5)
`);
run('Cooldown persistence, packet age and expiry',`
local now=100;local server=true;local math_max=math.max;local mod={}
local function gameplay_time()return now end;local function is_server()return server end
local VersusModeState={player_account_id=function(p)return p and p.account end}
${['cooldown_store','breed_cooldown','respawn_remaining','record_breed_death','snapshot_age','apply_breed_cooldowns'].map(n=>fn('VersusModeState.'+n)).join('\n')}
local role={infected_human=true,infected_unique_id='connection1',infected_player={account='account1'},respawn_breed='sniper',respawn_ready_at=105}
VersusModeState.record_breed_death(role,{breed={name='sniper'}})
now=110;assert(VersusModeState.respawn_remaining(role)==50)
local rejoined={infected_unique_id='connection2',infected_player={account='account1'}}
assert(VersusModeState.breed_cooldown(rejoined,'sniper')==50)
assert(VersusModeState.breed_cooldown({infected_unique_id='other'},'sniper')==0)
server=false;local client={};VersusModeState.apply_breed_cooldowns(client,{sniper=60},100)
assert(VersusModeState.breed_cooldown(client,'sniper')==50)
now=160;assert(VersusModeState.breed_cooldown(client,'sniper')==0)
server=true;mod._match_breed_cooldowns=nil
assert(VersusModeState.breed_cooldown({infected_unique_id='new',infected_player={account='account1'}},'sniper')==0)
`);
const hook=source.slice(source.indexOf('mod:hook_require("scripts/managers/minion/minion_spawn_manager"'),source.indexOf('\nfunction VersusModeState.spawn_exact_minion'));
run('Exact spawn override scope and failure cleanup',`
local VersusModeState={};local replacement;local mod={hook_require=function(_,_,f)f({})end,hook=function(_,_,_,f)replacement=f end}
local ALIVE={u=true};local actual='sniper';local removed=0
local function safe_extension()return {}end
local function safe_extension_call()return true,{name=actual}end
${hook}
${fn('VersusModeState.spawn_exact_minion')}
local manager={despawn_minion=function()removed=removed+1 end}
local native=function()return 'gunner'end
manager.spawn_minion=function(self,b)
 assert(replacement(native,self,b)==nil)
 assert(replacement(native,self,b)=='gunner','override must be consumed once')
 return 'u'
end
assert(VersusModeState.spawn_exact_minion(manager,'sniper',0,0,2,{})=='u')
assert(mod._exact_spawn_context==nil and replacement(native,manager,'sniper')=='gunner')
actual='gunner';assert(not pcall(VersusModeState.spawn_exact_minion,manager,'sniper',0,0,2,{}));assert(removed==1 and mod._exact_spawn_context==nil)
manager.spawn_minion=function()error('spawn failed')end
assert(not pcall(VersusModeState.spawn_exact_minion,manager,'sniper',0,0,2,{}));assert(mod._exact_spawn_context==nil)
`);
run('Newly spawned Daemonhosts initialize awake or roll back',`
local mod={};local VersusModeState={daemonhost_settings={stages={aggroed=3}}}
local ALIVE={unit=true};local breed;local ready=true;local stage;local removed=0
local function safe_extension(_,system)
 if system=='unit_data_system'then return {breed=function()return {name=breed}end}end
 return ready and {_template_data={game_session='session',game_object_id=7}} or nil
end
local function safe_extension_call(object,method)return pcall(object[method],object)end
local GameSession={set_game_object_field=function(session,id,field,value)assert(session=='session' and id==7 and field=='stage');stage=value end}
local manager={spawn_minion=function(_,name)breed=name;return 'unit'end,despawn_minion=function()removed=removed+1 end}
${fn('VersusModeState.spawn_exact_minion')}
for _,name in ipairs({'chaos_daemonhost','chaos_mutator_daemonhost'})do
 stage=nil;assert(VersusModeState.spawn_exact_minion(manager,name,0,0,2,{})=='unit' and stage==3)
end
ready=false;assert(not pcall(VersusModeState.spawn_exact_minion,manager,'chaos_daemonhost',0,0,2,{}));assert(removed==1)
stage=nil;assert(VersusModeState.spawn_exact_minion(manager,'cultist_mutant',0,0,2,{})=='unit' and stage==nil)
`);
run('Host HUD cache build rate',`
local now=0;local mod={};local function gameplay_time()return now end
local builds=0;local VersusModeState={team_hud_snapshot=function()builds=builds+1;return {sent_at=now,rows={}}end}
${fn('VersusModeState.cached_team_hud_snapshot')}
for frame=0,599 do now=frame/60;VersusModeState.cached_team_hud_snapshot()end
assert(builds<=100 and builds>=80,'cache must bound 600 frame reads to at most 100 snapshots')
mod._team_hud_host_cache=nil;local previous=builds;VersusModeState.cached_team_hud_snapshot();assert(builds==previous+1)
print('600 HUD reads, '..builds..' snapshot builds (including invalidation)')
`);
run('Host specialist cooldown defaults, bounds and live retiming',`
local VersusModeState={};local value
local function setting(id)assert(id=='specialist_shot_cooldown');return value end
${fn('VersusModeState.specialist_shot_cooldown')}
${fn('VersusModeState.refresh_specialist_shot_cooldown')}
assert(VersusModeState.specialist_shot_cooldown()==3)
value=0/0;assert(VersusModeState.specialist_shot_cooldown()==3)
value=-2;assert(VersusModeState.specialist_shot_cooldown()==3)
value=100;assert(VersusModeState.specialist_shot_cooldown()==30)
value=8;local host={sniper_last_shot_t=10,sniper_fire_cooldown_until=13}
local remote={netter_last_shot_t=20,netter_fire_cooldown_until=23,controller_peer_id='client'}
VersusModeState.refresh_specialist_shot_cooldown(host);VersusModeState.refresh_specialist_shot_cooldown(remote)
assert(host.sniper_fire_cooldown_until==18 and remote.netter_fire_cooldown_until==28 and remote.next_status_sync_at==0)
value=3;VersusModeState.refresh_specialist_shot_cooldown(remote);assert(remote.netter_fire_cooldown_until==23)
local client={remote_client=true,netter_last_shot_t=20,netter_fire_cooldown_until=28}
VersusModeState.refresh_specialist_shot_cooldown(client);assert(client.netter_fire_cooldown_until==28)
local idle={};VersusModeState.refresh_specialist_shot_cooldown(idle);assert(idle.sniper_fire_cooldown_until==nil)
`);
run('Night vision integration fades after camera return',`
local mod={_night_vision={}};local Managers={ui={has_active_view=function()return false end}}
local function get_mod()return mod end
mod._night_vision.ramp=(function()${fs.readFileSync(path.join(base,'VersusMode_night_ramp.lua'),'utf8')} end)()
mod._night_vision.optics=(function()${fs.readFileSync(path.join(base,'VersusMode_night_optics.lua'),'utf8')} end)()
local active=false;local VersusModeState={night_vision_active=function()return active end,local_infected_view=function()return active end}
local function setting()return nil end
${fn('VersusModeState.night_vision_tuning')}
local Unit={alive=function()return true end};local World={destroy_unit=function()end}
Managers.world={has_world=function()return true end,world=function()return 'world'end}
Managers.free_flight={is_in_free_flight=function()return false end}
${fn('VersusModeState.clear_night_vision')}
${fn('VersusModeState.update_night_vision')}
mod._night_vision.optics.set_target(1);mod._night_vision.optics.update(1)
VersusModeState.update_night_vision(.1);assert(mod._night_vision.optics.weight()>0 and mod._night_vision.optics.weight()<1)
for i=1,10 do VersusModeState.update_night_vision(.1)end
assert(mod._night_vision.optics.weight()==0)
`);
run('Night vision key, tuning, role restriction and neutral exposure',`
local settings={enable_versus_mode=true};local eligible=true;local menu=false
local function setting(id)return settings[id] end
local mod={_night_vision={},echo=function()end,localize=function(_,key)return key end}
local function get_mod()return mod end
local Managers={ui={has_active_view=function()return menu end}}
local VersusModeState={local_infected_view=function()return eligible end}
${fn('VersusModeState.night_vision_active')}
${fn('VersusModeState.night_vision_tuning')}
${source.slice(source.indexOf('mod.toggle_night_vision = function'),source.indexOf('function VersusModeState.night_vision_tuning'))}
assert(not VersusModeState.night_vision_active())
mod.toggle_night_vision(false);assert(not VersusModeState.night_vision_active())
mod.toggle_night_vision(true);assert(VersusModeState.night_vision_active())
menu=true;mod.toggle_night_vision(true);assert(VersusModeState.night_vision_active());menu=false
mod.toggle_night_vision(true);assert(not VersusModeState.night_vision_active())
eligible=false;mod.toggle_night_vision(true);assert(not VersusModeState.night_vision_active());eligible=true
local effect,fill,distance,exposure,tint=VersusModeState.night_vision_tuning()
assert(effect==0.5 and fill==4 and distance==60 and exposure==0 and tint==0)
local data=(function()${fs.readFileSync(path.join(base,'VersusMode_data.lua'),'utf8')} end)()
local night_group
for _,group in ipairs(data.options.widgets)do if group.setting_id=='night_vision_group'then night_group=group end end
assert(night_group and #night_group.sub_widgets==6)
local key=night_group.sub_widgets[1]
assert(key.function_name=='toggle_night_vision' and key.keybind_trigger=='pressed' and key.default_value[1]=='n')
assert(night_group.sub_widgets[2].default_value==50)
settings.night_vision_strength=100;assert(VersusModeState.night_vision_tuning()==1)
settings.night_vision_strength=0;assert(VersusModeState.night_vision_tuning()==0)
settings.night_vision_strength=0/0;assert(VersusModeState.night_vision_tuning()==0.5)
local writes={};local callback;local CLASS={CameraManager={}}
local ShadingEnvironment={scalar=function()return 1.25 end,set_scalar=function(_,key,v)writes[key]=v end}
mod.hook=function(_,_,_,f)callback=f end
mod._night_vision.ramp=(function()${fs.readFileSync(path.join(base,'VersusMode_night_ramp.lua'),'utf8')} end)()
local optics=(function()${fs.readFileSync(path.join(base,'VersusMode_night_optics.lua'),'utf8')} end)()
mod._night_vision.optics=optics;optics.install(mod)
optics.set_tuning(0,0,0,.3,.6);optics.set_surge(0,0,0,0);optics.set_intro_surge(0,0,0,0)
optics.set_target(1);optics.update(.3);callback(function()end,nil,nil,{})
assert(next(writes)==nil,'default must not add exposure, blur or desaturation')
optics.set_tuning(.5,0,0,.3,.6);callback(function()end,nil,nil,{})
assert(writes.exposure_compensation==1.75,'optional exposure must have no activation flash')
settings.night_vision_strength=50;mod.toggle_night_vision(true)
local intensity,range;local alive=false
local Unit={alive=function()return alive end,num_lights=function()return 1 end,light=function()return {}end,num_meshes=function()return 0 end,set_local_position=function()end,set_local_rotation=function()end}
local World={spawn_unit_ex=function()alive=true;return 'light'end,destroy_unit=function()alive=false end,update_unit=function()end}
local Light=setmetatable({set_intensity=function(_,v)intensity=v end,set_falloff_end=function(_,v)range=v end},{__index=function()return function()end end})
local function Vector3()return 0 end
local Quaternion={forward=function()return 1 end};local function vector3_up()return 1 end
Managers.world={has_world=function()return true end,world=function()return 'world'end}
Managers.free_flight={is_in_free_flight=function()return true end,camera_position_rotation=function()return 0,0 end}
mod.package_status=function()return 'loaded'end
${fn('VersusModeState.clear_night_vision')}
${fn('VersusModeState.update_night_vision')}
VersusModeState.update_night_vision(1);assert(alive and intensity==2 and range==60)
settings.night_vision_strength=100;VersusModeState.update_night_vision(.1);assert(intensity==4)
eligible=false;VersusModeState.update_night_vision(1);assert(not mod._night_vision_enabled and not alive)
eligible=true;VersusModeState.update_night_vision(1);assert(not alive,'returning to Heretics must not auto-enable')
`);
run('Training preflight, rollback and cleanup',`
local mod={warning=function()end};local VersusModeState={training_available=function()return true end,available_spawn_choices=function()return {{name='sniper'}}end,nav_queries={position_on_mesh_guaranteed=function(_,p)return p end},physics_world=function()return {}end,spawn_headroom=function()return 3 end}
local spawned=0;local removed={};local fail=false;local obstructed=false
local manager={request_param_table=function()return {}end,despawn_minion=function(_,u)removed[u]=true end}
local Managers={state={minion_spawn=manager,nav_mesh={nav_world=function()return {}end}}}
local ALIVE={player=true,old=true,new=true};local HEALTH_ALIVE=ALIVE
local function local_player()return {player_unit='player'}end
local Unit={world_rotation=function()return 1 end,world_position=function()return 0 end}
local Quaternion={forward=function()return 1 end,right=function()return 1 end};local Vector3={length=math.abs}
local function vector3_up()return 1 end;local PhysicsWorld={raycast=function()return obstructed end}
local function controllable_breed()return {}end;local function safe_extension()return {}end
VersusModeState.spawn_exact_minion=function()spawned=spawned+1;return 'new'end
local function release_possession()local state=mod._control;mod._control=nil;if not state.keep_training_unit then manager:despawn_minion(state.unit)end end
local function begin_possession(u,...)mod._control={unit=u,training_heretic=true};if fail and u=='new'then error('simulated partial possession failure')end;return true end
${fn('VersusModeState.training_select')}
mod._control={unit='old',training_heretic=true};fail=true
assert(not VersusModeState.training_select({name='sniper'}));assert(mod._control.unit=='old' and removed.new and not removed.old)
removed={};fail=false;assert(VersusModeState.training_select({name='sniper'}));assert(removed.old and mod._control.unit=='new')
obstructed=true;local before=spawned;assert(not VersusModeState.training_select({name='sniper'}));assert(spawned==before)
`);
