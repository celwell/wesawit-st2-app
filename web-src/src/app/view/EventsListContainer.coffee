Ext.define 'WSI.view.EventsListContainer',
  extend: 'Ext.tab.Panel'
  xtype: 'eventslistcontainer'
  requires: [
    'WSI.view.EventsList'
    'WSI.view.AccountContainer'
  ]
  config:
    layout:
      type: 'card'
      animation: false
    tabBarPosition: 'bottom'
    lastActiveTabBeforeCaptureActionSheetShown: 0
    listeners:
      activeitemchange: (tabPanel, value, oldValue) ->
        if value is @getAt(1) # browse button
          @config.lastActiveTabBeforeCaptureActionSheetShown = 0
          if @getAt(1).getActiveItem().getId() isnt 'eventdetailscontainer' and @getAt(1).getActiveItem().getId() isnt 'whostherecontainer'
            @fireEvent 'showCreateEventButton'
            @fireEvent 'hideTopToolbarHomeButton'
            @fireEvent 'hideMoreActionsButton'
            @fireEvent 'resetTopToolbarTitle'
          else
            @fireEvent 'hideCreateEventButton'
            @fireEvent 'showTopToolbarHomeButton'
            @fireEvent 'showMoreActionsButton'
            @fireEvent 'revertTopToolbarTitle'
          @getAt(3).hide()
        else if value is @getAt(3) # settings button
          @config.lastActiveTabBeforeCaptureActionSheetShown = 2
          @fireEvent 'hideCreateEventButton'
          @fireEvent 'hideTopToolbarHomeButton'
          @fireEvent 'hideMoreActionsButton'
          @fireEvent 'resetTopToolbarTitle'
        else if value is @getAt(2) # capture button
          @fireEvent 'hideCreateEventButton'
          @fireEvent 'hideTopToolbarHomeButton'
          @fireEvent 'hideMoreActionsButton'
          return false
  initialize: ->
    @callParent arguments
    search =
      xtype: 'formpanel'
      id: 'searchToolbar'
      layout: 'vbox'
      scrollable: false
      listeners:
        scope: this
        activate: (c) ->
          if c.getAt(0).getAt(1).getData().length is 0
            @fireEvent 'populateUiForSearch'
          c.getAt(0).getAt(0).focus()
          return true
      items: [
        {
          xtype: 'container'
          layout: 'hbox'
          docked: 'top'
          flex: 0
          padding: '0 5 5 5'
          height: 43
          style: 'background: #f0f0f0;'
          items: [
            {
              xtype: 'searchfield'
              id: 'eventsearch'
              name: 'eventsearch'
              flex: 4
              margin: '0 5 0 0'
              cls: 'event-details-facts'
              style:
                border: '1px solid #aaa'
                borderBottomRightRadius: '4px'
                borderBottomLeftRadius: '4px'
                opacity: 1
                display: 'block'
                color: '#333'
              placeHolder: 'Search'
              listeners:
                keyup: (field, e, eOpts) ->
                  Ext.getStore('EventsSearch').getProxy().getExtraParams().searchTerm = field.getValue()
                  Ext.getStore('EventsSearch').removeAll(true, true)
                  if Ext.getStore('EventsSearch').getProxy().getExtraParams().searchTerm isnt '' or Ext.getStore('EventsSearch').getProxy().getExtraParams().category isnt 'all'
                    Ext.getStore('EventsSearch').loadPage(1)
                    
                clearicontap: ->
                  Ext.getStore('EventsSearch').getProxy().getExtraParams().searchTerm = ''
                  Ext.getStore('EventsSearch').removeAll(true, true)
                  if Ext.getStore('EventsSearch').getProxy().getExtraParams().searchTerm isnt '' or Ext.getStore('EventsSearch').getProxy().getExtraParams().category isnt 'all'
                    Ext.getStore('EventsSearch').loadPage(1)
                  @focus()
            }
            {
              xtype: 'component'
              flex: 3
              tpl: [
                '<select onclick="this.className = \'active\';" onchange="this.className = \'\';Ext.getStore(\'EventsSearch\').getProxy().getExtraParams().category = this.value; if ( ! (this.value == \'all\' && Ext.getStore(\'EventsSearch\').getProxy().getExtraParams().searchTerm == \'\' )  ) Ext.getStore(\'EventsSearch\').removeAll(true,true); if ( ! (this.value == \'all\' && Ext.getStore(\'EventsSearch\').getProxy().getExtraParams().searchTerm == \'\' )  ) Ext.getStore(\'EventsSearch\').loadPage(1);">'
                  '<tpl for=".">'
                    '<option value="{value}">{text}</option>'
                  '</tpl>'
                '</select>'
              ]
              data: new Array()
            }
          ]
        }
        {
          xtype: 'eventslist'
          id: 'eventslistsearch'
          flex: 1
          width: '100%'
          cls: 'searchlist'
          itemHeight: 80
          store: Ext.getStore 'EventsSearch'
          emptyText: "<div style='width:100%;text-align:center;font-size:13px;color:#666;text-shadow:none;font-weight:bold;'>no events found</div>"
          plugins: false
          listeners:
            itemtap: (list, index, target, record, e, eOpts) ->
              @onViewEvent record
            scope: this
        }
      ]
    eventsListPresent =
      xtype: 'eventslist'
      id: 'eventslistpresent'
      store: Ext.getStore 'EventsCurrent'
      listeners:
        itemtap: (list, index, target, record, e, eOpts) ->
          @onViewEvent record
        scope: this
    eventsListPast =
      xtype: 'eventslist'
      id: 'eventslistpast'
      store: Ext.getStore 'EventsPast'
      listeners:
        itemtap: (list, index, target, record, e, eOpts) ->
          @onViewEvent record
        scope: this
    eventsListFuture =
      xtype: 'eventslist'
      id: 'eventslistfuture'
      store: Ext.getStore 'EventsFuture'
      listeners:
        itemtap: (list, index, target, record, e, eOpts) ->
          @onViewEvent record
        scope: this
    sliderMenu =
      xtype: 'toolbar'
      id: 'sliderMenu'
      docked: 'top'
      ui: 'orange'
      height: 35
      margin: 0
      padding: '0 0 2 0'
      layout:
        type: 'hbox'
        pack: 'center'
      html: '<div class="sliderMenuPointer"></div>'
      items: [
        {
          xtype: 'component'
          html: '<div class="x-button sliderMenuSearch"><span class="x-button-icon x-icon-mask search" style="margin: 0px auto"></span></div>'
          width: '25%'
          margin: 0
          padding: '5 0 5 0'
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
          html: 'Past'
          width: '25%'
          margin: 0
          padding: '8 0 8 0'
          style:
            textAlign: 'center'
          listeners:
            tap:
              element: 'element'
              fn: (e) ->
                @getParent().getParent().getAt(1).setActiveItem 1
        }
        {
          xtype: 'component'
          html: 'Trending'
          width: '25%'
          margin: 0
          padding: '8 0 8 0'
          style:
            textAlign: 'center'
          listeners:
            tap:
              element: 'element'
              fn: (e) ->
                @getParent().getParent().getAt(1).setActiveItem 2
        }
        {
          xtype: 'component'
          html: 'Upcoming'
          width: '25%'
          margin: 0
          padding: '8 0 8 0'
          style:
            textAlign: 'center'
          listeners:
            tap:
              element: 'element'
              fn: (e) ->
                @getParent().getParent().getAt(1).setActiveItem 3
        }
      ]
    listViewCarousel =
      xtype: 'carousel'
      direction: 'horizontal'
      indicator: false
      scrollable:
        indicators: false
        direction: 'horizontal'
        momentumEasing:
          momentum:
            acceleration: 1000000
            friction: 0.0001
        outOfBoundRestrictFactor: 0.0001
      activeItem: 2
      items: [
        search
        eventsListPast
        eventsListPresent
        eventsListFuture
      ]
      listeners:
        initialize: (container) ->
          tabPos = [
            13
            38
            63  
            88
          ]
          document.getElementsByClassName('sliderMenuPointer')[0]?.style.left = tabPos[container.getActiveIndex()] + '%'
              
        activeitemchange: (container, value, oldValue, eOpts) ->
          ###
          if container.listReloadTimeout?
            clearInterval container.listReloadTimeout
            delete container.listReloadTimeout
          if value.getStore?().lastTimeLoadCalled? and (new Date()).getTime() - value.getStore().lastTimeLoadCalled.getTime() > 60000
            reloadFn = do (value) =>=>
              value.getStore().load()
            container.listReloadTimeout = setTimeout reloadFn, 1000
          ###
          tabPos = [
            13
            38
            63  
            88
          ]
          document.getElementsByClassName('sliderMenuPointer')[0]?.style.left = tabPos[container.getActiveIndex()] + '%'
        scope: this
    browseTab =
      xtype: 'container'
      layout: 'card'
      iconCls: 'browse'
      id: 'browseTab'
      style: ' background: #222;' 
      items: [
        {
          xtype: 'container'
          layout: 'fit'
          fullscreen: true
          items: [
            sliderMenu
            listViewCarousel
          ]
        }
      ]
    cameraTab =
      xtype: 'container'
      layout: 'fit'
      iconCls: 'camera'
      scope: this
      tab:
        listeners:
          tap: (c) ->
            c.up().up().fireEvent 'captureMediaButtonTap'
    settingsTab =
      xtype: 'accountcontainer'
      iconCls: 'config'
      badgeText: if not window.localStorage.getItem('wsitoken')? then 'Log in here' else ''
    @add [
      browseTab
      cameraTab
      settingsTab
    ]
  onViewEvent: (record) ->
    this.fireEvent 'viewEventCommand', this, record
  onShowLoading: (tabBarIndex) ->
    this.fireEvent 'showLoading', tabBarIndex
  onHideLoading: (tabBarIndex) ->
    this.fireEvent 'hideLoading', tabBarIndex
