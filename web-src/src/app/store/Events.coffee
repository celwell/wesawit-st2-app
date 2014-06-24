Ext.define 'WSI.store.Events',
  extend: 'Ext.data.Store'
  requires: [
    'WSI.model.Event'
  ]
  config:
    model: 'WSI.model.Event'
    pageSize: 20
    autoLoad: true
    proxy:
      type: 'ajax'
      url : 'http://wesawit.com/event/get_events_mobile'
      extraParams:
        'api_version': util.API_VERSION
        'token': window.localStorage.getItem 'wsitoken'
        'uid': window.localStorage.getItem 'uid'
        category: 'all'
        country: 'world'
      reader:
        type: 'json'
        rootProperty: 'events'
    listeners:
      beforeload: (store) ->
        store.lastTimeLoadCalled = new Date()
        store.getProxy().config.extraParams.token = window.localStorage.getItem 'wsitoken'
        store.getProxy().config.extraParams.uid = window.localStorage.getItem 'uid'
        store.getProxy().config.extraParams.locationLat = window.localStorage.getItem 'locationLat'
        store.getProxy().config.extraParams.locationLng = window.localStorage.getItem 'locationLng'
        store.getProxy().config.extraParams.locationTimestamp = window.localStorage.getItem 'locationTimestamp'
        true
      load: (store, records, successful, operation) ->
        if operation.getResponse()?.timedout? and operation.getResponse().timedout is true
          navigator.notification.alert 'Your internet connection seems to be going too slow.', (()->return), 'Hmm...'
        true