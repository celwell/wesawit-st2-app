Ext.define 'WSI.view.MediaStrip'
  extend: 'Ext.DataView'
  xtype: 'mediastrip'
  config:
    inline:
      wrap: false
    loadingText: ""
    emptyText: ""
    scrollToTopOnRefresh: no
    itemTpl: "<img class='photo-thumb {status}{[(typeof values.vid !== 'undefined' && values.vid !== null) ? ' video-thumb' : '']}' src='resources/images/black1x1.jpg' data-src='{[window.util.image_url(values, 'small')]}' height='165' width='165' /><span class='timestamp-on-thumb'>{[(values.status == 'uploading') ? 'Uploading...' : window.util.calc_time(values.timestampTaken, false, 'M j / g:ia')]}</span>"
    scrollable:
      direction: 'horizontal'
      directionLock: true
      indicators: false
      momentumEasing:
        momentum:
          acceleration: 10
          friction: 0.75
    homeButtonDest: 'to-details-from-gallery'
    listeners:
      initialize: (c) ->
        c.getStore().setSorters
          property: 'timestampTaken'
          direction: 'DESC'
      itemtap: (c, index, target, record) ->
        c.fireEvent 'openGallery', index, c.getStore(), c.config.homeButtonDest
      refresh: (c) ->
        c.lastLoadX = 0
        c.visibleWidth = c.bodyElement.dom.clientWidth
        c.thumbs = c.bodyElement.query '.photo-thumb'
        c.loadImages c.getScrollable().getScroller().position.x
        
  initialize: ->
    @callParent arguments
    @getScrollable().getScroller().on
      scrollend: @onScrollEnd
      scope: this
      
  onScrollEnd: (scroller, x, y) ->
    @loadImages x unless Math.abs(@lastLoadX - x) < @getHeight() # only bother checking every so pixels
    return true
    
  loadImages: (x = null) ->
    x ?= @getScrollable().getScroller().position.x
    @lastLoadX = x
    width = @getHeight()
    leftBound = x - width * 1.333 - 1000
    rightBound = x + @visibleWidth + 220 + 1000
    displacement = 0
    for i,thumb of @thumbs
      displacement += 10 + width # 10+ is for margin
      if displacement > leftBound and displacement < rightBound
        if thumb.src.indexOf 'black1x1' isnt -1
          thumb.src = thumb.getAttribute "data-src"
    return true