Ext.define 'WSI.view.Following',
  extend: 'Ext.Container'
  xtype: 'following'
  requires: [
    'WSI.model.Event'
  ]
  config:
    layout: 'fit'
    scrollable: false
    margin: 0
    padding: 0
    
  initialize: ->
    @callParent arguments
    @populateWithProperItems()
    
  populateWithProperItems: ->
    followingStore = Ext.create 'Ext.data.Store',
      model: 'WSI.model.Event'
      proxy:
        type: 'ajax'
        url : 'http://wesawit.com/event/get_events_by_bookmarks'
        extraParams:
          'token': window.localStorage.getItem 'wsitoken'
          'uid': window.localStorage.getItem 'uid'
          'api_version': util.API_VERSION
        reader:
          type: 'json'
          rootProperty: 'events'
      pageSize: 50
      autoLoad: true
    @add
      xtype: 'eventslist'
      cls: 'searchlist'
      itemHeight: 80
      flex: 1
      padding: 0
      margin: 0
      scrollable:
        indicators: false
        directionLock: true
      disableSelection: true
      store: followingStore
      plugins: [
        {
          xclass: 'WSI.plugin.BetterPullRefresh'
          pullRefreshText: 'pull down to refresh'
          releaseRefreshText: 'release to refresh'
          loadingText: 'loading events...'
          pullTpl: [
              '<div class="x-list-pullrefresh">',
                  '<div class="x-list-pullrefresh-wrap">',
                      '<img src="resources/images/tarsier.png" width="45" height="24" />',
                      '<h3 class="x-list-pullrefresh-message" style="display:none">{message}</h3>',
                      '<div class="x-list-pullrefresh-updated" style="display:none">last updated: <span>{lastUpdated:date("m/d/Y h:iA")}</span></div>',
                  '</div>',
              '</div>',
              "<div class='x-list-emptytext' style='display:none;'>{[(navigator.onLine ? 'you are not following any events' : 'unable to connect to internet<br />pull down to refresh')]}</div>"
          ].join ''
          refreshFn: (plugin) ->
            if not navigator.onLine
              navigator.notification.alert 'Unable to connect to the internet.', (()->return), 'Oops!'
            else
              store = plugin.up().up().getStore()
              refresher = ->
                #store.removeAll true # true is for 'silent' option
                store.currentPage = 1
                store.load()
              if not window.localStorage.getItem('locationTimestamp')? or (new Date()) - new Date(window.localStorage.getItem('locationTimestamp')) > 30000
                plugin.up().up().fireEvent 'grabCurrentPosition'
                task = Ext.create 'Ext.util.DelayedTask', refresher
                task.delay 500
              else
                refresher()
            return false
        }
        {
          xclass: 'Ext.plugin.ListPaging',
          autoPaging: true
          noMoreRecordsText: ""
          loadMoreText: ""
        }
      ]
      loadingText: ""
      emptyText: ""
      listeners:
        refresh: (c) ->
          Ext.defer(
            ->
              if c.getPlugins()[0]?.element?.dom?.childNodes[1]?
                if c.getStore().isLoaded() and c.getStore().getCount() is 0
                  c.getPlugins()[0].element.dom.childNodes[1].style.display = 'block'
                else
                  c.getPlugins()[0].element.dom.childNodes[1].style.display = 'none'
            , 100
          )
        activate: (list) ->
          # this is needed to refresh from the localStorage
          list.getStore().getProxy().config.extraParams.token = window.localStorage.getItem 'wsitoken'
          list.getStore().getProxy().config.extraParams.uid = window.localStorage.getItem 'uid'
        itemtap: (list, index, target, record, e, eOpts) ->
          @fireEvent 'viewEventCommand', list, record
        scope: this