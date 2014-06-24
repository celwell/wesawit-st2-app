Ext.define "WSI.view.DateTimePicker",
  extend: "Ext.field.Text"
  alternateClassName: "Ext.form.DateTimePicker"
  xtype: "datetimepickerfield"
  requires: ["WSI.view.DateTime", "Ext.DateExtras"]
  
  ###
  @event change
  Fires when a date is selected
  @param {Ext.ux.field.DateTimePicker} this
  @param {Date} date The new date
  ###
  config:
    ui: "select"
    
    ###
    @cfg {Object/WSI.view.DateTime} picker
    An object that is used when creating the internal {@link WSI.view.DateTime} component or a direct instance of {@link WSI.view.DateTime}
    Defaults to true
    @accessor
    ###
    picker: true
    
    ###
    @cfg {Boolean}
    @hide
    @accessor
    ###
    clearIcon: false
    
    ###
    @cfg {Object/Date} value
    Default value for the field and the internal {@link WSI.view.DateTime} component. Accepts an object of 'year',
    'month' and 'day' values, all of which should be numbers, or a {@link Date}.
    
    Example: {year: 1989, day: 1, month: 5} = 1st May 1989 or new Date()
    @accessor
    ###
    
    ###
    @cfg {Boolean} destroyPickerOnHide
    Whether or not to destroy the picker widget on hide. This save memory if it's not used frequently,
    but increase delay time on the next show due to re-instantiation. Defaults to false
    @accessor
    ###
    destroyPickerOnHide: false
    
    ###
    @cfg {String} dateTimeFormat The format to be used when displaying the date in this field.
    Accepts any valid datetime format. You can view formats over in the {@link Ext.Date} documentation.
    Defaults to `Ext.util.Format.defaultDateFormat`.
    ###
    dateTimeFormat: "m/d/Y h:i:A"
    
    ###
    @cfg {Object}
    @hide
    ###
    component:
      useMask: true

  initialize: ->
    @callParent()
    @getComponent().on
      scope: this
      masktap: "onMaskTap"

    @getComponent().input.dom.disabled = true

  syncEmptyCls: Ext.emptyFn
  applyValue: (value) ->
    value = null  if not Ext.isDate(value) and not Ext.isObject(value)
    value = new Date(value.year, value.month - 1, value.day, value.hour, value.minute)  if Ext.isObject(value)
    value

  updateValue: (newValue) ->
    picker = @_picker
    picker.setValue newValue  if picker and picker.isPicker
    
    # Ext.Date.format expects a Date
    if newValue isnt null
      @getComponent().setValue Ext.Date.format(newValue, @getDateTimeFormat() or Ext.util.Format.defaultDateFormat)
    else
      @getComponent().setValue ""
    @_picker.setValue newValue  if @_picker and @_picker instanceof WSI.view.DateTime

  
  ###
  Updates the date format in the field.
  @private
  ###
  updateDateFormat: (newDateFormat, oldDateFormat) ->
    value = @getValue()
    @getComponent().setValue Ext.Date.format(value, newDateFormat or Ext.util.Format.defaultDateFormat)  if newDateFormat isnt oldDateFormat and Ext.isDate(value) and @_picker and @_picker instanceof WSI.view.DateTime

  
  ###
  Returns the {@link Date} value of this field.
  If you wanted a formated date
  @return {Date} The date selected
  ###
  getValue: ->
    return @_picker.getValue()  if @_picker and @_picker instanceof WSI.view.DateTime
    @_value

  
  ###
  Returns the value of the field formatted using the specified format. If it is not specified, it will default to
  {@link #dateFormat} and then {@link Ext.util.Format#defaultDateFormat}.
  @param {String} format The format to be returned
  @return {String} The formatted date
  ###
  getFormattedValue: (format) ->
    value = @getValue()
    console.log @getDateTimeFormat(), "format"
    (if (Ext.isDate(value)) then Ext.Date.format(value, format or @getDateTimeFormat() or Ext.util.Format.defaultDateFormat) else value)

  applyPicker: (picker, pickerInstance) ->
    picker = pickerInstance.setConfig(picker)  if pickerInstance and pickerInstance.isPicker
    picker

  getPicker: ->
    picker = @_picker
    value = @getValue()
    if picker and not picker.isPicker
      picker = Ext.factory(picker, WSI.view.DateTime)
      picker.on
        scope: this
        cancel: "onPickerCancel"
        change: "onPickerChange"
        hide: "onPickerHide"

      picker.setValue value  if value isnt null
      Ext.Viewport.add picker
      @_picker = picker
    picker

  
  ###
  @private
  Listener to the tap event of the mask element. Shows the internal DatePicker component when the button has been tapped.
  ###
  onMaskTap: ->
    return false  if @getDisabled()
    return false  if @getReadOnly()
    @getPicker().show()
    false

  
  ###
  @private
  Revert internal date so field won't appear changed
  ###
  onPickerCancel: (picker, options) ->
    @_picker = @_picker.config
    picker.destroy()
    true

  
  ###
  Called when the picker changes its value
  @param {WSI.view.DateTime} picker The date picker
  @param {Object} value The new value from the date picker
  @private
  ###
  onPickerChange: (picker, value) ->
    me = this
    me.setValue value
    me.fireEvent "change", me, me.getValue()

  
  ###
  Destroys the picker when it is hidden, if
  {@link Ext.ux.field.DateTimePicker#destroyPickerOnHide destroyPickerOnHide} is set to true
  @private
  ###
  onPickerHide: ->
    picker = @getPicker()
    if @getDestroyPickerOnHide() and picker
      picker.destroy()
      @_picker = true

  reset: ->
    @setValue @originalValue

  
  # @private
  destroy: ->
    picker = @getPicker()
    picker.destroy()  if picker and picker.isPicker
    @callParent arguments

#<deprecated product=touch since=2.0>
, ->
  @override getValue: (format) ->
    if format
      
      #<debug warn>
      Ext.Logger.deprecate "format argument of the getValue method is deprecated, please use getFormattedValue instead", this
      
      #</debug>
      return @getFormattedValue(format)
    @callOverridden()

  
  ###
  @method getDatePicker
  @inheritdoc Ext.ux.field.DateTimePicker#getPicker
  @deprecated 2.0.0 Please use #getPicker instead
  ###
  Ext.deprecateMethod this, "getDatePicker", "getPicker"


#</deprecated>