#
# * Ext.ux.ImageViewer
# *
# * A zoom-able Image Viewer Class for the Sencha Touch 2.0 Framework.
# *
# * Initial work by Perdiga with thanks to Armode for the help, publicated at Sencha Forum:
# * http://www.sencha.com/forum/showthread.php?197903-Pinch-Image-with-carousel-and-working-fine
# * 
# * Based on work by themightychris:
# * http://www.sencha.com/forum/showthread.php?137632-mostly-working-pinch-zoom-image-carousel-help-perfect-it!
# *
# * @updated till 2012-08 Many enhancements and BugFixes by users of the Sencha Forum
# * @updated 2012-08-24   by Dipl.-Ing. (FH) Andr� Fiedler (https://twitter.com/sonnenkiste)
# * Collected Enhancements from the Forum, Code Cleanup and Formating, Demos
#

Ext.define "WSI.view.ImageViewer",
  extend: "Ext.Container"
  xtype: "imageviewer"
  alias: "widget.imageviewer"
  config:
    doubleTapScale: 1
    maxScale: 4
    loadingMask: true
    previewSrc: false
    resizeOnLoad: true
    imageSrc: false
    initOnActivate: false
    cls: "imageBox"
    scrollable: "both"
    loadingMessage: "Loading ..."
    html: "<figure><img></figure>"
    errorImage: false

  duringDestroy: false
  initialize: ->
    me = this
    if me.getInitOnActivate()
      me.on "activate", me.initViewer, me,
        delay: 10
        single: true
    else
      me.on "painted", me.initViewer, me,
        delay: 10
        single: true


  initViewer: ->
    me = this
    scroller = me.getScrollable().getScroller()
    element = me.element
    
    #disable scroller
    scroller.setDisabled true

    # mask image viewer
    if me.getLoadingMask()
      me.setHtml [ # spinner location is hard coded for iPhone4
        "<div class='x-loading-spinner-outer' style='position: absolute; top: 272px; left: 160px; margin-left: -12px;'>"
          "<div class='x-loading-spinner'>"
            "<span class='x-loading-top'></span>"
            "<span class='x-loading-right'></span>"
            "<span class='x-loading-bottom'></span>"
            "<span class='x-loading-left'></span>"
          "</div>"
        "</div>"
        me.getHtml()
      ].join ""

    # retrieve DOM els
    me.figEl = element.down("figure")
    me.imgEl = me.figEl.down("img")

    # apply required styles
    me.figEl.setStyle
      overflow: "hidden"
      display: "block"
      margin: 0

    me.imgEl.setStyle
      "-webkit-user-drag": "none"
      "-webkit-transform-origin": "0 0"
      visibility: "hidden"

    # show preview
    if me.getPreviewSrc()
      element.setStyle
        backgroundImage: "url(" + me.getPreviewSrc() + ")"
        backgroundPosition: "center center"
        backgroundRepeat: "no-repeat"
        webkitBackgroundSize: "contain"

    # attach event listeners
    me.on "load", me.onImageLoad, me
    me.imgEl.addListener
      scope: me
      doubletap: me.onDoubleTap
      pinchstart: me.onImagePinchStart
      pinch: me.onImagePinch
      pinchend: me.onImagePinchEnd

    # load image
    me.loadImage me.getImageSrc()  if me.getImageSrc()

  loadImage: (src) ->
    me = this
    if me.imgEl
      me.imgEl.dom.src = src
      me.imgEl.dom.onload = Ext.Function.bind(me.onLoad, me, me.imgEl, 0)
      if me.getErrorImage()
        me.imgEl.dom.onerror = ->
          @src = me.getErrorImage()
    else
      me.setImageSrc src

  unloadImage: ->
    me = this
    
    # mask image viewer
    if me.getLoadingMask()
      me.setHtml [ # spinner location is hard coded for iPhone4
        "<div class='x-loading-spinner-outer' style='position: absolute; top: 225px; left: 168px; margin-left: -12px;'>"
          "<div class='x-loading-spinner'>"
            "<span class='x-loading-top'></span>"
            "<span class='x-loading-right'></span>"
            "<span class='x-loading-bottom'></span>"
            "<span class='x-loading-left'></span>"
          "</div>"
        "</div>"
        me.getHtml()
      ].join ""

    if me.imgEl
      me.imgEl.dom.src = ""
      me.imgEl.setStyle visibility: "hidden"
    else
      me.setImageSrc ""
      me.imgEl.setStyle visibility: "hidden"

  onLoad: (el, e) ->
    me = this
    me.addCls 'hide-spinner'
    me.fireEvent "load", me, el, e

  onImageLoad: ->
    me = this
    parentElement = me.parent.element
    
    # get viewport size
    me.viewportWidth = me.viewportWidth or me.getWidth() or parentElement.getWidth()
    me.viewportHeight = me.viewportHeight or me.getHeight() or parentElement.getHeight()
    
    # grab image size
    me.imgWidth = me.imgEl.dom.width
    me.imgHeight = me.imgEl.dom.height
    
    # calculate and apply initial scale to fit image to screen
    if me.getResizeOnLoad()
      me.scale = me.baseScale = Math.min(me.viewportWidth / me.imgWidth, me.viewportHeight / me.imgHeight)
      me.setMaxScale me.scale * 4
    else
      me.scale = me.baseScale = 1
    
    # calc initial translation
    tmpTranslateX = (me.viewportWidth - me.baseScale * me.imgWidth) / 2
    tmpTranslateY = (me.viewportHeight - me.baseScale * me.imgHeight) / 2
    
    # set initial translation to center
    me.setTranslation tmpTranslateX, tmpTranslateY
    me.translateBaseX = me.translateX
    me.translateBaseY = me.translateY
    
    # apply initial scale and translation
    me.applyTransform()
    
    # initialize scroller configuration
    me.adjustScroller()
    
    # show image and remove mask
    me.imgEl.setStyle visibility: "visible"
    
    # remove preview
    me.element.setStyle backgroundImage: "none"  if me.getPreviewSrc()
    me.setMasked false  if me.getLoadingMask()
    me.fireEvent "imageLoaded", me

  onImagePinchStart: (ev) ->
    me = this
    scroller = me.getScrollable().getScroller()
    scrollPosition = scroller.position
    touches = ev.touches
    element = me.element
    scale = me.scale
    
    # disable scrolling during pinch
    scroller.stopAnimation()
    scroller.setDisabled true
    
    # store beginning scale
    me.startScale = scale
    
    # calculate touch midpoint relative to image viewport
    me.originViewportX = (touches[0].pageX + touches[1].pageX) / 2 - element.getX()
    me.originViewportY = (touches[0].pageY + touches[1].pageY) / 2 - element.getY()
    
    # translate viewport origin to position on scaled image
    me.originScaledImgX = me.originViewportX + scrollPosition.x - me.translateX
    me.originScaledImgY = me.originViewportY + scrollPosition.y - me.translateY
    
    # unscale to find origin on full size image
    me.originFullImgX = me.originScaledImgX / scale
    me.originFullImgY = me.originScaledImgY / scale
    
    # calculate translation needed to counteract new origin and keep image in same position on screen
    me.translateX += (-1 * ((me.imgWidth * (1 - scale)) * (me.originFullImgX / me.imgWidth)))
    me.translateY += (-1 * ((me.imgHeight * (1 - scale)) * (me.originFullImgY / me.imgHeight)))
    
    # apply new origin
    me.setOrigin me.originFullImgX, me.originFullImgY
    
    # apply translate and scale CSS
    me.applyTransform()

  onImagePinch: (ev) ->
    me = this
    
    # prevent scaling to smaller than screen size
    me.scale = Ext.Number.constrain(ev.scale * me.startScale, me.baseScale - 2, me.getMaxScale())
    me.applyTransform()

  onImagePinchEnd: (ev) ->
    me = this
    
    # set new translation
    if me.scale is me.baseScale
      
      # move to center
      me.setTranslation me.translateBaseX, me.translateBaseY
    else
      
      #Resize to init size like ios
      if me.scale < me.baseScale and me.getResizeOnLoad()
        me.resetZoom()
        return
      
      # calculate rescaled origin
      me.originReScaledImgX = me.originScaledImgX * (me.scale / me.startScale)
      me.originReScaledImgY = me.originScaledImgY * (me.scale / me.startScale)
      
      # maintain zoom position
      me.setTranslation me.originViewportX - me.originReScaledImgX, me.originViewportY - me.originReScaledImgY
    
    # adjust scroll container
    me.adjustScroller()

    # reset origin and update transform with new translation
    me.applyTransformAndResetOrigin()
    

  onZoomIn: ->
    me = this
    ev =
      pageX: 0
      pageY: 0

    myScale = me.scale
    myScale = me.scale + 0.05  if myScale < me.getMaxScale()
    myScale = me.getMaxScale()  if myScale >= me.getMaxScale()
    ev.pageX = me.viewportWidth / 2
    ev.pageY = me.viewportHeight / 2
    me.zoomImage ev, myScale

  onZoomOut: ->
    me = this
    ev =
      pageX: 0
      pageY: 0

    myScale = me.scale
    myScale = me.scale - 0.05  if myScale > me.baseScale
    myScale = me.baseScale  if myScale <= me.baseScale
    ev.pageX = me.viewportWidth / 2
    ev.pageY = me.viewportHeight / 2
    me.zoomImage ev, myScale

  zoomImage: (ev, scale, scope) ->
    me = this
    scroller = me.getScrollable().getScroller()
    scrollPosition = scroller.position
    element = me.element
    
    # zoom in toward tap position
    oldScale = me.scale
    newScale = scale
    originViewportX = (if ev then (ev.pageX - element.getX()) else 0)
    originViewportY = (if ev then (ev.pageY - element.getY()) else 0)
    originScaledImgX = originViewportX + scrollPosition.x - me.translateX
    originScaledImgY = originViewportY + scrollPosition.y - me.translateY
    originReScaledImgX = originScaledImgX * (newScale / oldScale)
    originReScaledImgY = originScaledImgY * (newScale / oldScale)
    me.scale = newScale
    setTimeout (->
      me.setTranslation originViewportX - originReScaledImgX, originViewportY - originReScaledImgY
      
      # reset origin and update transform with new translation
      this.setOrigin 0, 0
      
      # reset origin and update transform with new translation
      me.applyTransform()
      
      # adjust scroll container
      me.adjustScroller()
      
      # force repaint to solve occasional iOS rendering delay
      Ext.repaint()
    ), 1

  onDoubleTap: (ev, t) ->
    me = this
    scroller = me.getScrollable().getScroller()
    scrollPosition = scroller.position
    element = me.element
    return false  unless me.getDoubleTapScale()
    
    # set scale and translation
    if me.scale > me.baseScale
      # zoom out to base view
      me.scale = me.baseScale
      me.setTranslation me.translateBaseX, me.translateBaseY
      
      # reset origin and update transform with new translation
      me.applyTransform()
      
      # adjust scroll container
      me.adjustScroller()
      
      # force repaint to solve occasional iOS rendering delay
      Ext.repaint()
    else
      # zoom in toward tap position
      oldScale = me.scale
      newScale = me.baseScale * 4
      originViewportX = (if ev then (ev.pageX - element.getX()) else 0)
      originViewportY = (if ev then (ev.pageY - element.getY()) else 0)
      originScaledImgX = originViewportX + scrollPosition.x - me.translateX
      originScaledImgY = originViewportY + scrollPosition.y - me.translateY
      originReScaledImgX = originScaledImgX * (newScale / oldScale)
      originReScaledImgY = originScaledImgY * (newScale / oldScale)
      me.scale = newScale
      
      #smoothes the transition
      setTimeout (->
        me.setTranslation originViewportX - originReScaledImgX, originViewportY - originReScaledImgY
        
        # reset origin and update transform with new translation
        me.applyTransform()
        
        # adjust scroll container
        me.adjustScroller()
        
        # force repaint to solve occasional iOS rendering delay
        Ext.repaint()
      ), 50

  setOrigin: (x, y) ->
    @imgEl.dom.style.webkitTransformOrigin = x + "px " + y + "px"

  setTranslation: (translateX, translateY) ->
    me = this
    me.translateX = translateX
    me.translateY = translateY
    
    # transfer negative translations to scroll offset
    me.scrollX = me.scrollY = 0
    if me.translateX < 0
      me.scrollX = me.translateX
      me.translateX = 0
    if me.translateY < 0
      me.scrollY = me.translateY
      me.translateY = 0

  resetZoom: ->
    me = this
    if typeof @imgEl isnt "undefined"
      return  if me.duringDestroy
      
      #Resize to init size like ios
      me.scale = me.baseScale
      me.setTranslation me.translateBaseX, me.translateBaseY
      
      # reset origin and update transform with new translation
      me.setOrigin 0, 0
      me.applyTransform()
      
      # adjust scroll container
      me.adjustScroller()

  resize: ->
    me = this
    if typeof @imgEl isnt "undefined"
      
      # get viewport size
      me.viewportWidth = me.parent.element.getWidth() or me.viewportWidth or me.getWidth()
      me.viewportHeight = me.parent.element.getHeight() or me.viewportHeight or me.getHeight()
      
      # grab image size
      me.imgWidth = me.imgEl.dom.width
      me.imgHeight = me.imgEl.dom.height
      
      # calculate and apply initial scale to fit image to screen
      if me.getResizeOnLoad()
        me.scale = me.baseScale = Math.min(me.viewportWidth / me.imgWidth, me.viewportHeight / me.imgHeight)
        me.setMaxScale me.scale * 4
      else
        me.scale = me.baseScale = 1
      
      # set initial translation to center
      me.translateX = me.translateBaseX = (me.viewportWidth - me.baseScale * me.imgWidth) / 2
      me.translateY = me.translateBaseY = (me.viewportHeight - me.baseScale * me.imgHeight) / 2
      
      # initialize scroller configuration
      me.adjustScroller()

      # apply initial scale and translation
      me.applyTransform()
      

  applyTransform: ->
    me = this
    
    #me.imgEl.dom.style.webkitTransform =
    
    #'matrix(' + fixedScale + ',0,0,' + fixedScale + ',' + fixedX + ',' + fixedY + ')';
    me.imgEl.dom.style.webkitTransform = "translate3d(" + parseInt(me.translateX) + "px, " + parseInt(me.translateY) + "px, 0)" + " scale3d(" + parseInt(me.scale * 1000) / 1000 + "," + parseInt(me.scale * 1000) / 1000 + ",1)"  unless Ext.os.is.Android

  applyTransformAndResetOrigin: ->
    me = this
    unless Ext.os.is.Android
      
      #me.imgEl.dom.style.webkitTransformOrigin = '0px 0px';
      #me.imgEl.dom.style.webkitTransform =
      #'matrix(' + fixedScale + ',0,0,' + fixedScale + ',' + fixedX + ',' + fixedY + ')';
      me.imgEl.dom.style.webkitTransformOrigin = "0px 0px"
      me.imgEl.dom.style.webkitTransform = "translate3d(" + parseInt(me.translateX) + "px, " + parseInt(me.translateY) + "px, 0)" + " scale3d(" + parseInt(me.scale * 1000) / 1000 + "," + parseInt(me.scale * 1000) / 1000 + ",1)"

  adjustScroller: ->
    me = this
    scroller = me.getScrollable().getScroller()
    scale = me.scale
    
    # disable scrolling if zoomed out completely, else enable it
    if scale is me.baseScale
      scroller.setDisabled true
    else
      scroller.setDisabled false
    
    # size container to final image size
    boundWidth = Math.max(me.imgWidth * scale, me.viewportWidth)
    boundHeight = Math.max(me.imgHeight * scale, me.viewportHeight)
    me.figEl.setStyle
      width: boundWidth + "px"
      height: boundHeight + "px"

    
    # update scroller to new content size
    scroller.refresh() #this appears to cause a flicker when when zooming
    
    # apply scroll
    x = 0
    x = me.scrollX  if me.scrollX
    y = 0
    y = me.scrollY  if me.scrollY
    scroller.scrollTo x * -1, y * -1

  destroy: ->
    me = this
    me.duringDestroy = true
    me.un "activate", me.initViewer, me
    me.un "painted", me.initViewer, me
    Ext.destroy me.getScrollable(), me.imgEl
    me.callParent()
