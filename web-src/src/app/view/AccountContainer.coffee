Ext.define 'WSI.view.AccountContainer',
  extend: 'Ext.Container'
  xtype: 'accountcontainer'
  id: 'accountcontainer'
  requires: [
    'WSI.view.Account'
    'WSI.view.Activity'
    'WSI.view.Following'
  ]
  config:
    padding: 0
    layout:
      type: 'card'
    listeners:
      activate: ->
        @getAt(1).setActiveItem @getAt(1).getActiveItem()
    items: [
      {
        xtype: 'toolbar'
        id: 'sliderMenuSettings'
        docked: 'top'
        ui: 'orange'
        height: 35
        layout:
          type: 'hbox'
          pack: 'center'
        html: '<div class="sliderMenuSettingsPointer"></div>'
        items: [
          {
            xtype: 'component'
            html: 'Account'
            width: '33%'
            padding: '8 0 8 0'
            style:
              textAlign: 'center'
            listeners:
              tap:
                element: 'element'
                fn: (e) ->
                  @getParent().getParent().getAt(1).setActiveItem 0
          }
          {
            xtype: 'component'
            html: 'Activity'
            width: '33%'
            padding: '8 0 8 0'
            style:
              textAlign: 'center'
            listeners:
              tap:
                element: 'element'
                fn: (e) ->
                  if window.localStorage.getItem('wsitoken')?
                    @getParent().getParent().getAt(1).setActiveItem 1
                  else
                    navigator.notification.alert '', (()->return), 'Please Login'
          }
          {
            xtype: 'component'
            html: 'Following'
            width: '33%'
            padding: '8 0 8 0'
            style:
              textAlign: 'center'
            listeners:
              tap:
                element: 'element'
                fn: (e) ->
                  if window.localStorage.getItem('wsitoken')?
                    @getParent().getParent().getAt(1).setActiveItem 2
                  else
                    navigator.notification.alert '', (()->return), 'Please Login'
          }
        ]
      }
      {
        xtype: 'carousel'
        fullscreen: true
        ui: 'light'
        direction: 'horizontal'
        items: [
          {
            xtype: 'container'
            layout: 'card'
            listeners:
              activate: ->
                if @getItems().items.length is 0
                  @add { xtype: "account" }
                  @getItems().getAt(0).show()
              deactivate: ->
                @removeAll true, true
          }
          {
            xtype: 'container'
            layout: 'card'
            listeners:
              activate: ->
                if @getItems().items.length is 0
                  @add { xtype: "activity" }
                  @getItems().getAt(0).show()
              deactivate: ->
                @removeAll true, true
          }
          {
            xtype: 'container'
            layout: 'card'
            listeners:
              activate: ->
                if @getItems().items.length is 0
                  @add { xtype: "following" }
                  @getItems().getAt(0).show()
              deactivate: ->
                @removeAll true, true
          }
        ]
        listeners:
          dragstart: 
            element: 'element'
            fn: (e) ->
              if not window.localStorage.getItem('wsitoken')?
                return false
          drag: 
            element: 'element'
            fn: (e) ->
              if not window.localStorage.getItem('wsitoken')?
                return false
          dragend:
            element: 'element'
            fn: (e) ->
              if not window.localStorage.getItem('wsitoken')?
                return false
          activeitemchange: (container, value, oldValue, eOpts) ->
            tabPos = [
              16
              50
              82
            ]
            document.getElementsByClassName('sliderMenuSettingsPointer')[0]?.style.left = tabPos[container.getActiveIndex()] + '%'
          scope: this
      }
    ]
  initialize: () ->
    @callParent arguments
