Ext.define 'WSI.view.WesawitRegister',
  extend: 'Ext.form.Panel'
  xtype: 'wesawitregister'
  config:
    padding: 0
    scrollable: false
  initialize: ->
    fieldset1 =
      xtype: 'fieldset'
      margin: '0 0 5 0'
      items: [
        {
          xtype: 'emailfield'
          name : 'email'
          placeHolder: 'your email address'
          style: 'font-size: 16px'
          ###
          listeners:
            keyup: ->
              if @getParent().getItems().getAt(1).getValue() is ''
                @getParent().getItems().getAt(1).setValue @getValue().substr(0,@getValue().indexOf('@'))
          ###
        },
        {
          xtype: 'textfield'
          autoCapitalize: false
          name : 'username'
          placeHolder: 'username (at least 4 characters)'
          style: 'font-size: 16px'
        },
        {
          xtype: 'passwordfield'
          name : 'password'
          placeHolder: 'password (at least 6 characters)'
          style: 'font-size: 16px'
        }
      ]
    registerButton =
      xtype: 'component'
      html: '<div class="form-group-toggle create" style="text-align: center;font-size: 18px;padding-top:5px;padding-bottom:5px;">Create Account</div>'
      listeners:
        tap:
          element: 'element'
          fn: (e) ->
            @getParent().onSubmitForm()
    @add([
      fieldset1
      registerButton
    ])
  onSubmitForm: ->
    @fireEvent 'submitForm'
