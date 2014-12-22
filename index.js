'use strict';
var util         = require('util');
var EventEmitter = require('events').EventEmitter;
var noble        = require('noble');
var async        = require('async');
var _            = require('lodash');
var debug        = require('debug')('meshblu-tickr:index');
var parseHeartRate = require('./parse-heart-rate');

var MESSAGE_SCHEMA = {
  type: 'object',
  properties: {}
};

var OPTIONS_SCHEMA = {
  type: 'object',
  properties: {}
};

var HEART_RATE_SERVICE = '180d'
var HEART_RATE_CHARACTERISTIC = '2a37';

function Plugin(){
  var self = this;
  self.options = {};
  self.messageSchema = MESSAGE_SCHEMA;
  self.optionsSchema = OPTIONS_SCHEMA;
  self.foundOne = false;

  return _.bindAll(this);
}
util.inherits(Plugin, EventEmitter);

Plugin.prototype.onMessage = function(message){
  var payload = message.payload;
  this.emit('message', {devices: ['*'], topic: 'echo', payload: payload});
};

Plugin.prototype.onConfig = function(device){
  this.setOptions(device.options||{});
};

Plugin.prototype.setOptions = function(options){
  debug('setOptions');
  var self = this;
  self.options = options;

  async.waterfall([
    self.connectToHeartRateMonitor,
    self.subscribeToHeartRate
  ], function(error, heartRate){
    if(error){
      console.error('error: ', error);
      return;
    }

    heartRate.on('read', function(data){
      var rate = parseHeartRate(data);
      debug('heartRate', rate);
      self.emit('message', {heartRate: rate, devices: '*'});
    });
  });
};

Plugin.prototype.connectToHeartRateMonitor = function(callback){
  debug('connectToHeartRateMonitor');
  var self = this;
  noble.on('discover', function(peripheral){
    if(self.foundOne){return;}
    self.foundOne = true;
    debug('discovered', peripheral.uuid);

    peripheral.connect(function(error){
      callback(error, peripheral);
    });
  });
  noble.startScanning([HEART_RATE_SERVICE]);
};

Plugin.prototype.subscribeToHeartRate = function(peripheral, callback){
  debug('subscribeToHeartRate');
  peripheral.discoverSomeServicesAndCharacteristics([HEART_RATE_SERVICE], [HEART_RATE_CHARACTERISTIC], function(error, services, characteristics){
    if(error){return callback(error);}

    var characteristic = _.first(characteristics);
    if(!characteristic){return callback('could not find heart rate characteristic');}

    characteristic.notify(true, function(error){
      callback(error, characteristic);
    });
  });
};

module.exports = {
  messageSchema: MESSAGE_SCHEMA,
  optionsSchema: OPTIONS_SCHEMA,
  Plugin: Plugin
};
