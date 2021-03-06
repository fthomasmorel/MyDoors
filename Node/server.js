var io = require('socket.io')();
var PortailManager = require('./PortailManager.js');
var portailManager = new PortailManager();
var constants = require('./Constants.js');
var fs = require('fs');
var file = "./uuid";
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

  socket.on('apns-token', function(json, callback) {
    console.log(json);
    if(json.apns_newToken && json.token == token){
        updateToken(json.apns_oldToken, json.apns_newToken, function(dict){
          callback(dict);
        })
    }else{
        callback({ status:400, error: constants.WRONG_AUTH_MESSAGE});
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
      var isOpen = portailManager.isOpen()
      portailManager.actionOnPortail();
      if(isOpen){
        portailManager.startWatchDog(function(){
          callback({ status:200, isOpen: false});
        })
      }else{
        callback({ status:200, isOpen: true});
      }
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

function updateToken(oldToken, newToken, handler){
  return fs.readFile(file, 'utf8', function (err,data) {
  if (err) {
    handler({ status:400, error: constants.ERROR_APNS_TOKEN_MESSAGE})
  }

  var result = '';
  if(oldToken && data.indexOf(oldToken) > -1) {
    result = data.replace(oldToken, newToken);
  }else{
    result = data + newToken+'\n';
  }
  return fs.writeFile(file, result, 'utf8', function (err) {
      if (err) handler({ status:400, error: constants.ERROR_APNS_TOKEN_MESSAGE})
      else handler({ status:200})
  });
  });
}
