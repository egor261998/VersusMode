// CPU microbenchmark with engine APIs stubbed: NOT an in-game FPS/GPU measurement.
// node tools/benchmark-ui.cjs <baseline directory> <game-source ui_renderer.lua>
const fs=require('fs'),path=require('path'),parse=require('luaparse').parse;
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('fengari');
const root=path.resolve(__dirname,'..'),base=path.join(root,'scripts/mods/VersusMode');
const [baseline,nativePath]=process.argv.slice(2);
if(!baseline||!nativePath)throw Error('Pass baseline directory and native ui_renderer.lua');
const native=fs.readFileSync(nativePath,'utf8').replace(/^\uFEFF/,'');
const ast=parse(native,{luaVersion:'5.1',ranges:true});
const assignment=ast.body.find(n=>n.type==='AssignmentStatement'&&n.variables[0]?.identifier?.name==='draw_rect');
if(!assignment)throw Error('Native draw_rect missing');
const before=fs.readFileSync(path.join(baseline,'VersusMode_portraits.lua'),'utf8');
const after=fs.readFileSync(path.join(base,'VersusMode_portraits.lua'),'utf8');
const images=fs.readFileSync(path.join(base,'VersusMode_portrait_images.lua'),'utf8');
const pickerBefore=fs.readFileSync(path.join(baseline,'versus_spawn_view.lua'),'utf8');
const pickerAfter=fs.readFileSync(path.join(base,'ui/versus_spawn_view.lua'),'utf8');
const code=`
local vectors,colors,rects,resets=0,0,0,0
function Vector3(...)vectors=vectors+1;return {...}end
function Color(...)colors=colors+1;return {...}end
function table.clear(t)for k in pairs(t)do t[k]=nil end end
Script={temp_count=function()return 0,0,0 end,set_temp_count=function()resets=resets+1 end}
Gui={scale_vector3=function(v,s)return Vector3(v[1]*s,v[2]*s,v[3]*s)end}
local trace;local reference;local cursor=0
Gui2={rect=function(gui,p,s,o)
 rects=rects+1
 local line
 if trace or reference then
  line={p[1],p[2],p[3],s[1],s[2],s[3],o.color[1],o.color[2],o.color[3],o.color[4],o.snap_pixel_positions,o.render_pass or ''}
 end
 if trace then trace[#trace+1]=line end
 if reference then
  cursor=cursor+1;local old=assert(reference[cursor])
  for i=1,12 do assert(type(line[i])=='number' and math.abs(line[i]-old[i])<0.000001 or line[i]==old[i],'rectangle mismatch '..i)end
 end
end}
local Gui2_rect=Gui2.rect;local SNAP_PIXEL_POSITIONS=false;local optional_gui_args={};local UIRenderer={}
${native.slice(...assignment.range)}
function require()return UIRenderer end
local imported=(function() ${images} end)()
function get_mod()return {io_dofile=function()return imported end}end
local before=(function() ${before} end)()
local after=(function() ${after} end)()
local content={use_imported_portrait=true,portrait_breed='chaos_ogryn_executor'}
for _,scale in ipairs({0.75,1,1.5})do
 for _,settings in ipairs({{}, {alpha_multiplier=0.5,color_intensity_multiplier=1.2,start_layer=7,snap_pixel_positions=true,hdr=true},
  {alpha_multiplier=0,color_intensity_multiplier=0,start_layer=-3,snap_pixel_positions=false}})do
  local renderer={gui={},scale=scale,render_settings=settings,base_render_pass='ui'}
  trace={};before.draw(nil,renderer,nil,content,{10,20,3},{110,110})
  reference=trace;trace=nil;cursor=0;after.draw(nil,renderer,nil,content,{10,20,3},{110,110})
  assert(cursor==#reference);reference=nil
 end
end
local renderer={gui={},scale=1,render_settings={}}
local function draw(p) p.draw(nil,renderer,nil,content,{10,20,3},{110,110}) end
local function measure(p)
 for i=1,3 do draw(p)end
 vectors,colors,rects,resets=0,0,0,0
 draw(p)
 local counts=string.format('"vectors":%d,"colors":%d,"rects":%d,"temp_resets":%d',vectors,colors,rects,resets)
 local times={}
 for sample=1,5 do
  local start=os.clock();for i=1,8 do draw(p)end
  times[sample]=(os.clock()-start)*1000/8
 end
 local raw={};for i,v in ipairs(times)do raw[i]=tostring(v)end
 table.sort(times)
 return '{'..counts..',"median_ms":'..times[3]..',"samples_ms":['..table.concat(raw,',')..']}'
end
local portrait_results='"portrait_before":'..measure(before)..',"portrait_after":'..measure(after)
local localizations=0
local mod={_view_definitions={versus_mode_spawn_view={}},spawn_picker_available=function()return true end,
 spawn_picker_cooldown=function()return 0 end,spawn_picker_hold=function()end,
 localize=function(_,key)localizations=localizations+1;return key end}
function get_mod()return mod end
function class()return {super={update=function()return true,true end}}end
local oldPicker=(function() ${pickerBefore} end)()
local newPicker=(function() ${pickerAfter} end)()
local function measure_picker(class)
 local view=setmetatable({_choices={},_selected=1,_heartbeat_at=0,_widgets_by_name={}}, {__index=class})
 for i=1,8 do
  view._choices[i]={}
  view._widgets_by_name['enemy_'..i]={content={hotspot={}},style={cooldown={text_color={}},background={color={}},frame={color={}}}}
 end
 for i=1,30 do view:update(1/60,0,{})end
 localizations=0
 local old={}
 for i=1,8 do local s=view._widgets_by_name['enemy_'..i].style;old[i]={s.cooldown.text_color,s.background.color,s.frame.color}end
 view:update(1/60,0,{})
 local replacements=0
 for i=1,8 do
  local s=view._widgets_by_name['enemy_'..i].style
  for j,v in ipairs({s.cooldown.text_color,s.background.color,s.frame.color})do
   if v~=old[i][j] then replacements=replacements+1 end
  end
 end
 local counts=string.format('"localizations":%d,"color_tables":%d',localizations,replacements)
 local times,raw={},{}
 for sample=1,5 do
  local start=os.clock();for i=1,120 do view:update(1/60,0,{})end
  times[sample]=(os.clock()-start)*1000/120;raw[sample]=tostring(times[sample])
 end
 table.sort(times)
 return '{'..counts..',"median_ms":'..times[3]..',"samples_ms":['..table.concat(raw,',')..']}'
end
result='{'..portrait_results..',"picker_before":'..measure_picker(oldPicker)..',"picker_after":'..measure_picker(newPicker)..'}'
`;
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
if(lauxlib.luaL_dostring(L,to_luastring(code))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));
lua.lua_getglobal(L,to_luastring('result'));console.log(to_jsstring(lua.lua_tostring(L,-1)));lua.lua_close(L);
