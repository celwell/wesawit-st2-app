Ext.define 'WSI.view.FeedbackForm',
  extend: 'Ext.form.Panel'
  xtype: 'feedbackform'
  
  config:
    scrollable: false
  
  initialize: ->
    submitButton =
      xtype: 'component'
      html: '<div class="form-group-toggle create" style="text-align: center;font-size: 18px;padding-top:5px;padding-bottom:5px;">Send</div>'
      margin: '5 0 0 0'
      listeners:
        tap:
          element: 'element'
          fn: (e) ->
            @getParent().onSubmitForm()
    @add
      xtype: 'textareafield'
      name : 'Feedback_Content'
      rows: 1
      maxLength: 200
      placeHolder: 'Please write bugs/questions/feedback here.'
      flex: 1
      value: ''
      style:
        background: '#F5F5F5'
        fontSize: '13px'
        textShadow: '0px 1px 0px #eee'
        color: '#444'
        border: '1px solid #aaa'
        borderRadius: '4px'
    if not window.localStorage.getItem('wsitoken')?
      @add
        xtype: 'emailfield'
        placeHolder: 'email address (if response needed)'
        name : 'Email_Address'
        style: 'font-size: 15px'
    @add submitButton
  onSubmitForm: ->
    @fireEvent 'submitForm'