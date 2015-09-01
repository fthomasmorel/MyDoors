var apn = require('apn');
var options = {cert:"../Cert/PushMyDoorsProdCert.pem",key:"../Cert/PushMyDoorsProdKey.pem",passphrase:"Escargot35!",production:true};

var PortailManager = require('./PortailManager.js');
var portailManager = new PortailManager();
var state = portailManager.isOpen();

function prepareNotificationWithText(text){
var readline = require('readline');
var fs = require('fs');
var rl = readline.createInterface({
      input : fs.createReadStream('uuid'),
      output: process.stdout,
      terminal: false
    })

    rl.on('line',function(line){
        sendNotification(line,text);
    })
}

function sendNotification(token,text){
console.log("send push")
  var conn  = new apn.Connection(options)
  var dev   = new apn.Device(token)
  var note  = new apn.Notification()
  note.alert = text;
  conn.pushNotification(note, dev)
}


function main(){
  if (state != portailManager.isOpen()){
      var text = "🔒Le portail s'est fermé";
      if (portailManager.isOpen()) { text = "🔓Le portail s'est ouvert" }
      prepareNotificationWithText(text);
      state = portailManager.isOpen();
  }
  setTimeout(function() {
    console.log("recursive call")
    main()
  }, 15000);
}

main()
