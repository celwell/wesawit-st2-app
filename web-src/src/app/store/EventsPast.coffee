Ext.define 'WSI.store.EventsPast',
  extend: 'WSI.store.Events'
  config:
    proxy:
      type: 'ajax'
      extraParams:
        sort: 'backward'