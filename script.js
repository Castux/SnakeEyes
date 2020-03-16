const luaconf  = fengari.luaconf;
const lua      = fengari.lua;
const lauxlib  = fengari.lauxlib;
const lualib   = fengari.lualib;

var editor;
var output;

function setup()
{
    var myTextarea = document.getElementById("code");
    editor = CodeMirror.fromTextArea(myTextarea, {
        lineNumbers: true,
        mode: "lua"
    });

    output = document.getElementById("output");

    read_script();
}

function clear_output()
{
    output.innerHTML = "";
}

function write_to_output(s)
{
    var text = document.createTextNode(s);
    output.appendChild(text);
}

const luaB_print = function(L) {
    let n = lua.lua_gettop(L); /* number of arguments */
    lua.lua_getglobal(L, fengari.to_luastring("tostring", true));
    for (let i = 1; i <= n; i++) {
        lua.lua_pushvalue(L, -1);  /* function to be called */
        lua.lua_pushvalue(L, i);  /* value to print */
        lua.lua_call(L, 1, 1);
        let s = lua.lua_tolstring(L, -1);
        if (s === null)
            return lauxlib.luaL_error(L, fengari.to_luastring("'tostring' must return a string to 'print'"));
        if (i > 1) write_to_output("\t");
        write_to_output(fengari.to_jsstring(s));
        lua.lua_pop(L, 1);
    }
    write_to_output("\n");
    return 0;
};

function run()
{
    clear_output();

    var script = editor.doc.getValue();

    const L = lauxlib.luaL_newstate();
    lualib.luaL_openlibs(L);

    var status = lauxlib.luaL_loadstring(L, fengari.to_luastring(script));
    var result = "";

    if(status == lua.LUA_OK)
    {
        lauxlib.luaL_loadfile(L, fengari.to_luastring("dice.lua"));
        lua.lua_call(L, 0, 1);
        lua.lua_setupvalue(L, -2, 1);

        lua.lua_pushjsfunction(L, luaB_print);
        lua.lua_setglobal(L, fengari.to_luastring("print"));

        var call_result = lua.lua_pcall(L, 0, 0, 0);
        if (call_result != lua.LUA_OK)
        {
            write_to_output(fengari.to_jsstring(lua.lua_tostring(L, -1)) + "\n");
        }
    }
    else
    {
        write_to_output(fengari.to_jsstring(lua.lua_tostring(L, -1)) + "\n");
    }

    encode_script(script);
}

function read_script()
{
    var params = new URLSearchParams(document.location.search);
    var script = params.get("script");

    if(script != null)
    {
        var decompressed = LZString.decompressFromEncodedURIComponent(script);
        editor.doc.setValue(decompressed);
    }
}

function encode_script(s)
{
    var compressed = LZString.compressToEncodedURIComponent(s);
    window.history.pushState(null, "", "?script=" + compressed);
}
