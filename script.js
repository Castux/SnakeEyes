const luaconf  = fengari.luaconf;
const lua      = fengari.lua;
const lauxlib  = fengari.lauxlib;
const lualib   = fengari.lualib;


var myTextarea = document.getElementById("code");
var editor = CodeMirror.fromTextArea(myTextarea, {
    lineNumbers: true,
    mode: "lua"
});

var output = document.getElementById("output");

function run()
{
    var script = editor.doc.getValue();

    const L = lauxlib.luaL_newstate();
    lualib.luaL_openlibs(L);
    var status = lauxlib.luaL_loadstring(L, fengari.to_luastring(script));

    var result = "";

    if(status == lua.LUA_OK)
    {
        lua.lua_call(L, 0, 0);
        result = "Did it!";
    }
    else
    {
        result = "Error occured";
    }

    var text = document.createTextNode(result);
    output.innerHTML = "";
    output.appendChild(text);
}
