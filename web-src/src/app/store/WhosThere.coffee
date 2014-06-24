Ext.define 'WSI.store.WhosThere',
  extend: 'Ext.data.Store'
  xtype: 'whostherestore'
  requires: [
    'WSI.model.Who'
  ]
  config:
    model: 'WSI.model.Who'
    pageSize: 100
    autoLoad: false
    proxy:
      type: 'ajax'
      url : 'http://wesawit.com/event/who'
      extraParams:
        'api_version': util.API_VERSION
        'uid': window.localStorage.getItem 'uid'
        'eid': '0'
      reader:
        type: 'json'
        rootProperty: 'data'
    listeners:
      beforeload: (store) ->
        store.getProxy().config.extraParams.uid = window.localStorage.getItem 'uid' # update uid according to localStorage
        true
      load: (s, records, successful, operation) ->
        if operation.getResponse()?.timedout? and operation.getResponse().timedout is true
          navigator.notification.alert 'Your internet connection seems to be going too slow.', (()->return), 'Hmm...'
        true