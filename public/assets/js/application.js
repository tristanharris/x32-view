var ws = null;

function connected(sock) {
  ws = sock;
}

connect();

function connect() {
  var uri      = window.document.location.origin + "/";
  var ws       = new WebSocket(uri);
  ws.onmessage = function(msg) {
    var data = JSON.parse(msg.data);
    update(data);
  };
  ws.onopen = function(data) {
    connected(ws);
    ws.onclose = function(data) {
    };
  };
  return ws;
};

function update(data) {
  console.log(data);
  $(data).each(function(c) {
    var level = this;
    $("[data-channel="+(c+1)+"]").css('width', (100*level)+'px');
  });
};
