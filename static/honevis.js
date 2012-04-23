var h;
  
function log_it(stuff) {
  $("#log").append(stuff+'<br/>');
}
 
$(function() {
  h = new Hippie( document.location.host, 'ping', function() {
      log_it("connected");
  },
  function() {
      log_it("disconnected");
  },
  function(e) {
      if (! e.Type) return;

      log_it("got message: type = "+e.Type+", PID = "+e.PID+" Command = " +e.Args);
  } );

  setInterval(function () {
    var log = document.getElementById('log');
    log.scrollTop = log.scrollHeight;
  }, 500);

});
