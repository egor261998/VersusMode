const fs=require('fs'),path=require('path');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('fengari');
const root=path.resolve(__dirname,'..');
const source=fs.readFileSync(path.join(root,'scripts/mods/VersusMode/VersusMode_portraits.lua'),'utf8');
const importedSource=fs.readFileSync(path.join(root,'scripts/mods/VersusMode/VersusMode_portrait_images.lua'),'utf8');
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
const code=`
local texture_calls,rect_calls=0,0;local fail=false;local force=false;local frame=1
local renderer={draw_texture=function()texture_calls=texture_calls+1;if fail then error('missing material')end end,
draw_rect=function(_,pos,size,color)assert(pos[1]==pos[1] and size[1]>0 and size[2]>0);assert(color.frame==frame,'expired frame color');rect_calls=rect_calls+1 end}
function require()return renderer end
local imported=(function()${importedSource} end)()
function get_mod()return {get=function()return force end,io_dofile=function()return imported end}end
Application={can_get_resource=function()return true end}
function Vector3(...)return {...}end
function Color(...)local c={...};c.frame=frame;return c end
local portraits=(function()${source} end)()
local result={};local n=0
for breed in pairs(portraits.profiles)do
 local runs=portraits.build(breed);assert(rawequal(runs,portraits.build(breed)));assert(#runs<150)
 local pixels=0;local encoded={}
 for _,r in ipairs(runs)do
  assert(r[1]>=0 and r[2]>=0 and r[1]+r[3]<=32 and r[2]+r[4]<=32)
  pixels=pixels+r[3]*r[4]
  encoded[#encoded+1]=string.format('[%d,%d,%d,%d,%d,%d,%d]',r[1],r[2],r[3],r[4],r[5][1],r[5][2],r[5][3])
 end
 assert(pixels==1024);n=n+1
 result[#result+1]='"'..breed..'":['..table.concat(encoded,',')..']'
end
assert(n==32)
for breed in pairs(portraits.profiles)do
 local p=assert(imported[breed],breed);local area=0
 assert(type(p.packed)=='string' and #p.packed%7==0 and #p.packed/7<=2048)
 for i=1,#p.packed,7 do
  local x,y,w,h=string.byte(p.packed,i,i+3)
  assert(x+w<=p.width and y+h<=p.height and w>0 and h>0)
  area=area+w*h
 end
 assert(area==p.width*p.height)
end
portraits.draw(nil,{},nil,{portrait_breed='chaos_ogryn_executor',portrait='native',use_imported_portrait=true},{0,0,1},{110,110})
assert(rect_calls==#imported.chaos_ogryn_executor.packed/7 and texture_calls==0)
frame=frame+1
portraits.draw(nil,{},nil,{portrait_breed='chaos_ogryn_executor',portrait='native',use_imported_portrait=true},{0,0,1},{110,110})
assert(rect_calls==2*#imported.chaos_ogryn_executor.packed/7 and texture_calls==0)
rect_calls=0
local content={portrait_breed='renegade_gunner',portrait='native'}
portraits.draw(nil,{},nil,content,{0,0,1},{56,56});assert(texture_calls==1 and rect_calls==0)
force=true;portraits.draw(nil,{},nil,content,{0,0,1},{56,56});assert(rect_calls>0 and texture_calls==1)
force=false;fail=true;rect_calls=0;portraits.draw(nil,{},nil,content,{0,0,1},{90,90});assert(rect_calls>0)
local old=texture_calls;portraits.draw(nil,{},nil,content,{0,0,1},{110,110});assert(texture_calls==old)
portrait_json='{'..table.concat(result,',')..'}'
`;
if(lauxlib.luaL_dostring(L,to_luastring(code))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));
lua.lua_getglobal(L,to_luastring('portrait_json'));const icons=JSON.parse(to_jsstring(lua.lua_tostring(L,-1)));
const main=fs.readFileSync(path.join(root,'scripts/mods/VersusMode/VersusMode.lua'),'utf8');
const roster=main.slice(main.indexOf('    respawn_breeds = {'),main.indexOf('    allow_boss_reinforcements'));
for(const [,breed] of roster.matchAll(/name = "([^"]+)"/g))if(!icons[breed])throw Error('Missing icon '+breed);
if(process.argv.includes('--preview')){
 const dir=path.join(root,'artifacts');fs.mkdirSync(dir,{recursive:true});
 fs.writeFileSync(path.join(dir,'enemy-portraits.json'),JSON.stringify(icons));
 const names=Object.keys(icons).sort(),width=1200,height=Math.ceil(names.length/6)*220;
 let svg=`<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}"><rect width="100%" height="100%" fill="#10171c"/>`;
 names.forEach((name,i)=>{const x=(i%6)*200+36,y=Math.floor(i/6)*220+16;for(const [rx,ry,w,h,r,g,b]of icons[name])svg+=`<rect x="${x+rx*4}" y="${y+ry*4}" width="${w*4}" height="${h*4}" fill="rgb(${r},${g},${b})"/>`;svg+=`<text x="${x+64}" y="${y+155}" text-anchor="middle" fill="#eee" font-family="sans-serif" font-size="10">${name}</text>`;});
 fs.writeFileSync(path.join(dir,'enemy-portraits.svg'),svg+'</svg>');
}
console.log('32 cached portraits, roster coverage, native rendering and fallback checks passed');
