Ext.define 'WSI.controller.Account',
  extend: 'Ext.app.Controller'
  config:
    refs:
      accountPanel: 'account'
      wesawitLogin: 'wesawitlogin'
      wesawitRegister: 'wesawitregister'
      feedbackForm: 'feedbackform'
      wesawitPasswordField: '#wesawitpasswordfield'
      facebookLoginButton: '#facebookloginbutton'
      wesawitLoginButton: '#wesawitloginbutton'
    control:
      accountPanel:
        facebookLoginButtonTap: 'onFacebookLoginButtonTap'
        wesawitLoginButtonTap: 'onWesawitLoginButtonTap'
        wesawitLogoutButtonTap: 'onWesawitLogoutButtonTap'
        wesawitRegisterButtonTap: 'onWesawitRegisterButtonTap'
      wesawitLogin:
        submitForm: 'onSubmitWesawitLoginForm'
      wesawitRegister:
        submitForm: 'onSubmitWesawitRegisterForm'
      feedbackForm:
        submitForm: 'onSubmitFeedbackForm'
        
  currentlyLoggingIn: no
        
  onFacebookLoginButtonTap: ->
    if not navigator.onLine
      navigator.notification.alert 'Unable to connect to internet.', (()->return), 'Oops!'
    else
      if Ext.os.is.Android
        window.plugins.childBrowser.onClose = ->
          return true
        window.plugins.childBrowser.onLocationChange = (url) =>
          if util.DEBUG then console.log 'onLocationChange called'
          if util.DEBUG then console.log url
          if url.indexOf('%23closeChildBrowser') isnt -1
            dataStr = url.substr(url.indexOf('%23closeChildBrowser')+21)
          else if url.indexOf('#closeChildBrowser') isnt -1
            dataStr = url.substr(url.indexOf('#closeChildBrowser')+19)
          if dataStr?
            dataArr = dataStr.split('/')
            for d in dataArr
              window.localStorage.setItem decodeURIComponent(decodeURIComponent(d.split('=')[0])), decodeURIComponent(decodeURIComponent(d.split('=')[1]))
            @loginStateChanged()
            @getAccountPanel().removeAll true, true
            @getAccountPanel().populateWithProperItems()
            @getAccountPanel().getParent().getParent().getParent().getParent().getTabBar().getItems().getAt(2).setBadgeText ''
            window.plugins.childBrowser.close()
        window.plugins.childBrowser.showWebPage 'https://m.facebook.com/dialog/oauth/?scope=email,user_birthday,user_events,publish_actions&client_id=361157600604985&redirect_uri=http://wesawit.com/login/mobile_receive',
          showLocationBar: true
      else
        ctrl = this
        window.plugins.facebookConnect.login(
          {
            permissions: [
              "email"
              "user_birthday"
              "user_events"
              "publish_actions"
            ]
            appId: "361157600604985"
          },
          (result) ->
            #navigator.notification.alert 'result: ' + JSON.stringify(result), (()->return), 'Log'
            #navigator.notification.alert 'accessToken: ' + result['accessToken'], (()->return), 'Log'
            if result['accessToken']? and result['accessToken'] isnt '' and not window.localStorage.getItem('wsitoken')? and not ctrl.currentlyLoggingIn # if not already logged in and not currently logging in
              ctrl.currentlyLoggingIn = yes
              Ext.Viewport.setMasked
                xtype: 'loadmask'
                message: ''
              Ext.Ajax.request
                url: "http://wesawit.com/login/native_fb"
                method: 'POST'
                params:
                  'accessToken': result['accessToken']
                timeout: 15000
                success: (response) ->
                  Ext.Viewport.setMasked false
                  resp = Ext.decode response.responseText
                  #navigator.notification.alert 'resp: ' + resp.toString(), (()->return), 'Log'
                  if resp.success
                    delete resp.success
                    #navigator.notification.alert 'was successful', (()->return), 'Log'
                    for key,val of resp
                      #navigator.notification.alert key + ': ' + val, (()->return), 'Log'
                      window.localStorage.setItem key, val
                    ctrl.loginStateChanged()
                    ctrl.getAccountPanel().removeAll true, true
                    ctrl.getAccountPanel().populateWithProperItems()
                    ctrl.getAccountPanel().getParent().getParent().getParent().getParent().getTabBar().getItems().getAt(2).setBadgeText ''
                    ctrl.currentlyLoggingIn = no
                  else
                    navigator.notification.alert resp.error_message, (()->return), 'Oops!'
                    ctrl.currentlyLoggingIn = no
                failure: (response) ->
                  Ext.Viewport.setMasked false
                  if response.timedout? and response.timedout
                    navigator.notification.alert 'Your internet connection seems to be going too slow.', (()->return), 'Hmm...'
                  else
                    navigator.notification.alert 'Please try again later.', (()->return), 'Oops!'
                  ctrl.currentlyLoggingIn = no
        )
        
  onWesawitLogoutButtonTap: ->
    if not navigator.onLine
      navigator.notification.alert 'Unable to connect to internet.', (()->return), 'Oops!'
    else
      window.localStorage.removeItem 'wsitoken'
      window.localStorage.removeItem 'uid'
      window.localStorage.removeItem 'username'
      window.localStorage.removeItem 'fbid'
      @getAccountPanel().removeAll true, true
      @getAccountPanel().populateWithProperItems()
      @getAccountPanel().getParent().getParent().getParent().getParent().getTabBar().getItems().getAt(2).setBadgeText 'Log in here'
      @loginStateChanged()
      
  onSubmitWesawitLoginForm: ->
    if not navigator.onLine
      navigator.notification.alert 'Unable to connect to internet.', (()->return), 'Oops!'
    else
      Ext.Viewport.setMasked(
        {
          xtype: 'loadmask'
          message: ''
        }
      )
      @getWesawitLogin().submit({
        url: 'http://wesawit.com/service/login'
        method: 'POST'
        params:
          'api_key': '---REMOVED---'
        success: (form, result) ->
          window.localStorage.setItem 'wsitoken', result.token
          window.localStorage.setItem 'uid', result.uid
          window.localStorage.setItem 'username', result.username
          @loginStateChanged()
          @getAccountPanel().getParent().getParent().getParent().getParent().getTabBar().getItems().getAt(2).setBadgeText ''
          Ext.Viewport.setMasked false
          @getAccountPanel().removeAll true, true
          @getAccountPanel().populateWithProperItems()
        failure: (form, result) ->
          Ext.Viewport.setMasked false
          navigator.notification.alert result.error_message, (()->return), 'Error'
          @getWesawitPasswordField().reset()
        scope: this
      })
      
  onSubmitWesawitRegisterForm: ->
    if not navigator.onLine
      navigator.notification.alert 'Unable to connect to internet.', (()->return), 'Oops!'
    else
      Ext.Viewport.setMasked(
        {
          xtype: 'loadmask'
          message: ''
        }
      )
      @getWesawitRegister().submit
        url: 'http://wesawit.com/service/register'
        method: 'POST'
        params:
          'api_key': '---REMOVED---'
        success: (form, res) ->
          # now log them in
          Ext.Ajax.request
            url: 'http://wesawit.com/service/login'
            method: 'POST'
            params:
              'api_key': '---REMOVED---'
              'login': form.getValues().username
              'password': form.getValues().password
            scope: this
            success: (response) ->
              result = Ext.JSON.decode response.responseText
              window.localStorage.setItem 'wsitoken', result.token
              window.localStorage.setItem 'uid', result.uid
              window.localStorage.setItem 'username', result.username
              @loginStateChanged()
              @getAccountPanel().getParent().getParent().getParent().getParent().getTabBar().getItems().getAt(2).setBadgeText ''
              Ext.Viewport.setMasked false
              @getAccountPanel().removeAll true, true
              @getAccountPanel().populateWithProperItems()
            failure: ->
              Ext.Viewport.setMasked false
              navigator.notification.alert result.error_message, (()->return), 'Error'
              @getWesawitPasswordField().reset()
        failure: (form, result) ->
          Ext.Viewport.setMasked false
          navigator.notification.alert result.error_message, (()->return), 'Error'
        scope: this
      
  onSubmitFeedbackForm: ->
    if not navigator.onLine
      navigator.notification.alert 'Unable to connect to internet.', (()->return), 'Oops!'
    else
      Ext.Viewport.setMasked(
        {
          xtype: 'loadmask'
          message: ''
        }
      )
      p = new Array()
      for i in [0..localStorage.length-1]
        p[window.localStorage.key(i)] = window.localStorage.getItem( window.localStorage.key i )
      p['api_key'] = '---REMOVED---'
      p['Device_Name'] = device?.name
      p['Device_Platform'] = device?.platform
      p['Device_UUID'] = device?.uuid # fyi this is not super helpful especially on iOS (because of the way it is generated and how often that happens)
      p['Device_Version'] = device?.version
      p['Device_Cordova'] = device?.cordova
      p['APP_VERSION'] = window.util.APP_VERSION
      p['API_VERSION'] = window.util.API_VERSION
      delete p['listOfCountries']
      delete p['wsitoken']
      @getFeedbackForm().submit({
        url: 'http://wesawit.com/feedback/app'
        method: 'POST'
        params: p
        success: (form, result) ->
          navigator.notification.alert 'Your feedback is extremely valuable to us!', (()->return), 'Thank you!'
          Ext.Viewport.setMasked false
          @getAccountPanel().removeAll true, true
          @getAccountPanel().populateWithProperItems()
        failure: (form, result) ->
          Ext.Viewport.setMasked false
          navigator.notification.alert result.error_message, (()->return), 'Error'
        scope: this
      })
      
  loginStateChanged: ->
    #@refreshForEventDetails() obviously that wont work in this scope, but we'll have to do something similar to update the eventdetailscontainer after login state changes
    Ext.data.StoreManager.each ->
      if @isLoaded() then @load() # reload all the stores that have been loaded at least once