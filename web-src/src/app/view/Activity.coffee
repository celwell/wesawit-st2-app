Ext.define 'WSI.view.Activity',
  extend: 'Ext.Container'
  xtype: 'activity'
  requires: [
    'WSI.model.Media'
    'Ext.SegmentedButton'
  ]
  
  config:
    scrollable: false
    layout: 'vbox'
    margin: '0 5 0 5'
    padding: 0
    
  initialize: ->
    @callParent arguments
    @populateWithProperItems()
  
  populateWithProperItems: ->
    @add
      xtype: "segmentedbutton"
      baseCls: 'activity-segmented-button'
      flex: 0
      height: 38
      zIndex: 1000
      items: [
        {
          mediaType: 'events'
          iconCls: 'list'
          iconMask: true
          pressed: true
          text: ' '
          flex: 1
          height: 38
        }
        {
          mediaType: 'photos'
          iconCls: 'photo_black2'
          iconMask: true
          text: ' '
          flex: 1
          height: 38
        }
        {
          mediaType: 'videos'
          iconCls: 'video_black2'
          iconMask: true
          text: ' '
          flex: 1
          height: 38
        }
      ],
      listeners:
        toggle: (container, button, pressed)->
          @onContributionsMediaTypeChange button.config.mediaType
        scope: this
    activityListsContainer =
      xtype: 'container'
      layout: 'vbox'
      flex: 1
      zIndex: 999
      items: [
        {
          xtype: 'list'
          cls: [
            'activity-list'
            'fluid'
          ]
          width: '100%'
          padding: 0
          margin: 0
          flex: 1
          scrollable:
            direction: 'vertical'
            indicators: false
            directionLock: true
            momentumEasing:
              momentum:
                acceleration: 10
                friction: 0.95
              bounce:
                acceleration: 30
                springTension: 0.3
          disableSelection: true
          loadingText: ""
          emptyText: ""
          store:
            model: 'WSI.model.Event'
            proxy:
              type: 'ajax'
              url : 'http://wesawit.com/event/get_events_mobile'
              extraParams:
                'token': window.localStorage.getItem 'wsitoken'
                'uid': window.localStorage.getItem 'uid'
                sort: 'top'
                category: 'all'
                country: 'world'
                dateTimeStart: '1950-01-01T00:00:00Z'
                dateTimeEnd: '2025-12-31T23:59:59Z'
                searchTerm: 'user:'+window.localStorage.getItem('uid')
                includeExternalSources: 1
              reader:
                type: 'json'
                rootProperty: 'events'
            pageSize: 10
            autoLoad: true
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
                  "<div class='x-list-emptytext' style='display:none;'>{[(navigator.onLine ? 'you have not created any events' : 'unable to connect to internet<br />pull down to refresh')]}</div>"
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
              loadMoreText: ''
            }
          ]
          itemTpl: Ext.create('Ext.XTemplate',
            "<div class='delete'></div>"
            '{title}'
            '<span class="sub-info">'
              '<br />{[window.util.commaize_number(values.viewCount)]} views'
              "<br />{dateTimeStart:date('j M Y')} at {dateTimeStart:date('g:i a')}"
            '</span>'
          )
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
            activate: (c) ->
              # this is needed to refresh from the localStorage
              c.getStore().getProxy().config.extraParams.searchTerm = 'user:' + window.localStorage.getItem('uid')
            itemtap: (list, index, target, record, e, eOpts) ->
              if e.target.className is 'delete'
                if record.get('viewCount') < 301
                  deleteFn = (buttonIndex) =>
                    if buttonIndex is 2
                      @fireEvent 'deleteRecord', 'event', record, list
                  navigator.notification.confirm record.get('title'), deleteFn, 'Delete this event?', 'No,Yes'
                else
                  navigator.notification.alert 'You cannot delete an event that has more than 300 views.', (()->return), 'Oops!'
              else
                @fireEvent 'viewEventCommand', list, record
            scope: this
        }
        {
          xtype: 'list'
          cls: [
            'activity-list'
          ]
          width: '100%'
          padding: 0
          margin: 0
          flex: 1
          itemHeight: 100
          refreshHeightOnUpdate: false
          variableHeights: false
          disableSelection: false
          scrollable:
            indicators: false
            directionLock: true
            direction: 'vertical'
            momentumEasing:
              momentum:
                acceleration: 10
                friction: 0.95
              bounce:
                acceleration: 30
                springTension: 0.3
          loadingText: ""
          emptyText: ""
          hidden: true
          store:
            model: 'WSI.model.Media'
            proxy:
              type: 'ajax'
              url: 'http://wesawit.com/event/get_photos/0/' + encodeURIComponent(window.localStorage.getItem('uid'))
              reader:
                type: 'json'
                rootProperty: 'photos'
            pageSize: 8
          plugins: [
            {
              xclass: 'WSI.plugin.BetterPullRefresh'
              pullRefreshText: 'pull down to refresh'
              releaseRefreshText: 'release to refresh'
              loadingText: 'loading photos...'
              pullTpl: [
                  '<div class="x-list-pullrefresh">',
                      '<div class="x-list-pullrefresh-wrap">',
                          '<img src="resources/images/tarsier.png" width="45" height="24" />',
                          '<h3 class="x-list-pullrefresh-message" style="display:none">{message}</h3>',
                          '<div class="x-list-pullrefresh-updated" style="display:none">last updated: <span>{lastUpdated:date("m/d/Y h:iA")}</span></div>',
                      '</div>',
                  '</div>',
                  "<div class='x-list-emptytext' style='display:none;'>{[(navigator.onLine ? 'you have not uploaded any photos' : 'unable to connect to internet<br />pull down to refresh')]}</div>"
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
              loadMoreText: ''
            }
          ]
          itemTpl: Ext.create('Ext.XTemplate',
            "<div class='media-item thumb' style='width: 155px; height: 100px; float: left; background-image: url({[util.image_url(values, 'small')]}); background-size: cover; background-position: center;'></div>"
            "<div class='right-side'>"
              "<div class='delete'></div>"
              "<span class='sub-info'>"
                "{[window.util.commaize_number(values.worthinessCount)]} like{[(values.worthinessCount != 1 ? 's' : '')]}"
                "<br />{timestampTaken:date('j M Y')}"
                "<br />{timestampTaken:date('g:i a')}"
              "</span>"
            "</div>"
          )
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
            itemtap: (list, index, target, record, e, eOpts) ->
              if e.target.className is 'delete'
                if record.get('worthinessCount') < 11
                  deleteFn = (buttonIndex) =>
                    if buttonIndex is 2
                      @fireEvent 'deleteRecord', 'photo', record, list
                  navigator.notification.confirm 'Delete this photo?', deleteFn, 'Delete?', 'No,Yes'
                else
                  navigator.notification.alert 'You cannot delete a photo that has more than 10 likes.', (()->return), 'Oops!'
              else
                eid = record.get('event_id')
                if Ext.getStore('EventsCurrent').getById(eid)?
                  @fireEvent 'viewEventCommand', null, Ext.getStore('EventsCurrent').getById(eid)
                else if Ext.getStore('EventsPast').getById(eid)?
                  @fireEvent 'viewEventCommand', null, Ext.getStore('EventsPast').getById(eid)
                else if Ext.getStore('EventsFuture').getById(eid)?
                  @fireEvent 'viewEventCommand', null, Ext.getStore('EventsFuture').getById(eid)
                else if Ext.getStore('EventsSearch').getById(eid)?
                  @fireEvent 'viewEventCommand', null, Ext.getStore('EventsSearch').getById(eid)
                else
                  # the event that this media is/was for is not currently in our stores
                  Ext.Ajax.request({
                    url: "http://wesawit.com/event/view/#{eid}/1"
                    method: 'GET'
                    scope: this
                    success: (response) ->
                      obj = Ext.decode response.responseText
                      if obj.event_data? and obj.event_data isnt false
                        eventRecord = Ext.create 'WSI.model.Event', obj.event_data
                        @fireEvent 'viewEventCommand', null, eventRecord
                      else
                        navigator.notification.alert 'The event that this was for has been deleted.', (()->return), 'Oops!'
                    failure: ->
                      navigator.notification.alert 'The event that this was for has been deleted.', (()->return), 'Oops!'
                  })
            scope: this
        }
        {
          xtype: 'list'
          cls: [
            'activity-list'
          ]
          hidden: true
          width: '100%'
          padding: 0
          margin: 0
          flex: 1
          itemHeight: 100
          refreshHeightOnUpdate: false
          variableHeights: false
          disableSelection: false
          scrollable:
            indicators: false
            directionLock: true
            direction: 'vertical'
            momentumEasing:
              momentum:
                acceleration: 10
                friction: 0.95
              bounce:
                acceleration: 30
                springTension: 0.3
          loadingText: ""
          emptyText: ""
          store:
            model: 'WSI.model.Media'
            proxy:
              type: 'ajax'
              url : 'http://wesawit.com/event/get_videos/0/' + encodeURIComponent(window.localStorage.getItem('uid'))
              reader:
                type: 'json'
                rootProperty: 'videos'
            pageSize: 8
          plugins: [
            {
              xclass: 'WSI.plugin.BetterPullRefresh'
              pullRefreshText: 'pull down to refresh'
              releaseRefreshText: 'release to refresh'
              loadingText: 'loading videos...'
              pullTpl: [
                  '<div class="x-list-pullrefresh">',
                      '<div class="x-list-pullrefresh-wrap">',
                          '<img src="resources/images/tarsier.png" width="45" height="24" />',
                          '<h3 class="x-list-pullrefresh-message" style="display:none">{message}</h3>',
                          '<div class="x-list-pullrefresh-updated" style="display:none">last updated: <span>{lastUpdated:date("m/d/Y h:iA")}</span></div>',
                      '</div>',
                  '</div>',
                  "<div class='x-list-emptytext' style='display:none;'>{[(navigator.onLine ? 'you have not uploaded any videos' : 'unable to connect to internet<br />pull down to refresh')]}</div>"
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
              loadMoreText: ''
            }
          ]
          itemTpl: Ext.create('Ext.XTemplate',
            "<div class='media-item thumb' style='width: 155px; height: 100px; float: left; background-image: url({[util.image_url(values, 'small')]}); background-size: cover; background-position: center;'></div>"
            "<div class='right-side'>"
              "<div class='delete'></div>"
              "<span class='sub-info'>"
                "{[window.util.commaize_number(values.worthinessCount)]} like{[(values.worthinessCount != 1 ? 's' : '')]}"
                "<br />{timestampTaken:date('j M Y')}"
                "<br />{timestampTaken:date('g:i a')}"
              "</span>"
            "</div>"
            window.util
          )
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
            itemtap: (list, index, target, record, e, eOpts) ->
              if e.target.className is 'delete'
                if record.get('worthinessCount') < 11
                  deleteFn = (buttonIndex) =>
                    if buttonIndex is 2
                      @fireEvent 'deleteRecord', 'video', record, list
                  navigator.notification.confirm 'Delete this video?', deleteFn, 'Delete?', 'No,Yes'
                else
                  navigator.notification.alert 'You cannot delete a video that has more than 10 likes.', (()->return), 'Oops!'
              else
                eid = record.get('event_id')
                if Ext.getStore('EventsCurrent').getById(eid)?
                  @fireEvent 'viewEventCommand', null, Ext.getStore('EventsCurrent').getById(eid)
                else if Ext.getStore('EventsPast').getById(eid)?
                  @fireEvent 'viewEventCommand', null, Ext.getStore('EventsPast').getById(eid)
                else if Ext.getStore('EventsFuture').getById(eid)?
                  @fireEvent 'viewEventCommand', null, Ext.getStore('EventsFuture').getById(eid)
                else if Ext.getStore('EventsSearch').getById(eid)?
                  @fireEvent 'viewEventCommand', null, Ext.getStore('EventsSearch').getById(eid)
                else
                  # the event that this media is/was for is not currently in our stores
                  Ext.Ajax.request({
                    url: "http://wesawit.com/event/view/#{eid}/1"
                    method: 'GET'
                    scope: this
                    success: (response) ->
                      obj = Ext.decode response.responseText
                      if obj.event_data? and obj.event_data isnt false
                        eventRecord = Ext.create 'WSI.model.Event', obj.event_data
                        @fireEvent 'viewEventCommand', null, eventRecord
                      else
                        navigator.notification.alert 'The event that this was for has been deleted.', (()->return), 'Oops!'
                    failure: ->
                      navigator.notification.alert 'The event that this was for has been deleted.', (()->return), 'Oops!'
                  })
            scope: this
        }
      ]
    @add activityListsContainer
  
  onContributionsMediaTypeChange: (mediaType) ->
    if mediaType isnt 'events' then @getAt(1).getAt(0).hide()
    if mediaType isnt 'photos' then @getAt(1).getAt(1).hide()
    if mediaType isnt 'videos' then @getAt(1).getAt(2).hide()
    switch mediaType
      when 'events'
        @getAt(1).getAt(0).getStore().loadPage(1)
        @getAt(1).getAt(0).show()
      when 'photos'
        @getAt(1).getAt(1).getStore().getProxy().config.url = 'http://wesawit.com/event/get_photos/0/' + encodeURIComponent(window.localStorage.getItem('uid'))
        @getAt(1).getAt(1).getStore().loadPage(1)
        @getAt(1).getAt(1).show()
      when 'videos'
        @getAt(1).getAt(2).getStore().getProxy().config.url = 'http://wesawit.com/event/get_videos/0/'+encodeURIComponent(window.localStorage.getItem('uid'))
        @getAt(1).getAt(2).getStore().loadPage(1)
        @getAt(1).getAt(2).show()
