'use strict';
util           = require 'util'
{EventEmitter} = require 'events'
HeartRate      = require './src/heartrate.coffee'
debug          = require('debug')('meshblu-ble-heartrate')

MESSAGE_SCHEMA =
  type: 'object'
  properties: {}

OPTIONS_SCHEMA =
  type: 'object'
  properties: {}

class Plugin extends EventEmitter
  constructor: ->
    @options = {}
    @messageSchema = MESSAGE_SCHEMA
    @optionsSchema = OPTIONS_SCHEMA
    @start()

  onMessage: (message) =>
    debug 'onMessage', message

  onConfig: (device) =>
    @setOptions device.options

  setOptions: (options={}) =>
    debug 'setOptions', options
    @options = options

  start: =>
    debug 'starting...'
    @heartRate = new HeartRate
    @heartRate.on 'heartRate', (rate) =>
      debug 'emitting message'
      @emit 'message', devices: ['*'], topic: 'heartRate', payload: heartRate: rate
    @heartRate.start()

module.exports =
  messageSchema: MESSAGE_SCHEMA
  optionsSchema: OPTIONS_SCHEMA
  Plugin: Plugin
