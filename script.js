const luaconf  = fengari.luaconf;
const lua      = fengari.lua;
const lauxlib  = fengari.lauxlib;
const lualib   = fengari.lualib;
const interop  = fengari.interop;

var editor;
var outputContainer;

function setup()
{
    var myTextarea = document.getElementById("code");
    editor = CodeMirror.fromTextArea(myTextarea, {
        lineNumbers: true,
        mode: "lua",
        indentWithTabs: true,
        indentUnit: 4
    });

    outputContainer = document.getElementById("outputContainer");

    check_url();
}

function clear_output()
{
    outputContainer.innerHTML = "";
}

function write_to_output(s)
{
    if(outputContainer.lastChild == null ||
        !outputContainer.lastChild.classList.contains("textOutput"))
    {
        var pre = document.createElement("pre");
        pre.classList.add("textOutput");
        outputContainer.appendChild(pre);
    }

    var text = document.createTextNode(s);
    outputContainer.lastChild.appendChild(text);
}

function open_url()
{
    var url = prompt("URL of the file to load", "");
    load_file(url);
    window.history.pushState(null, "", "?url=" + url);
}

const report = function(L, status) {
    if (status !== lua.LUA_OK) {
        write_to_output(lua.lua_tojsstring(L, -1) + "\n");
        lua.lua_pop(L, 1);
    }
    return status;
};

const msghandler = function(L) {
    let msg = lua.lua_tostring(L, 1);
    if (msg === null) {  /* is error object not a string? */
        if (lauxlib.luaL_callmeta(L, 1, fengari.to_luastring("__tostring")) &&  /* does it have a metamethod */
          lua.lua_type(L, -1) == LUA_TSTRING)  /* that produces a string? */
            return 1;  /* that is the message */
        else
            msg = lua.lua_pushstring(L, fengari.to_luastring(`(error object is a ${fengari.to_jsstring(lauxlib.luaL_typename(L, 1))} value)`));
    }
    lauxlib.luaL_traceback(L, L, msg, 1);  /* append a standard traceback */
    return 1;  /* return the traceback */
};

const docall = function(L, narg, nres) {
    let base = lua.lua_gettop(L) - narg;
    lua.lua_pushcfunction(L, msghandler);
    lua.lua_insert(L, base);
    let status = lua.lua_pcall(L, narg, nres, base);
    lua.lua_remove(L, base);
    return status;
};

function run()
{
    clear_output();

    var script = editor.doc.getValue();
    encode_script(script);

    const L = lauxlib.luaL_newstate();
    lualib.luaL_openlibs(L);
    lauxlib.luaL_requiref(L, "js", interop.luaopen_js, 0);
    lua.lua_atnativeerror(L, (x) => {
        console.log("Native error:");
        console.log(x);
    });

    var status = lauxlib.luaL_loadfile(L, fengari.to_luastring("dice-web.lua"))
        || docall(L, 0, 0);
    report(L, status);
    
    if(status != lua.LUA_OK)
        return;

    var buffer = fengari.to_luastring(script);
    var status = lauxlib.luaL_loadbuffer(L, buffer, buffer.length, "SuperDice script")
        || docall(L, 0, 0);
    report(L, status);

}

function check_url()
{
    var params = new URLSearchParams(document.location.search);
    var script = params.get("script");
    var url = params.get("url");

    if(script != null)
        read_script(script);
    else if(url != null)
        load_file(url);
}

function read_script(script)
{
    var decompressed = LZString.decompressFromEncodedURIComponent(script);
    if(decompressed == null)
        decompressed = "-- error while decoding URL";

    editor.doc.setValue(decompressed);
}

function encode_script(s)
{
    var compressed = LZString.compressToEncodedURIComponent(s);
    window.history.pushState(null, "", "?script=" + compressed);
}

function load_file(url)
{
    if(url == null || url == "")
        return;

    var xhttp = new XMLHttpRequest();
    xhttp.onload = function() {
        editor.doc.setValue(xhttp.responseText);
    };
    xhttp.onerror = function() {
        editor.doc.setValue("-- error occured while loading " + url);
    }
    xhttp.open("GET", url, true);
    xhttp.send();
}

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

function plot(labels, datasets)
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

    create_chart({
        labels: labels,
        datasets: datasets
    });
}

function create_chart(data)
{
    var ctx = document.getElementById('chartCanvas');
    var canvasContainer = document.createElement("div");
    var canvas = document.createElement("canvas");

    canvasContainer.appendChild(canvas);
    outputContainer.appendChild(canvasContainer);

    canvasContainer.classList.add("canvasContainer");

    var myChart = new Chart(canvas, {
        type: 'bar',
        data: data,
        options: {
            scales: {
                yAxes: [{
                    ticks: {
                        callback: function(value, index, values) {
                            return (value * 100).toFixed(2) + "%" ;
                        },
                        beginAtZero: true
                    }
                }]
            }
        }
    });
}
