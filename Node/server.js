var io = require('socket.io')();
//var rpio = new Rpio();

console.log("Starting Server...");

io.on('connection', function(socket){
  console.log("Connected");
  socket.on('portail-action', function(json) {
    console.log(json);
  })
  socket.on('portail-action', function(json, callback){
    console.log('Socket (server-side): received message:', json);
    var responseData = { string1:'I like ', string2: 'bananas ', string3:' dude!' };
    callback(responseData);
  });
});

io.listen(8080);
