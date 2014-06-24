Ext.define 'WSI.plugin.BetterPullRefresh',
  extend: 'Ext.plugin.PullRefresh'
  alias: 'plugin.betterpullrefresh'
  requires: [
    'Ext.plugin.PullRefresh'
  ]
  
  loadStore: ->
    list = @getList()
    store = list.getStore() ? list.store
    scroller = list.getScrollable().getScroller()
    @setViewState 'loading'
    @isReleased = false
    
    store.on
      load: ->
        scroller.minPosition.y = 0
        scroller.scrollTo null, 0, true
        @resetRefreshState()
      delay: 100
      single: true
      scope: this
      
    if @getRefreshFn?
      @getRefreshFn().call this, this
    else
      @fetchLatest()
    
    return true