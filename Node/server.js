var io = require('socket.io')();
//var rpio = new Rpio();

io.on('connection', function(socket){
  console.log("Connected");
  socket.on('portail-action', function(json) {
    console.log(json);
  })
});

io.listen(8080);
