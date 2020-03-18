const luaconf  = fengari.luaconf;
const lua      = fengari.lua;
const lauxlib  = fengari.lauxlib;
const lualib   = fengari.lualib;
const interop  = fengari.interop;

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

    check_url();
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

function run()
{
    clear_output();

    var script = editor.doc.getValue();

    const L = lauxlib.luaL_newstate();
    lualib.luaL_openlibs(L);
    lauxlib.luaL_requiref(L, "js", interop.luaopen_js, 0);

    lauxlib.luaL_loadfile(L, fengari.to_luastring("dice-web.lua"));
    lua.lua_call(L, 0, 0);

    var status = lauxlib.luaL_loadstring(L, fengari.to_luastring(script));
    if(status == lua.LUA_OK)
    {
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
    create_chart();
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
    var xhttp = new XMLHttpRequest();
    xhttp.onload = function() {
        editor.doc.setValue(xhttp.responseText);
    };
    xhttp.open("GET", url, true);
    xhttp.send();
}

function create_chart()
{
    var ctx = document.getElementById('chartCanvas');
    var myChart = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: ['Red', 'Blue', 'Yellow', 'Green', 'Purple', 'Orange'],
            datasets: [{
                label: '# of Votes',
                data: [0.12, 0.19, 0.3, 0.5, 0.2, 0.3],
                borderWidth: 1
            }]
        },
        options: {
            scales: {
                yAxes: [{
                    ticks: {
                        beginAtZero: true
                    }
                }]
            }
        }
    });
}
