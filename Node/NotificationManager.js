var readline = require('readline');
var fs = require('fs');
var rl = readline.createInterface({
      input : fs.createReadStream('uuid'),
      output: process.stdout,
      terminal: false
})

var PortailManager = require('./PortailManager.js');
var portailManager = new PortailManager();
var state = portailManager.isOpen();

while(true){
  if (portailManager.isOpen() != state){
    state = portailManager.isOpen();
    var text = "Le portail s'est fermé";
    if (portailManager.isOpen()) { text = "Le portail s'est ouvert" }
    rl.on('line',function(line){
        sendNotification(line,text);
    })
  }
}

function sendNotification(line,text){
  console.log(line + " " + text)
}
