var io = require('socket.io')();
var PortailManager = require('./PortailManager.js');
var portailManager = new PortailManager();
var constants = require('./constants');
//var rpio = new Rpio();

var token = "";

console.log("Starting Server...");

io.on('connection', function(socket){
  console.log("Connected");

  socket.on('auth', function(json, callback) {
    console.log(json);
    if(json.auth_key == constants.AUTH_KEY){
        token = generateToken();
        console.log("token = " + token);
        callback({ status:200, token: token});
    }else{
        callback({ status:400, token: '', error: constants.WRONG_AUTH_MESSAGE});
    }
  })

  socket.on('portail-state', function(json, callback){
    if(json.token == token){
      callback({ status:200, isOpen: portailManager.isOpen()});
    }else{
      callback({ status:400, token: '', error: constants.WRONG_AUTH_MESSAGE});
    }
  })

  socket.on('portail-action', function(json, callback){
    if(json.token == token){
      console.log('Socket (server-side): received message:', json);
      var responseData = { string1:'I like ', string2: 'bananas ', string3:' dude!' };
      callback(responseData);
    }else{
      callback({ status:400, token: '', error: constants.WRONG_AUTH_MESSAGE});
    }
  });
});

io.listen(8080);

function generateToken(){
  var current_date = (new Date()).valueOf().toString();
  var random = Math.random().toString();
  return require('crypto').createHash('sha1').update(current_date + random).digest('hex');
}
