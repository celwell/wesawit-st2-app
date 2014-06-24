Ext.define 'WSI.controller.Events',
  extend: 'Ext.app.Controller'
  requires: [
    'Ext.Carousel'
    'WSI.view.ImageViewer'
    'WSI.view.EventDetailsContainer'
    'WSI.view.WhosThereContainer'
    'WSI.view.CreateEventForm'
    'WSI.view.WhereContainer'
    'WSI.view.WhenContainer'
  ]
  config:
    refs:
      mainContainer: 'maincontainer'
      accountPanel: 'account'
      activityPanel: 'activity'
      followingPanel: 'following'
      eventsListContainer: 'eventslistcontainer'
      eventsListPresent: '#eventslistpresent'
      eventsListPast: '#eventslistpast'
      eventsListFuture: '#eventslistfuture'
      eventsListSearch: '#eventslistsearch'
      browseTab: '#browseTab'
      eventDetailsContainer: 'eventdetailscontainer'
      whosThereContainer: '#whostherecontainer'
      mediaStrip: 'mediastrip'
      mediaWall: 'mediawall'
      gallery: '#gallery'
      createEventForm: 'createeventform'
      topToolbar: 'toptoolbar'
      topToolbarHomeButton: 'toptoolbar #homeButton'
      createEventButton: '#createEventButton'
      moreActionsButton: '#moreActionsButton'
      sliderMenu: '#sliderMenu'
      whereContainer: 'wherecontainer'
      whenContainer: 'whencontainer'
      askAlreadyExistsPanel: '#askalreadyexistspanel'
      askAddToPanel: '#askaddtopanel'
    control:
      mainContainer:
        grabCurrentPosition: 'grabCurrentPosition'
      activityPanel:
        deleteRecord: 'deleteRecord'
        viewEventCommand: 'onViewEventCommand'
      followingPanel:
        viewEventCommand: 'onViewEventCommand'
      eventsListContainer:
        viewEventCommand: 'onViewEventCommand'
        accountCommand: 'onAccountCommand'
        hideTopToolbarHomeButton: 'hideTopToolbarHomeButton'
        showTopToolbarHomeButton: 'showTopToolbarHomeButton'
        hideCreateEventButton: 'hideCreateEventButton'
        showCreateEventButton: 'showCreateEventButton'
        hideMoreActionsButton: 'hideMoreActionsButton'
        showMoreActionsButton: 'showMoreActionsButton'
        showLoading: 'showLoading'
        hideLoading: 'hideLoading'
        refreshMap: 'refreshMap'
        resetTopToolbarTitle: 'resetTopToolbarTitle'
        revertTopToolbarTitle: 'revertTopToolbarTitle'
        populateUiForSearch: 'populateUiForSearch'
        captureMediaButtonTap: 'initCaptureMedia'
      eventsList:
        grabCurrentPosition: 'grabCurrentPosition'
      topToolbar:
        homeButtonTap: 'onHomeButtonTap'
        createEventButtonTap: 'showNewEventForm'
        moreActionsButtonTap: 'showMoreActions'
      eventDetailsContainer:
        newCommentSubmit: 'onNewCommentSubmit'
        flagMedia: 'flagMedia'
        refreshForEventDetails: 'refreshForEventDetails'
        mediaLibraryButtonTap: 'openMediaLibrary'
        whosThereButtonTap: 'openWhosThere'
        shareButtonTap: 'shareMedia'
      mediaStrip:
        openGallery: 'openGallery'
      mediaWall:
        openGallery: 'openGallery'
      whosThereContainer:
        focusOnPhoto: 'openGallery'
      createEventForm:
        createEventFormSubmit: 'createEventFormSubmit'
        onApplyListOfCategories: 'onApplyListOfCategories'
        showWhereContainer: 'showWhereContainer'
        showWhenContainer: 'showWhenContainer'
        newEventChooseLocation: 'newEventChooseLocation'
        newEventChooseTimeInfo: 'newEventChooseTimeInfo'
        generateSuggestions: 'generateSuggestions'
        homeButtonTap: 'onHomeButtonTap'
      whereContainer:
        newEventChooseLocation: 'newEventChooseLocation'
        generateSuggestions: 'generateSuggestions'
      whenContainer:
        newEventChooseTimeInfo: 'newEventChooseTimeInfo'
    listOfCategories: null
    targetEid: false # target of uploads of media
    targetRecord: false
    uploadMediaFileUponNextViewEvent: null
    
  mediaAddQueue: {} # keeps track of what medias need to be "added" (since the upload is async and in native code)
  
  launch: ->
    @callParent arguments
    
    window.launchEndTime = new Date()
    
    @reinstateDynamicLists()
    
    setTimeout (->navigator.splashscreen?.hide()), 350
    setTimeout (Ext.bind @delayedTasksAfterLaunch, this), 3000
    
  delayedTasksAfterLaunch: ->
    
    @clearGpsLocation 15000
    
    onResume = Ext.bind (->
        timeoutTillRemoveSplash = 0
        if not @pauseDueToPluginIntent
          setTimeout (Ext.bind (->
            @refreshForEventDetails()
            Ext.data.StoreManager.each ->
              # reload all the stores that have been loaded at least once and have a load that is at least 60 seconds old
              if @isLoaded() and (not @lastTimeLoadCalled? or (new Date()).getTime() - @lastTimeLoadCalled.getTime() > 60000)
                @load()
                timeoutTillRemoveSplash = 3500
            @clearGpsLocation 15000
          ), this), 750
        else
          @pauseDueToPluginIntent = no
        setTimeout (->navigator.splashscreen?.hide()), timeoutTillRemoveSplash
      ), this
    document.addEventListener "resume", onResume, false
    
    onPause = Ext.bind (->
        navigator.splashscreen?.show()
      ), this
    document.addEventListener "pause", onPause, false
    
    if Ext.os.is.iOS
      iosToolbar = cordova?.require 'cordova/plugin/keyboard_toolbar_remover'
      iosToolbar?.hide()
      window.flurry.startSession "---REMOVED---", (->), (->)
      @checkForNewAppVersion()
      
    if Ext.os.is.Android
      onBackButton = Ext.bind (->
        @onHomeButtonTap()
      ), this
      document.addEventListener "backbutton", onBackButton, false
    
    ###
    domLength = ->
      console.log 'dom length: ' + document.getElementsByTagName('*').length # if dom length gets up around 1500 or more, that's pretty bad. we want it under 1000 if possible.
    setInterval domLength, 2000
    ###
    
  checkForNewAppVersion: ->
    Ext.Ajax.request
      url: "http://wesawit.com/app/current_version/ios"
      method: 'GET'
      success: (response) ->
        v1 = util.APP_VERSION.split(".") # local version
        v2 = response.responseText.split(".") # version from server
        v1[0] ?= 0
        v2[0] ?= 0
        v1[1] ?= 0
        v2[1] ?= 0
        v1[2] ?= 0
        v2[2] ?= 0
        needToUpdate = no
        if parseInt(v1[0]) < parseInt(v2[0])
          needToUpdate = yes
        else if parseInt(v1[0]) is parseInt(v2[0])
          if parseInt(v1[1]) < parseInt(v2[1])
            needToUpdate = yes
          else if parseInt(v1[1]) is parseInt(v2[1])
            if parseInt(v1[2]) < parseInt(v2[2])
              needToUpdate = yes
        if needToUpdate
          confFn = (buttonIndex) ->
            if buttonIndex is 2
              window.location = 'https://itunes.apple.com/app/id544946196' # use direct itunes link instead of the wesawit.com redirector because then it would open mobile safari and then itunes, rather than directly itunes
            else
              console.log 'canceld'
          navigator.notification.confirm '', confFn, 'A new version is available!', 'Ignore,Download'
        
  
  # maxAge should be int/milliseconds
  clearGpsLocation: (maxAge = -1, refreshPosition = yes) ->
    if not window.localStorage.getItem('locationTimestamp')? or window.localStorage.getItem('locationTimestamp') is '' or (new Date()) - new Date(window.localStorage.getItem('locationTimestamp')) > maxAge
      window.localStorage.setItem 'locationLat', '0'
      window.localStorage.setItem 'locationLng', '0'
      window.localStorage.setItem 'locationTimestamp', ''
      if refreshPosition
        @grabCurrentPosition()
  
  onHomeButtonTap: ->
    unless @getTopToolbarHomeButton().config.busyHandling # this switch doesn't seem to be very effective. need to listen till handling is truly finished before setting the switch to false
      @getTopToolbarHomeButton().config.busyHandling = yes
      switch @getTopToolbarHomeButton().config.dest
        when 'to-home-from-details'
          @getTopToolbarHomeButton().hide()
          @getMoreActionsButton().hide()
          @resetTopToolbarTitle()
          @getCreateEventButton()?.show()
          @getBrowseTab().setActiveItem 0
          @getBrowseTab().remove @getEventDetailsContainer(), true
        when 'to-details-from-gallery'
          @getTopToolbarHomeButton().config.dest = 'to-home-from-details'
          @getMainContainer().remove @getGallery(), true
          @getEventDetailsContainer().loadImages @getEventDetailsContainer().getScrollable().getScroller().position.y # otherwise we may end end with blacksquare for a mediawall upon return from gallery view
          @getMoreActionsButton().show()
        when 'to-whosthere-from-gallery'
          @getTopToolbarHomeButton().config.dest = 'to-details-from-whosthere'
          @getMainContainer().remove @getGallery(), true
          @getMoreActionsButton().show()
        when 'to-details-from-whosthere'
          @setEventTitle @getEventDetailsContainer().getEventRecord()
          @getTopToolbarHomeButton().config.dest = 'to-home-from-details'
          @getBrowseTab().setActiveItem @getEventDetailsContainer()
          @getBrowseTab().remove @getWhosThereContainer(), true
          @getMoreActionsButton().show()
          Ext.getStore('WhosThere').removeAll()
        when 'to-home-from-create'
          # it's a misnomer, could mean 'to-details-from-create'
          @getMainContainer().remove @getCreateEventForm(), true
          if @getGallery()?
            @getMainContainer().setActiveItem @getGallery()
            @getTopToolbarHomeButton().config.dest = 'to-details-from-gallery'
            @getTopToolbarHomeButton().show()
            @getMoreActionsButton()?.show()
            @setEventTitle @getEventDetailsContainer().getEventRecord()
            @getMoreActionsButton().show()
          else if @getEventDetailsContainer()? and @getBrowseTab().getActiveItem() is @getEventDetailsContainer()
            @getTopToolbarHomeButton().config.dest = 'to-home-from-details'
            @getTopToolbarHomeButton().show()
            @setEventTitle @getEventDetailsContainer().getEventRecord()
            @getMoreActionsButton().show()
          else if @getWhosThereContainer()? and @getBrowseTab().getActiveItem() is @getWhosThereContainer()
            @getTopToolbarHomeButton().config.dest = 'to-details-from-whosthere'
            @getTopToolbarHomeButton().show()
            @setEventTitle @getEventDetailsContainer().getEventRecord()
            @getMoreActionsButton().show()
          else
            @getTopToolbarHomeButton().hide()
            @resetTopToolbarTitle()
            @getCreateEventButton()?.show()
        when 'to-create-from-where'
          @getTopToolbarHomeButton().config.dest = 'to-home-from-create'
          @getTopToolbarHomeButton().hide()
          @getMainContainer().remove @getWhereContainer(), true
          @getMainContainer().setActiveItem @getCreateEventForm()
          @getTopToolbar().setTitle "<div class='full-title'>New Event</div>"
        when 'to-create-from-when'
          @getTopToolbarHomeButton().config.dest = 'to-home-from-create'
          @getTopToolbarHomeButton().hide()
          @getMainContainer().remove @getWhenContainer(), true
          @getMainContainer().setActiveItem @getCreateEventForm()
          @getTopToolbar().setTitle "<div class='full-title'>New Event</div>"
        when 'to-create-from-alreadyexists'
          @getTopToolbarHomeButton().config.dest = 'to-home-from-create'
          @getTopToolbarHomeButton().hide()
          Ext.Viewport.setMasked false
          Ext.Viewport.remove @getAskAlreadyExistsPanel(), true # "alreadyexists/askPanel" modal panel, remove it
          @getMainContainer().setActiveItem @getCreateEventForm()
          @getTopToolbar().setTitle "<div class='full-title'>New Event</div>"
    @getTopToolbarHomeButton().config.busyHandling = no
  
  showWhereContainer: ->
    @getTopToolbarHomeButton().config.dest = 'to-create-from-where'
    @getTopToolbarHomeButton().show()
    @getTopToolbar().setTitle "<div class='full-title'>Where</div>"
    @getMainContainer().setActiveItem Ext.create('WSI.view.WhereContainer')
  
  showWhenContainer: ->
    @getTopToolbarHomeButton().config.dest = 'to-create-from-when'
    @getTopToolbarHomeButton().show()
    @getTopToolbar().setTitle "<div class='full-title'>When</div>"
    @getMainContainer().setActiveItem Ext.create('WSI.view.WhenContainer')
  
  hideTopToolbarHomeButton: ->
    @getTopToolbarHomeButton()?.hide()
  
  showTopToolbarHomeButton: ->
    @getTopToolbarHomeButton()?.show()
    
  hideMoreActionsButton: ->
    @getMoreActionsButton()?.hide()
  
  showMoreActionsButton: ->
    @getMoreActionsButton()?.show()
  
  showMoreActions: ->
    ctrl = this
    if Ext.os.is.Android
      window.plugins.actionSheet.create(
        {
          title: ctrl.getEventDetailsContainer()?.getEventRecord()?.get('title').replace('&amp;', '&')
          items: [
            if ctrl.getEventDetailsContainer()?.getEventRecord()?.get('bookmarked_by_me') then 'Stop following this event' else 'Follow this event'
            'Share via Facebook'
            'Share via Email'
            'Report as inappropriate'
            'Cancel'
          ]
          destructiveButtonIndex: 3
          cancelButtonIndex: 4
        },
        (value, index) ->
          switch index
            when 0
              ctrl.bookmarkEvent()
            when 1
              ctrl.shareMedia ctrl, 'event', ctrl.getEventDetailsContainer()?.getEventRecord(), 'facebook'
            when 2
              ctrl.shareMedia ctrl, 'event', ctrl.getEventDetailsContainer()?.getEventRecord(), 'email'
            when 3
              ctrl.flagEvent ctrl.getEventDetailsContainer()?.getEventRecord()
            when 4
              true
      )
    else
      window.plugins.actionSheet.create(
        {
          title: ctrl.getEventDetailsContainer()?.getEventRecord()?.get('title').replace('&amp;', '&')
          items: [
            if ctrl.getEventDetailsContainer()?.getEventRecord()?.get('bookmarked_by_me') then 'Stop following this event' else 'Follow this event'
            'Share via Facebook'
            'Share via Twitter'
            'Share via Email'
            'Report as inappropriate'
            'Cancel'
          ]
          destructiveButtonIndex: 4
          cancelButtonIndex: 5
        },
        (value, index) ->
          switch index
            when 0
              ctrl.bookmarkEvent()
            when 1
              ctrl.shareMedia ctrl, 'event', ctrl.getEventDetailsContainer()?.getEventRecord(), 'facebook'
            when 2
              ctrl.shareMedia ctrl, 'event', ctrl.getEventDetailsContainer()?.getEventRecord(), 'twitter'
            when 3
              ctrl.shareMedia ctrl, 'event', ctrl.getEventDetailsContainer()?.getEventRecord(), 'email'
            when 4
              ctrl.flagEvent ctrl.getEventDetailsContainer()?.getEventRecord()
            when 5
              true
      )
    
  showMoreActionsMedia: (type, record) ->
    ctrl = this
    if Ext.os.is.Android
      window.plugins.actionSheet.create(
        {
          title: "#{type[0].toUpperCase() + type.substr(1)} of " + ctrl.getEventDetailsContainer()?.getEventRecord()?.get('title').replace('&amp;', '&')
          items: [
            'Share via Facebook'
            'Share via Email'
            'Report as inappropriate'
            'Cancel'
          ]
          destructiveButtonIndex: 2
          cancelButtonIndex: 3
        },
        (value, index) ->
          switch index
            when 0
              ctrl.shareMedia ctrl, type, record, 'facebook'
            when 1
              ctrl.shareMedia ctrl, type, record, 'email'
            when 2
              ctrl.flagMedia type, record
            when 3
              true
      )
    else
      window.plugins.actionSheet.create(
        {
          title: "#{type[0].toUpperCase() + type.substr(1)} of " + ctrl.getEventDetailsContainer()?.getEventRecord()?.get('title').replace('&amp;', '&')
          items: [
            'Share via Facebook'
            'Share via Twitter'
            'Share via Email'
            'Report as inappropriate'
            'Cancel'
          ]
          destructiveButtonIndex: 3
          cancelButtonIndex: 4
        },
        (value, index) ->
          switch index
            when 0
              ctrl.shareMedia ctrl, type, record, 'facebook'
            when 1
              ctrl.shareMedia ctrl, type, record, 'twitter'
            when 2
              ctrl.shareMedia ctrl, type, record, 'email'
            when 3
              ctrl.flagMedia type, record
            when 4
              true
      )
  
  hideCreateEventButton: ->
    @getCreateEventButton()?.hide()
  
  showCreateEventButton: ->
    @getCreateEventButton()?.show()
  
  refreshForEventDetails: () ->
    if @getEventDetailsContainer()?
      Ext.Ajax.request
        url: 'http://wesawit.com/event/get_media_page'
        params:
          token: window.localStorage.getItem 'wsitoken'
          uid: window.localStorage.getItem 'uid'
          eid: @getEventDetailsContainer().getEventRecord().get('id')
          start: 0
          limit: 100
        timeout: 30000
        method: 'GET'
        scope: this
        success: (response) ->
          if @getEventDetailsContainer()? # do we still have the event detials container (they may have pressed the back button while it was loading from  the server)
            r = Ext.JSON.decode response.responseText
            if @getEventDetailsContainer().getEventRecord().get('outdated') is yes
              @getEventDetailsContainer().getEventRecord().set 'outdated', no
            @getEventDetailsContainer().media = new Array()
            for i in r.medias
              i.status = 'loaded'
              i.event_id = i.aeid
              arr = i.timestampTaken.split /[- :\.]/ # needs to be converted to a Date
              i.timestampTaken = new Date()
              i.timestampTaken.setUTCSeconds parseInt(arr[5])
              i.timestampTaken.setUTCMinutes parseInt(arr[4])
              i.timestampTaken.setUTCHours parseInt(arr[3])
              i.timestampTaken.setUTCDate parseInt(arr[2])
              i.timestampTaken.setUTCMonth parseInt(arr[1]-1)
              i.timestampTaken.setUTCFullYear parseInt(arr[0])
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
              @getEventDetailsContainer().media.push i
            if @getEventDetailsContainer().media.length is 0
              @getEventDetailsContainer().getAt(2).getStore().removeAll()
            else
              @getEventDetailsContainer().getAt(2).getStore().setData @getEventDetailsContainer().media
            @getMediaWall().refreshItemTpl()
            @getMediaWall().refresh()
          Ext.Viewport.setMasked false # unmask it either way... this has to be outside of the above conditional because the function could  error out on undefined @getEventDetailsContainer and then we will never unmask
        failure: ->
          console.log 'failed to refresh event details contianrer'
          Ext.Viewport.setMasked false
    else
      # there is no event details container (they must hve pressed the home button or something while it was handling this function)
      # make sure it doesn't get left with a mask because event details pull refresh masks the viewport while it is loading
      Ext.Viewport.setMasked false
          
  bookmarkEvent: ->
    if @getEventDetailsContainer()?.getEventRecord()?
      if not window.localStorage.getItem('wsitoken')?
        @getTopToolbarHomeButton().setHidden true
        @getMoreActionsButton().hide()
        @getEventsListContainer().setActiveItem 3
        @getMainContainer().setActiveItem 0
      else
        Ext.Viewport.setMasked
          xtype: 'loadmask'
          message: ''
        record = @getEventDetailsContainer().getEventRecord()
        Ext.Ajax.request
          url: "http://wesawit.com/event/bookmark/#{record.get('id')}"
          method: 'POST'
          params:
            'token': window.localStorage.getItem 'wsitoken'
            'uid': window.localStorage.getItem 'uid'
            'unbookmark': record.get 'bookmarked_by_me'
          timeout: 7000
          success: (response) ->
            Ext.Viewport.setMasked false
            resp = Ext.decode response.responseText
            if resp.success
              record.set 'bookmarked_by_me', not record.get('bookmarked_by_me')
              navigator.notification.alert "#{if record.get('bookmarked_by_me') then 'Started' else 'Stopped'} following this event", (()->return), "#{record.get('title').replace('&amp;', '&')}"
            else
              navigator.notification.alert 'Session has expired, please log out and log in again.', (()->return), 'Oops!'
          failure: (response) ->
            Ext.Viewport.setMasked false
            if response.timedout? and response.timedout
              navigator.notification.alert 'Your internet connection seems to be going too slow.', (()->return), 'Hmm...'
            else
              navigator.notification.alert 'Please try again later.', (()->return), 'Oops!'
          scope: this
          
  setEventTitle: (record) ->
    @getTopToolbar().addCls 'hide-logo'
    @topToolbarLastTitle = record.get('title')
    if @topToolbarLastTitle.length > 30
      @getTopToolbar().addCls 'long-title'
    else
      @getTopToolbar().removeCls 'long-title'
    @getTopToolbar().setTitle @topToolbarLastTitle
    
  onViewEventCommand: (legacyPlaceholderIgnore, record, scrollToTop = true) ->
    if not @getEventDetailsContainer()?
      eventDetailsContainer = Ext.create 'WSI.view.EventDetailsContainer'
      eventDetailsContainer.changeEvent record, scrollToTop
    else if @getEventDetailsContainer().getEventRecord().get('id') isnt record.get('id')
      @getEventDetailsContainer().destroy()
      eventDetailsContainer = Ext.create 'WSI.view.EventDetailsContainer'
      eventDetailsContainer.changeEvent record, scrollToTop
    @getWhosThereContainer()?.destroy()
    @getTopToolbarHomeButton().config.dest = 'to-home-from-details'
    @getTopToolbarHomeButton().show()
    @getMoreActionsButton()?.show()
    @getCreateEventButton()?.hide()
    @setEventTitle record
    @getMainContainer().setActiveItem @getEventsListContainer()
    @getBrowseTab().setActiveItem eventDetailsContainer
    @getEventsListContainer().setActiveItem @getBrowseTab()
    # report this as a view
    viewReportFn = ->
      Ext.Ajax.request
        url: "http://wesawit.com/event/report_a_view/#{record.get('id')}/event"
        method: 'GET'
        params:
          'token': window.localStorage.getItem('wsitoken') ? ''
          'uid': window.localStorage.getItem('uid') ? ''
    setTimeout viewReportFn, 3000
    
    if @getUploadMediaFileUponNextViewEvent()?
      if @tempRecordOfNewEvent is record # was event that was just created
        imageURI = @getUploadMediaFileUponNextViewEvent().imageURI
        mediaType = @getUploadMediaFileUponNextViewEvent().mediaType
        metadata = @getUploadMediaFileUponNextViewEvent().metadata
        mediumURI = @getUploadMediaFileUponNextViewEvent().mediumURI
        thumbURI = @getUploadMediaFileUponNextViewEvent().thumbURI
        mid = @getUploadMediaFileUponNextViewEvent().mid

        mediaStrip = @getMediaWall()
        entry =
          id: mid
          pid: null
          vid: null
          aeid: record.get 'id'
          event_id: record.get 'id'
          worthinessCount: 0
          deemed_worthy_by_me: false
          flagCount: 0
          flagged_by_me: false
          author: window.localStorage.getItem 'username'
          authorUid: window.localStorage.getItem 'uid'
          url: imageURI ? 'resources/images/placeholder.jpg'
          thumbUrl: thumbURI ? 'resources/images/placeholder.jpg'
          mediumUrl: mediumURI ? 'resources/images/placeholder.jpg'
          status: 'uploading'
          timestampTaken: @getDateTimeFromMetadata(metadata, yes) ? new Date()
        if mediaType is 'photo'
          entry.pid = mid
          entry.vid = null
        else
          entry.pid = null
          entry.vid = mid
        if @getEventDetailsContainer()?
          @getEventDetailsContainer().media.unshift entry
          @getEventDetailsContainer().getAt(2).getStore().setData @getEventDetailsContainer().media
          mediaStrip.refreshItemTpl()
          mediaStrip.refresh()
        if @mediaAddQueue[''+mid]?['video_status'] is 'loaded' or ( @mediaAddQueue[''+mid]?['econ_status'] is 'loaded' and @mediaAddQueue[''+mid]?['thumb_status'] is 'loaded' )
          @addMedia record, mid, mediaType, metadata, @mediaAddQueue[''+mid]['fileExt']
        else
          @mediaAddQueue[''+mid]['targetEventRecord'] = record
          @mediaAddQueue[''+mid]['metadata'] = metadata
      @setUploadMediaFileUponNextViewEvent null
    
    if record.get('outdated') is yes
      @refreshForEventDetails()
  
  geolocationSuccess: (position) ->
    window.localStorage.setItem 'locationLat', position.coords.latitude
    window.localStorage.setItem 'locationLng', position.coords.longitude
    #window.localStorage.setItem 'locationAlt', position.coords.altitude
    window.localStorage.setItem 'locationTimestamp', new Date()
    @getEventsListPresent()?.refresh()
    @getEventsListPast()?.refresh()
    @getEventsListFuture()?.refresh()
    @getEventsListSearch()?.refresh()
  
  geolocationError: (error) ->
    if util.DEBUG then console.log 'geolocation error'
    return true
  
  milesBetweenCoords: (latA, lngA, latB, lngB) ->
    latDiffMiles = (latA - latB) * 68.88
    lngDiffMiles = (lngA - lngB) * 59.95
    Math.sqrt latDiffMiles * latDiffMiles + lngDiffMiles * lngDiffMiles
  
  isMetadataOk: (metadata, record) ->
    if metadata.locationData? and metadata.locationData.lat isnt 0
      if 1 > @milesBetweenCoords metadata.locationData.lat, metadata.locationData.lng, record.get('locationLat'), record.get('locationLng')
        # location is fine, but can we check time too?
        if metadata['{Exif}']? or metadata['Exif']?
          # yes we can check time, let's do it
          metadata['{Exif}'] ?= metadata['Exif'] # android uses the version without the {Exif} just Exif (for json compatibility reasons)
          # check the time also to see if that makes sense too:
          eventDateTimeStart = new Date record.get('dateTimeStart').getTime() - (12*60*60*1000) # 12 hours after event
          eventDateTimeEnd = new Date record.get('dateTimeEnd').getTime() + (12*60*60*1000) # 12 hours before event
          metadataDateTime = null
          if metadata['{Exif}']['DateTimeOriginal']? and metadata['{Exif}']['DateTimeOriginal'] isnt '0000-00-00 00:00:00'
            metadataDateTime = metadata['{Exif}']['DateTimeOriginal']
          else if metadata['{Exif}']['DateTimeDigitized']? and metadata['{Exif}']['DateTimeDigitized'] isnt '0000-00-00 00:00:00'
            metadataDateTime = metadata['{Exif}']['DateTimeDigitized']
          if metadataDateTime?
            metadataDateTimeDateObj = new Date metadataDateTime.replace(' ', 'T')
            return eventDateTimeStart < metadataDateTimeDateObj and eventDateTimeEnd > metadataDateTimeDateObj
          else
            return true
        else
          # we couldn't check time, but the location seems fine, so it's OK
          return true
      else
        # we had location info but it was not OK (not within the limitation spatially)
        return false
    # perhaps we can go by just time info
    if metadata['{Exif}']? or metadata['Exif']?
      metadata['{Exif}'] ?= metadata['Exif'] # android uses the version without the {Exif} just Exif (for json compatibility reasons)
      # check the time also to see if that makes sense too:
      eventDateTimeStart = new Date record.get('dateTimeStart').getTime() - (12*60*60*1000) # 12 hours after event
      eventDateTimeEnd = new Date record.get('dateTimeEnd').getTime() + (12*60*60*1000) # 12 hours before event
      metadataDateTime = null
      if metadata['{Exif}']['DateTimeOriginal']? and metadata['{Exif}']['DateTimeOriginal'] isnt '0000-00-00 00:00:00'
        metadataDateTime = metadata['{Exif}']['DateTimeOriginal']
      else if metadata['{Exif}']['DateTimeDigitized']? and metadata['{Exif}']['DateTimeDigitized'] isnt '0000-00-00 00:00:00'
        metadataDateTime = metadata['{Exif}']['DateTimeDigitized']
      if metadataDateTime?
        metadataDateTimeDateObj = new Date metadataDateTime.replace(' ', 'T')
        # we didn't have location data, but we do have time data. let's make sure it falls within the limitations of the event
        return eventDateTimeStart < metadataDateTimeDateObj and eventDateTimeEnd > metadataDateTimeDateObj
      else
        # no time data either. oh well, this bypasses the check and is considered OK
        return true
    else
      # no time data either. oh well, this bypasses the check and is considered OK
      return true
  
  # Flow to determine target eid
  # tell server the media loc
  # --> response from server is either of determinationType 'certain' or 'uncertain'
  # --> if certain then that's the eid we use. if uncertain then user is presented with choices to choose from and ability to create a new event.
  determineTargetEid: (imageURI, metadata = null, mediumURI = null, thumbURI = null, mid = null) ->
    ctrl = this
    
    if localStorage.getItem('locationLat')? and localStorage.getItem('locationLng')?
      mediaType = ctrl.mediaAddQueue[''+mid]?['mediaType'] ? 'photo'
      Ext.Ajax.request
        url: "http://wesawit.com/event/determine_target_eid"
        method: 'GET'
        params:
          'timestampTaken': ctrl.convertDateToMySqlFormat new Date() # that convert func also makes it UTC
          'locationLatOfMedia': localStorage.getItem 'locationLat'
          'locationLngOfMedia': localStorage.getItem 'locationLng'
        success: (response) ->
          obj = Ext.decode response.responseText
          if obj.success
            if obj.determinationType is 'certain'
              # no need to ask user to decide, we know which event we want to put this at
              record = Ext.create 'WSI.model.Event', obj.events[0]
              ctrl.onViewEventCommand null, record
              mediaStrip = ctrl.getMediaWall()
              entry =
                id: mid
                aeid: record.get 'id'
                event_id: record.get 'id'
                worthinessCount: 0
                deemed_worthy_by_me: false
                flagCount: 0
                flagged_by_me: false
                author: window.localStorage.getItem 'username'
                authorUid: window.localStorage.getItem 'uid'
                url: imageURI ? 'resources/images/placeholder.jpg'
                thumbUrl: thumbURI ? 'resources/images/placeholder.jpg'
                mediumUrl: mediumURI ? 'resources/images/placeholder.jpg'
                status: 'uploading'
                timestampTaken: ctrl.getDateTimeFromMetadata(metadata, yes) ? new Date()
              if mediaType is 'photo'
                entry.pid = mid
                entry.vid = null
              else
                entry.pid = null
                entry.vid = mid
              if ctrl.getEventDetailsContainer()?
                ctrl.getEventDetailsContainer().media.unshift entry
                ctrl.getEventDetailsContainer().getAt(2).getStore().setData ctrl.getEventDetailsContainer().media
                mediaStrip.refreshItemTpl()
                mediaStrip.refresh()
              mediaInQueue = ctrl.mediaAddQueue[''+mid]
              if mediaInQueue['mediaType'] is 'photo' and
                mediaInQueue['econ_status'] is 'loaded' and
                mediaInQueue['medium_status'] is 'loaded' and
                mediaInQueue['thumb_status'] is 'loaded' and
                mediaInQueue['canceled'] isnt yes
                  ctrl.addMedia record, mid, mediaType, metadata, mediaInQueue['fileExt']
              else if mediaInQueue['mediaType'] is 'video' and
                mediaInQueue['video_status'] is 'loaded' and
                mediaInQueue['canceled'] isnt yes
                  ctrl.addMedia record, mid, mediaType, metadata, mediaInQueue['fileExt']
              else
                mediaInQueue['targetEventRecord'] = record
                mediaInQueue['metadata'] = metadata
              Ext.Viewport.setMasked false
            else if obj.events.length is 0
              confFn = (buttonIndex) ->
                Ext.Viewport.setMasked false
                if buttonIndex is 2
                  ctrl.setUploadMediaFileUponNextViewEvent
                    'imageURI': imageURI
                    'mediaType': mediaType
                    'metadata': metadata
                    'thumbURI': thumbURI
                    'mid': mid
                  ctrl.showNewEventForm()
                else
                  ctrl.mediaAddQueue[''+mid]['canceled'] = yes
                  if ctrl.getEventsListContainer().config.lastActiveTabBeforeCaptureActionSheetShown?
                    ctrl.getEventsListContainer().getTabBar().setActiveTab ctrl.getEventsListContainer().config.lastActiveTabBeforeCaptureActionSheetShown
              navigator.notification.confirm '', confFn, 'No events happening around you.', 'Cancel,Create Event'
            else
              # ask user to decide from the possible choices
              suggestedEventsList =
                xtype: 'eventslist'
                itemHeight: 125
                store: Ext.create('Ext.data.Store',
                  model: 'WSI.model.Event'
                  data: obj.events
                )
                emptyText: 'No events near you right now.'
                flex: 1
                plugins: false
                style:
                  background: '#f0f0f0'
                  borderRadius: '4px'
                  paddingTop: '5px'
                  padding: '0px 0px 10px 0px'
                  margin: '5px 0px 0px 0px'
                listeners:
                  itemtap: (list, index, target, record, e, eOpts) ->
                    ctrl.revertTopToolbarTitle()
                    ctrl.getTopToolbarHomeButton().show()
                    ctrl.getMainContainer().remove ctrl.getAskAddToPanel(), true
                    ctrl.onViewEventCommand null, record
                    mediaStrip = ctrl.getMediaWall()
                    entry =
                      id: mid
                      aeid: record.get 'id'
                      event_id: record.get 'id'
                      worthinessCount: 0
                      deemed_worthy_by_me: false
                      flagCount: 0
                      flagged_by_me: false
                      author: window.localStorage.getItem 'username'
                      authorUid: window.localStorage.getItem 'uid'
                      url: imageURI ? 'resources/images/placeholder.jpg'
                      thumbUrl: thumbURI ? 'resources/images/placeholder.jpg'
                      mediumUrl: mediumURI ? 'resources/images/placeholder.jpg'
                      status: 'uploading'
                      timestampTaken: ctrl.getDateTimeFromMetadata(metadata, yes) ? new Date()
                    if mediaType is 'photo'
                      entry.pid = mid
                      entry.vid = null
                    else
                      entry.pid = null
                      entry.vid = mid
                    if ctrl.getEventDetailsContainer()?
                      ctrl.getEventDetailsContainer().media.unshift entry
                      ctrl.getEventDetailsContainer().getAt(2).getStore().setData ctrl.getEventDetailsContainer().media
                      mediaStrip.refreshItemTpl()
                      mediaStrip.refresh()
                    mediaInQueue = ctrl.mediaAddQueue[''+mid]
                    if mediaInQueue['mediaType'] is 'photo' and
                      mediaInQueue['econ_status'] is 'loaded' and
                      mediaInQueue['medium_status'] is 'loaded' and
                      mediaInQueue['thumb_status'] is 'loaded' and
                      mediaInQueue['canceled'] isnt yes
                        ctrl.addMedia record, mid, mediaType, metadata, mediaInQueue['fileExt']
                    else if mediaInQueue['mediaType'] is 'video' and
                      mediaInQueue['video_status'] is 'loaded' and
                      mediaInQueue['canceled'] isnt yes
                        ctrl.addMedia record, mid, mediaType, metadata, mediaInQueue['fileExt']
                    else
                      mediaInQueue['targetEventRecord'] = record
                      mediaInQueue['metadata'] = metadata
                    Ext.Viewport.setMasked false
              askAddToPanel =
                xtype: 'panel'
                id: 'askaddtopanel'
                cls: 'ask-panel-list'
                style: 'border-radius:0px;background:#444;'
                fullscreen: true
                layout: 'vbox'
                modal: true
                top: 0
                width: '100%'
                height: '100%'
                pack: 'center'
                align: 'center'
                items: [
                  {
                    xtype: 'component'
                    flex: 0
                    docked: 'top'
                    html: '<strong style="font-weight:bold;">Choose an event below to add your ' + mediaType + ' to:</strong>'
                    padding: '5 0 5 0'
                    style: 'font-size: 14px; color: white;'
                  }
                  {
                    xtype: 'container'
                    style:
                      background: '#f0f0f0'
                      borderRadius: '4px'
                    layout: 'vbox'
                    flex: 1
                    padding: '0 0 4 0'
                    items: [
                      suggestedEventsList
                    ]
                  }
                  {
                    xtype: 'container'
                    padding: '10 0 5 0'
                    flex: 0
                    height: 62
                    layout: 'hbox'
                    pack: 'center'
                    items: [
                      {
                        xtype: 'component'
                        flex: 0
                        padding: '0 10 0 0'
                        html: '<div class="form-group-toggle">Cancel</div>'
                        listeners:
                          tap:
                            element: 'element'
                            fn: (e) ->
                              if ctrl.getEventsListContainer().config.lastActiveTabBeforeCaptureActionSheetShown?
                                ctrl.getEventsListContainer().getTabBar().setActiveTab ctrl.getEventsListContainer().config.lastActiveTabBeforeCaptureActionSheetShown
                              ctrl.getMainContainer().remove ctrl.getAskAddToPanel(), true
                      }
                      {
                        xtype: 'component'
                        flex: 1
                        html: '<div class="form-group-toggle" style="text-align:center;">Or, create an event</div>'
                        listeners:
                          tap:
                            element: 'element'
                            fn: (e) ->
                              ctrl.getMainContainer().remove ctrl.getAskAddToPanel(), true
                              ctrl.setUploadMediaFileUponNextViewEvent
                                'imageURI': imageURI
                                'mediaType': mediaType
                                'metadata': metadata
                                'thumbURI': thumbURI
                                'mid': mid
                              ctrl.showNewEventForm()
                      }
                    ]
                  }
                ]
              ctrl.getTopToolbar().addCls 'hide-logo'
              ctrl.getTopToolbar().setTitle "<div class='full-title'>Add #{mediaType}</div>"
              ctrl.getMainContainer().add askAddToPanel
              Ext.Viewport.setMasked false
          else
            navigator.notification.alert 'Error #537.', (()->return), 'Error'
        failure: (response) ->
          navigator.notification.alert 'Connection error. Please try again or upload using the Upload button on an event page.', (()->return), 'Error'
    else
      navigator.notification.alert 'GPS Location is required to add media. Please go to your home screen and choose Settings -> Privacy -> Location Services. On that page, make sure the "Location Services" is ON and "WeSawIt" is ON.', (()->return), 'Oops!'
      if ctrl.getEventsListContainer().config.lastActiveTabBeforeCaptureActionSheetShown?
        ctrl.getEventsListContainer().getTabBar().setActiveTab ctrl.getEventsListContainer().config.lastActiveTabBeforeCaptureActionSheetShown
      ctrl.mediaAddQueue[''+mid]['canceled'] = yes
    
  initCaptureMedia: ->
    if not window.localStorage.getItem('wsitoken')?
      # not logged in
      @getTopToolbarHomeButton().setHidden true
      @getEventsListContainer().setActiveItem 3
      @getMainContainer().setActiveItem 0
      navigator.notification.alert '', (()->return), 'Please log in'
    else
      Ext.Viewport.setMasked
        xtype: 'loadmask'
        message: ''
      @grabCurrentPosition()
      captureMediaSuccessCallback = Ext.bind @captureMediaSuccess, this
      errorCallback = Ext.bind @captureError, this
      # since I've modified .captureVideo in phonegap. this is now a misnomer. it does photo and video
      if Ext.os.is.Android then @pauseDueToPluginIntent = yes
      navigator.device.capture.captureVideo captureMediaSuccessCallback, errorCallback, {limit: 1}
      
  openMediaLibrary: (skipDetermineTargetId = false) ->
    if not window.localStorage.getItem('wsitoken')?
      # not logged in
      @getTopToolbarHomeButton().setHidden true
      @getEventsListContainer().setActiveItem 3
      @getMainContainer().setActiveItem 0
      navigator.notification.alert '', (()->return), 'Please log in'
    else
      Ext.Viewport.setMasked
        xtype: 'loadmask'
        message: ''
      @grabCurrentPosition()
      librarySuccessCallback = Ext.bind @captureLibrarySuccess, this
      errorCallback = Ext.bind @captureError, this
      if Ext.os.is.Android then @pauseDueToPluginIntent = yes
      navigator.camera.getPicture librarySuccessCallback, errorCallback, { quality: 20, correctOrientation: true, sourceType : Camera.PictureSourceType.PHOTOLIBRARY, mediaType: Camera.MediaType.ALLMEDIA, destinationType: Camera.DestinationType.FILE_URI }
  
  captureMediaSuccess: (mediaFiles) ->
    #console.log mediaFiles
    for i,file of mediaFiles # right now, there is always just one element in this mediaFiles array
      @mediaAddQueue[''+file.mid] ?= {}
      mid = file.mid
      mediaType = file.mediaType
      mediaInQueue = @mediaAddQueue[''+file.mid]
      mediaInQueue['mediaType'] ?= file.mediaType
      if not @blacklistedMids? or not @blacklistedMids[mid]? or not @blacklistedMids[mid]
        if mediaInQueue['mediaType'] is 'video' and file.fileExt?
          mediaInQueue['fileExt'] = file.fileExt
        if file.status is 'loaded'
          mediaInQueue['econ_status'] = 'loaded'
          mediaInQueue['video_status'] = 'loaded'
        if file.statusMedium is 'loaded'
          mediaInQueue['medium_status'] = 'loaded'
        if file.statusThumb is 'loaded'
          mediaInQueue['thumb_status'] = 'loaded'
        if file.typeOfPluginResult is 'initialRecordInformer'
          if mediaInQueue['mediaType'] is 'photo'
            @determineTargetEid file.filePath, null, file.filePathMedium, file.filePathThumb, file.mid
          else if mediaInQueue['mediaType'] is 'video'
            @determineTargetEid file.filePathMedium, null, file.filePathMedium, file.filePathThumb, file.mid
        else if file.typeOfPluginResult is 'progress'
          if file.uploadType is 'main' #pretend that main is the only upload that exists as far as progress is concerned (the others go fast)
            percentComplete = Math.floor 100 * parseInt(file.totalBytesWritten) / parseInt(file.totalBytesExpectedToWrite)
            #console.log file.mid + ' progress %' + percentComplete
            document.getElementById("progress-bar-#{mid}")?.style.width = "#{percentComplete}%"
        else if file.typeOfPluginResult is 'success'
          if mediaInQueue['targetEventRecord']?
            if mediaInQueue['mediaType'] is 'photo' and
                mediaInQueue['econ_status'] is 'loaded' and
                mediaInQueue['medium_status'] is 'loaded' and
                mediaInQueue['thumb_status'] is 'loaded' and
                mediaInQueue['canceled'] isnt yes
              @addMedia mediaInQueue['targetEventRecord'], file.mid, mediaInQueue['mediaType'], null, mediaInQueue['fileExt']
            else if mediaInQueue['mediaType'] is 'video' and
                mediaInQueue['video_status'] is 'loaded' and
                mediaInQueue['canceled'] isnt yes
              @addMedia mediaInQueue['targetEventRecord'], file.mid, mediaInQueue['mediaType'], null, mediaInQueue['fileExt']
        else if file.typeOfPluginResult is 'failure'
          @blacklistedMids ?= {}
          @blacklistedMids[mid] = yes
          navigator.notification.alert "Sorry, #{mediaType} upload failed.", (()->return), 'Oops!'
          if @getEventDetailsContainer()?
            # find in array and remove
            medias = @getEventDetailsContainer().media
            indexToRemove = null
            for m,media of medias
              if media.id is mid
                indexToRemove = m
            if indexToRemove?
              @getEventDetailsContainer().media.splice indexToRemove, 1
              @getEventDetailsContainer().getAt(2).getStore().setData @getEventDetailsContainer().media
              @getMediaWall()?.refreshItemTpl()
              @getMediaWall()?.refresh()
  
  captureLibrarySuccess: (mediaFiles) ->
    Ext.Viewport.setMasked false
    #console.log mediaFiles
    for i,file of mediaFiles # there is always just one element in this mediaFiles array
      @mediaAddQueue[''+file.mid] ?= {}
      mid = file.mid
      mediaType = file.mediaType
      mediaInQueue = @mediaAddQueue[''+file.mid]
      mediaInQueue['mediaType'] ?= file.mediaType
      mediaInQueue['targetEventRecord'] ?= @getEventDetailsContainer()?.getEventRecord() or @tempRecordOfNewEvent
      if not mediaInQueue['targetEventRecord']?
        console.log 'captureLibrarySuccess error: record is not defined ~line #905' 
      else
        if not @blacklistedMids? or not @blacklistedMids[mid]? or not @blacklistedMids[mid]
          if mediaInQueue['mediaType'] is 'video' and file.fileExt? then mediaInQueue['fileExt'] = file.fileExt
          if file.status is 'loaded'
            mediaInQueue['econ_status'] = 'loaded'
            mediaInQueue['video_status'] = 'loaded'
          if file.statusMedium is 'loaded' then mediaInQueue['medium_status'] = 'loaded'
          if file.statusThumb is 'loaded' then mediaInQueue['thumb_status'] = 'loaded'
          if file.metadataJson?
            metadata = Ext.decode file.metadataJson
          if file.metadataDateTime?
            metadata = {}
            metadata['{Exif}'] = {}
            metadata['{Exif}']['DateTimeOriginal'] = file.metadataDateTime
            metadata['{Exif}']['DateTimeDigitized'] = file.metadataDateTime
          if not metadata? or @isMetadataOk(metadata, mediaInQueue['targetEventRecord'])
            if file.typeOfPluginResult is 'initialRecordInformer'
              # just add it visibly to the mediastrip and show it as loading
              mediaStrip = @getMediaWall()
              entry =
                id: mid
                pid: null
                vid: null
                aeid: mediaInQueue['targetEventRecord'].get 'id'
                event_id: mediaInQueue['targetEventRecord'].get 'id'
                worthinessCount: 0
                deemed_worthy_by_me: false
                flagCount: 0
                flagged_by_me: false
                author: window.localStorage.getItem 'username'
                authorUid: window.localStorage.getItem 'uid'
                url: file.filePath ? 'resources/images/placeholder.jpg'
                thumbUrl: file.filePathThumb ? 'resources/images/placeholder.jpg'
                mediumUrl: file.filePathMedium ? 'resources/images/placeholder.jpg'
                status: 'uploading'
                timestampTaken: @getDateTimeFromMetadata(metadata, yes) ? new Date()
              if mediaType is 'photo'
                entry.pid = mid
                entry.vid = null
              else
                entry.pid = null
                entry.vid = mid
              if @getEventDetailsContainer()?
                @getEventDetailsContainer().media.unshift entry
                @getEventDetailsContainer().getAt(2).getStore().setData @getEventDetailsContainer().media
                mediaStrip.refreshItemTpl()
                mediaStrip.refresh()
            else if file.typeOfPluginResult is 'progress'
              if file.uploadType is 'main' #pretend that main is the only upload that exists as far as progress is concerned (the others go fast)
                percentComplete = Math.floor 100 * parseInt(file.totalBytesWritten) / parseInt(file.totalBytesExpectedToWrite)
                #console.log file.mid + ' progress %' + percentComplete
                document.getElementById("progress-bar-#{mid}")?.style.width = "#{percentComplete}%"
            else if file.typeOfPluginResult is 'success'
              if mediaInQueue['mediaType'] is 'photo' and
                mediaInQueue['econ_status'] is 'loaded' and
                mediaInQueue['medium_status'] is 'loaded' and
                mediaInQueue['thumb_status'] is 'loaded' and
                mediaInQueue['canceled'] isnt yes
                  @addMedia mediaInQueue['targetEventRecord'], file.mid, mediaInQueue['mediaType'], null, mediaInQueue['fileExt']
              else if mediaInQueue['mediaType'] is 'video' and
                mediaInQueue['video_status'] is 'loaded' and
                mediaInQueue['canceled'] isnt yes
                  @addMedia mediaInQueue['targetEventRecord'], file.mid, mediaInQueue['mediaType'], null, mediaInQueue['fileExt']
            else if file.typeOfPluginResult is 'failure'
              @blacklistedMids ?= {}
              @blacklistedMids[mid] = yes
              navigator.notification.alert "Sorry, #{mediaType} upload failed.", (()->return), 'Oops!'
              if @getEventDetailsContainer()?
                # find in array and remove
                medias = @getEventDetailsContainer().media
                indexToRemove = null
                for m,media of medias
                  if media.id is mid
                    indexToRemove = m
                if indexToRemove?
                  @getEventDetailsContainer().media.splice indexToRemove, 1
                  @getEventDetailsContainer().getAt(2).getStore().setData @getEventDetailsContainer().media
                  @getMediaWall()?.refreshItemTpl()
                  @getMediaWall()?.refresh()
          else
            @blacklistedMids ?= {}
            @blacklistedMids[mid] = yes
            navigator.notification.alert "Sorry, that #{mediaType} doesn't seem to be of this event.", (()->return), 'Oops!'
  
  captureError: (error) ->
    ctrl = this
    if ctrl.getBrowseTab().getActiveItem() is ctrl.getEventDetailsContainer()
      ctrl.getTopToolbarHomeButton().show()
      ctrl.revertTopToolbarTitle()
    else
      ctrl.resetTopToolbarTitle()
      if ctrl.getEventsListContainer().getActiveItem() is ctrl.getBrowseTab()
        ctrl.showCreateEventButton()
    if @getEventsListContainer().config.lastActiveTabBeforeCaptureActionSheetShown?
      @getEventsListContainer().getTabBar().setActiveTab @getEventsListContainer().config.lastActiveTabBeforeCaptureActionSheetShown
    Ext.Viewport.setMasked false
    #console.log error
    if error.code? and error.code isnt '3' and error.code isnt 3  # if they didn't simply press Cancel
      navigator.notification.alert "Unable to use camera.", (()->return), 'Oops!'
    
  getDateTimeFromMetadata: (metadata, asDateObj = no) ->
    if metadata? and ( metadata['{Exif}']? or metadata['Exif']? )
      metadata['{Exif}'] ?= metadata['Exif']
      if metadata['{Exif}']['DateTimeOriginal']? and metadata['{Exif}']['DateTimeOriginal'] isnt '0000-00-00 00:00:00'
        metadataDateTime = metadata['{Exif}']['DateTimeOriginal']
      else if metadata['{Exif}']['DateTimeDigitized']? and metadata['{Exif}']['DateTimeDigitized'] isnt '0000-00-00 00:00:00'
        metadataDateTime = metadata['{Exif}']['DateTimeDigitized']
      if metadataDateTime? and asDateObj then new Date metadataDateTime.replace(' ', 'T')
      else metadataDateTime
    else null
    
  # add media record into database
  addMedia: (targetRecord, mid, mediaType, metadata = null, fileExt = '') ->
    ajaxParams =
      token: window.localStorage.getItem 'wsitoken'
      uid: window.localStorage.getItem 'uid'
      file_ext: fileExt
      api_version: util.API_VERSION
    ajaxParams["#{mediaType}_id"] = mid
    
    if metadata?.locationData? and metadata.locationData.lat isnt 0
      ajaxParams.locationLat = metadata.locationData.lat
      ajaxParams.locationLng = metadata.locationData.lng
    else
      ajaxParams.locationLat = if window.localStorage.getItem('locationLat')? then window.localStorage.getItem('locationLat') else '0'
      ajaxParams.locationLng = if window.localStorage.getItem('locationLng')? then window.localStorage.getItem('locationLng') else '0'
      
    ajaxParams.timestampTaken = @convertDateToMySqlFormat ( @getDateTimeFromMetadata(metadata, yes) ? new Date() ) # that convert func also makes it UTC
    
    Ext.Ajax.request
      url: "http://wesawit.com/event/add_#{mediaType}/#{targetRecord.get 'id'}"
      method: 'GET'
      params: ajaxParams
      scope: this
      success: (response, opts) ->
        obj = Ext.decode response.responseText
        if obj.success
          if mediaType is 'photo'
            @getMediaWall()?.getStore()?.getById(mid)?.set 'status', 'loaded'
            @getMediaWall()?.refresh()
            targetRecord.set 'outdated', yes
          else if mediaType is 'video'
            if @getEventDetailsContainer()?
              # find in array and remove
              medias = @getEventDetailsContainer().media ? new Array()
              indexToRemove = null
              for m,media of medias
                if media.id is mid
                  indexToRemove = m
              if indexToRemove?
                @getEventDetailsContainer().media.splice indexToRemove, 1
                if @getEventDetailsContainer().media.length is 0
                  # setData seemsto not work if the array you are setting it to is empty, so in that case use removeAll to clean out the store (rather than setting it to an empty array)
                  @getEventDetailsContainer().getAt(2).getStore().removeAll()
                else
                  @getEventDetailsContainer().getAt(2).getStore().setData @getEventDetailsContainer().media
                @getMediaWall().refreshItemTpl()
                @getMediaWall().refresh()
            targetRecord.set 'outdated', yes
            navigator.notification.alert 'Your video has been uploaded, but it may take a minute before everyone can see it.', (()->return), 'Video Uploaded'
        else
          navigator.notification.alert 'Sorry, upload failed. Please log out and then log back in and try again.', (()->return), 'Oops!'
      failure: (response, opts) ->
        obj = Ext.decode response.responseText
        navigator.notification.alert 'Sorry, upload failed. Please log out and then log back in and try again.', (()->return), 'Oops!'
    
  openWhosThere: (record) ->
    whosThereContainer = Ext.create 'WSI.view.WhosThereContainer'
    whosThereContainer.changeWhosThere record
    @getTopToolbarHomeButton().config.dest = 'to-details-from-whosthere'
    @getBrowseTab().setActiveItem whosThereContainer
    
  showNewEventForm: ->
    # if logged in...
    if window.localStorage.getItem('wsitoken')?
      @grabCurrentPosition()
      @getCreateEventButton()?.hide()
      @getTopToolbarHomeButton()?.hide()
      @getMoreActionsButton()?.hide()
      @getTopToolbarHomeButton()?.config.dest = 'to-home-from-create'
      @getTopToolbar().addCls 'hide-logo'
      @getTopToolbar().setTitle "<div class='full-title'>New Event</div>"
      if @getCreateEventForm()?
        @getMainContainer().remove @getCreateEventForm(), true
      createEventForm = Ext.create 'WSI.view.CreateEventForm'
      @populateUi()
      @getMainContainer().setActiveItem createEventForm
      #ga_storage._trackEvent "UI", "Load Create Event Form", "Logged In: True"
    else # not logged in
      @getTopToolbarHomeButton().setHidden true
      @getEventsListContainer().setActiveItem 3
      @getMainContainer().setActiveItem 0
      #ga_storage._trackEvent "UI", "Load Create Event Form", "Logged In: False"
      navigator.notification.alert '', (()->return), 'Please log in'
      
  createEventFormSubmit: ->
    event = @getCreateEventForm().config.eventData
    if event.title is ''
      navigator.notification.alert '"Title" is a required field.', (()->return), 'Oops!'
      return
    if event.locationName is '' or event.locationName is 'Loading...' or event.locationName is '<div class="x-loading-spinner-outer" style="margin-top: 0px;"><div class="x-loading-spinner" style="margin: 0px auto; font-size: 18px !important;"><span class="x-loading-top"></span><span class="x-loading-right"></span><span class="x-loading-bottom"></span><span class="x-loading-left"></span></div></div>'
      navigator.notification.alert '"Where" is a required field.', (()->return), 'Oops!'
      return
    if event.dateTimeStart is ''
      navigator.notification.alert '"When" is a required field.', (()->return), 'Oops!'
      return
    Ext.Viewport.setMasked
      xtype: 'loadmask'
      message: ''
    
    # get lat lng if needed
    if event.reference isnt '' and ( event.locationLat is '0' or event.locationLng is '0' or not event.locationType? or event.locationType is '')
      if not document.placesService?
        document.placesService = new google.maps.places.PlacesService(document.getElementsByClassName('x-map')[0])
      that = this
      document.placesService.getDetails { 'reference': event.reference },
        (placeResult, placeServiceStatus) ->
          if placeServiceStatus is google.maps.places.PlacesServiceStatus.OK and placeResult.geometry?.location?
            event.locationLat = placeResult.geometry.location.lat()
            event.locationLng = placeResult.geometry.location.lng()
            event.locationType = placeResult.types[0]
            that.checkIfEventExists event
    else
      @checkIfEventExists event
    
  checkIfEventExists: (event) ->
    ctrl = this
    
    if event.locationLat isnt '0' and event.locationLng isnt '0'
      country = 'within:1:of:' + event.locationLat + ':' + event.locationLng
    else
      country = 'world'
    dateTimeStart = new Date event.dateTimeStart.getTime()
    dateTimeEnd = new Date event.dateTimeEnd.getTime()
    dateTimeStart.setHours( dateTimeStart.getHours() - 12 )
    dateTimeEnd.setHours( dateTimeEnd.getHours() + 12 )
    Ext.Ajax.request
      url: 'http://wesawit.com/event/get_events_mobile'
      params:
        'start': 0
        'limit': 3
        'searchTerm': event.title + ' ' + event.description + ' ' + event.locationName
        'dateTimeStart': dateTimeStart
        'dateTimeEnd': dateTimeEnd
        'country': country
        'sort': 'custom_range'
      timeout: 30000
      method: 'GET'
      success: (response) ->
        resp = Ext.JSON.decode response.responseText
        if resp.events.length is 0
          ctrl.createEvent event
        else
          eventsListAlreadyExists =
            xtype: 'eventslist'
            itemHeight: 159
            flex: 1
            plugins: false
            store:
              data: resp.events
              model: 'WSI.model.Event'
            emptyText: 'Nothing here.'
            style:
              background: '#f0f0f0'
              borderRadius: '4px'
              paddingTop: '5px'
              padding: '0px 0px 10px 0px'
              margin: '5px 0px 0px 0px'
            listeners:
              itemtap: (list, index, target, record, e, eOpts) ->
                Ext.Viewport.setMasked false
                if ctrl.getCreateEventForm()?
                  ctrl.getMainContainer().remove ctrl.getCreateEventForm(), true
                Ext.Viewport.remove ctrl.getAskAlreadyExistsPanel(), true # the modal panel, remove it
                ctrl.onViewEventCommand null, record
          askAlreadyExistsPanel =
            xtype: 'panel'
            id: 'askalreadyexistspanel'
            cls: [
              'ask-panel-list'
              'already-exists'
            ]
            layout: 'vbox'
            modal: true
            top: 0
            width: '100%'
            height: '100%'
            pack: 'center'
            align: 'center'
            style: 'border-radius:0px;background:#444;'
            fullscreen: true
            items: [
              {
                xtype: 'component'
                flex: 0
                docked: 'top'
                html: '<div style="-webkit-mask-image:url(resources/images/warning_black.png);-webkit-mask-repeat:no-repeat;-webkit-mask-position: center right;-webkit-mask-size:60%;float:left;background-color:white;width:40px;height:40px;margin:-3px 13px 0px 0px"></div><strong style="font-weight:bold;">Hmm...<br />Does your event already exist?</strong>'
                padding: '5 0 5 0'
                style: 'font-size: 14px; color: white;'
              }
              {
                xtype: 'container'
                flex: 1
                style:
                  background: '#f0f0f0'
                  borderRadius: '4px'
                padding: '0 0 4 0'
                layout: 'vbox'
                items: [
                  eventsListAlreadyExists
                ]
              }
              {
                xtype: 'container'
                docked: 'bottom'
                height: 50
                padding: '10 0 5 0'
                layout: 'hbox'
                flex: 0
                pack: 'center'
                items: [
                  {
                    xtype: 'container'
                    layout: 'vbox'
                    flex: 0
                    padding: '0 10 0 0'
                    hidden: true
                    html: '<div class="form-group-toggle">Cancel Post</div>'
                    listeners:
                      tap:
                        element: 'element'
                        fn: (e) ->
                          Ext.Viewport.setMasked false
                          Ext.Viewport.remove ctrl.getAskAlreadyExistsPanel(), true # this modal panel, remove it
                          ctrl.getTopToolbarHomeButton().config.dest = 'to-home-from-create'
                          ctrl.onHomeButtonTap()
                  }
                  {
                    xtype: 'container'
                    layout: 'vbox'
                    flex: 1
                    html: '<div class="form-group-toggle create">No, it\'s new. Continue posting it!<img src="resources/images/disclosure-white.png" width="11" height="15" /></div>'
                    listeners:
                      tap:
                        element: 'element'
                        fn: (e) ->
                          Ext.Viewport.setMasked false
                          Ext.Viewport.remove ctrl.getAskAlreadyExistsPanel(), true # this modal panel, remove it
                          ctrl.createEvent event
                  }
                ]
              }
            ]
          ctrl.getTopToolbarHomeButton().config.dest = 'to-create-from-alreadyexists'
          ctrl.getTopToolbarHomeButton().show()
          Ext.Viewport.setMasked false
          Ext.Viewport.add askAlreadyExistsPanel
      failure: ->
        navigator.notification.alert 'Could not create event.', (()->return), 'Oops!'
        Ext.Viewport.setMasked false
  
  twoDigits: (d) ->
    if 0 <= d and d < 10
      "0" + d.toString()
    else if -10 < d and d < 0
      "-0" + (-1*d).toString()
    else
      d.toString()
  
  convertDateToMySqlFormat: (date) ->
    if (typeof date).toLowerCase() is 'object'
      date.getUTCFullYear() + "-" + @twoDigits(1 + date.getUTCMonth()) + "-" + @twoDigits(date.getUTCDate()) + " " + @twoDigits(date.getUTCHours()) + ":" + @twoDigits(date.getUTCMinutes()) + ":" + @twoDigits(date.getUTCSeconds())
    else
      navigator.notification.alert 'Error converting date. Please notify us about this error at contact@wesawit.com. Sorry.', (()->return), 'Oops!'
        
  createEvent: (event) ->
    Ext.Viewport.setMasked
      xtype: 'loadmask'
      message: ''
    Ext.Ajax.request
      url: 'http://wesawit.com/event/create'
      params:
        'api_version': util.API_VERSION
        'token': window.localStorage.getItem 'wsitoken'
        'uid': window.localStorage.getItem 'uid'
        'title': event.title
        'description': event.description
        'dateTimeStart': @convertDateToMySqlFormat event.dateTimeStart
        'dateTimeEnd': @convertDateToMySqlFormat (event.dateTimeEnd ? event.dateTimeStart)
        'locationName': event.locationName ? '' # for nearbySearch this is the 'name' field, for autocomplete this is the first 'term'
        'locationVicinity': event.locationVicinity ? '' # for nearbySearch this is the 'vicinity' field, for autocomplete this is the 'term's after the first term
        'locationLat': event.locationLat ? '0'
        'locationLng': event.locationLng ? '0'
        'locationType': event.locationType ? ''
        'locationReference': event.reference ? '' # a google places reference id
        'category': event.category ? ''
        'userLatAtTimeOfCreation': window.localStorage.getItem('locationLat') ? '0'
        'userLngAtTimeOfCreation': window.localStorage.getItem('locationLng') ? '0'
      timeout: 30000
      method: 'POST'
      scope: this
      success: (response) ->
        Ext.Viewport.setMasked false
        resp = Ext.JSON.decode response.responseText
        # scope/globablize it to @ because determineTargetEid() might need this data later
        @tempRecordOfNewEvent = Ext.create 'WSI.model.Event',
          'id': resp.event.event_id
          'title': resp.event.title
          'description': resp.event.description
          'category': resp.event.category ? ''
          'dateTimeStart': resp.event.dateTimeStart
          'dateTimeEnd': resp.event.dateTimeEnd
          'locationName': resp.event.locationName ? '' # for nearbySearch this is the 'name' field, for autocomplete this is the first 'term'
          'locationVicinity': resp.event.locationVicinity ? '' # for nearbySearch this is the 'vicinity' field, for autocomplete this is the 'term's after the first term
          'locationLat': resp.event.locationLat ? '0'
          'locationLng': resp.event.locationLng ? '0'
          'viewCount': 0
          'bookmarked_by_me': false
          'flagged_by_me': false
          'photos': resp.event.photos
          'videos': resp.event.videos
          'num_whosthere': resp.event.num_whosthere
        @onViewEventCommand null, @tempRecordOfNewEvent
        @getMainContainer().remove @getCreateEventForm(), true
      failure: (response) ->
        Ext.Viewport.setMasked false
        resp = Ext.JSON.decode response.responseText
        navigator.notification.alert resp.error_message, (()->return), 'Error'
        
  newEventChooseLocation: (locationName, locationVicinity = '', locationLat = '0', locationLng = '0', locationType = '', reference = '', autoPressHomeButton = false) ->
    @getCreateEventForm()?.getItems().getAt(2).getItems().getAt(1).setData
      'locationName': locationName
      'locationVicinity': locationVicinity
      'locationLat': locationLat
      'locationLng': locationLng
      'locationType': locationType
      'reference': reference
    if autoPressHomeButton is true
      @onHomeButtonTap()
      
  newEventChooseTimeInfo: (dateTimeStart, dateTimeEnd = '', autoPressHomeButton = false) ->
    @getCreateEventForm().getItems().getAt(3).getItems().getAt(1).setData
      'dateTimeStart': dateTimeStart
      'dateTimeEnd': dateTimeEnd
    if autoPressHomeButton is true
      @onHomeButtonTap()
      
  populateUiForSearch: ->
    if @getListOfCategories()?
      @categories = new Array()
      for cat in @getListOfCategories()
        @categories.push({
          'text': cat
          'value': cat
        })
      @categories.unshift({
        'text': 'All Categories'
        'value': 'all'
      })
      @getBrowseTab().getAt(0).getAt(1).getAt(0).getAt(0).getAt(1).setData @categories
  
  # this one is for the createEventForm
  populateUi: ->
    if @getListOfCategories()?
      @categories = new Array()
      for cat in @getListOfCategories()
        @categories.push({
          'text': cat
          'value': cat
        })
      @getCreateEventForm().getItems().getAt(5).getItems().getAt(0).setData @categories
  
  deleteRecord: (type, record, list = null) ->
    Ext.Viewport.setMasked
      xtype: 'loadmask'
      message: ''
    id = record.get 'id'
    Ext.Ajax.request({
      url: "http://wesawit.com/event/delete/#{id}/#{type}"
      method: 'POST'
      params:
        'token': window.localStorage.getItem 'wsitoken'
        'uid': window.localStorage.getItem 'uid'
      success: (response) ->
        record.destroy()
        if list?
          list.refresh()
        Ext.Viewport.setMasked false
      failure: (response) ->
        if response.timedout? and response.timedout
          navigator.notification.alert 'Your internet connection seems to be going too slow.', (()->return), 'Hmm...'
        else
          navigator.notification.alert 'Could not be deleted.', (()->return), 'Oops!'
        Ext.Viewport.setMasked false
      scope: this
    })
  
  likeMedia: (type, target, mid, mediaRecord, tapListener) ->
    ctrl = this
    if not window.localStorage.getItem('wsitoken')?
      @getTopToolbarHomeButton().setHidden true
      @getEventsListContainer().setActiveItem 3
      @getMainContainer().setActiveItem 0
      @getMainContainer().remove @getGallery(), true
    else
      if target.className.indexOf('liked') is -1 and target.className.indexOf('static-liked') is -1
        Ext.Ajax.request
          url: "http://wesawit.com/event/deem_worthy/#{mid}/#{type}"
          method: 'POST'
          params:
            'token': window.localStorage.getItem 'wsitoken'
            'uid': window.localStorage.getItem 'uid'
          success: (response) ->
            resp = Ext.decode response.responseText
            ctrl.on 'tap', tapListener
            if resp.success
              target.className += ' liked'
              newCount = parseInt(target.nextSibling.textContent) + 1
              target.nextSibling.textContent = newCount # increment the likes count
              mediaRecord.set 'worthinessCount', newCount
              mediaRecord.set 'deemed_worthy_by_me', true
              @getMediaWall()?.refresh()
              @getMediaStrip()?.refresh()
            else if resp.error_message?
              navigator.notification.alert 'Session has expired, please log out and log in again.', (()->return), 'Oops!'
          failure: (response) ->
            ctrl.on 'tap', tapListener
            if response.timedout? and response.timedout
              navigator.notification.alert 'Your internet connection seems to be going too slow.', (()->return), 'Hmm...'
            else
              navigator.notification.alert 'Hmm... idk, you can try again later.', (()->return), 'Oops!'
          scope: this
      else
        Ext.Ajax.request
          url: "http://wesawit.com/event/deem_worthy/#{mid}/#{type}/true" # unlike
          method: 'POST'
          params:
            'token': window.localStorage.getItem 'wsitoken'
            'uid': window.localStorage.getItem 'uid'
          success: (response) ->
            resp = Ext.decode response.responseText
            ctrl.on 'tap', tapListener
            if resp.success
              target.className = 'like-button' # in effect removing the 'liked' class and the 'static-liked' class
              newCount = parseInt(target.nextSibling.textContent) - 1
              target.nextSibling.textContent = newCount # decrement the likes count
              mediaRecord.set 'worthinessCount', newCount
              mediaRecord.set 'deemed_worthy_by_me', false
              @getMediaWall()?.refresh()
              @getMediaStrip()?.refresh()
            else if resp.error_message?
              navigator.notification.alert 'Session has expired, please log out and log in again.', (()->return), 'Oops!'
          failure: (response) ->
            ctrl.on 'tap', tapListener
            if response.timedout? and response.timedout
              navigator.notification.alert 'Your internet connection seems to be going too slow.', (()->return), 'Hmm...'
            else
              navigator.notification.alert 'Hmm... idk, you can try again later.', (()->return), 'Oops!'
          scope: this
          
  shareMedia: (ctrl, type, record, platform = 'facebook') ->
    if not navigator.onLine
      navigator.notification.alert 'Unable to connect to internet.', (()->return), 'Oops!'
    else
      if Ext.os.is.Android
        if platform is 'facebook'
          window.plugins.childBrowser.onLocationChange = (url) ->
            if url.indexOf('redirect_uri') is -1 and ( url.indexOf('%23closeChildBrowser') isnt -1 or url.indexOf('#closeChildBrowser') isnt -1 )
              window.plugins.childBrowser.close()
          switch type
            when 'event'
              fbUrl = [
                "https://www.facebook.com/dialog/feed?"
                "app_id=361157600604985"
                "&link=" + encodeURIComponent "http://wesawit.com/app/event/#{record.get('id')}"
                #"&picture=" + encodeURIComponent "#{window.util.image_url(record.getData(), 'large', yes, no)}"
                "&name=" + encodeURIComponent "#{record.get('title')}"
                "&caption=" + encodeURIComponent "#{Ext.util.Format.date(record.get('dateTimeStart'), 'M. j, Y \\a\\t g:i a')}"
                "&description=" + encodeURIComponent "#{record.get('description')}"
                "&display=touch"
                "&redirect_uri=" + encodeURIComponent "http://wesawit.com/wait#closeChildBrowser"
              ].join ''
            when 'photo'
              fbUrl = [
                "https://www.facebook.com/dialog/feed?"
                "app_id=361157600604985"
                "&link=" + encodeURIComponent "http://wesawit.com/app/event/#{record.get('event_id')}/#{type}/#{record.get('id')}"
                #"&picture=" + encodeURIComponent "#{window.util.image_url(record.getData(), 'large', no, no)}"
                "&name=" + encodeURIComponent "Photo on WeSawIt"
                "&caption=" + encodeURIComponent "#{Ext.util.Format.date(record.get('timestampTaken'), 'M. j, Y \\a\\t g:i a')}"
                #"&description=" + encodeURIComponent "#{record.get('description')}"
                "&display=touch"
                "&redirect_uri=" + encodeURIComponent "http://wesawit.com/wait#closeChildBrowser"
              ].join ''
            when 'video'
              fbUrl = [
                "https://www.facebook.com/dialog/feed?"
                "app_id=361157600604985"
                "&link=" + encodeURIComponent "http://wesawit.com/app/event/#{record.get('event_id')}/#{type}/#{record.get('id')}"
                #"&picture=" + encodeURIComponent "#{window.util.image_url(record.getData(), 'large', no, no)}"
                "&name=" + encodeURIComponent "Video on WeSawIt"
                "&caption=" + encodeURIComponent "#{Ext.util.Format.date(record.get('timestampTaken'), 'M. j, Y \\a\\t g:i a')}"
                #"&description=" + encodeURIComponent "#{record.get('description')}"
                "&display=touch"
                "&redirect_uri=" + encodeURIComponent "http://wesawit.com/wait#closeChildBrowser"
              ].join ''
          window.plugins.childBrowser.showWebPage fbUrl,
            showLocationBar: false
        else if platform is 'email'
          switch type
            when 'event'
              #ga_storage._trackEvent 'Social', 'Share Event via Email', "Event #{parseInt(record.get('id'))}"
              window.location = "mailto:?subject=#{encodeURIComponent record.get('title')}&body=#{encodeURIComponent("Check out this event on WeSawIt: http://wesawit.com/app/event/" + record.get('id'))}"
            when 'photo'
              #ga_storage._trackEvent 'Social', 'Share Photo via Email', "Photo #{parseInt(record.get('id'))}"
              event = ctrl.getEventDetailsContainer().getEventRecord()
              window.location = "mailto:?subject=#{encodeURIComponent 'Photo of ' + event.get('title') + ' WeSawIt'}&body=#{encodeURIComponent("Check out this photo on WeSawIt: http://wesawit.com/app/event/" + event.get('id') + "/photo/" + record.get('id'))}"
            when 'video'
              #ga_storage._trackEvent 'Social', 'Share Video via Email', "Video #{parseInt(record.get('id'))}"
              event = ctrl.getEventDetailsContainer().getEventRecord()
              window.location = "mailto:?subject=#{encodeURIComponent 'Video of ' + event.get('title') + ' WeSawIt'}&body=#{encodeURIComponent("Check out this video on WeSawIt: http://wesawit.com/app/event/" + event.get('id') + "/video/" + record.get('id'))}"
      else
        if platform is 'facebook'
          if not window.localStorage.getItem('wsitoken')? or window.localStorage.getItem('uid').substr(0, 2) isnt 'fb'
            if window.localStorage.getItem('wsitoken')?
              navigator.notification.alert '', (()->return), 'Please log out, then log back in with Facebook.'
            else
              navigator.notification.alert '', (()->return), 'Please log in with Facebook.'
            ctrl.getTopToolbarHomeButton().hide()
            ctrl.getMoreActionsButton().hide()
            ctrl.resetTopToolbarTitle()
            ctrl.getEventsListContainer().setActiveItem 3
            ctrl.getMainContainer().setActiveItem 0
            ctrl.getBrowseTab().setActiveItem 0
            ctrl.getBrowseTab().remove ctrl.getEventDetailsContainer(), true
            if ctrl.getGallery()?
              ctrl.getMainContainer().remove ctrl.getGallery(), true
          else
            switch type
              when 'event'
                dialogOptions =
                  link: "http://wesawit.com/app/event/#{record.get('id')}"
                  name: "#{record.get('title')}"
                  caption: "#{Ext.util.Format.date(record.get('dateTimeStart'), 'M. j, Y \\a\\t g:i a')}"
                  description: "#{record.get('description')}"
              when 'photo'
                event = ctrl.getEventDetailsContainer().getEventRecord()
                dialogOptions =
                  link: "http://wesawit.com/app/event/#{record.get('event_id')}/#{type}/#{record.get('id')}"
                  name: "Photo of \"#{event.get('title')}\" on WeSawIt"
                  caption: "#{Ext.util.Format.date(record.get('timestampTaken'), 'M. j, Y \\a\\t g:i a')}"
              when 'video'
                event = ctrl.getEventDetailsContainer().getEventRecord()
                dialogOptions =
                  link: "http://wesawit.com/app/event/#{record.get('event_id')}/#{type}/#{record.get('id')}"
                  name: "Video of \"#{event.get('title')}\" on WeSawIt"
                  caption: "#{Ext.util.Format.date(record.get('timestampTaken'), 'M. j, Y \\a\\t g:i a')}"

            window.plugins.facebookConnect.initWithAppId "361157600604985", ->
              window.plugins.facebookConnect.dialog 'feed', dialogOptions, (->)
          return true
        else if platform is 'twitter'
          text = ""
          url = ""
          imageUrl = ""
          switch type
            when 'event'
              #ga_storage._trackEvent 'Social', 'Share Event via Twitter', "Event #{parseInt(record.get('id'))}"
              text = "\"#{record.get('title')}\" on @wesawitapp"
              url = "http://wesawit.com/app/event/#{record.get('id')}"
              imageUrl = "#{window.util.image_url(record.getData(), 'large', yes, no)}"
            when 'photo'
              #ga_storage._trackEvent 'Social', 'Share Photo via Twitter', "Photo #{parseInt(record.get('id'))}"
              event = ctrl.getEventDetailsContainer().getEventRecord()
              text = "Photo of \"#{event.get('title')}\" on @wesawitapp"
              url = "http://wesawit.com/app/event/#{record.get('event_id')}/#{type}/#{record.get('id')}"
              imageUrl = "#{window.util.image_url(record.getData(), 'large', no, no)}"
            when 'video'
              #ga_storage._trackEvent 'Social', 'Share Video via Twitter', "Video #{parseInt(record.get('id'))}"
              event = ctrl.getEventDetailsContainer().getEventRecord()
              text = "Video of \"#{event.get('title')}\" on @wesawitapp"
              url = "http://wesawit.com/app/event/#{record.get('event_id')}/#{type}/#{record.get('id')}"
              imageUrl = "#{window.util.image_url(record.getData(), 'large', no, no)}"
          window.plugins.twitter.composeTweet(
            ((s) -> return), 
            ((s) -> return), 
            text, 
            {
              urlAttach: url
              imageAttach: imageUrl
            }
          )
          return true
        else if platform is 'email'
          switch type
            when 'event'
              #ga_storage._trackEvent 'Social', 'Share Event via Email', "Event #{parseInt(record.get('id'))}"
              window.location = "mailto:?subject=#{encodeURIComponent record.get('title')}&body=#{encodeURIComponent("Check out this event on WeSawIt: http://wesawit.com/app/event/" + record.get('id'))}"
            when 'photo'
              #ga_storage._trackEvent 'Social', 'Share Photo via Email', "Photo #{parseInt(record.get('id'))}"
              event = ctrl.getEventDetailsContainer().getEventRecord()
              window.location = "mailto:?subject=#{encodeURIComponent 'Photo of ' + event.get('title') + ' WeSawIt'}&body=#{encodeURIComponent("Check out this photo on WeSawIt: http://wesawit.com/app/event/" + event.get('id') + "/photo/" + record.get('id'))}"
            when 'video'
              #ga_storage._trackEvent 'Social', 'Share Video via Email', "Video #{parseInt(record.get('id'))}"
              event = ctrl.getEventDetailsContainer().getEventRecord()
              window.location = "mailto:?subject=#{encodeURIComponent 'Video of ' + event.get('title') + ' WeSawIt'}&body=#{encodeURIComponent("Check out this video on WeSawIt: http://wesawit.com/app/event/" + event.get('id') + "/video/" + record.get('id'))}"
  
  flagEvent: (record) ->
    if not navigator.onLine
      navigator.notification.alert 'Unable to connect to internet.', (()->return), 'Oops!'
    else
      if not window.localStorage.getItem('wsitoken')?
        @getTopToolbarHomeButton().hide()
        @getMoreActionsButton().hide()
        @resetTopToolbarTitle()
        @getEventsListContainer().setActiveItem 3
        @getMainContainer().setActiveItem 0
        @getBrowseTab().setActiveItem 0
        @getBrowseTab().remove @getEventDetailsContainer(), true
        if @getGallery()?
          @getMainContainer().remove @getGallery(), true
      else
        if record.get('flagged_by_me') is false
          Ext.Ajax.request
            url: "http://wesawit.com/event/flag/#{record.get('id')}/event"
            method: 'POST'
            params:
              'token': window.localStorage.getItem 'wsitoken'
              'uid': window.localStorage.getItem 'uid'
            success: (response) ->
              resp = Ext.decode response.responseText
              if resp.success
                record.set 'flagged_by_me', true
                navigator.notification.alert "Thank you for reporting this event.", (()->return), "#{record.get('title')}"
              else if resp.error_message?
                navigator.notification.alert 'Session has expired, please log out and log in again.', (()->return), 'Oops!'
            failure: (response) ->
              if response.timedout? and response.timedout
                navigator.notification.alert 'Your internet connection seems to be going too slow.', (()->return), 'Hmm...'
              else
                navigator.notification.alert 'Hmm... idk, you can try again later.', (()->return), 'Oops!'
            scope: this
  
  flagMedia: (type, record) ->
    if not navigator.onLine
      navigator.notification.alert 'Unable to connect to internet.', (()->return), 'Oops!'
    else
      if not window.localStorage.getItem('wsitoken')?
        @getTopToolbarHomeButton().hide()
        @getMoreActionsButton().hide()
        @resetTopToolbarTitle()
        @getEventsListContainer().setActiveItem 3
        @getMainContainer().setActiveItem 0
        @getBrowseTab().setActiveItem 0
        @getBrowseTab().remove @getEventDetailsContainer(), true
        if @getGallery()?
          @getMainContainer().remove @getGallery(), true
      else
        if record.get('flagged_by_me') is false
          Ext.Ajax.request
            url: "http://wesawit.com/event/flag/#{record.get('id')}/#{type}"
            method: 'POST'
            params:
              'token': window.localStorage.getItem 'wsitoken'
              'uid': window.localStorage.getItem 'uid'
            success: (response) ->
              resp = Ext.decode response.responseText
              if resp.success
                record.set 'flagged_by_me', true
                navigator.notification.alert "", (()->return), "Thank you for reporting this #{type}."
              else if resp.error_message?
                navigator.notification.alert 'Session has expired, please log out and log in again.', (()->return), 'Oops!'
            failure: (response) ->
              if response.timedout? and response.timedout
                navigator.notification.alert 'Your internet connection seems to be going too slow.', (()->return), 'Hmm...'
              else
                navigator.notification.alert 'Hmm... idk, you can try again later.', (()->return), 'Oops!'
            scope: this
  
  getAndroidVideoBackgroundImage: (media) ->
    if media.get('authorUid') is 'vine'
      media.get 'thumbUrl'
    else
      window.util.image_url media.getData(), 'large'
      
  openGallery: (index, store, dest) ->
    if @getGallery()?
      if util.DEBUG then console.log 'Error: A gallery is already open! Destroying current one first.'
      @getMainContainer().remove @getGallery(), true
    ctrl = this
    medias = store.getData().all
    items = []
    Ext.each medias, (media) ->
      # check if photo or video
      if media.get('pid')? then mediaType = 'photo' else mediaType = 'video'
      if mediaType is 'photo'
        if media.get('author').substr(0,10) is 'instagram_'
          instagram = yes
        else
          instagram = no
        if Ext.os.is.Android
          mediaEntry =
            xtype: 'container'
            mid: media.get 'id'
            aeid: media.get 'event_id'
            mediaType: 'photo'
            style:
              backgroundColor: '#000'
              backgroundImage: "url(#{if media.get('url')? and media.get('url') isnt '' then media.get('url') else "http://wweye1.s3.amazonaws.com/econ_#{media.get 'id'}.jpg"})"
              backgroundSize: 'contain'
              backgroundRepeat: 'no-repeat'
              backgroundPosition: 'center'
            items: [
              {
                xtype: 'component'
                docked: 'bottom'
                height: 50
                html: [
                  "<div class='photos-carousel-details' style='text-align:left;'>"
                  "  <div class='photos-carousel-likes'><div class='like-button#{if media.get('deemed_worthy_by_me') then ' static-liked' else ''}'></div>#{media.get('worthinessCount').toString().replace /(\d)(?=(\d\d\d)+(?!\d))/g, "$1,"}</div>"
                  "  <div class='share-button'></div>"
                  "  <div class='photos-carousel-author'>#{if instagram then media.get('author').substr(10) else media.get('author')}#{if instagram then ' <small>via instagram</small>' else ''}<br />#{window.util.calc_time(media.get('timestampTaken'))}</div>"
                  "</div>"
                ].join('')
              }
            ]
            listeners:
              tap:
                element: 'element'
                fn: (e) ->
                  that = @
                  if e.target.className.indexOf('like-button') isnt -1
                    ctrl.un 'tap', that # disable until ajax request completed
                    ctrl.likeMedia 'photo', e.target, @config.mid, media, that
                  else if e.target.className is 'photos-carousel-likes' and e.target.childNodes[0].className.indexOf('like-button') isnt -1
                    ctrl.un 'tap', that # disable until ajax request completed
                    ctrl.likeMedia 'photo', e.target.childNodes[0], @config.mid, media, that
                  else if e.target.className.indexOf('share-button') isnt -1
                    ctrl.showMoreActionsMedia 'photo', media
        else
          mediaEntry =
            xtype: 'imageviewer'
            style:
              backgroundColor: '#000'
            initOnActivate: false
            loadingMessage: ''
            loadingMask: true
            imageSrc: if media.get('url')? and media.get('url') isnt '' then media.get('url') else "http://wweye1.s3.amazonaws.com/econ_#{media.get 'id'}.jpg"
            mid: media.get 'id'
            aeid: media.get 'aeid'
            mediaType: 'photo'
            html: [
              "<figure><img></figure>"
            ].join ''
            items: [
              {
                xtype: 'component'
                docked: 'bottom'
                height: 50
                html: [
                  "<div class='photos-carousel-details' style='text-align:left;'>"
                  "  <div class='photos-carousel-likes'><div class='like-button#{if media.get('deemed_worthy_by_me') then ' static-liked' else ''}'></div>#{media.get('worthinessCount').toString().replace /(\d)(?=(\d\d\d)+(?!\d))/g, "$1,"}</div>"
                  "  <div class='share-button'></div>"
                  "  <div class='photos-carousel-author'>#{if instagram then media.get('author').substr(10) else media.get('author')}#{if instagram then ' <small>via instagram</small>' else ''}<br />#{window.util.calc_time(media.get('timestampTaken'))}</div>"
                  "</div>"
                ].join('')
              }
            ]
            listeners:
              tap:
                element: 'element'
                fn: (e) ->
                  that = @
                  if e.target.className.indexOf('like-button') isnt -1
                    ctrl.un 'tap', that # disable until ajax request completed
                    ctrl.likeMedia 'photo', e.target, @config.mid, media, that
                  else if e.target.className is 'photos-carousel-likes' and e.target.childNodes[0].className.indexOf('like-button') isnt -1
                    ctrl.un 'tap', that # disable until ajax request completed
                    ctrl.likeMedia 'photo', e.target.childNodes[0], @config.mid, media, that
                  else if e.target.className.indexOf('share-button') isnt -1
                    ctrl.showMoreActionsMedia 'photo', media
      else # is a video
        mediaEntry =
          xtype: 'container'
          layout: 'vbox'
          pack: 'center'
          align: 'center'
          fullscreen: true
          style:
            backgroundColor: '#000'
          mid: media.get 'id'
          aeid: media.get 'aeid'
          mediaType: 'video'
          items: [
            {
              xtype: 'spacer'
              flex: 1
            }
            {
              xtype: 'component'
              flex: 8
              style:
                textAlign: 'center'
                backgroundColor: '#000'
                backgroundImage: if media.get('status') isnt 'uploading' and media.get('status') isnt 'processing' and Ext.os.is.Android then "url('resources/images/play-button.png'), url(#{ctrl.getAndroidVideoBackgroundImage(media)})" else ''
                backgroundSize: '72px 72px, contain'
                backgroundRepeat: 'no-repeat, no-repeat'
                backgroundPosition: 'center, center'
              html: if media.get('authorUid') is 'vine' and not Ext.os.is.Android then [
                  "<video controls='controls' onended='this.webkitExitFullScreen()' preload='none' poster='#{media.get('thumbUrl')}' style='margin:0px auto;min-height: 300px;max-width:90%;max-height:100%;'#{if Ext.os.is.iOS then ' webkit-playsinline loop="true"' else ' onclick="this.play()"'}>"
                    "<source src='#{media.get('url')}'>"
                  "</video>"
                ].join('') else if media.get('url') is '' and not Ext.os.is.Android then [
                  "<video controls='controls' onended='this.webkitExitFullScreen()' preload='none' poster='#{window.util.image_url(media.getData(), 'large')}' style='margin:0px auto;min-height: 300px;max-width:90%;max-height:100%;'#{if Ext.os.is.iOS then ' webkit-playsinline' else ' onclick="this.play()"'}>"
                    "<source src='http://wweye1.s3.amazonaws.com/iphone_#{media.get('id')}.mp4'>"
                  "</video>"
                ].join('') else if media.get('status') is 'processing' and not Ext.os.is.Android then [
                  "<video controls='controls' preload='none' poster='#{media.get('thumbUrl')}' style='margin:0px auto;min-height: 300px;max-width:90%;max-height:100%;' webkit-playsinline>"
                    "<source src='a-file-that-doesnt-exist-but-gives-crossed-out-play-button.mp4'>"
                  "</video>"
                ].join('') else if media.get('status') is 'uploading' or media.get('status') is 'processing' then [
                  "<div style='margin:48% auto 0px auto;min-height;300px;max-width:100%;max-height:100%;text-align: center; color: white !important; font-size:13px !important;'>This video is not yet available.</div>"
                ].join('')
              listeners:
                tap:
                  element: 'element'
                  fn: (e) ->
                    if media.get('status') isnt 'uploading' and media.get('status') isnt 'processing' and Ext.os.is.Android
                      ctrl.pauseDueToPluginIntent = yes
                      if media.get('authorUid') is 'vine'
                        window.plugins.videoPlayer.play "#{media.get('url')}"
                      else
                        window.plugins.videoPlayer.play "http://wweye1.s3.amazonaws.com/iphone_#{media.get('id')}.mp4"
            }
            {
              xtype: 'component'
              docked: 'bottom'
              height: 50
              mid: media.get 'id'
              html: [
                  "<div class='photos-carousel-details' style='text-align:left;'>"
                  "  <div class='photos-carousel-likes'><div class='like-button#{if media.get('deemed_worthy_by_me') then ' static-liked' else ''}'></div>#{media.get('worthinessCount').toString().replace /(\d)(?=(\d\d\d)+(?!\d))/g, "$1,"}</div>"
                  "  <div class='share-button'></div>"
                  "  <div class='photos-carousel-author'>#{if media.get('authorUid') is 'vine' then media.get('author').substr(5) else media.get('author')}#{if media.get('authorUid') is 'vine' then ' <small>via vine</small>' else ''}#{if media.get('status') is 'processing' then ' <small>(being processed)</small>' else ''}<br />#{window.util.calc_time(media.get('timestampTaken'))}</div>"
                  "</div>"
                ].join('')
              listeners:
                tap:
                  element: 'element'
                  fn: (e) ->
                    that = @
                    if e.target.className.indexOf('like-button') isnt -1
                      ctrl.un 'tap', that # disable until ajax request completed
                      ctrl.likeMedia 'video', e.target, @config.mid, media, that
                    else if e.target.className is 'photos-carousel-likes' and e.target.childNodes[0].className.indexOf('like-button') isnt -1
                      ctrl.un 'tap', that # disable until ajax request completed
                      ctrl.likeMedia 'video', e.target.childNodes[0], @config.mid, media, that
                    else if e.target.className.indexOf('share-button') isnt -1
                      ctrl.showMoreActionsMedia 'video', media
            }
            {
              xtype: 'spacer'
              flex: 1
            }
          ]
      items.push mediaEntry
      
    gallery = Ext.create 'Ext.Carousel',
      id: 'gallery'
      fullscreen: true
      ui: 'light'
      indicator: false
      style:
        backgroundColor: '#000'
      listeners:
        initialize: (container) ->
          # nullify the "tap indicator to the change card" functionality
          if container.getIndicator()?
            container.getIndicator().onTap = ->
              return true
              
        activeitemchange: (c, value, oldValue, eOpts) ->
          if value? and oldValue?
            oldValue.resetZoom?()
            @getActiveItem().resize?()
            # first find out: which side to add to? left or right side of carousel
            # if any...
            if @getActiveIndex() is 0
              # add two to left side if possible
              if items[@leftIndex-1]?
                @leftIndex -= 1
                @insert(0, items[@leftIndex])
              #if items[@leftIndex-1]?
              #  @leftIndex -= 1
              #  @insert(0, items[@leftIndex])
            else if @getActiveIndex() is @getItems().length - 1
              if items[@rightIndex+1]?
                @rightIndex += 1
                @add(items[@rightIndex])
              #if items[@rightIndex+1]?
              #  @rightIndex += 1
              #  @add(items[@rightIndex])
          #if value? then ga_storage._trackEvent "Gallery", "View #{value.config.mediaType}", "#{value.config.mid} - #{value.config.aeid}"
          
        # not sure if this is been used anymore
        resize: (c, eOpts) ->
          @getActiveItem().resize?()
          
        dragstart:
          element: 'element'
          fn: (e) ->
            if @getActiveItem().getScrollable()?
              scroller = @getActiveItem().getScrollable().getScroller()
              if e.targetTouches.length is 1 and (e.deltaX < 0 and scroller.position.x >= scroller.getMaxPosition().x) or (e.deltaX > 0 and scroller.position.x <= 0)
                return true
              else
                return false
            else
              return true
        drag:
          element: 'element'
          fn: (e) ->
            if @getActiveItem().getScrollable()?
              scroller = @getActiveItem().getScrollable().getScroller()
              if e.targetTouches.length is 1 and (e.deltaX < 0 and scroller.position.x >= scroller.getMaxPosition().x) or (e.deltaX > 0 and scroller.position.x <= 0)
                return true
              else
                return false
            else
              return true
        dragend:
          element: 'element'
          fn: (e) ->
            if @getActiveItem().getScrollable()?
              scroller = @getActiveItem().getScrollable().getScroller()
              if e.targetTouches.length < 2 and (e.deltaX < 0 and scroller.position.x >= scroller.getMaxPosition().x) or (e.deltaX > 0 and scroller.position.x <= 0)
                return true
              else
                return false
            else
              return true
              
    gallery.add items[index]
    gallery.rightIndex = index
    gallery.leftIndex = index
    if items[index+1]?
      gallery.rightIndex += 1
      gallery.add items[gallery.rightIndex]
    if items[index-1]?
      gallery.leftIndex -= 1
      gallery.insert 0, items[gallery.leftIndex]
      gallery.setActiveItem 1
    else
      gallery.setActiveItem 0
    @getTopToolbarHomeButton().config.dest = dest
    @getMoreActionsButton().hide()
    @getMainContainer().setActiveItem gallery
  
  reinstateDynamicLists: ->
    #this will get the categories list or pull from localstorage cache
    if window.localStorage.getItem('listOfCategories')? and window.localStorage.getItem('listOfCategoriesCacheExpiration')? and parseInt(window.localStorage.getItem('listOfCategoriesCacheExpiration')) > parseInt(Ext.util.Format.date(new Date(), 'Ymd'))
      obj = Ext.decode window.localStorage.getItem('listOfCategories')
      @setListOfCategories obj.categories
    else
      Ext.Ajax.request
        url: "http://wesawit.com/event/get_list_of_categories"
        method: 'GET'
        scope: this
        timeout: 15000
        success: (response) ->
          window.localStorage.setItem 'listOfCategories', response.responseText
          date = new Date( (new Date()).getTime() + (10*24*60*60*1000) )  # cache lasts for 10 days
          window.localStorage.setItem 'listOfCategoriesCacheExpiration', Ext.util.Format.date(date, 'Ymd')
          obj = Ext.decode response.responseText
          @setListOfCategories obj.categories
        failure: (response) ->
          # if it fails than just use a static copy and hope it's up-to-date enough
          @setListOfCategories [
            'Social'
            'Emergency'
            'Arts'
            'Business'
            'Comedy'
            'Culture'
            'Dance'
            'Fashion'
            'Film'
            'Food & Drink'
            'Health'
            'Music'
            'Politics'
            'Sports'
            'Tech & Sci'
            'Theater'
          ]
  
  grabCurrentPosition: ->
    geolocationSuccessCallback = Ext.bind @geolocationSuccess, this
    geolocationErrorCallback = Ext.bind @geolocationError, this
    navigator.geolocation.getCurrentPosition geolocationSuccessCallback, geolocationErrorCallback, {maximumAge: 0, enableHighAccuracy: true}
  
  generateRandomMid: ->
    Math.floor(Math.random() * 1000000000) + 1000000000 # corressponds to maximum int primitive in ios and it gives from 1000000000 - 9999999999
  
  resetTopToolbarTitle: ->
    @getTopToolbar().setTitle ''
    @getTopToolbar().removeCls 'hide-logo'
  
  revertTopToolbarTitle: ->
    if @topToolbarLastTitle?
      @getTopToolbar().addCls 'hide-logo'
      @getTopToolbar().setTitle @topToolbarLastTitle
    else
      @resetTopToolbarTitle()
  
  refreshMap: (senchaMap, nameOfStore) ->
    map = senchaMap.map
    data = Ext.getStore(nameOfStore).getData().all

    senchaMap.config.currLocMarker = new L.Marker(new L.LatLng(window.localStorage.getItem("locationLat"), window.localStorage.getItem("locationLng")),
      zIndexOffset: 97
      icon: new L.Icon
        iconUrl: "resources/images/map-pin-curr-loc.gif"
        iconAnchor: [12, 12]
        iconSize: [24, 24]
    )
    senchaMap.config.currLocMarker.addTo map
    markers = new L.LayerGroup()
    for d in data
      eventData = d.data
      status = "past"
      if new Date(Ext.util.Format.date(eventData.dateTimeStart, "c")) > new Date()
        status = "future"
      else
        status = "present"  if new Date(Ext.util.Format.date(eventData.dateTimeStart, "c")) < new Date() and new Date(Ext.util.Format.date(eventData.dateTimeEnd, "c")) > new Date()
      marker = ((eventData) ->
        marker = new L.Marker new L.LatLng(eventData.locationLat, eventData.locationLng),
          zIndexOffset: if status is "present" then 100 else if status is "future" then 99 else 98
          icon: new L.Icon
            iconSize: [32, 32]
            iconAnchor: [16, 32]
            popupAnchor: [0, -27]
            iconUrl: "resources/images/map-pin-#{status}.png"
      )(eventData)
      infoWindow = ((eventData, nameOfStore) ->
        [
          "<div class=\"x-list-item info-bubble\" onclick=\"WSI.app.getController('Events').onViewEventCommand(null,Ext.getStore('" + nameOfStore + "').getById('" + eventData.id + "'))\">"
            "<div class=\"list-item-top-cap\">"
              "" + (window.util.calc_time(eventData.dateTimeStart, eventData.dateTimeEnd))
              "<div class='distance-away'>#{(window.util.calc_distance(eventData.locationLat, eventData.locationLng))}</div>"
              "<div class='location-text'>#{eventData.locationName}</div>"
            "</div>"
            "<div class='list-item-thumb' style='background-image: url(" + (window.util.image_url(eventData, "medium", true)) + ");'></div>"
            "<div class=\"list-item-bottom-cap\">"
              "<div class='title-text'>" + eventData.title + "</div>"
              "<div class='view-count'>" + (window.util.commaize_number(eventData.viewCount)) + " view" + ((if eventData.viewCount is 1 then "s" else "")) + "</div>"
              "<div class='photo-count'>" + (window.util.commaize_number(eventData.photos.length)) + "</div>"
              "<div class='video-count'>" + (window.util.commaize_number(eventData.videos.length)) + "</div>"
            "</div>"
          "</div>"
        ].join ""
      )(eventData, nameOfStore, marker)
      marker.bindPopup infoWindow,
        minWidth: 310
        width: 310
        maxWidth: 310
        minHeight: 240
        height: 240
        maxHeight: 240
        closeButton: false

      marker.addTo markers
    markers.addTo map
    
  getSuggestionsFromGoogle: (existingSuggestions, suggestionsCmp, simple = false) ->
    that = @
    lat = parseFloat window.localStorage.getItem('locationLat')
    lng = parseFloat window.localStorage.getItem('locationLng')
    if not navigator.onLine
      navigator.notification.alert 'Unable to connect to the internet.', (()->return), 'Oops!'
    else
      latlng = new google.maps.LatLng lat, lng
      if not document.placesService?
        document.placesService = new google.maps.places.PlacesService document.getElementById('gmap-container').children[0]
      document.placesService.nearbySearch { 'location': latlng, 'radius': '50', 'types': ['street_address','room','point_of_interest','establishment','post_office','night_club','museum','park','local_government_office','library','hospital','gym','fire_station','embassy','courthouse','city_hall','cemetery','casino','art_gallery','amusement_park','airport'] },
        (placeResults, placesServiceStatus, placeSearchPagination) ->
          if placesServiceStatus is google.maps.places.PlacesServiceStatus.OK and placeResults.length > 0
            if simple is true
              that.newEventChooseLocation placeResults[0].name, placeResults[0].vicinity, placeResults[0].geometry.location.lat(), placeResults[0].geometry.location.lng(), placeResults[0].types[0] # returns jsut the first result
            else
              for i in [0..Math.min(20,placeResults.length-1)]
                existingSuggestions.push
                  'locationName': placeResults[i].name
                  'locationVicinity': placeResults[i].vicinity
                  'locationLat': placeResults[i].geometry.location.lat()
                  'locationLng': placeResults[i].geometry.location.lng()
                  'locationType': placeResults[i].types[0]
                  'photos': placeResults[i].photos
                  'icon': placeResults[i].icon
              suggestionsCmp.setData existingSuggestions
              
  generateSuggestions: (suggestionsCmp, simple = false) ->  #simple means to insert it directly into the Where field on create event form
    suggestions = new Array()
    if window.localStorage.getItem('locationLat')? and window.localStorage.getItem('locationLng')?
      lat = parseFloat window.localStorage.getItem('locationLat')
      lng = parseFloat window.localStorage.getItem('locationLng')
      #if Math.sqrt( (lat - 34.069227) * (lat - 34.069227) + ( lng - (-118.447223) ) * ( lng - (-118.447223) ) ) < 0.0096751509 # meaning on campus
      bbCenters = new Array()
      usedLocs = new Array()
      for b in window.util.customLocations
        maxRadius = Math.max( ( ( b[1] - b[3] ) * 68.88 * 1609.344 ), ( ( b[2] - b[4] ) * -1 * 59.95 * 1609.344 ) ) / 2 # in meters. 1609.344 meters in a mile. deg of lat = miles / 68.88. deg of lng = miles / 59.95. ONLY WORKS FOR northeast hemisphere of earth. the /2 is because we want radius not diameter
        bbCenters.push [
          b[0]
          ( b[3] + (b[1]-b[3]) / 2 ) # center point latitude
          ( b[4] + (b[2]-b[4]) / 2 ) # center point longitude
          maxRadius
        ]
        if lat < b[1] and lng > b[2] and lat > b[3] and lng < b[4] and usedLocs.indexOf(b[0]) is -1 # specialized conditional ONLY WORKS FOR northeast hemisphere of earth
          usedLocs.push b[0]
          suggestions.push [
            b[0]
            lat # users lat inside bounding box
            lng # users lng inside bounding box
            'UCLA, Los Angeles'
            maxRadius
          ]
      bbDists = new Array()
      for b in bbCenters
        bbDists.push [
          b[0]
          b[1]
          b[2]
          Math.sqrt( (lat-b[1])*(lat-b[1]) + (lng-b[2])*(lng-b[2]) )
        ]
      bbDists.sort (a,b)->(a[3]-b[3])
      for i in bbDists
        if i[3] < 0.001105146596 and usedLocs.indexOf(i[0]) is -1
          usedLocs.push i[0]
          suggestions.push [
            i[0]
            i[1]
            i[2]
            'UCLA, Los Angeles'
            i[3]
          ]
      if suggestions.length > 0 and simple is true
        @newEventChooseLocation suggestions[0][0], suggestions[0][3], suggestions[0][1], suggestions[0][2], "custom_radius:#{parseInt(suggestions[0][4])}"
      else if suggestions.length > 3
        s2 = new Array()
        for sugg in suggestions
          s2.push
            'locationName': sugg[0]
            'locationVicinity': sugg[3]
            'locationLat': sugg[1]
            'locationLng': sugg[2]
            'locationType': "custom_radius:#{parseInt(sugg[4])}"
        suggestionsCmp.setData s2
      else
        s2 = new Array()
        for sugg in suggestions
          s2.push
            'locationName': sugg[0]
            'locationVicinity': sugg[3]
            'locationLat': sugg[1]
            'locationLng': sugg[2]
            'locationType': "custom_radius:#{parseInt(sugg[4])}"
        @getSuggestionsFromGoogle s2, suggestionsCmp, simple
    else
      if simple is true
        @newEventChooseLocation 'Choose location...'
      else
        suggestionsCmp.setData { locationName: '', locationVicinity: '', locationLat: '0', locationLng: '0' }