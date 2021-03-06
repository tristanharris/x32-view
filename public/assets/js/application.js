var ws = null;

function connected(sock) {
  ws = sock;
}

connect();

function connect() {
  var uri      = window.document.location.origin + "/";
  uri = uri.replace(/^http/, 'ws');
  var ws       = new WebSocket(uri);
  ws.onmessage = function(msg) {
    var data = JSON.parse(msg.data);
    if (data.type === 'meters') {
      update(data.data);
    } else if (data.type === 'channel') {
      update_channel(data.data);
    }
  };
  ws.onopen = function(data) {
    connected(ws);
    ws.onclose = function(data) {
    };
  };
  return ws;
};

function update(data) {
  $(data).each(function(c) {
    var level = this;
    $("[data-channel="+(c+1)+"] .meter").css('width', (100*level)+'px');
  });
};

function update_channel(data) {
  $("[data-channel="+data.idx+"] .name").html('&nbsp;'+data.name);
  $("[data-channel="+data.idx+"]").toggleClass('mute', data.mute);
}
