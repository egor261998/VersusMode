const fs=require('fs'), path=require('path'),parse=require('luaparse').parse;
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('fengari');
const root=path.resolve(__dirname,'..');
let parsed=0;function scan(dir){for(const e of fs.readdirSync(dir,{withFileTypes:true})){if(e.name==='.git'||e.name==='node_modules')continue;const p=path.join(dir,e.name);if(e.isDirectory())scan(p);else if(/\.(lua|mod)$/.test(p)){parse(fs.readFileSync(p,'utf8'),{luaVersion:'5.1'});parsed++}}}scan(root);
const s=fs.readFileSync(root+'/scripts/mods/VersusMode/VersusMode.lua','utf8'),ast=parse(s,{luaVersion:'5.1',ranges:true});
const ident=n=>n.type==='Identifier'?n.name:ident(n.base)+'.'+n.identifier.name;
const fn=name=>{const n=ast.body.find(n=>n.type==='FunctionDeclaration'&&n.identifier&&ident(n.identifier)===name);if(!n)throw Error(name);return s.slice(...n.range)};
const code=`
local now=100;local server=true;local math_max=math.max
local function gameplay_time()return now end
local function is_server()return server end
local function setting()return 10 end
local mod={localize=function(_,x)return x end,info=function()end,echo=function()end,_realms_compat={peer_compatible=function()return true end}}
local role={infected_human=true};local choices={{name='sniper'},{name='gunner'}}
local VersusModeState={respawn_breeds=choices,breeds={sniper=true,gunner=true},local_role=function()return role end,
 local_active=function()return true end,spawn_selection_enabled=function()return true end,control_for_peer=function()end,
 available_spawn_choices=function()return choices end,publish_roster=function()end,respawn_label=function(n)return n end,
 echo_localized=function()end,send_remote_respawn_notice=function()end,send_remote_status=function()end,
 normalize_peer_id=function(p)return p end,role_for_peer=function()return role end}
${['cooldown_store','snapshot_age','respawn_remaining','breed_cooldown','breed_cooldown_payload','record_breed_death','apply_breed_cooldowns','cycle_respawn','schedule_respawn','try_respawn','try_remote_respawn'].map(n=>fn('VersusModeState.'+n)).join('\n')}
local count=0;local function check(x)assert(x);count=count+1 end
VersusModeState.record_breed_death(role,{breed={name='sniper'}})
check(VersusModeState.breed_cooldown(role,'sniper')==60)
check(VersusModeState.breed_cooldown(role,'gunner')==0)
check(VersusModeState.breed_cooldown({infected_human=true},'sniper')==0)
check(not VersusModeState.cycle_respawn(role,nil,'sniper'))
check(VersusModeState.cycle_respawn(role,nil,'gunner'))
role.respawn_breed='sniper';role.respawn_ready_at=0
check(not VersusModeState.try_respawn(role));check(not VersusModeState.try_remote_respawn('peer',{}))
now=130;check(VersusModeState.breed_cooldown(role,'sniper')==30)
local payload=VersusModeState.breed_cooldown_payload(role);local client={};now=900
VersusModeState.apply_breed_cooldowns(client,payload);check(VersusModeState.breed_cooldown(client,'sniper')==30)
now=910;check(VersusModeState.breed_cooldown(client,'sniper')==20)
VersusModeState.apply_breed_cooldowns(client,{sniper=0/0,gunner=61});check(next(client.breed_cooldowns)==nil)
now=130;VersusModeState.schedule_respawn(role);check(role.respawn_breed=='gunner')
VersusModeState.record_breed_death(role,{breed={name='gunner'}})
VersusModeState.schedule_respawn(role);check(role.respawn_breed=='sniper')
now=160;check(VersusModeState.breed_cooldown(role,'sniper')==0);check(VersusModeState.cycle_respawn(role,nil,'sniper'))
check(VersusModeState.breed_cooldown(role,'gunner')==30)
server=false;VersusModeState.record_breed_death(role,{breed={name='sniper'}});check(VersusModeState.breed_cooldown(role,'sniper')==0)
print(count..' authoritative cooldown checks passed')
`;
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);if(lauxlib.luaL_dostring(L,to_luastring(code))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));
console.log(parsed+' Lua files parsed');