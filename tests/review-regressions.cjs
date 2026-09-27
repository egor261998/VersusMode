const fs=require('fs'),path=require('path'),parse=require('luaparse').parse;
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('fengari');
const root=path.resolve(__dirname,'..'),base=path.join(root,'scripts/mods/VersusMode');
const source=fs.readFileSync(path.join(base,'VersusMode.lua'),'utf8');
const ast=parse(source,{luaVersion:'5.1',ranges:true});
const id=n=>n.type==='Identifier'?n.name:id(n.base)+'.'+n.identifier.name;
const fn=name=>{const n=ast.body.find(n=>n.type==='FunctionDeclaration'&&n.identifier&&id(n.identifier)===name);if(!n)throw Error(name);return source.slice(...n.range)};
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
current=nil;fire('ai_dodge',3)
local function state_look_direction()return nil,'forward' end
${aimHook}
for _,breed in ipairs({'renegade_gunner','cultist_gunner','chaos_ogryn_gunner'})do
 current={possessed=true,unit='unit',attack_deadline=10,breed={name=breed},requested_attack={gunner_combat_range='far'},grenadier_target_lock=false}
 local stored;local scratch={current_aim_position={store=function(_,p)stored=p end}}
 local calls=0;local function native_aim()calls=calls+1;return 'native_lock' end
 assert(callback(native_aim,'unit',scratch,0,{},current.breed)==true and stored=='crosshair' and calls==0)
 current.grenadier_target_lock=true;stored=nil
 assert(callback(native_aim,'unit',scratch,0,{},current.breed)=='native_lock' and stored==nil and calls==1)
end
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
`);
function run(name,code){const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);if(lauxlib.luaL_dostring(L,to_luastring(code))!==lua.LUA_OK)throw Error(name+': '+to_jsstring(lua.lua_tostring(L,-1)));console.log(name+' passed');}
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
run('Host HUD cache build rate',`
local now=0;local mod={};local function gameplay_time()return now end
local builds=0;local VersusModeState={team_hud_snapshot=function()builds=builds+1;return {sent_at=now,rows={}}end}
${fn('VersusModeState.cached_team_hud_snapshot')}
for frame=0,599 do now=frame/60;VersusModeState.cached_team_hud_snapshot()end
assert(builds<=100 and builds>=80,'cache must bound 600 frame reads to at most 100 snapshots')
mod._team_hud_host_cache=nil;local previous=builds;VersusModeState.cached_team_hud_snapshot();assert(builds==previous+1)
print('600 HUD reads, '..builds..' snapshot builds (including invalidation)')
`);
run('Night vision integration fades after camera return',`
local mod={_night_vision={}};local Managers={ui={has_active_view=function()return false end}}
local function get_mod()return mod end
mod._night_vision.ramp=(function()${fs.readFileSync(path.join(base,'VersusMode_night_ramp.lua'),'utf8')} end)()
mod._night_vision.optics=(function()${fs.readFileSync(path.join(base,'VersusMode_night_optics.lua'),'utf8')} end)()
local active=false;local VersusModeState={night_vision_active=function()return active end}
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
