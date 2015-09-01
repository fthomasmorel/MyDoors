var readline = require('readline');
var fs = require('fs');
var rl = readline.createInterface({
      input : fs.createReadStream('uuid'),
      output: process.stdout,
      terminal: false
})
var apn = require('apn');
var options = {cert:"PushMyDoorsProdCert.pem",key:"PushMyDoorsProdKey.pem",passphrase:"Escargot35!",production:true};
var conn  = new apn.Connection(options)

var PortailManager = require('./PortailManager.js');
var portailManager = new PortailManager();

main()

function main(){
  console.log("main called")
  var state = !portailManager.isOpen();
  if (state != portailManager.isOpen()){
    console.log("notif")
      var text = "🔒Le portail s'est fermé";
      if (portailManager.isOpen()) { text = "🔓Le portail s'est ouvert" }
      prepareNotificationWithText(text);
  }
  setTimeout(function() {
    console.log("recursive call")
    main()
  }, 5000);
}

function prepareNotificationWithText(text){
    rl.on('line',function(line){
        sendNotification(line,text);
        sendNotification(line,text+"2");
    })
}

function sendNotification(token,text){
  var dev   = new apn.Device(token)
  var note  = new apn.Notification()
  note.alert = text;
  conn.pushNotification(note, dev)
}
