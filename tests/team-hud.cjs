const fs=require('fs'),path=require('path'),parse=require('luaparse').parse;
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('fengari');
const base=path.resolve(__dirname,'../scripts/mods/VersusMode');
const source=fs.readFileSync(path.join(base,'VersusMode.lua'),'utf8');
const ast=parse(source,{luaVersion:'5.1',ranges:true});
const id=n=>n.type==='Identifier'?n.name:n.type==='MemberExpression'?id(n.base)+'.'+n.identifier.name:'';
const extract=name=>{const node=ast.body.find(n=>n.type==='FunctionDeclaration'&&n.identifier&&id(n.identifier)===name||n.type==='AssignmentStatement'&&id(n.variables[0])===name);if(!node)throw Error(name);return source.slice(...node.range)};
const code=`
local now=10;local server=true;local heretic=false;local menus=false;local portraits=0
local role1={infected_unique_id='1',infected_name='Alive player',infected_human=true}
local role2={infected_unique_id='2',infected_name='Dead player',infected_human=true,respawn_breed='sniper',death_choice_pending=true}
local role3={infected_unique_id='3',infected_name='Spawning player',infected_human=true,respawn_breed='sniper'}
local state={possessed=true,unit=1,breed={name='sniper'}}
local mod={localize=function(_,key)return key end,_portraits={draw=function()portraits=portraits+1 end}}
local function setting()return true end
local function gameplay_time()return now end
local function is_server()return server end
local math_max=math.max
local ALIVE={[1]=true};local HEALTH_ALIVE=ALIVE
local function safe_extension()return {}end
local function safe_extension_call(_,method)return true,method=='current_health' and 100 or 200 end
local ENEMY_PORTRAITS={sniper='portrait'};local ENEMY_PORTRAIT_FALLBACK='fallback'
local VersusModeState={roles=function()return {role1,role2,role3}end,control_for_role=function(r)return r==role1 and state end,
 respawn_remaining=function()return 3 end,snapshot_age=function()return 0 end,
 local_infected_view=function()return heretic end,training_available=function()return false end,
 respawn_label=function()return 'Sniper'end}
${extract('VersusModeState.team_hud_snapshot')}
${extract('VersusModeState.cached_team_hud_snapshot')}
${extract('VersusModeState.receive_team_hud')}
${extract('mod.heretic_team_hud_data')}
local snapshot=VersusModeState.team_hud_snapshot()
assert(snapshot.rows[1].alive and not snapshot.rows[1].respawning)
assert(not snapshot.rows[2].respawning and snapshot.rows[3].respawning)
for _,on_server in ipairs({true,false})do
 server=on_server
 if not server then VersusModeState.receive_team_hud(snapshot) end
 heretic=false;local rows=mod.heretic_team_hud_data()
 assert(rows[1].status=='heretic_team_alive' and rows[2].status=='heretic_team_dead' and rows[3].status=='heretic_team_respawning')
 for _,row in ipairs(rows)do assert(row.compact and row.portrait==nil and row.portrait_breed==nil and row.label==nil and row.health==nil and row.maximum==nil)end
 heretic=true;rows=mod.heretic_team_hud_data()
 assert(not rows[1].compact and rows[1].portrait=='portrait' and rows[1].label=='Sniper' and rows[1].health==100 and rows[1].maximum==200)
 assert(rows[2].status=='heretic_team_wait')
end
local function clone(t)local r={};for k,v in pairs(t)do r[k]=type(v)=='table' and clone(v) or v end;return r end
table.clone=clone
local W={create_definition=function(passes,_,content)return {passes=passes,content=content}end,
 init=function(_,def)local w={content=clone(def.content),style={},offset={},passes=def.passes};for _,p in ipairs(def.passes)do if p.style_id then w.style[p.style_id]=clone(p.style)end end;return w end}
function require(name)return name=='scripts/managers/ui/ui_widget' and W or {body={}}end
function get_mod()return mod end
function class()return {super={init=function(self)self._widgets={}end,update=function()end}}end
Managers={ui={has_active_view=function()return menus end}}
local H=(function() ${fs.readFileSync(path.join(base,'VersusMode_team_hud.lua'),'utf8')} end)()
local hud=setmetatable({},{__index=H});hud:init({},1,1)
local function update()hud:update(0.1,now,{},{},{})end
heretic=false;update();local row=hud._team_rows[1]
assert(row.content.compact and row.content.status=='heretic_team_alive' and row.style.background.size[2]==56)
for _,p in ipairs(row.passes)do
 if p.pass_type=='logic' or p.value_id=='label' or p.style_id=='health_fill' or p.style_id=='health_back' then assert(not p.visibility_function(row.content))end
end
heretic=true;update();assert(not row.content.compact and row.content.status=='100 / 200' and row.style.background.size[2]==116)
for _,p in ipairs(row.passes)do if p.pass_type=='logic' and p.visibility_function(row.content)then p.value()end end
assert(portraits==1 and row.style.name.offset[1]==116)
heretic=false;update();assert(row.content.portrait==nil and row.content.portrait_breed==nil and row.content.label=='' and row.style.name.offset[1]==10)
menus=true;update();assert(not row.content.visible)
menus=false;now=14;update();assert(not row.content.visible)
print('Host/client team HUD role privacy, statuses, role changes, portrait suppression and stale snapshots passed')
`;
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
if(lauxlib.luaL_dostring(L,to_luastring(code))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));
lua.lua_close(L);
