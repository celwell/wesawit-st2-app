# Timeline class
class Timeline
  constructor: (@dom) ->
    #@event_loader = new Event_Loader
    #@event_loader.sort = 'custom_range'
    #@event_loader.load_more_on_scroll = true
    #@event_loader.initialize output_dom
    @initialize()
  
  initialized: false
  width: null
  height: null
  mouse_x: 0
  mouse_y: 0
  mouse_down: false
  mouse_over: true
  zoom: 50
  zoom_vel: 0
  zoom_min: 0.79
  zoom_max: 30000
  zoom_vel_min: -0.05
  zoom_vel_max: 15
  year_x_offset: -344.45
  year_x_vel: -2
  x_offset_min: -430
  x_offset_max: 0
  bar_height: 4
  selection_start: 300
  selection_stop: 640
  currently_loaded_days: ''
  selected_days: ''
  start_date: ''
  end_date: ''
  months: ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC']
  days_in_month: [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
  g: null
  initialize: () =>
    # bind events for interacting with timeline canvas
    ###
    @dom.bind 'swipe', (e) =>
      alert 'swiped'
      prev_x = @mouse_x
      prev_y = @mouse_y
      @mouse_x = e.pageX - @dom.position().left
      @mouse_y = e.pageY - @dom.position().top
      if @mouse_x > 0 and @mouse_y > 0
        @shift((@mouse_x - prev_x) * 0.3 / @zoom)
    @dom.bind 'mousedown', (e) =>
      @mouse_down = true
    @dom.bind 'mouseup', (e) =>
      @mouse_down = false
    @dom.bind 'mousewheel', (event, delta, deltaX, deltaY) =>
      @zoom_in( deltaY * @zoom / 7 )
      @shift(deltaX * 10 / @zoom) # this may need to be adjust more. the main use of this is for macs (two-finger scroll)
      false # stop the normal mousewheel action (from scrolling down page)
    ###
    #@dom.bind 'dblclick', (e) =>
    #  @always_out = true
    # set graphics context
    @g = @dom.getContext "2d"
    @width = 400 #@dom.width()
    @height = 100 #@dom.height()
    ###
    @gradient = @g.createLinearGradient 0, 0, @width, 0
    @gradient.addColorStop 0,   "rgba(136,136,136,0)"
    @gradient.addColorStop 0.05, "rgba(136,136,136,1)"
    @gradient.addColorStop 0.95, "rgba(136,136,136,1)"
    @gradient.addColorStop 1, "rgba(136,136,136,0)"
    ###
    @gradient = '#aaaaaa'
    @interval = setInterval(@draw, 10)
    @initialized = true
  zoom_in: (amount) =>
    @zoom_vel += amount
    if @zoom_vel > @zoom_vel_max * @zoom
      @zoom_vel = @zoom_vel_max * @zoom
    if @zoom_vel < @zoom_vel_min * @zoom
      @zoom_vel = @zoom_vel_min * @zoom
  shift: (amount) ->
    @year_x_vel += amount
  update_positions: () =>
    if @always_out
      @zoom_vel = -(@zoom / 70)
    @zoom += @zoom_vel
    @year_x_offset += @year_x_vel
    if @zoom < @zoom_min and @zoom_vel < 0
      @zoom = @zoom_min
    else if @zoom > @zoom_max and @zoom_vel > 0
      @zoom = @zoom_max
    if @year_x_offset < @x_offset_min and @year_x_vel < 0
      @year_x_offset = @x_offset_min
      @year_x_vel = Math.abs(@year_x_vel) * 0.3
    else if @year_x_offset > @x_offset_max and @year_x_vel > 0
      @year_x_offset = @x_offset_max
      @year_x_vel = -1 * Math.abs(@year_x_vel) * 0.3
    @zoom_vel *= 0.9 # dampening of zoom velocity
    @year_x_vel *= 0.8 # friction: dampening of x velocity
  draw: () =>
    @update_positions()
    @clear()
    std_offset = @year_x_offset * @zoom
    half_width = @width / 2
    half_height = @height / 2
    @g.fillStyle = @gradient
    @g.fillRect 0, parseInt(half_height) - parseInt(@bar_height / 2) + 8, @width, parseInt(@bar_height)
    @g.font = "19px 'Helvetica Neue', HelveticaNeue, Helvetica-Neue, Helvetica, 'BBAlpha Sans', sans-serif"
    @g.fillText 'Drag left or right. Pinch to zoom in or out.', half_width-164, @height-20
    @g.fillStyle = "#FF4E00"
    @g.fillRect @selection_start, parseInt(half_height) - parseInt(@bar_height / 2) + 8, @selection_stop - @selection_start, parseInt(@bar_height)
    @selected_days = ''
    @start_date = ''
    @end_date = ''
    anchor_y = Math.floor(half_height) - parseInt(@bar_height / 2) - 10 + 15
    for h in [0..75]
      h_offset = 5.7 * h * @zoom
      # only render if will be visible, because it tends to lag; especially in Chrome
      hpos = Math.floor(half_width + std_offset + h_offset)
      if hpos > -@width and hpos < @width
        @g.font = "600 #{Math.max(Math.min(Math.floor(@zoom), 65), 3)}px 'Helvetica Neue', HelveticaNeue, Helvetica-Neue, Helvetica, 'BBAlpha Sans', sans-serif"
        if @zoom / 150 <= 0.75 and hpos > (@selection_start - Math.min(@zoom, 65) * 2) and hpos < @selection_stop
          @selected_days += "#{h + 1950}-YEAR-YEAR|"
          if @start_date is ''
            @start_date = "#{h + 1950}-01-01"
            @end_date = "#{h + 1950}-12-31"
          else
            @end_date = "#{h + 1950}-12-31"
          @g.fillStyle = "#FF4E00"
          @g.fillText 1950 + h, hpos, anchor_y
        else
          #@g.fillStyle = "rgba(136,136,136,#{(@zoom_max - @zoom * (@zoom*0.00001) ) / @zoom_max})"
          @g.fillStyle = @gradient
          @g.fillText 1950 + h, hpos, anchor_y 
      # see if we should bother showing months (i.e., will it be too small anyways?)
      if @zoom / 20 > 3
        # show months for this year (h)
        for i in [0..11]
          i_offset = 0.47 * i * @zoom
          ipos = Math.floor( @width / 2 + std_offset + h_offset + i_offset ) + 10
          if ipos > -@width and ipos < @width
            @g.font = "600 #{Math.min(Math.floor(@zoom / 20), 45)}px 'Helvetica Neue', HelveticaNeue, Helvetica-Neue, Helvetica, 'BBAlpha Sans', sans-serif"
            if @zoom / 150 > 0.75 and @zoom / 150 <= 7 and ipos > @selection_start - Math.min( @zoom / 20, 45 ) * 1.75 and ipos < @selection_stop
              @selected_days += "#{h + 1950}-#{i+1}-MONTH|"
              if @start_date is ''
                @start_date = "#{h + 1950}-#{ if i+1 < 10 then "0" + (i+1) else (i+1)}-01"
              @end_date = "#{h + 1950}-#{ if i+1 < 10 then "0" + (i+1) else (i+1)}-#{ if @days_in_month[i] < 10 then "0" + @days_in_month[i] else @days_in_month[i]}"
              @g.fillStyle = "#FF4E00"
              @g.fillText @months[i], ipos, anchor_y
            else
              @g.fillStyle = @gradient
              @g.fillText @months[i], ipos, anchor_y
          # see if we should bother showing days (or will it be too small anyways)
          if @zoom / 150 > 5
            # show days
            @g.font = "600 #{Math.min(Math.floor(@zoom / 150), 25)}px 'Helvetica Neue', HelveticaNeue, Helvetica-Neue, Helvetica, 'BBAlpha Sans', sans-serif"
            #@g.fillStyle = "rgb(136,136,136)"
            @g.fillStyle = @gradient
            for j in [0..(@days_in_month[i]-1)]
              j_offset = 0.015 * j * @zoom
              jpos = Math.floor(half_width + std_offset + 0.0002 * @zoom + j_offset + i_offset + h_offset)
              if jpos > -half_width and jpos < @width
                if @zoom / 150 > 7 and jpos > @selection_start - Math.min(@zoom / 150, 25) and jpos < @selection_stop
                  @selected_days += "#{h + 1950}-#{i + 1}-#{j + 1}|"
                  if @start_date is ''
                    @start_date = "#{h + 1950}-#{if (i+1) < 10 then "0" + (i+1) else (i+1)}-#{if (j+1) < 10 then "0" + (j+1) else (j+1)}"
                    @end_date = "#{h+1950}-#{if (i+1) < 10 then "0" + (i+1) else (i+1)}-#{if (j+1) < 10 then "0" + (j+1) else (j+1)}"
                  else
                    @end_date = "#{h+1950}-#{if (i+1) < 10 then "0" + (i+1) else (i+1)}-#{if (j+1) < 10 then "0" + (j+1) else (j+1)}"
                  @g.fillStyle = "#FF4E00"
                  @g.fillText (j+1), jpos, anchor_y
                  @g.fillStyle = "rgb(136,136,136)"
                else
                  @g.fillText (j+1), jpos, anchor_y
    if @start_date isnt ''
      selected_range = @months[Math.floor(@start_date.substr(5, 2))-1] + ' ' + @start_date.substr(8, 2) + ', ' + @start_date.substr(0, 4)
      if @start_date isnt @end_date
        selected_range += ' to ' + @months[Math.floor(@end_date.substr(5, 2))-1] + ' ' + @end_date.substr(8, 2) + ', ' + @end_date.substr(0, 4)
      @g.fillStyle = "#FF4E00"
      @g.font = "normal 24px 'Helvetica Neue', HelveticaNeue, Helvetica-Neue, Helvetica, 'BBAlpha Sans', sans-serif"
      #@g.fillText selected_range, 308, half_height
      @reload_events()
  clear: () =>
    @g.clearRect 0, 0, @width, @height
  reload_events: () =>
    if Math.abs(@zoom_vel) < 1.5 and Math.abs(@year_x_vel) < 0.025
      if not Ext.getStore('Events').isLoading() and @selected_days isnt '' and @selected_days isnt @currently_loaded_days and @start_date isnt '' and @end_date isnt ''
        @currently_loaded_days = @selected_days
        # reload events
        Ext.getStore('Events').getModel().getProxy().getExtraParams().startDate = @start_date.replace(/-/g, '')
        Ext.getStore('Events').getModel().getProxy().getExtraParams().endDate = @end_date.replace(/-/g, '')
        Ext.getStore('Events').removeAll()
        Ext.getStore('Events').loadPage(1)
        
        
        
Ext.define 'WSI.view.Timeline',
  extend: 'Ext.Container'
  xtype: 'timeline'
  config:
    layout: 'fit'
    docked: 'top'
    html: [
      "<canvas id='timeline-canvas' width='400' height='100'></canvas>"
    ].join ''
    oldSort: 'top'
    oldCategory: 'all'
    oldCountry: 'world'
    ###
    plugins: [
      {
        xclass: 'Ext.plugin.Pinchemu',
        helpers: true #enable touches visualization
      }
    ]
    ###
    listeners:
      dragstart:
        element: 'element'
        fn: (e) ->
          if e.previousDeltaX isnt 0
            @timeline.shift(e.previousDeltaX * 0.3 / @timeline.zoom)
      drag:
        element: 'element'
        fn: (e) ->
          if e.previousDeltaX isnt 0
            @timeline.shift(e.previousDeltaX * 0.3 / @timeline.zoom)
      pinchstart:
        element: 'element'
        fn: (e) ->
          @timeline.zoom_in( (1 - e.scale) * @timeline.zoom / -7)
      pinch:
        element: 'element'
        fn: (e) ->
          @timeline.zoom_in( (1 - e.scale) * @timeline.zoom / -7)
      painted: ->
        if Ext.feature.has.Canvas
          #Ext.Msg.alert 'Under Development', "The timeline feature currently runs unacceptably slow but will be faster in the next release."
          if Ext.getStore('Events').getModel().getProxy().getExtraParams().sort isnt 'custom_range'
            @oldSort = Ext.getStore('Events').getModel().getProxy().getExtraParams().sort
            Ext.getStore('Events').getModel().getProxy().getExtraParams().sort = 'custom_range'
          if Ext.getStore('Events').getModel().getProxy().getExtraParams().category isnt 'all'
            @oldCategory = Ext.getStore('Events').getModel().getProxy().getExtraParams().category
            Ext.getStore('Events').getModel().getProxy().getExtraParams().category = 'all'
          if Ext.getStore('Events').getModel().getProxy().getExtraParams().country isnt 'world'
            @oldCountry = Ext.getStore('Events').getModel().getProxy().getExtraParams().country
            Ext.getStore('Events').getModel().getProxy().getExtraParams().country = 'world'
          Ext.getStore('Events').getModel().getProxy().getExtraParams().searchTerm = ''
          if not @timeline?
            @timeline = new Timeline Ext.get('timeline-canvas').dom
          else
            @timeline.interval = setInterval @timeline.draw, 10
        else
          Ext.Msg.alert 'Canvas not supported', "Sorry, the Timeline feature is not compatible with your device."
      erased: ->
        Ext.getStore('Events').getModel().getProxy().getExtraParams().sort = @oldSort
        Ext.getStore('Events').getModel().getProxy().getExtraParams().category = @oldCategory
        Ext.getStore('Events').getModel().getProxy().getExtraParams().country = @oldCountry
        Ext.getStore('Events').getModel().getProxy().getExtraParams().startDate = ''
        Ext.getStore('Events').getModel().getProxy().getExtraParams().endDate = ''
        Ext.getStore('Events').removeAll()
        Ext.getStore('Events').loadPage(1)
        clearInterval @timeline.interval