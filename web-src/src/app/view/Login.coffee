Ext.define 'WSI.view.Login',
  extend: 'Ext.form.Panel'
  xtype: 'wesawitlogin'
  config:
    scrollable: false
  initialize: ->
    loginFieldset =
      xtype: 'fieldset'
      margin: '0 0 5 0'
      items: [
        {
          xtype: 'emailfield'
          placeHolder: 'username or email'
          name : 'login'
          style: 'font-size:15px;'
        },
        {
          xtype: 'passwordfield'
          id: 'wesawitpasswordfield'
          name : 'password'
          placeHolder: 'password'
          style: 'font-size:15px;'
        }
      ]
    loginButton =
      xtype: 'component'
      html: '<div class="form-group-toggle create" style="text-align: center;font-size: 18px;padding-top:5px;padding-bottom:5px;">Login</div>'
      listeners:
        tap:
          element: 'element'
          fn: (e) ->
            @getParent().onSubmitForm()
    @add([
      loginFieldset
      loginButton
    ])
  onSubmitForm: ->
    @fireEvent 'submitForm'