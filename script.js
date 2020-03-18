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

    var status = lauxlib.luaL_loadstring(L, fengari.to_luastring(script)) ||
        lua.lua_pcall(L, 0, 0, 0);

    if(status != lua.LUA_OK)
    {
        write_to_output(fengari.to_jsstring(lua.lua_tostring(L, -1)) + "\n");
    }

    encode_script(script);
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

function to_js_array(luatable)
{
    var arr = [];
    var i = 1;
    while(luatable.has(i))
    {
        arr.push(luatable.get(i));
        i++;
    }
    return arr;
}

function plot(labels, datasets)
{
    labels = to_js_array(labels);
    datasets = to_js_array(datasets);

    for(var i = 0; i < datasets.length ; i++)
    {
        datasets[i] = {
            data: to_js_array(datasets[i]),
            label: datasets[i].get("label"),
            lineTension: 0,
            type: datasets[i].get("type")
        };
    }

    create_chart({
        labels: labels,
        datasets: datasets
    });
}

function create_chart(data)
{
    console.log(data);

    var ctx = document.getElementById('chartCanvas');
    var myChart = new Chart(ctx, {
        type: 'line',
        data: data,
        options: {
            scales: {
                yAxes: [{
                    ticks: {
                        callback: function(value, index, values) {
                            return (value * 100).toFixed(2) + "%" ;
                        }
                    }
                }]
            }
        }
    });
}
