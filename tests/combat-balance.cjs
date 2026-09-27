const fs = require('fs'), path = require('path'), assert = require('assert');
const {parse} = require('luaparse');
const {lua, lauxlib, lualib, to_luastring, to_jsstring} = require('fengari');
const base = path.resolve(__dirname, '../scripts/mods/VersusMode');
const source = fs.readFileSync(path.join(base, 'VersusMode.lua'), 'utf8');
const moduleSource = fs.readFileSync(path.join(base, 'VersusMode_combat_balance.lua'), 'utf8');
const ast = parse(source, {luaVersion:'5.1', ranges:true});
const id = n => n.type === 'Identifier' ? n.name : id(n.base) + '.' + n.identifier.name;
function fn(name) {
    const node = ast.body.find(n => n.type === 'FunctionDeclaration' && n.identifier && id(n.identifier) === name);
    assert(node, name); return source.slice(...node.range);
}
function hook(target, method) {
    const node = ast.body.find(n => {
        const c = n.expression, args = c && c.arguments;
        return n.type === 'CallStatement' && args && args.length === 3
            && args[0].type !== 'StringLiteral' && args[0].type !== 'CallExpression'
            && id(args[0]) === target && args[1].type === 'StringLiteral'
            && source.slice(...args[1].range) === JSON.stringify(method);
    });
    assert(node, target + '.' + method); return source.slice(...node.range);
}
let suites = 0;
function run(name, code) {
    const L = lauxlib.luaL_newstate(); lualib.luaL_openlibs(L);
    if (lauxlib.luaL_dostring(L, to_luastring(code)) !== lua.LUA_OK)
        throw Error(name + ': ' + to_jsstring(lua.lua_tostring(L, -1)));
    lua.lua_close(L); suites++; console.log(name + ' passed');
}
const setup = `
local values={}
local function setting(k)return values[k] end
local balance=(function() ${moduleSource} end)()(setting)
local now=10
local function gameplay_time()return now end
local mod={_combat_balance=balance,localize=function(_,k,v)return k end}
local hooks={}
function mod:hook(_,name,callback)hooks[name]=callback end
`;

run('Shotgun magazines, live host values and cancellation cannot reset cooldowns', setup + `
local shot={shotgun_combat_range='close'};local melee={shotgun_combat_range='melee'}
for _,name in ipairs({'renegade_shocktrooper','cultist_shocktrooper'})do
 local s={breed={name=name}}
 for i=1,6 do
  local t=10+i
  assert(balance.remaining(s,shot,t)==0)
  balance.shot(s,t)
  s.requested_attack=nil;s.attack_deadline=nil -- cancellation/behavior restart
  assert(balance.remaining(s,shot,t+0.1)>0)
 end
 assert(s.balance_shots==6 and s.balance_reload_t==16)
 assert(balance.remaining(s,shot,18)==1)
 assert(balance.remaining(s,melee,18)==0) -- movement/melee is not a reload
 assert(balance.remaining(s,shot,19)==0 and s.balance_shots==0)
 balance.shot(s,19);assert(s.balance_shots==1)
 values.shotgun_shot_delay=2;assert(balance.remaining(s,shot,20)==1)
 values.shotgun_shot_delay=nil
end
local plasma={breed={name='renegade_plasma_gunner'}}
balance.shot(plasma,10);assert(plasma.balance_shots==nil)
local s={breed={name='grenadier'},balance_bomb_t=10,balance_cancel_t=11}
assert(balance.remaining(s,{grenadier_path='far'},11.5)==1.5)
assert(balance.remaining(s,{grenadier_path='close'},11.5)==0.5)
assert(balance.remaining(s,{grenadier_path='far'},13)==0)
values.bomber_throw_delay=5;assert(balance.remaining(s,{grenadier_path='far'},13)==2)
values.attack_cancel_delay=0/0;assert(balance.remaining(s,{},11.5)==0.5)
values.shotgun_magazine_size=1
local one={breed={name='cultist_shocktrooper'}}
balance.shot(one,10);assert(balance.remaining(one,shot,10)==3)
`);

run('Boss checkbox, cancellation and stagger gate all authoritative commands', setup + `
local VersusModeState={}
local function set_status()end
${fn('VersusModeState.balance_attack_blocked')}
local s={breed={is_boss=true},requested_attack={},attack_deadline=15}
balance.finished(s,10);s.attack_deadline=nil;s.requested_attack=nil
assert(VersusModeState.balance_attack_blocked(s,{}))
values.enable_boss_attack_delay=false
assert(not VersusModeState.balance_attack_blocked(s,{}))
s.balance_cancel_t=10;assert(VersusModeState.balance_attack_blocked(s,{}))
now=11;assert(not VersusModeState.balance_attack_blocked(s,{}))
s.player_cc_active=true;assert(VersusModeState.balance_attack_blocked(s,{}))
s.player_cc_active=nil;values.enable_boss_attack_delay=true;values.boss_attack_delay=3
assert(VersusModeState.balance_attack_blocked(s,{}));now=13
assert(not VersusModeState.balance_attack_blocked(s,{}))
`);

run('Cancellation stamps the server timer once and clients only send requests', setup + `
local HOUND_BREEDS={};local POXBURSTER_BREED_NAME='burster'
local sent,paused=0,0
local VersusModeState={send_client_action=function()sent=sent+1 end,echo_attack_log_notice=function()end}
local function set_status()end
local function safe_anim_event()end
local function pause_brain(s)paused=paused+1;s.attack_deadline=nil;s.requested_attack=nil end
${fn('VersusModeState.cancel_control_action')}
local s={possessed=true,breed={name='gunner'},attack_deadline=12,requested_attack={cancellable=true,label='Shoot'}}
VersusModeState.cancel_control_action(s)
assert(s.balance_cancel_t==10 and paused==1)
now=10.5;VersusModeState.cancel_control_action(s)
assert(s.balance_cancel_t==10 and paused==1)
s.player_cc_active=true;s.attack_deadline=13;s.requested_attack={cancellable=true,label='Shoot'}
VersusModeState.cancel_control_action(s);assert(paused==1 and s.attack_deadline==13)
s.player_cc_active=nil;s.remote_client=true;s.balance_cancel_t=nil
VersusModeState.cancel_control_action(s);assert(sent==1 and s.balance_cancel_t==nil)
`);

run('Actual grenade spawn establishes cooldown only after a successful throw', setup + `
local BtGrenadierThrowAction={}
local GRENADIER_BREEDS={grenadier=true}
local s={unit=1,breed={name='grenadier'},requested_attack={grenadier_path='far'}}
local VersusModeState={control_for_unit=function()return s end}
${hook('BtGrenadierThrowAction','_throw_grenade')}
local function fire(kind,native)
 return hooks._throw_grenade(native or function()return 'spawned' end,{},1,{}, {},{},kind,1,2,{},10)
end
assert(fire('drop')=='spawned' and s.balance_bomb_t==nil)
assert(not pcall(fire,'throw',function()error('spawn failed')end) and s.balance_bomb_t==nil)
fire('throw');assert(s.balance_bomb_t==10 and s.grenade_projectile_spawned)
assert(balance.remaining(s,{grenadier_path='far'},11)==2)
assert(balance.remaining(s,{grenadier_path='close'},11)==0)
`);

run('Actual shot hook counts pellets as one blast and ignores failed native shots', setup + `
local MinionAttack={};local SNIPER_BREED_NAME='sniper'
local s={unit=1,possessed=true,breed={name='renegade_shocktrooper'}}
local VersusModeState={controlled_gunner_shot=function()return s end}
local Specialist={free_aim=function()return false end}
${hook('MinionAttack','shoot_hit_scan')}
local native=0
hooks.shoot_hit_scan(function()native=native+1;return 'ok' end,{}, {},1)
assert(native==1 and s.balance_shots==1 and s.balance_shot_t==10)
assert(not pcall(hooks.shoot_hit_scan,function()error('native failed')end,{}, {},1))
assert(s.balance_shots==1)
s.breed.name='renegade_plasma_gunner'
hooks.shoot_hit_scan(function()end,{}, {},1)
assert(s.shotgun_fire_cooldown_until==11 and s.balance_shots==1)
`);

run('Trapper retains aiming audio entry and waits for configured preparation', setup + `
local BtShootNetAction={};local NETTER_BREED_NAME='netter'
local s={unit=1,breed={name='netter'},requested_attack={action_name='shoot_net'},attack_deadline=20}
local VersusModeState={control_for_unit=function()return s end}
local function safe_extension_call()end
local Vector3={zero=function()return 0 end}
local function camera_aim_ray()return 42,nil,10 end
local function state_look_direction()return 1,2 end
local Quaternion={look=function()return 1 end}
local function vector3_up()return 1 end
${hook('BtShootNetAction','enter')}
${hook('BtShootNetAction','_update_aiming')}
local shots,audio=0,0
local action={_start_shooting=function()shots=shots+1 end}
local pad={locomotion_extension={set_wanted_rotation=function()end},current_aim_position={store=function()end}}
hooks.enter(function()audio=audio+1;pad.shoot_t=100 end,action,1,{}, {},pad,{},10)
assert(audio==1 and pad.shoot_t==11 and pad.num_shots==1)
hooks._update_aiming(function()error('unexpected fallback')end,action,1,10.9,pad,{})
assert(shots==0)
hooks._update_aiming(function()end,action,1,11,pad,{})
assert(shots==1)
values.trapper_shot_delay=3
hooks.enter(function()end,action,1,{}, {},pad,{},20)
assert(pad.shoot_t==23)
`);

run('Only operative push/ability CC passes; native immunity and force scope remain', setup + `
local s={unit=1,possessed=true,breed={},blackboard={stagger={num_triggered_staggers=0}}}
local active,paused,applied=0,0,0
s.behavior={set_brain_enabled=function(_,enabled)if enabled then active=active+1 end end}
local function safe_extension_call(e,k,...)return e[k](e,...)end
local function pause_brain(state)paused=paused+1;state.attack_deadline=nil end
local function valid_player_target(u)return u=='operative' end
local VersusModeState={stagger={},control_for_unit=function()return s end,
 controlled_stagger_immune=function()return true end}
${fn('VersusModeState.resume_player_cc')}
${fn('VersusModeState.update_player_cc')}
${fn('VersusModeState.with_player_ability_cc')}
${hook('VersusModeState.stagger','apply_stagger')}
${hook('VersusModeState.stagger','force_stagger')}
local function native()applied=applied+1;s.blackboard.stagger.num_triggered_staggers=1;return true,'heavy' end
local function apply(profile,attacker)
 return hooks.apply_stagger(native,1,profile,{}, {},attacker,100)
end
assert(not apply({},'operative')) -- ordinary melee/bullets
assert(not apply({suppression_type='ability'},'barrel'))
assert(not apply({is_push=true},'enemy'))
assert(applied==0)
assert(apply({is_push=true},'operative') and paused==1 and s.player_cc_active)
assert(VersusModeState.update_player_cc(s))
assert(apply({suppression_type='ability'},'operative') and paused==1)
hooks.force_stagger(native,1,'heavy',1,4,1,4,'operative')
assert(applied==2) -- attribution alone must not allow barrel CC
VersusModeState.with_player_ability_cc(function()
 hooks.force_stagger(native,1,'heavy',1,4,1,4,'operative')
end,'operative')
assert(applied==3 and mod._player_ability_cc==nil)
s.blackboard.stagger.num_triggered_staggers=0
assert(not VersusModeState.update_player_cc(s) and not s.player_cc_active and paused==2)
local rejected=hooks.apply_stagger(function()return false end,1,{is_push=true},{},{},'operative')
assert(not rejected and not s.player_cc_active)
assert(not pcall(VersusModeState.with_player_ability_cc,function()error('ability failed')end,'operative'))
assert(mod._player_ability_cc==nil)
VersusModeState.with_player_ability_cc(function()
 VersusModeState.with_player_ability_cc(function()assert(mod._player_ability_cc=='inner')end,'inner')
 assert(mod._player_ability_cc=='operative')
end,'operative')
assert(mod._player_ability_cc==nil)
`);

// Both local and remote authority must leave locomotion to the stagger leaf.
assert(fn('VersusModeState.update_authoritative_remote_control').includes('VersusModeState.update_player_cc(state)'));
assert(fn('request_attack_for_state').indexOf('if state.remote_client then') < fn('request_attack_for_state').indexOf('balance_attack_blocked'));
assert(fn('start_attack_burst').includes('balance_attack_blocked'));
assert(fn('pause_brain').includes('mod._combat_balance.finished(state, t)'));
assert(fn('VersusModeState.cancel_control_action').includes('state.balance_cancel_t = gameplay_time()'));
console.log(suites + ' combat balance regression suites passed');
