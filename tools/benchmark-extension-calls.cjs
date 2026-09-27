// Microbenchmark: Fengari and identical extension stubs, not in-game FPS.
const fs=require('fs'),path=require('path'),cp=require('child_process');
const {parse}=require('luaparse');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('fengari');
const root=path.resolve(__dirname,'..'),file='scripts/mods/VersusMode/VersusMode.lua';
const before=cp.execFileSync('git',['show','e4a6e91:'+file],{cwd:root,encoding:'utf8',maxBuffer:8e6});
const after=fs.readFileSync(path.join(root,file),'utf8');
function extract(source){
 const ast=parse(source,{luaVersion:'5.1',ranges:true});
 function id(n){return n.type==='Identifier'?n.name:id(n.base)+'.'+n.identifier.name}
 return ast.body.filter(n=>n.type==='FunctionDeclaration'&&n.identifier&&
 ['safe_extension','safe_extension_call','VersusModeState.protected_unit_alive',
 'VersusModeState.protected_unit_extension','VersusModeState.protected_extension_method'].includes(id(n.identifier)))
 .map(n=>source.slice(...n.range)).join('\n').replace(/\\n/g,'\n');
}
for(const [label,source]of [['before',before],['after',after]]){
 const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
 const code=`
 local VersusModeState={}
 local ALIVE={[1]=true}
 local ext={value=function(self,a)return a+1 end}
 local ScriptUnit={has_extension=function()return ext end}
 local table_unpack=table.unpack
 ${extract(source)}
 local function batch()for i=1,10000 do local e=safe_extension(1,'health');local ok,v=safe_extension_call(e,'value',i);assert(ok and v==i+1)end end
 for i=1,3 do batch()end
 local samples={}
 for i=1,5 do local t=os.clock();batch();samples[i]=(os.clock()-t)*1000 end
 print('${label} ms per 10000 query+call pairs: '..table.concat(samples,', '))
 table.sort(samples);print('median: '..samples[3])
 `;
 if(lauxlib.luaL_dostring(L,to_luastring(code))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));
 lua.lua_close(L);
}