const fs = require('fs'), path = require('path'), assert = require('assert');
const parse = require('luaparse').parse;
const {lua, lauxlib, lualib, to_luastring, to_jsstring} = require('fengari');
const root = path.resolve(__dirname, '..');
const base = path.join(root, 'scripts/mods/VersusMode');
const source = fs.readFileSync(path.join(base, 'VersusMode_localization.lua'), 'utf8');
assert(!source.includes('\ufffd'), 'Invalid replacement character in localization');
const fields = parse(source).body[0].arguments[0].fields;
const entries = new Map();
const text = node => JSON.parse(node.raw);
function signature(value) {
    const result = [];
    for (let i = 0; i < value.length; i++) {
        if (value[i] !== '%') continue;
        const match = value.slice(i).match(/^%(?:%|[-+ #0]*\d*(?:\.\d+)?[cdiouxXeEfgGqs])/);
        assert(match, 'Unescaped percent: ' + value);
        if (match[0] !== '%%') result.push(match[0]);
        i += match[0].length - 1;
    }
    return result;
}
let formatted = 0;
const checks = [];
for (const entry of fields) {
    const key = entry.key.name;
    assert(!entries.has(key), 'Duplicate key: ' + key);
    const languages = new Map();
    for (const field of entry.value.fields) {
        const language = field.key.name || text(field.key);
        assert(!languages.has(language), 'Duplicate language: ' + key + '/' + language);
        languages.set(language, text(field.value));
    }
    assert(languages.get('en') && languages.get('ru'), 'Missing en/ru: ' + key);
    const expected = signature(languages.get('en'));
    for (const [language, value] of languages) {
        assert.deepStrictEqual(signature(value), expected, key + '/' + language + ' placeholders');
        const args = expected.map(spec => /[sq]$/.test(spec) ? '"Test"' : '2');
        checks.push(`assert(pcall(string.format, ${JSON.stringify(value)}${args.length ? ', ' + args.join(', ') : ''}), ${JSON.stringify(key + '/' + language)})`);
        formatted++;
    }
    entries.set(key, languages);
}
function walk(node, visit) {
    if (!node || typeof node !== 'object') return;
    visit(node);
    for (const value of Object.values(node)) {
        if (Array.isArray(value)) value.forEach(v => walk(v, visit));
        else if (value && typeof value === 'object') walk(value, visit);
    }
}
let references = 0;
function scan(dir) {
    for (const item of fs.readdirSync(dir, {withFileTypes: true})) {
        const file = path.join(dir, item.name);
        if (item.isDirectory()) scan(file);
        else if (item.name.endsWith('.lua')) {
            walk(parse(fs.readFileSync(file, 'utf8')), node => {
                if (node.type === 'CallExpression' && node.base.type === 'MemberExpression'
                    && node.base.base.name === 'mod' && node.base.identifier.name === 'localize'
                    && node.arguments[0]?.type === 'StringLiteral') {
                    const key = text(node.arguments[0]);
                    assert(entries.has(key), 'Missing localization key: ' + key + ' in ' + file);
                    references++;
                }
                if (item.name === 'VersusMode_data.lua' && node.type === 'TableKeyString'
                    && ['setting_id', 'tooltip', 'button_text'].includes(node.key.name)
                    && node.value.type === 'StringLiteral') {
                    assert(entries.has(text(node.value)), 'Missing settings label: ' + text(node.value));
                }
            });
        }
    }
}
scan(base);
const L = lauxlib.luaL_newstate(); lualib.luaL_openlibs(L);
if (lauxlib.luaL_dostring(L, to_luastring(checks.join('\n'))) !== lua.LUA_OK) {
    throw Error(to_jsstring(lua.lua_tostring(L, -1)));
}
console.log(`${entries.size} English/Russian entries, ${formatted} Lua format checks, ${references} literal references passed`);
