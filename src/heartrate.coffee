noble          = require 'noble'
async          = require 'async'
_              = require 'lodash'
{EventEmitter} = require 'events'
parseHeartRate = require '../parse-heart-rate'
debug          = require('debug')('meshblu-ble-heartrate:heartrate')

HEART_RATE_SERVICE = '180d'
HEART_RATE_CHARACTERISTIC = '2a37'
ON_STATE = 'poweredOn'

class HeartRate extends EventEmitter
  constructor: ->
    @peripheral = null
    @characteristic = null
    process.on 'exit', @disconnect

  start: =>
    noble.on 'stateChange',  (state) =>
      debug 'state change', state
      return @startScanning() if state == ON_STATE
      @stopScanning()

    tasks = [
      @connectToHeartRateMonitor,
      @subscribeToHeartRate
    ]
    async.waterfall tasks, (error, heartRate) =>
      return console.error 'error', error if error?

      heartRate.on 'read', (data) =>
        rate = parseHeartRate data
        debug 'heartRate', rate
        @emit 'heartRate', rate

  disconnect: =>
    debug 'disconnecting'
    noble.stopScanning();
    @peripheral.disconnect() if @peripheral?
    @peripheral = null
    @characteristic.notify false if @characteristic?
    @characteristic = null

  onDisconnect: =>
    @peripheral.on 'disconnect', (msg) =>
      debug 'disconnected', msg
      @peripheral = null;

  connectToHeartRateMonitor: (callback=->) =>
    debug 'connectToHeartRateMonitor'
    noble.on 'discover', (peripheral) =>
      return debug 'already found one' if @peripheral?
      debug 'discovered', peripheral.uuid

      peripheral.connect (error) =>
        debug 'connected to peripheral', error: error
        return callback error if error?
        @peripheral = peripheral
        @stopScanning()
        callback null, @peripheral

  startScanning: =>
    debug 'starting scanning'
    noble.startScanning [HEART_RATE_SERVICE], false

  stopScanning: =>
    debug 'stopping scanning'
    noble.stopScanning()

  subscribeToHeartRate: (peripheral, callback=->) =>
    debug 'subscribeToHeartRate'
    peripheral.discoverSomeServicesAndCharacteristics [HEART_RATE_SERVICE], [HEART_RATE_CHARACTERISTIC], (error, services, characteristics) =>
      return callback error if error?

      @characteristic = _.first characteristics
      return callback 'could not find heart rate characteristic' unless @characteristic?

      @characteristic.notify true, (error) =>
        callback error, @characteristic

module.exports = HeartRate
