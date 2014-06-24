Ext.define 'WSI.view.EventDetailsContainer',
  extend: 'Ext.Container'
  xtype: 'eventdetailscontainer'
  id: 'eventdetailscontainer'
  requires: [
    'WSI.view.MediaWall'
  ]
  config:
    layout: 'vbox'
    scrollable:
      direction: 'vertical'
      directionLock: yes
      indicators: no
      momentumEasing:
        momentum:
          acceleration: 15
          friction: 0.99
    eid: null
    eventRecord: null
    
  initialize: ->
    @callParent arguments
    
    @yPivotPoint = 0
    @scrollDirDown = yes
    @lastY = 0
    @lastYCheck = 0
    @mediaPageBusy = no
    @lastYLoadImages = 0
    @mediaPage = 1
    @mediaPageHeight = 5000
    @minItemHeight = 80
    @maxItemHeight = 200
    @maxItemsPerRow = 3
    @mediasPerPage = Math.floor (@mediaPageHeight / @minItemHeight) * @maxItemsPerRow
    @dataSrcs = {}
    @flipbookIntervals = {}
    @isLightboxMode = no
    @getScrollable().getScroller().on
      scrollend: @onScrollEnd
      scroll: @onScroll
      scope: this
      
  destroy: ->
    for i,item of @flipbookIntervals
      clearInterval item.interval
    @flipbookIntervals = {}
    @callParent arguments
  
  onScroll: (scroller, x, y) ->
    pullRefresh = @getAt 0
    if scroller.isTouching
      if y < -75
        pullRefresh.addCls "x-list-pullrefresh-release"
        @refreshOnLetGo = yes
      else
        pullRefresh.removeCls "x-list-pullrefresh-release"
        @refreshOnLetGo = no
    true
    
  onScrollEnd: (scroller, x, y) ->
    if @refreshOnLetGo
      @refreshOnLetGo = no
      Ext.Viewport.setMasked
        xtype: 'loadmask'
        message: ''
      @fireEvent 'refreshForEventDetails'
    else
      if not @mediaPageBusy and Math.abs(@lastYCheck - y) > 100
        @lastYCheck = y
        if scroller.position.y > scroller.maxPosition.y - 150 and @media.length < @getEventRecord().get('num_of_photos') + @getEventRecord().get('num_of_videos') then @loadPage y
      if not scroller.isTouching and Math.abs(@lastYLoadImages-y) > @minItemHeight
        @loadImages y
    true
  
  loadImages: (y) ->
    thumbs = @getAt(2)?.thumbs
    if thumbs? # just in case this was slightly delayed and actually the event details container has been destroyed.
      @lastYLoadImages = y
      topBound = (y - @maxItemHeight) - 50
      bottomBound = y + @scrollerContainerHeight + 500
      for i,thumb of thumbs
        midKey = "mid#{thumb.getAttribute('data-mid')}"
        if thumb.offsetTop > topBound and thumb.offsetTop < bottomBound
          # item is inside loading boundary
          if thumb.classList.contains 'flipbook'
            # it's a video
            if not @flipbookIntervals[midKey]? and Object.keys(@flipbookIntervals).length < 3 # 3 is max number of flipbooks goin at once
              stepper = do (i, midKey) =>=>
                @flipbookStep i, midKey
              @flipbookIntervals[midKey] =
                interval: setInterval stepper, 600
          else
            # it's a photo or it's an uploading/processing video (which are presented as static thumb images)
            if thumb.style.backgroundImage is ''
              @dataSrcs[midKey] ?= thumb.getAttribute 'data-src' # if the image url is not is our dataSrcs caching object, then add transfer it from the DOM to it
              thumb.style.backgroundImage = "url(#{@dataSrcs[midKey]})"
        else
          # item is outside loading boundary
          if thumb.classList.contains 'flipbook'
            # it's a video that is loaded, and therefore in 'flipbook' mode
            # since it is outside the boundary we kill any flipbook interval occuring (to save resources)
            if @flipbookIntervals[midKey]?
              clearInterval @flipbookIntervals[midKey].interval
              delete @flipbookIntervals[midKey].interval
              delete @flipbookIntervals[midKey]
  
  loadPage: (y) ->
    @mediaPageBusy = yes
    @getAt(3).setHidden no
    Ext.defer (-> # defer this to give time to be masked
      Ext.Ajax.request
        url: 'http://wesawit.com/event/get_media_page'
        params:
          token: window.localStorage.getItem 'wsitoken'
          uid: window.localStorage.getItem 'uid'
          eid: @getEventRecord().get('id')
          start: @media.length
          limit: 100
        timeout: 30000
        method: 'GET'
        scope: this
        success: (response) ->
          r = Ext.JSON.decode response.responseText
          for i in r.medias
            i.status = 'loaded'
            i.event_id = i.aeid
            arr = i.timestampTaken.split /[- :\.]/ # needs to be converted to a Date
            i.timestampTaken = new Date()
            i.timestampTaken.setUTCFullYear parseInt(arr[0])
            i.timestampTaken.setUTCMonth parseInt(arr[1]) - 1
            i.timestampTaken.setUTCDate parseInt(arr[2])
            i.timestampTaken.setUTCHours parseInt(arr[3])
            i.timestampTaken.setUTCMinutes parseInt(arr[4])
            i.timestampTaken.setUTCSeconds parseInt(arr[5])
            if i.pid?
              i.url = null
              i.mediumUrl = null
              if i.thumbUrl isnt ''
                i.url = i.thumbUrl.slice(0, -5) + '7.jpg'
                i.mediumUrl = i.thumbUrl.slice(0, -5) + '6.jpg'
              else
                i.url = null
                i.mediumUrl = null
                i.thumbUrl = null
            @media.push i
          @getAt(2).getStore().setData @media
          @getAt(3).setHidden yes
          @mediaPageBusy = no
        failure: ->
          @getAt(3).setHidden yes
    ), 50, this
  
  flipbookStep: (i, midKey) ->
    # the interval may have been destroyed, so make sure we still have 'thumbs'
    # if the interval was destroy then this would be the last function call
    thumb = @getAt(2)?.thumbs?[i]
    if thumb?
      pages = thumb.getElementsByTagName 'IMG'
      nextPageToShow = 0
      for p of pages
        if pages[p].classList.contains 'show'
          pages[p].classList.remove 'show'
          nextPageToShow = parseInt(p) + 1
          if nextPageToShow > pages.length - 1 then nextPageToShow = 0
          if pages[nextPageToShow].complete is false then nextPageToShow = 0
          break
      if nextPageToShow < pages.length - 1 # preload next image that will be shown
        if pages[nextPageToShow + 1].src.indexOf('#') isnt -1
          pages[nextPageToShow + 1].src = pages[nextPageToShow + 1].getAttribute 'data-src'
      pages[nextPageToShow].classList.add 'show'
        
  changeEvent: (record, scrollToTop = true) ->  # scrollToTop doesn't do anything anymore
    @setEventRecord record
        
    # aggregate media and sort it chronologically
    @media = record.get('photos').concat record.get('videos')
    @media = @media.sort (x, y) -> y.timestampTaken - x.timestampTaken
    
    # determine average (mean) number of likes of the media for this event
    meanWorthiness = 0
    wcSum = 0
    wcCount = 0
    for m,media of @media
      wcSum += parseInt(media.worthinessCount)
      wcCount++
    meanWorthiness = wcSum / wcCount
    
    mediaWall =
      xtype: 'mediawall'
      id: 'mediawall'
      flex: 0
      margin: 0
      padding: '5 0 50 5'
      flipbookIntervalArrayRef: @flipbookIntervals
      store:
        data: @media
        model: 'WSI.model.Media'
      emptyText: if record.get('photos').length + record.get('videos').length is 0 then [
        "<div class='empty-text' style='text-align: center'>"
          "No photos or videos have been added yet."
          "<br /><br />Be the first to upload what you see!"
        "</div>"
      ].join ''
      meanWorthiness: meanWorthiness
      listeners:
        refresh: (c) ->
          edc = c.up() # edc is short of Event Details Container
          edc.scrollerContainerHeight = edc.getScrollable().getScroller().container.dom.clientHeight
          c.thumbs = c.bodyElement.query '.media-item'
          Ext.defer (->
            edc.loadImages edc.getScrollable().getScroller().position.y
            edc.setMasked false
          ), 50
    
    numWhosThere = record.get 'num_whosthere'
    tenseToBe = util.getTenseOfToBe record.get('dateTimeStart'), record.get('dateTimeEnd'), numWhosThere is 1
    
    pullRefresh =
      xtype: 'component'
      snappingAnimationDuration: 150
      translatable: true
      isRefreshing: false
      currentViewState: ""
      html: [
        '<div class="x-list-pullrefresh">',
            '<div class="x-list-pullrefresh-wrap">',
                '<img src="resources/images/tarsier.png" width="45" height="24" />',
            '</div>',
        '</div>',
        "<div class='x-list-emptytext' style='display:none;'></div>"
      ].join ''
      refreshFn: (plugin) ->
        if not navigator.onLine
          navigator.notification.alert 'Unable to connect to the internet.', (()->return), 'Oops!'
        else
          Ext.Viewport.setMasked
            xtype: 'loadmask'
            message: ''
          plugin.up().fireEvent 'refreshForEventDetails'
        return false
    
    @add [
      pullRefresh
      {
        xtype: 'container'
        baseCls: 'event-details'
        cls: [
          'hide-description'
        ]
        layout: 'vbox'
        scrollable: no
        flex: 0
        items: [
          { # event details (textual info at the top)
            xtype: 'component'
            flex: 0
            style: 'font-family: GillSans, HelveticaNeue, Helvetica;'
            html: [
              "<span class='event-fact event-fact-date'>#{Ext.util.Format.date(record.get('dateTimeStart'), 'j M Y')}</span>"
              "<span class='event-fact event-fact-time'>#{Ext.util.Format.date(record.get('dateTimeStart'), 'g:i a')}</span>"
              "<span class='event-fact event-fact-info'>Info</span>"
              "<div class='event-details-description' style='clear: left;'>"
                if record.get('description') isnt '' then record.get('description')
                if record.get('description') isnt '' and record.get('category') isnt '' then "<br />"
                if record.get('category') isnt '' then "<small>Category: "+record.get('category')+"</small>"
                if record.get('description') is '' and record.get('category') is '' then '<span style="font-style:italic;">No description available.</span>'
              "</div>"
              "<span class='event-fact event-fact-location' style='clear: left;'>#{if distance = window.util.calc_distance(record.get('locationLat'), record.get('locationLng')) then distance else ""} #{record.get('locationName') + ', ' + record.get('locationVicinity')}</span>"
            ].join ''
            listeners:
              tap:
                element: 'element'
                fn: (e) ->
                  if e.target.classList.contains 'event-fact-info'
                    if @up().element.classList.indexOf('hide-description') isnt -1
                      @up().removeCls 'hide-description'
                    else
                      @up().addCls 'hide-description'
                  else if e.target.classList.contains 'event-fact-location'
                    mapsFn = (buttonIndex) =>
                      if buttonIndex is 2
                        if Ext.os.is.Android
                          window.location = 'geo:0,0?q=' + encodeURIComponent( record.get('locationName') + ', ' + record.get('locationVicinity') )
                        else
                          window.location = 'maps:q=' + record.get('locationLat') + ',' + record.get('locationLng')
                    navigator.notification.confirm 'View event location in Maps app?', mapsFn, 'Leaving WeSawIt', 'No,Yes'
          }
          { # those buttons underneath the description
            xtype: 'container'
            flex: 0
            padding: 5
            layout: 'hbox'
            pack: 'center'
            align: 'center'
            items: [
              {
                xtype: 'container'
                layout: 'vbox'
                flex: 0
                margin: '0 15 0 -5'
                html: '<div class="form-group-toggle upload">Upload</div>'
                listeners:
                  tap:
                    element: 'element'
                    fn: (e) ->
                        @up().up().up().fireEvent 'mediaLibraryButtonTap', true # true for 'skipDetermineTargetId'
                        #ga_storage._trackEvent 'UI', 'Upload From Library Button', "Event #{parseInt(record.get('id'))}"
              }
              {
                xtype: 'container'
                layout: 'vbox'
                flex: 1
                margin: '0 -5 0 0'
                html: "<div class='form-group-toggle who#{if numWhosThere > 999 then ' long-text' else ''}'>#{if tenseToBe? then util.commaize_number(numWhosThere) + ' ' + tenseToBe + ' there' else 'Who\'s there?'}</div>"
                listeners:
                  tap:
                    element: 'element'
                    fn: (e) ->
                      @up().up().up().fireEvent 'whosThereButtonTap', record
                      #ga_storage._trackEvent 'UI', 'Whos There Button', "Event #{parseInt(record.get('id'))}"
              }
            ]
          }
        ]
      }
      mediaWall
      {
        xtype: 'component'
        baseCls: Ext.baseCSSPrefix + 'list-paging'
        hidden: true
        html: """
          <div class="#{Ext.baseCSSPrefix}loading-spinner" style="top: -40px; margin: 0px auto; display: block;">
            <span class="#{Ext.baseCSSPrefix}loading-top"></span>
            <span class="#{Ext.baseCSSPrefix}loading-right"></span>
            <span class="#{Ext.baseCSSPrefix}loading-bottom"></span>
            <span class="#{Ext.baseCSSPrefix}loading-left"></span>
          </div>
        """
      }
    ]