///////////
// Setup //
///////////

var editor;
var outputContainer;

function setup()
{
    var myTextarea = document.getElementById("code");
    editor = CodeMirror.fromTextArea(myTextarea, {
        lineNumbers: true,
        mode: "lua",
        indentWithTabs: true,
        indentUnit: 4,
        lineWrapping: true,
        inputStyle: "textarea"
    });

    editor.on("blur", () => {
        store_in_storage(encode_script());
    });

    outputContainer = document.getElementById("outputContainer");

    document.onkeyup = function(e)
    {
        if (e.ctrlKey && e.which == 13)
        {
            on_run_clicked();
        }
    };

    try_load_script();
}

function try_load_script()
{
    var params = new URLSearchParams(document.location.search);
    var compressed = params.get("script");
    var url = params.get("url");

    if(compressed != null)
    {
        editor.doc.setValue(decode_script(compressed));
        run();
    }
    else if(url != null)
    {
        load_file(url);
        run();
    }
    else
    {
        var stored = load_from_storage();
        if(stored != null)
        {
            var script = decode_script(stored);
            if (script != "")
                editor.doc.setValue(script);
            else
                load_file("examples/placeholder.lua");
        }
        else
        {
            load_file("examples/placeholder.lua");
        }
    }
}

function decode_script(script)
{
    var decompressed = LZString.decompressFromEncodedURIComponent(script);
    if(decompressed == null)
        decompressed = "-- error while decoding URL";

    return decompressed;
}

function encode_script()
{
    var script = editor.doc.getValue();
    var compressed = LZString.compressToEncodedURIComponent(script);
    return compressed;
}

const storageKey = "lastScript";

function store_in_storage(data)
{
    var storage = window.localStorage;
    if(storage != null)
    {
        storage.setItem(storageKey, data);
    }
}

function load_from_storage()
{
    var storage = window.localStorage;
    if(storage != null)
    {
        return storage.getItem(storageKey);
    }
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

function share()
{
    var compressed = encode_script();
    var url = window.location.origin + window.location.pathname + "?script=" + compressed;

    var text = document.createElement('textarea');
    text.value = url;
    document.body.appendChild(text);
    text.select();
    document.execCommand('copy');
    document.body.removeChild(text);

    alert("URL copied to clipboard:\n" + url);
    gtag('event', 'share');
}

/////////////////////
// Lua integration //
/////////////////////

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

function on_run_clicked()
{
    gtag('event', 'run');
    run();
}

function run()
{
    clear_output();

    var script = editor.doc.getValue();

    var w = new Worker("lua-worker.js");

    w.addEventListener('message', function(e)
    {
        var msg = e.data;
        switch (msg.cmd)
        {
            case 'print':
                write_to_output(msg.data)
                break;
            case 'plot':
                create_chart(msg.data);
                break;
        }
    });

    w.postMessage(script);
}

//////////////////////////
// Chart.js integration //
//////////////////////////

function ticks_callback(value, index, values)
{
    return (value * 100).toFixed(2) + "%" ;
}

function create_chart(params)
{
    var style = getComputedStyle(document.querySelector("body"));

    Chart.defaults.global.defaultFontFamily = style.fontFamily;
    Chart.defaults.global.defaultFontSize = parseInt(style.fontSize);

    var ctx = document.getElementById('chartCanvas');
    var canvasContainer = document.createElement("div");
    var canvas = document.createElement("canvas");

    canvasContainer.appendChild(canvas);
    outputContainer.appendChild(canvasContainer);

    canvasContainer.classList.add("canvasContainer");

    var ticks = {
        callback: ticks_callback,
        beginAtZero: true
    };

    if(!params.percentage)
    {
        delete ticks["callback"];
    }

    var data =
    {
        labels: params.labels,
        datasets: params.datasets
    };

    var myChart = new Chart(canvas, {
        type: 'bar',
        data: data,
        options: {
            scales: {
                yAxes: [{
                    ticks: ticks,
                    stacked: params.stacked
                }],
                xAxes: [{
                    stacked: params.stacked
                }]
            }
        }
    });
}
