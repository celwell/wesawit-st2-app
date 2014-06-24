Ext.define 'WSI.model.Who',
  extend: 'Ext.data.Model'
  config:
    fields: [
      { name: 'id', type: 'string' }
      { name: 'username', type: 'string' }
      {
        name: 'medias'
        convert: (v, rec) ->
          for i in v
            i.pid ?= null
            i.vid ?= null
            i.xid ?= null
            i.file_ext ?= null
            i.status ?= 'loaded'
            i.webHeight ?= null
            i.webWidth ?= null
            arr = i.timestampTaken.split /[- :\.]/ # needs to be converted to a Date
            i.timestampTaken = new Date()
            i.timestampTaken.setUTCFullYear parseInt(arr[0])
            i.timestampTaken.setUTCMonth parseInt(arr[1]) - 1
            i.timestampTaken.setUTCDate parseInt(arr[2])
            i.timestampTaken.setUTCHours parseInt(arr[3])
            i.timestampTaken.setUTCMinutes parseInt(arr[4])
            i.timestampTaken.setUTCSeconds parseInt(arr[5])
          v
      }
    ]