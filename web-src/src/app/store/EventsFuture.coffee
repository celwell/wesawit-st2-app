Ext.define 'WSI.store.EventsFuture',
  extend: 'WSI.store.Events'
  config:
    proxy:
      type: 'ajax'
      extraParams:
        sort: 'forward'