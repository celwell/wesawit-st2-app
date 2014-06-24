Ext.define 'WSI.view.CreateEventForm',
  extend: 'Ext.Container'
  xtype: 'createeventform'
  requires: [
    'Ext.Map'
  ]
  config:
    id: 'createeventform'
    layout: 'vbox'
    hidden: true
    justCreated: true
    margin: 0
    padding: '0 10 0 10'
    width: '100%'
    scrollable:
      direction: 'vertical'
      indicators: false
      directionLock: true
    listeners:
      activate: ->
        that = this
        if that.config.justCreated
          that.config.justCreated = false
          that.show
            type: 'slide'
            direction: 'up'
    eventData:
      title: ''
      description: ''
      locationName: ''
      locationVicinity: ''
      locationLat: '0'
      locationLng: '0'
      locationType: ''
      reference: ''
      dateTimeStart: ''
      dateTimeEnd: ''
      category: ''
  initialize: ->
    askTitle =
      xtype: 'container'
      layout: 'hbox'
      margin: '10 0 0 0'
      flex: 0
      items: [
        {
          xtype: 'component'
          width: 65
          height: 40
          padding: '10 10 15 10'
          html: 'What'
          style:
            fontWeight: 'bold'
            fontSize: '15px'
            textTransform: 'lowercase'
            background: '#f5f5f5'
            textShadow: '0px 1px 0px #eee'
            color: '#777'
            border: '1px solid #aaa'
            borderRight: 'none'
            borderTopLeftRadius: '4px'
        }
        {
          xtype: 'textfield'
          flex: 1
          name: 'Event_Title'
          height: 40
          placeHolder: 'Event Title (60 characters max)'
          required: true
          maxLength: 60
          style:
            background: '#F5F5F5'
            textShadow: '0px 1px 0px #eee'
            color: '#006AB7 !important'
            border: '1px solid #aaa'
            borderLeft: 'none'
            borderTopRightRadius: '4px'
            marginLeft: '-1px'
        }
      ]
    askCategory =
      xtype: 'container'
      layout: 'hbox'
      margin: '10 0 0 0'
      flex: 0
      items: [
        {
          xtype: 'component'
          flex: 1
          tpl: [
            '<select name="blahblahlahlbahlba" placeHolder="Category" onchange="document.getElementById(\'Event_Category\').childNodes[1].childNodes[0].childNodes[0].value = this.value;">'
              '<option value="" disabled="diasbled" selected="selected">Category</option>'
              '<tpl for=".">'
                '<option value="{value}">{text}</option>'
              '</tpl>'
            '</select>'
          ]
          data: null
        }
        {
          xtype: 'textfield'
          id: 'Event_Category'
          name : 'Event_Category'
          value: ''
          hidden: true
        }
      ]
    askDescription =
      xtype: 'container'
      layout: 'hbox'
      margin: '10 0 0 0'
      flex: 0
      items: [
        {
          xtype: 'textareafield'
          name : 'Event_Description'
          rows: 1
          maxLength: 200
          placeHolder: 'Description (optional)'
          flex: 1
          value: ''
          style:
            background: '#F5F5F5'
            fontSize: '13px'
            textShadow: '0px 1px 0px #eee'
            color: '#444'
            border: '1px solid #aaa'
            borderRadius: '4px'
        }
      ]
    askWhere =
      xtype: 'container'
      layout: 'hbox'
      margin: '0 0 0 0'
      flex: 0
      items: [
        {
          xtype: 'component'
          width: 65
          height: 40
          padding: '10 10 15 10'
          html: 'Where'
          style:
            fontWeight: 'bold'
            fontSize: '15px'
            textTransform: 'lowercase'
            background: '#f5f5f5'
            textShadow: '0px 1px 0px #eee'
            color: '#777'
            border: '1px solid #aaa'
            borderTop: 'none'
            borderRight: 'none'
        }
        {
          xtype: 'component'
          flex: 1
          tpl: '<div class="form-group-toggle in-form" style="font-size: 13px !important; font-weight: normal !important; padding: 11px 7px 9px 7px !important; color: #006AB7 !important; background: #f5f5f5 !important;border-left: none !important;height:40px !important;border-radius:0px !important;border-top:none !important;"><span style="max-width:190px !important;display:inline-block !important;white-space:nowrap !important;overflow:hidden !important;text-overflow:ellipsis !important;">{locationName}</span> <img src="resources/images/disclosure.png" width="11" height="15" /></div>'
          data:
            locationName: '<div class="x-loading-spinner-outer" style="margin-top: 0px;"><div class="x-loading-spinner" style="margin: 0px auto; font-size: 18px !important;"><span class="x-loading-top"></span><span class="x-loading-right"></span><span class="x-loading-bottom"></span><span class="x-loading-left"></span></div></div>'
            locationVicinity: ''
            locationLat: '0'
            locationLng: '0'
            reference: ''
          style:
            marginLeft: '-1px'
          listeners:
            tap:
              element: 'element'
              fn: (e) ->
                @getParent().getParent().showWhere()
        }
      ]
    askWhen =
      xtype: 'container'
      layout: 'hbox'
      margin: '0 0 0 0'
      flex: 0
      items: [
        {
          xtype: 'component'
          width: 65
          height: 40
          padding: '10 10 15 10'
          html: 'When'
          style:
            fontWeight: 'bold'
            fontSize: '15px'
            textTransform: 'lowercase'
            background: '#f5f5f5'
            textShadow: '0px 1px 0px #eee'
            color: '#777'
            border: '1px solid #aaa'
            borderTop: 'none'
            borderRight: 'none'
            borderBottomLeftRadius: '4px'
        }
        {
          xtype: 'component'
          flex: 9
          tpl: '<div class="form-group-toggle in-form" style="font-size: 13px !important; white-space:nowrap !important;overflow:hidden !important;text-overflow:ellipsis !important;font-size: 13px !important; font-weight: normal !important; padding: 11px 7px 9px 7px !important; color: #006AB7 !important; background: #f5f5f5 !important; border-left: none !important;height:40px !important;border-bottom-left-radius: 0px !important;border-top-left-radius: 0px !important;border-top-right-radius: 0px !important;border-top:none !important;"><span style="max-width:220px !important;display:inline-block !important;white-space:nowrap !important;overflow:hidden !important;text-overflow:ellipsis !important;">{[(values.dateTimeStart == "Now" ? "Now" : Ext.util.Format.date(values.dateTimeStart, "M j, Y") + " at " + Ext.util.Format.date(values.dateTimeStart, " g:i a"))]}</span> <img src="resources/images/disclosure.png" width="11" height="15" /></div>'
          data:
            dateTimeStart: 'Now'
            dateTimeEnd: ''
          style:
            marginLeft: '-1px'
          listeners:
            tap:
              element: 'element'
              fn: (e) ->
                @getParent().getParent().showWhen()
        }
      ]
    submitButton =
      xtype: 'component'
      flex: 1
      html: '<div class="form-group-toggle create" style="text-align: center !important;font-size: 18px !important;padding-top:5px !important;padding-bottom:5px !important;">Post Event</div>'
      listeners:
        tap:
          element: 'element'
          fn: (e) ->
            @up().up().onCreateEventFormSubmit()
    cancelButton =
      xtype: 'component'
      flex: 0
      padding: '0 10 0 0'
      html: '<div class="form-group-toggle" style="text-align: center !important;font-size: 17px !important;padding-top:6px !important;padding-bottom:7px !important;">Cancel</div>'
      listeners:
        tap:
          element: 'element'
          fn: (e) ->
            @up().up().onCancelButtonTap()
    @add([
      {
        xtype: 'component'
        hidden: true
        html: "<div id='gmap-container'></div>"
        listeners:
          initialize: (c) ->
            map = new google.maps.Map c.bodyElement.dom.children[0].children[0]
            google.maps.event.addListenerOnce map, 'idle', ->
              if c.up().getAt(2).getAt(1).getData().locationName is '' or c.up().getAt(2).getAt(1).getData().locationName is 'Loading...' or c.up().getAt(2).getAt(1).getData().locationName is '<div class="x-loading-spinner-outer" style="margin-top: 0px;"><div class="x-loading-spinner" style="margin: 0px auto; font-size: 18px !important;"><span class="x-loading-top"></span><span class="x-loading-right"></span><span class="x-loading-bottom"></span><span class="x-loading-left"></span></div></div>'
                c.up().config.genSuggTimeout = setTimeout (()->c.up().fireEvent('generateSuggestions', null, true)), 500
      }
      askTitle
      askWhere
      askWhen
      askDescription
      askCategory
      {
        xtype: 'container'
        padding: '10 0 5 0'
        flex: 0
        height: 50
        layout: 'hbox'
        pack: 'center'
        items: [
          cancelButton
          submitButton
        ]
      }
    ])
  onCancelButtonTap: ->
    @fireEvent 'homeButtonTap'
  onCreateEventFormSubmit: ->
    @config.eventData.title = @getItems().getAt(1).getItems().getAt(1).getValue()
    @config.eventData.description = @getItems().getAt(4).getItems().getAt(0).getValue()
    @config.eventData.locationName = @getItems().getAt(2).getItems().getAt(1).getData().locationName
    @config.eventData.locationVicinity = @getItems().getAt(2).getItems().getAt(1).getData().locationVicinity
    @config.eventData.locationLat = @getItems().getAt(2).getItems().getAt(1).getData().locationLat
    @config.eventData.locationLng = @getItems().getAt(2).getItems().getAt(1).getData().locationLng
    @config.eventData.locationType = @getItems().getAt(2).getItems().getAt(1).getData().locationType
    @config.eventData.reference = @getItems().getAt(2).getItems().getAt(1).getData().reference
    dateTimeStart = @getItems().getAt(3).getItems().getAt(1).getData().dateTimeStart
    if dateTimeStart is 'Now'
      dateTimeStart = new Date()
    @config.eventData.dateTimeStart = dateTimeStart
    dateTimeEnd = @getItems().getAt(3).getItems().getAt(1).getData().dateTimeEnd
    if dateTimeEnd is ''
      dateTimeEnd = new Date(dateTimeStart.getTime())
      dateTimeEnd.setHours( dateTimeEnd.getHours() + 3 )
    @config.eventData.dateTimeEnd = dateTimeEnd
    @config.eventData.category = @getItems().getAt(5).getItems().getAt(1).getValue()
    @fireEvent 'createEventFormSubmit'
    
  showWhere: ->
    @fireEvent 'showWhereContainer'
    
  showWhen: ->
    @fireEvent 'showWhenContainer'