Ext.define 'WSI.view.WhosThereContainer',
  extend: 'Ext.Container'
  xtype: 'whostherecontainer'
  id: 'whostherecontainer'
  requires: [
    'WSI.view.MediaStrip'
    'Ext.util.DelayedTask'
    'WSI.store.WhosThere'
  ]
  config:
    layout: 'fit'
    fullscreen: true
    padding: 0
    margin: 0
    items: [
      {
        xtype: 'list'
        cls: 'whosthere'
        padding: 0
        margin: 0
        itemHeight: 66
        refreshHeightOnUpdate: true
        variableHeights: true
        scrollable: true
        disableSelection: true
        pressedCls: false
        scrollToTopOnRefresh: false
        loadingText: 'loading...'
        emptyText: 'no one yet'
        expandedItem: false
        store: null
        listeners:
          itemtap: (list, index, target, record, e, eOpts) ->
            if list.config.expandedItem is false
              list.config.expandedItem = target
              for i,item of list.getViewItems()
                if item isnt target
                  item.setStyle 'opacity: 0.25'
              target.add
                xtype: 'container'
                padding: '10 0 10 0'
                margin: '0 0 0 0'
                html: '<div class="container-inlet-triangle"></div>'
                style:
                  background: '#444'
                  boxShadow: '0px -50px 50px -50px rgba(0,0,0,0.9) inset, 0px 50px 50px -50px rgba(0,0,0,0.9) inset'
                layout: 'fit'
                height: 185
                items: [
                  {
                    xtype: 'mediastrip'
                    homeButtonDest: 'to-whosthere-from-gallery'
                    padding: '0 0 0 10'
                    margin: 0
                    cls: 'second-row-mediastrip'
                    style:
                      background: 'transparent !important'
                    data: if record.get('medias').length > 0 then record.get('medias') else new Array()
                    height: 165
                  }
                ]
              list.refresh()
              list.getScrollable().getScroller().scrollTo 0, index * 66, true
              list.getScrollable().getScroller().setDisabled true
              target.getAt( target.getItems().length - 1 ).setHidden true
              target.getAt( target.getItems().length - 1 ).show
                duration: 300
                easing: 'ease'
                from:
                  'opacity': '0'
                to:
                  'opacity': '1'
            else
              list.config.expandedItem.removeAt list.config.expandedItem.getItems().length - 1, true
              list.config.expandedItem = false
              for i,item of list.getViewItems()
                item.setStyle 'opacity: 1'
              list.getScrollable().getScroller().setDisabled false
              list.refresh()
            
        itemTpl: Ext.create('Ext.XTemplate',
          "<img src='{[this.profileImageUrl(values.id)]}' class='profile-image' width='50' height='50' />"
          "<div class='name-line{[(values.friend ? ' friend' : '')]}'>"
            "<div class='name'>{username}</div>"
            "<div class='photo-count'>{[this.numOf(values.medias, 'photos')]}</div>"
            "<div class='video-count'>{[this.numOf(values.medias, 'videos')]}</div>"
          "</div>"
          {
            profileImageUrl: (uid) ->
              uid = uid.toString()
              if uid.substr(0,2) is 'fb'
                "https://graph.facebook.com/#{uid.substr 2}/picture?width=130&height=130"
              else if uid.substr(0,10) is 'instagram_'
                'resources/images/instagram-icon-square-114.png'
              else if uid.substr(0,5) is 'vine_'
                'resources/images/vine-icon-square-114.png'
              else
                'resources/images/tarsier-square-no-padding.png'
            numOf: (medias, type) ->
              key = ''
              if type is 'photos' then key = 'pid'
              if type is 'videos' then key = 'vid'
              count = 0
              for i,media of medias
                if media[key]?
                  count++
              count
          }
        )
      }
    ]
    
  initialize: ->
    @getAt(0).setStore Ext.getStore('WhosThere')
    
  changeWhosThere: (record) ->
    if not util.getTenseOfToBe(record.get('dateTimeStart'), record.get('dateTimeEnd'))?
      @getAt(0).setEmptyText 'event hasn\'t started yet'
    @getAt(0).getStore().getProxy().config.extraParams.eid = record.get 'id'
    @getAt(0).setMasked
      xtype: 'loadmask'
      message: ''
    @getAt(0).getStore().load()
