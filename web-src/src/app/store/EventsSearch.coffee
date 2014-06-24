Ext.define 'WSI.store.EventsSearch',
  extend: 'WSI.store.Events'
  config:
    pageSize: 15
    autoLoad: false
    proxy:
      type: 'ajax'
      extraParams:
        sort: 'custom_range'
        dateTimeStart: '1950-01-01T00:00:00Z'
        dateTimeEnd: '2025-12-31T23:59:59Z'
        searchTerm: ''