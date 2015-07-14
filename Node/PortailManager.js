var rpio = require('rpio');
var constants = require('./Constants.js');

function PortailManager() {
  rpio.setMode('physical');
  rpio.setOutput(constants.REMOTE_PIN_PORTAIL);
  rpio.setInput(constants.DATA_PIN_PORTAIL);
  rpio.write(constants.REMOTE_PIN_PORTAIL, rpio.LOW);
}


PortailManager.prototype.isOpen = function() {
  return rpio.read(constants.DATA_PIN_PORTAIL) == 0
}

PortailManager.prototype.actionOnPortail = function() {
  rpio.write(constants.REMOTE_PIN_PORTAIL, rpio.HIGH);
  rpio.write(constants.REMOTE_PIN_PORTAIL, rpio.LOW);
}

module.exports = PortailManager;