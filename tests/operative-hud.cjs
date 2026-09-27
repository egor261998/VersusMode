const fs=require('fs'),path=require('path'),parse=require('luaparse').parse;
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('fengari');
const base=path.resolve(__dirname,'../scripts/mods/VersusMode');
const benchmark=process.argv.includes('--benchmark');
const sourceArg=process.argv.indexOf('--source-root');
const hud=fs.readFileSync(path.join(sourceArg>=0?process.argv[sourceArg+1]:base,'VersusMode_operative_health_hud.lua'),'utf8');
const feedback=fs.readFileSync(path.join(base,'VersusMode_damage_feedback.lua'),'utf8');
const main=fs.readFileSync(path.join(base,'VersusMode.lua'),'utf8');
const mainAst=parse(main,{luaVersion:'5.1',ranges:true});
const receiveNode=mainAst.body.find(n=>n.type==='FunctionDeclaration'&&n.identifier?.identifier?.name==='apply_remote_status');
parse(hud,{luaVersion:'5.1'});parse(feedback,{luaVersion:'5.1'});
const code=`
local function clone(t)local r={};for k,v in pairs(t)do r[k]=type(v)=='table' and clone(v) or v end;return r end
table.clone=clone
local hooks={};local clock=0;local owner='heretic';local state={unit=owner,possessed=true};local remote=false;local packets={}
local mod={hook=function(_,target,name,callback)hooks[name]=callback end}
function require(name)return name end
local create=(function() ${feedback} end)()
local f=create(mod,{now=function()return clock end,local_owner=function()return owner end,
 is_local=function()return not remote end,send=function(e)packets[#packets+1]=e end,
 attacker=function(unit,attacker)return attacker=='heretic' and state or nil end})
local function deal(_,_,_,_,hp,tp)
 hooks.add_damage(function()return tp end,{_unit='operative'})
 return hp
end
assert(hooks.deal_damage(deal,'operative',{},'heretic','heretic',0,25)==0)
assert(#f.events==1 and f.events[1].kind=='toughness' and f.events[1].value==25)
hooks.deal_damage(deal,'operative',{},'heretic','heretic',12,5)
assert(#f.events==2 and f.events[1].value==30 and f.events[2].value==12)
hooks.deal_damage(deal,'operative',{},'other','other',100,100);assert(#f.events==2 and f.events[2].value==12)
remote=true
for i=1,10 do hooks.deal_damage(deal,'operative',{},'heretic','heretic',2,3) end
assert(#f.pending==1 and f.pending[1].health==20 and f.pending[1].toughness==30)
f:update(0.1);assert(#packets==1 and #f.pending==0)
f:receive('operative',0/0,math.huge);assert(#f.events==2)
clock=2;f:update(0.1);assert(#f.events==0)
for i=1,100 do f:receive(i,1,1)end;assert(#f.events==48)
owner='another';f:update(0);assert(#f.events==0)
owner=nil;f:receive('operative',1,1);assert(#f.events==0)
print('Damage attribution, separate actual health/toughness, aggregation, expiry and bounds passed')

local V={};V.__index=V
local vector_calls,ray_calls,projection_calls=0,0,0
local function vec(x,y,z)vector_calls=vector_calls+1;return setmetatable({x=x,y=y,z=z},V)end
function V.__add(a,b)return vec(a.x+b.x,a.y+b.y,a.z+b.z)end
function V.__sub(a,b)return vec(a.x-b.x,a.y-b.y,a.z-b.z)end
function V.__div(a,b)return vec(a.x/b,a.y/b,a.z/b)end
Vector3=setmetatable({length=function(v)return math.sqrt(v.x*v.x+v.y*v.y+v.z*v.z)end},{__call=function(_,...)return vec(...)end})
local physics={};local context={unit='heretic',player_unit='shell',physics_world=physics}
local hits=nil;local hidden=false;local menu=false;local frustum=true;local broken=false
local hp,maxhp,tp,maxtp,basetp=120,200,150,200,100
local health={max_health=function()if broken then error('unit despawned')end;return maxhp end,current_health=function()return hp end}
local toughness={max_toughness=function()return maxtp end,max_toughness_visual=function()return basetp end,current_toughness_percent=function()return tp/maxtp end}
ScriptUnit={has_extension=function(_,name)return name=='health_system' and health or toughness end}
Unit={has_node=function()return true end,node=function()return 2 end,world_position=function()return vec(1,2,3)end}
ALIVE={operative=true}
Camera={world_position=function()return vec(0,0,0)end,inside_frustum=function()return frustum and 1 or 0 end,
 world_to_screen=function()projection_calls=projection_calls+1;return vec(500,400,0),10 end}
PhysicsWorld={raycast=function(_,_,_,_,mode,_,types,_,filter)
 ray_calls=ray_calls+1
 assert(mode=='all' and types=='both' and filter=='filter_interactable_line_of_sight_marker_check');return hits end}
Actor={unit=function(actor)return actor end}
Managers={ui={has_active_view=function()return menu end},free_flight={is_in_free_flight=function()return true end,camera=function()return {}end},
 player={players=function()return {{player_unit='operative'}}end}}
local UIWidget={create_definition=function(passes,_,content)return {passes=passes,content=content}end,
 init=function(_,def)
  local w={offset={},content=clone(def.content),style={}}
  for _,p in ipairs(def.passes)do if p.style_id then w.style[p.style_id]=clone(p.style)end end
  return w
 end}
local colors={color_tint_6={255,80,170,255},color_tint_10={255,255,200,60}}
function require(name)
 if name=='scripts/managers/ui/ui_widget' then return UIWidget end
 if name=='scripts/managers/ui/ui_font_settings' then return {body={}}end
 return colors
end
function class()return {super={init=function(self)self._widgets={}end,update=function()end}}end
mod.operative_health_hud_context=function()return context end
mod.operative_health_hud_target=function()return not hidden end
mod.operative_damage_hud_target=function()return not hidden end
mod.localize=function(_,key,a,b)return string.format('%s %d / %d',key,a,b)end
function get_mod()return mod end
local H=(function() ${hud} end)()
local h=setmetatable({},{__index=H});h:init({},1,1)
local function update()h:update(0.1,clock,{inverse_scale=1},{},{})end
update();local row=h._rows[1]
assert(row.content.visible and row.style.health.size[1]==108 and row.style.toughness.size[1]==180)
assert(row.content.toughness:find('+50',1,true) and row.style.toughness.color[3]==200)
tp=80;update();assert(row.style.toughness.size[1]==144 and row.style.toughness.color[3]==170)
assert(not row.content.toughness:find('+',1,true))
hits={{0,0,0,'heretic'},{0,0,0,'wall'}};update();assert(not row.content.visible)
hits={{0,0,0,'heretic'},{0,0,0,'shell'},{0,0,0,'operative'}};update();assert(row.content.visible)
hidden=true;update();assert(not row.content.visible);hidden=false
menu=true;update();assert(not row.content.visible);menu=false
frustum=false;update();assert(not row.content.visible);frustum=true
broken=true;update();assert(not row.content.visible);broken=false
maxhp=0;update();assert(not row.content.visible);maxhp=200
maxtp=0;basetp=0;update();assert(row.content.visible and row.style.toughness.size[1]==0)
maxtp=200;basetp=100
owner='heretic';mod._damage_feedback=f;f:receive('operative',12,25);ray_calls=0;projection_calls=0;update()
if H._project then assert(ray_calls==1 and projection_calls==2,'one LOS ray per unit per frame')end
assert(h._damage_rows[1].content.visible and h._damage_rows[1].style.number.text_color[2]==255)
assert(h._damage_rows[2].content.visible and h._damage_rows[2].style.number.text_color[4]==255)
hits={{0,0,0,'wall'}};update();assert(not h._damage_rows[1].content.visible and not h._damage_rows[2].content.visible)
context=nil;update();assert(not row.content.visible and row._unit==nil)
if h._projections then assert(next(h._projections)==nil)end
print('Operative HUD gold bonus, depleted toughness, LOS, stealth, menus, teardown and colored damage passed')
local received=0
local VersusModeState={unit_from_network_id=function(id)return ({[1]='heretic',[2]='operative',[3]='old_heretic'})[id]end}
${main.slice(...receiveNode.range)}
mod._damage_feedback={receive=function(_,unit,hp,tp)assert(unit=='operative' and hp==7 and tp==12);received=received+1 end}
context={unit='heretic',remote_client=true,attack_deadline=99}
local payload={kind='operative_damage',target_id=2,attacker_id=1,health=7,toughness=12}
VersusModeState.apply_remote_status(payload);assert(received==1 and context.attack_deadline==99)
payload.attacker_id=3;VersusModeState.apply_remote_status(payload);assert(received==1)
payload.attacker_id=1;context=nil;VersusModeState.apply_remote_status(payload);assert(received==1)
print('Remote damage packets preserve attack state and reject previous possession hits passed')
${benchmark?`
context={unit='heretic',player_unit='shell',physics_world=physics};hits=nil;clock=5;owner='heretic'
mod._damage_feedback=f;f.events={}
local players={}
for i=1,4 do local unit='p'..i;ALIVE[unit]=true;players[i]={player_unit=unit} end
Managers.player.players=function()return players end
for i=1,48 do f.events[i]={unit=players[(i-1)%4+1].player_unit,kind=i%2==0 and 'health' or 'toughness',value=i,started=4.5} end
local function frame()h:update(1/60,clock,{inverse_scale=1},{},{})end
for i=1,30 do frame()end
ray_calls,projection_calls,vector_calls=0,0,0;frame()
local counts=string.format('"rays":%d,"projections":%d,"vectors":%d',ray_calls,projection_calls,vector_calls)
local times={};local raw={}
for sample=1,5 do
 local start=os.clock();for i=1,120 do frame()end
 times[sample]=(os.clock()-start)*1000/120;raw[sample]=tostring(times[sample])
end
table.sort(times)
print('HUD_BENCH {'..counts..',"median_ms":'..times[3]..',"samples_ms":['..table.concat(raw,',')..']}')
`:''}
`;
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
let result=lauxlib.luaL_loadstring(L,to_luastring(code));if(result===lua.LUA_OK)result=lua.lua_pcall(L,0,0,0);
if(result!==lua.LUA_OK)throw new Error(to_jsstring(lua.lua_tostring(L,-1)));
lua.lua_close(L);
