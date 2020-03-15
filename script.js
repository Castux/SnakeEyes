var myTextarea = document.getElementById("code");
var editor = CodeMirror.fromTextArea(myTextarea, {
    lineNumbers: true,
    mode: "lua"
});

var output = document.getElementById("output");

function run()
{
    var text = document.createTextNode(editor.doc.getValue());
    output.innerHTML = "";
    output.appendChild(text);
}
