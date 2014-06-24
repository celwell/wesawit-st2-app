Ext.define 'WSI.view.WhenContainer',
  extend: 'Ext.Panel'
  xtype: 'whencontainer'
  id: 'whencontainer'
  requires: [
    'WSI.view.DateTimePicker'
  ]
  config:
    fullscreen: true
    padding: '0 10 0 10'
    width: '100%'
    scrollable: false
      
  initialize: ->
    if Ext.os.is.Android
      askDateTime =
        xtype: 'datetimepickerfield'
        name : 'blahblahblahblahblah'
        label: false
        value: new Date()
        dateTimeFormat: 'M j, Y h:i A'
        destroyPickerOnHide: no
        picker:
          cancelButton: no
          style:
            fontSize: '13px'
          yearFrom: 1950
          yearTo: 2025
          minuteInterval : 15
          ampm : true
          slotOrder: [
            'day'
            'month'
            'year'
            'hour'
            'minute'
            'ampm'
          ]
    else
      askDateTime =
        xtype: 'container'
        layout: 'hbox'
        margin: '0 0 0 0'
        items: [
          {
            xtype: 'component'
            flex: 1
            html: '<input type="datetime" class="like-select" style="text-align: center !important;border-top-left-radius:0px !important; border-top-right-radius:0px !important;" min="1950-01-01 00:00" max="2025-12-31 23:59" step="900" value="' + (Ext.util.Format.date (new Date()), 'c') + '" />'
          }
        ]
    @add([
      {
        xtype: 'component'
        flex: 1
        margin: '45 0 45 0'
        html: '<div class="form-group-toggle">Happening Now</div>'
        listeners:
          tap:
            element: 'element'
            fn: (e) ->
              @getParent().chooseTimeInfo 'Now'
      }
      {
        xtype: 'component'
        margin: '0 0 0 0'
        html: '<div class="event-details-facts" style="padding: 10px !important;background: #f5f5f5 !important; text-transform: none !important;">Or, enter a different date and time below:</div>'
      }
      askDateTime
      {
        xtype: 'component'
        flex: 1
        margin: '10 0 30 0'
        html: '<div class="form-group-toggle">Done</div>'
        listeners:
          tap:
            element: 'element'
            fn: (e) ->
              if Ext.os.is.Android
                dateTime = "" + @getParent().getItems().getAt(2).getValue()
              else
                dateTime = "" + @getParent().getItems().getAt(2).element.dom.childNodes[0].childNodes[0].childNodes[0].childNodes[0].value
              if util.DEBUG then console.log dateTime
              #arr = dateTime.split(/[- :TZ]/)
              #@getParent().chooseTimeInfo( new Date(arr[0], arr[1]-1, arr[2], arr[3], arr[4], 0) )
              @getParent().chooseTimeInfo( new Date(dateTime) )
      }
    ])
  chooseTimeInfo: (dateTimeStart) ->
    @fireEvent 'newEventChooseTimeInfo', dateTimeStart, null, true