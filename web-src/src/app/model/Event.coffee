Ext.define 'WSI.model.Event',
  extend: 'Ext.data.Model'
  config:
    useCache: no
    fields: [
      { name: 'id', type: 'string' }
      { name: 'title', type: 'string' }
      { name: 'description', type: 'string' }
      { name: 'category', type: 'string' }
      {
        name: 'dateTimeStart'
        convert: (v, rec) ->
          arr = v.split /[- :\.]/ # needs to be converted to a Date
          d = new Date()
          d.setUTCFullYear parseInt(arr[0])
          d.setUTCMonth parseInt(arr[1]) - 1
          d.setUTCDate parseInt(arr[2])
          d.setUTCHours parseInt(arr[3])
          d.setUTCMinutes parseInt(arr[4])
          d.setUTCSeconds parseInt(arr[5])
          d
      }
      {
        name: 'dateTimeEnd'
        convert: (v, rec) ->
          arr = v.split /[- :\.]/ # needs to be converted to a Date
          d = new Date()
          d.setUTCFullYear parseInt(arr[0])
          d.setUTCMonth parseInt(arr[1]) - 1
          d.setUTCDate parseInt(arr[2])
          d.setUTCHours parseInt(arr[3])
          d.setUTCMinutes parseInt(arr[4])
          d.setUTCSeconds parseInt(arr[5])
          d
      }
      { name: 'locationName', type: 'string' }
      { name: 'locationVicinity', type: 'string' }
      { name: 'locationLat', type: 'string' }
      { name: 'locationLng', type: 'string' }
      { name: 'viewCount', type: 'number' }
      { name: 'num_whosthere', type: 'number' }
      { name: 'bookmarked_by_me', type: 'boolean', defaultValue: false }
      { name: 'flagged_by_me', type: 'boolean', defaultValue: false }
      {
        name: 'photos'
        convert: (v, rec) ->
          for i in v
            i.status = 'loaded'
            i.url = null
            i.mediumUrl = null
            i.pid = i.id
            i.event_id = i.aeid
            if i.thumbUrl isnt ''
              i.url = i.thumbUrl.slice(0, -5) + '7.jpg'
              i.mediumUrl = i.thumbUrl.slice(0, -5) + '6.jpg'
            else
              i.url = null
              i.mediumUrl = null
              i.thumbUrl = null
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
      { name: 'num_of_photos', type: 'number' }
      {
        name: 'top_photo'
        convert: (v, rec) ->
          if v?
            v.status = 'loaded'
            v.url = null
            v.mediumUrl = null
            v.pid = v.id
            v.event_id = v.aeid
            if v.thumbUrl isnt ''
              v.url = v.thumbUrl.slice(0, -5) + '7.jpg'
              v.mediumUrl = v.thumbUrl.slice(0, -5) + '6.jpg'
            else
              v.url = null
              v.mediumUrl = null
              v.thumbUrl = null
            arr = v.timestampTaken.split /[- :\.]/ # needs to be converted to a Date
            v.timestampTaken = new Date()
            v.timestampTaken.setUTCFullYear parseInt(arr[0])
            v.timestampTaken.setUTCMonth parseInt(arr[1]) - 1
            v.timestampTaken.setUTCDate parseInt(arr[2])
            v.timestampTaken.setUTCHours parseInt(arr[3])
            v.timestampTaken.setUTCMinutes parseInt(arr[4])
            v.timestampTaken.setUTCSeconds parseInt(arr[5])
          v
      }
      {
        name: 'videos'
        convert: (v, rec) ->
          for i in v
            i.status = 'loaded'
            i.vid = i.id
            i.event_id = i.aeid
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
      { name: 'num_of_videos', type: 'number' }
      {
        name: 'top_video'
        convert: (v, rec) ->
          if v?
            v.status = 'loaded'
            v.vid = v.id
            v.event_id = v.aeid
            arr = v.timestampTaken.split /[- :\.]/ # needs to be converted to a Date
            v.timestampTaken = new Date()
            v.timestampTaken.setUTCFullYear parseInt(arr[0])
            v.timestampTaken.setUTCMonth parseInt(arr[1]) - 1
            v.timestampTaken.setUTCDate parseInt(arr[2])
            v.timestampTaken.setUTCHours parseInt(arr[3])
            v.timestampTaken.setUTCMinutes parseInt(arr[4])
            v.timestampTaken.setUTCSeconds parseInt(arr[5])
          v
      }
      { name: 'outdated', type: 'boolean', defaultValue: no }
    ]
