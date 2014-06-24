Ext.define 'WSI.view.MediaWall'
  extend: 'Ext.DataView'
  xtype: 'mediawall'
  config:
    baseCls: 'mediawall'
    homeButtonDest: 'to-details-from-gallery'
    loadingText: "loading..."
    emptyText: "" # this will be changed by EventDetailsContainer if there is no media for an event
    scrollable: no
    meanWorthiness: 0
    flipbookIntervalArrayRef: null
    listeners:
      initialize: (c) ->
        c.refreshItemTpl()
      itemtap: (c, index, target, record) ->
        c.fireEvent 'openGallery', index, c.getStore(), c.config.homeButtonDest
        
    itemTpl: [
      "<tpl if='this.isPhoto(pid)'>"
        "<div class='media-item thumb {status}{[(this.isPhoto(values.pid) ? '' : ' video')]}' style='{[this.getDimCss(values)]}' data-mid='{id}' data-src='{[(this.widthByMid['mid'+values.id] > 300 ? util.image_url(values, 'medium') : util.image_url(values, 'small'))]}'>"
          "<tpl if='values.status == \"uploading\"'>"
            "<span id='progress-bar-{id}' class='progress-bar'></span>"
          "</tpl>"
          "<span class='timestamp'>"
            "{[(values.status == 'uploading') ? 'Uploading...' : util.calc_time(values.timestampTaken, false, 'g:ia', true)]}"
          "</span>"
        "</div>"
      "</tpl>"
      "<tpl if='!this.isPhoto(pid) && (values.status == \"uploading\" || values.status == \"processing\")'>"
        "<div class='media-item thumb video {status}' style='{[this.getDimCss(values)]} background-image:url({[(this.widthByMid['mid'+values.id] > 300 ? util.image_url(values, 'medium') : util.image_url(values, 'small'))]});' data-mid='{id}' data-src='{[(this.widthByMid['mid'+values.id] > 300 ? util.image_url(values, 'medium') : util.image_url(values, 'small'))]}'>"
          "<tpl if='values.status == \"uploading\"'>"
            "<span id='progress-bar-{id}' class='progress-bar'></span>"
          "</tpl>"
          "<span class='timestamp'>"
            "{[(values.status == 'uploading') ? 'Uploading...' : ((values.status == 'processing') ? 'Processing...' : util.calc_time(values.timestampTaken, false, 'g:ia', true))]}"
          "</span>"
        "</div>"
      "</tpl>"
      "<tpl if='!this.isPhoto(pid) && values.status == \"loaded\"'>"
        "<div class='media-item thumb video flipbook {status}' style='{[this.getDimCss(values)]}' data-mid='{id}'>"
          "{[this.getFlipbook(values)]}"
          "<span class='timestamp'>"
            "{[util.calc_time(values.timestampTaken, false, 'g:ia', true)]}"
          "</span>"
        "</div>"
      "</tpl>"
      {
        disableFormats: yes # optimizes sencha telling it not to look for formatting like "date:" etc.
        widthByMid: {} # remember the width of certain mid as determined by the getDimCss algorithm
        heightByMid: {} # remember the height of certain mid as determined by the getDimCss algorithm
        itemsLeftUntilNextRow: 0 # used for getDimCss algorithm
        widthLeftOnCurrentRow: 0 # used for getDimCss algorithm
        heightOfCurrentRow: null # used for getDimCss algorithm
        meanWorthiness: 0
        getDimCss: (values) ->
          mediaType = if values.pid? then 'photo' else 'video'
          if not @widthByMid["mid"+values.id]?
            # need to calculate a width for this item
            if @itemsLeftUntilNextRow is 0
              if mediaType is 'photo' and parseInt(values.worthinessCount) + (Math.random() - 0.75) > @meanWorthiness
                @itemsLeftUntilNextRow = 1
              else
                @itemsLeftUntilNextRow = Math.floor(Math.random() * 2) + 2 # random number between 2 and 3 inclusive
              if @itemsLeftUntilNextRow is 1 and Math.random() < 0.5 # make single row items be half as likely, and two per row be twice as likely
                @itemsLeftUntilNextRow = 2
              @widthLeftOnCurrentRow = 315 - @itemsLeftUntilNextRow * 5 # not 320 because some px is saved for the 5px margins of items and the 5px of the container on the very left side
              @heightOfCurrentRow = Math.floor(Math.random() * 40) + 200 - 40 * @itemsLeftUntilNextRow # establish a random height for this row
            if @itemsLeftUntilNextRow is 1
              @widthByMid["mid"+values.id] = @widthLeftOnCurrentRow
            else
              if parseInt(values.worthinessCount) + (Math.random() - 0.75) > @meanWorthiness
                @widthByMid["mid"+values.id] = Math.floor @widthLeftOnCurrentRow / @itemsLeftUntilNextRow + 30
              else
                @widthByMid["mid"+values.id] = Math.floor @widthLeftOnCurrentRow / @itemsLeftUntilNextRow + 60 * (Math.random() - 0.5)
            @itemsLeftUntilNextRow--
            @widthLeftOnCurrentRow -= @widthByMid["mid"+values.id]
          if not @heightByMid["mid"+values.id]?
            @heightByMid["mid"+values.id] = @heightOfCurrentRow
          "width: #{@widthByMid["mid"+values.id]}px; height: #{@heightByMid["mid"+values.id]}px;"
        isPhoto: (pid) ->
          pid?
        getFlipbook: (values) ->
          result = ""
          for i in [0...15]
            url = "#{util.S3_BASE_URL}flipbook_#{values.id}_#{i}.jpg"
            if i is 0
              result += "<img src='#{url}' data-src='#{url}' class='show' style='z-index: #{i+1}' />"
            else if i is 1
              result += "<img src='#{url}' data-src='#{url}' style='z-index: #{i+1}' />"
            else
              result += "<img src='#' data-src='#{url}' style='z-index: #{i+1}' />"
          result
      }
    ]
    
  refreshItemTpl: ->
    tpl = @getItemTpl()
    tpl.widthByMid = {} # force some resets in the xtemplate for the mediawall
    tpl.heightByMid = {}
    tpl.itemsLeftUntilNextRow = 0
    tpl.widthLeftOnCurrentRow = 0
    tpl.heightOfCurrentRow = null
    tpl.meanWorthiness = @config.meanWorthiness
    if @config.flipbookIntervalArrayRef?
      for i,item of @config.flipbookIntervalArrayRef
        clearInterval item.interval
      @config.flipbookIntervalArrayRef = {}
    @setItemTpl tpl