Ext.define 'WSI.store.EventsMap',
  extend: 'WSI.store.Events'
  config:
    pageSize: 75
    autoLoad: false
    proxy:
      type: 'ajax'
      extraParams:
        sort: 'top'
        dateTimeStart: null
        dateTimeEnd: null
    listeners:
      scope: this
      beforeload: (store) ->
        store.getProxy().config.extraParams.token = window.localStorage.getItem 'wsitoken'
        store.getProxy().config.extraParams.uid = window.localStorage.getItem 'uid'
        store.getProxy().config.extraParams.locationLat = window.localStorage.getItem 'locationLat'
        store.getProxy().config.extraParams.locationLng = window.localStorage.getItem 'locationLng'
        store.getProxy().config.extraParams.locationTimestamp = window.localStorage.getItem 'locationTimestamp'
        p = new Date()
        p.setHours( p.getHours() - 24 )
        store.getProxy().config.extraParams.dateTimeStart = p
        f = new Date()
        f.setHours( f.getHours() + 24 )
        store.getProxy().config.extraParams.dateTimeEnd = f
        true