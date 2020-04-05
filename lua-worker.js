importScripts("fengari-webworker.js")

const luaconf  = fengari.luaconf;
const lua      = fengari.lua;
const lauxlib  = fengari.lauxlib;
const lualib   = fengari.lualib;
const interop  = fengari.interop;

self.addEventListener('message', function(e)
{
    var script = e.data;
    run(script);
});

function write_to_output(s)
{
    postMessage({'cmd': 'print', 'data': s});
}

/////////////////////
// Lua integration //
/////////////////////

const report = function(L, status)
{
    if (status !== lua.LUA_OK)
    {
        write_to_output(lua.lua_tojsstring(L, -1) + "\n");
        lua.lua_pop(L, 1);
    }
    return status;
};

const msg_handler = function(L)
{
    let msg = lua.lua_tostring(L, 1);
    if (msg === null)
    {
        if (lauxlib.luaL_callmeta(L, 1, fengari.to_luastring("__tostring")) && lua.lua_type(L, -1) == LUA_TSTRING)
            return 1;
        else
            msg = lua.lua_pushstring(L, fengari.to_luastring(`(error object is a ${fengari.to_jsstring(lauxlib.luaL_typename(L, 1))} value)`));
    }
    lauxlib.luaL_traceback(L, L, msg, 1);
    return 1;
};

const do_call = function(L, narg, nres)
{
    let base = lua.lua_gettop(L) - narg;
    lua.lua_pushcfunction(L, msg_handler);
    lua.lua_insert(L, base);
    let status = lua.lua_pcall(L, narg, nres, base);
    lua.lua_remove(L, base);
    return status;
};

function run(script)
{
    const L = lauxlib.luaL_newstate();
    lualib.luaL_openlibs(L);
    lauxlib.luaL_requiref(L, "js", interop.luaopen_js, 0);
    lua.lua_atnativeerror(L, (x) => {
        console.log("Native error:");
        console.log(x);
    });

    var status = lauxlib.luaL_loadfile(L, fengari.to_luastring("dice-web.lua"))
        || do_call(L, 0, 0);
    report(L, status);

    if(status != lua.LUA_OK)
        return;

    var buffer = fengari.to_luastring(script);
    var status = lauxlib.luaL_loadbuffer(L, buffer, buffer.length, "user script")
        || do_call(L, 0, 0);
    report(L, status);
}

//////////////////////////
// Chart.js integration //
//////////////////////////

function to_js_array(luatable, size)
{
    var arr = [];
    if(size != null)
    {
        for(var i = 1; i <= size ; i++)
            arr[i - 1] = luatable.get(i);
    }
    else
    {
        var i = 1;
        while(luatable.has(i))
        {
            arr[i - 1] = luatable.get(i);
            i++;
        }
    }

    return arr;
}

const colors = [
    "rgba(52, 152, 219, 0.8)",
    "rgba(155, 89, 182, 0.8)",
    "rgba(233, 30, 99, 0.8)",
    "rgba(241, 196, 15, 0.8)",
    "rgba(230, 126, 34, 0.8)",
    "rgba(231, 76, 60, 0.8)",
    "rgba(149, 165, 166, 0.8)",
    "rgba(96, 125, 139, 0.8)",
    "rgba(26, 188, 156, 0.8)",
    "rgba(46, 204, 113, 0.8)"
];

function plot(labels, datasets, stacked, percentage)
{
    labels = to_js_array(labels);
    datasets = to_js_array(datasets);

    for(var i = 0; i < datasets.length ; i++)
    {
        datasets[i] = {
            data: to_js_array(datasets[i], labels.length),
            label: datasets[i].get("label"),
            lineTension: 0,
            type: datasets[i].get("type"),
            fill: datasets[i].get("type") == "line" ? false : null,
            backgroundColor: colors[i % colors.length],
            borderColor: colors[i % colors.length]
        };
    }

    postMessage({'cmd': 'plot', 'data': {
        'labels': labels,
        'datasets': datasets,
        'stacked': stacked,
        'percentage': percentage
    }});
}
