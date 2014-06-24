Ext.application
  name: 'WSI'
  #viewport:
  #  autoMaximize: not util.TO_BE_NATIVELY_PACKAGED # only use this settings when building for non-native (i.e., wesawit.com/mobile) cause it can cause bugs in phonegap i've heard
  requires: [
    'Ext.plugin.ListPaging'
    'Ext.form.FieldSet'
    'Ext.form.Panel'
    'Ext.field.TextArea'
    'Ext.field.Email'
    'Ext.field.Search'
    'Ext.field.Password'
    'Ext.Anim'
    'WSI.plugin.BetterPullRefresh'
    'WSI.store.Events'
  ]
  stores: [
    'EventsCurrent'
    'EventsPast'
    'EventsFuture'
    'EventsSearch'
    'EventsMap'
    'WhosThere'
  ]
  controllers: [
    'Events'
    'Account'
  ]
  views: [
    'Main'
    'TopToolbar'
  ]
  launch: ->
    Ext.Viewport.add [
      Ext.create 'WSI.view.TopToolbar'
      Ext.create 'WSI.view.Main'
    ]
    # clean outthat preload div, we no longer need those there
    document.getElementById('images-to-preload').innerHTML = ""