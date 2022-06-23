const GOOD_AGE = 10; //seconds

var ws = null;

function connected(sock) {
  ws = sock;
}

connect();

function connect() {
  var uri      = window.document.location.origin + "/";
  uri = uri.replace(/^http/, 'ws');
  var ws       = new ReconnectingWebSocket(uri);
  var last_message = Date.now();
  ws.onmessage = function(msg) {
    last_message = Date.now();
    var data = JSON.parse(msg.data);
    if (data.type === 'meters') {
      update(data.data);
      $('#message').hide();
    } else if (data.type === 'signal') {
      update_signals(data.data);
      $('#message').hide();
    } else if (data.type === 'channel') {
      update_channel(data.data);
    } else if (data.type === 'connection_lost') {
      $('#message').html('X32 connection lost').show();
    }
  };
  setInterval(function(){
    if (Date.now() - last_message > 1000) {
      $('#message').html('Server connection lost').show();
    }
  }, 3000);
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
    $(".channels [data-channel="+(c+1)+"] .meter").css('width', (100*level)+'px');
  });
};

function update_signals(data) {
  $(data).each(function(c) {
    var signal_age = this;
    $(".signals [data-channel="+(c+1)+"] .age").text(Math.round(signal_age));
    $(".signals [data-channel="+(c+1)+"]").toggle(signal_age < GOOD_AGE);
  });
};

function update_channel(data) {
  $("[data-channel="+data.idx+"] .name").html('&nbsp;'+data.name);
  $("[data-channel="+data.idx+"]").toggleClass('mute', data.mute);
}

$('#message').hide();
