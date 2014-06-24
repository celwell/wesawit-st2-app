Ext.define 'WSI.view.TopToolbar',
  extend: 'Ext.Toolbar'
  xtype: 'toptoolbar'
  config:
    docked: 'top'
    ui: 'blue'
    height: 'auto'
    minHeight: 'auto'
    title: '&nbsp;'
  initialize: () ->
    @callParent arguments
    homeButton =
      xtype: 'button'
      id: 'homeButton'
      cls: 'x-button-cback'
      text: ' '
      hidden: yes
      dest: 0 # which item index to the button should take us to
      busyHandling: no
      handler: @onHomeButtonTap
      scope: this
    createEventButton =
      xtype: 'button'
      id: 'createEventButton'
      cls: 'x-button-create'
      #style: if Ext.os.is.Android then 'margin-top: -999px !important;' else ''
      text: ' '
      handler: @onCreateEventButtonTap
      scope: this
    moreActionsButton =
      xtype: 'button'
      id: 'moreActionsButton'
      cls: 'x-button-more-actions'
      hidden: true
      text: ' '
      handler: ->
        @fireEvent 'moreActionsButtonTap'
      scope: this
    @add([
      homeButton
      { xtype: 'spacer' }
      moreActionsButton
      #createEventButton
    ])
    
  onHomeButtonTap: () ->
    @fireEvent 'homeButtonTap'
    
  onCreateEventButtonTap: () ->
    @fireEvent 'createEventButtonTap'