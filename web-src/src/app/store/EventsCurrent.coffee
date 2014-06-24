Ext.define 'WSI.store.EventsCurrent',
  extend: 'WSI.store.Events'
  config:
    proxy:
      type: 'ajax'
      extraParams:
        sort: 'today'