Ext.define 'WSI.model.Media',
  extend: 'Ext.data.Model'
  config:
    #useCache: no
    fields: [
      { name: 'id', type: 'string' }
      { name: 'pid', type: 'string' } # photos will have this, it is duplicate of id
      { name: 'vid', type: 'string' } # videos will have this, it is duplicate of id
      { name: 'xid', type: 'string' } # external media (not currently being used at all)
      { name: 'event_id', type: 'string' }
      { name: 'aeid', type: 'string' } # 'associated event id', duplicate of event_id
      { name: 'author', type: 'string' }
      { name: 'authorUid', type: 'string' }
      { name: 'viewCount', type: 'int' }
      { name: 'worthinessCount', type: 'int' }
      { name: 'deemed_worthy_by_me', type: 'boolean', defaultValue: false }
      { name: 'flagged_by_me', type: 'boolean', defaultValue: false }
      { name: 'mobileOrigin', type: 'int' }
      { name: 'thumbUrl', type: 'string' }
      { name: 'mediumUrl', type: 'string' }
      { name: 'url', type: 'string' }
      {
        name: 'status'
        type: 'string'
        convert: (v, rec) ->
          if v is 'uploading'
            'uploading'
          else if v is 'processing'
            'processing'
          else
            'loaded'
          
      }
      {
        name: 'timestampTaken'
        convert: (v, rec) ->
          if typeof v is 'string'
            arr = v.split /[- :\.]/ # needs to be converted to a Date object
            d = new Date()
            d.setUTCFullYear parseInt(arr[0])
            d.setUTCMonth parseInt(arr[1]) - 1
            d.setUTCDate parseInt(arr[2])
            d.setUTCHours parseInt(arr[3])
            d.setUTCMinutes parseInt(arr[4])
            d.setUTCSeconds parseInt(arr[5])
            d
          else
            v
      }
    ]