Ext.define "WSI.view.DateTime",
  extend: "Ext.picker.Picker"
  xtype: "datetimepicker"
  alternateClassName: "Ext.ux.DateTimePicker"
  requires: ["Ext.DateExtras"]
  config:
    
    ###
    @cfg {Number} yearFrom
    The start year for the date picker.
    @accessor
    ###
    yearFrom: 1980
    
    ###
    @cfg {Number} yearTo
    The last year for the date picker.
    @default the current year (new Date().getFullYear())
    @accessor
    ###
    yearTo: new Date().getFullYear()
    
    ###
    @cfg {String} monthText
    The label to show for the month column.
    @accessor
    ###
    monthText: (if (Ext.os.deviceType.toLowerCase() is "phone") then "M" else "Month")
    
    ###
    @cfg {String} dayText
    The label to show for the day column.
    @accessor
    ###
    dayText: (if (Ext.os.deviceType.toLowerCase() is "phone") then "j" else "Day")
    
    ###
    @cfg {String} yearText
    The label to show for the year column.
    @accessor
    ###
    yearText: (if (Ext.os.deviceType.toLowerCase() is "phone") then "Y" else "Year")
    
    ###
    @cfg {String} hourText
    The label to show for the hour column. Defaults to 'Hour'.
    ###
    hourText: (if (Ext.os.deviceType.toLowerCase() is "phone") then "H" else "Hour")
    
    ###
    @cfg {String} minuteText
    The label to show for the minute column. Defaults to 'Minute'.
    ###
    minuteText: (if (Ext.os.deviceType.toLowerCase() is "phone") then "i" else "Minute")
    
    ###
    @cfg {String} ampmText
    The label to show for the ampm column. Defaults to 'AM/PM'.
    ###
    ampmText: (if (Ext.os.deviceType.toLowerCase() is "phone") then "A" else "AM/PM")
    
    ###
    @cfg {Array} slotOrder
    An array of strings that specifies the order of the slots.
    @accessor
    ###
    slotOrder: ["month", "day", "year", "hour", "minute", "ampm"]
    
    ###
    @cfg {Int} minuteInterval
    @accessor
    ###
    minuteInterval: 15
    
    ###
    @cfg {Boolean} ampm
    @accessor
    ###
    ampm: false

  
  ###
  @cfg {Object/Date} value
  Default value for the field and the internal {@link Ext.picker.Date} component. Accepts an object of 'year',
  'month' and 'day' values, all of which should be numbers, or a {@link Date}.
  
  Examples:
  {year: 1989, day: 1, month: 5} = 1st May 1989.
  new Date() = current date
  @accessor
  ###
  
  ###
  @cfg {Boolean} useTitles
  Generate a title header for each individual slot and use
  the title configuration of the slot.
  @accessor
  ###
  
  ###
  @cfg {Array} slots
  @hide
  @accessor
  ###
  initialize: ->
    @callParent()
    @on
      scope: this
      delegate: "> slot"
      slotpick: @onSlotPick


  setValue: (value, animated) ->
    if Ext.isDate(value)
      ampm = "AM"
      currentHours = hour = value.getHours()
      if @getAmpm()
        if currentHours > 12
          ampm = "PM"
          hour -= 12
        else if currentHours is 12
          ampm = "PM"
        else hour = 12  if currentHours is 0
      value =
        day: value.getDate()
        month: value.getMonth() + 1
        year: value.getFullYear()
        hour: hour
        minute: value.getMinutes()
        ampm: ampm
    @callParent [value, animated]

  getValue: ->
    values = {}
    daysInMonth = undefined
    day = undefined
    hour = undefined
    minute = undefined
    items = @getItems().items
    ln = items.length
    item = undefined
    i = undefined
    i = 0
    while i < ln
      item = items[i]
      values[item.getName()] = item.getValue()  if item instanceof Ext.picker.Slot
      i++
    daysInMonth = @getDaysInMonth(values.month, values.year)
    day = Math.min(values.day, daysInMonth)
    hour = values.hour
    minute = values.minute

    yearval = (if (isNaN(values.year)) then new Date().getFullYear() else values.year)
    monthval = (if (isNaN(values.month)) then (new Date().getMonth()) else (values.month - 1))
    dayval = (if (isNaN(day)) then (new Date().getDate()) else day)
    hourval = (if (isNaN(hour)) then new Date().getHours() else hour)
    minuteval = (if (isNaN(minute)) then new Date().getMinutes() else minute)
    hourval = hourval + 12  if values.ampm and values.ampm is "PM" and hourval < 12
    hourval = 0  if values.ampm and values.ampm is "AM" and hourval is 12
    new Date(yearval, monthval, dayval, hourval, minuteval)

  
  ###
  Updates the yearFrom configuration
  ###
  updateYearFrom: ->
    @createSlots()  if @initialized

  
  ###
  Updates the yearTo configuration
  ###
  updateYearTo: ->
    @createSlots()  if @initialized

  
  ###
  Updates the monthText configuration
  ###
  updateMonthText: (newMonthText, oldMonthText) ->
    innerItems = @getInnerItems
    ln = innerItems.length
    item = undefined
    i = undefined
    
    #loop through each of the current items and set the title on the correct slice
    if @initialized
      i = 0
      while i < ln
        item = innerItems[i]
        item.setTitle newMonthText  if (typeof item.title is "string" and item.title is oldMonthText) or (item.title.html is oldMonthText)
        i++

  
  ###
  Updates the dayText configuraton
  ###
  updateDayText: (newDayText, oldDayText) ->
    innerItems = @getInnerItems
    ln = innerItems.length
    item = undefined
    i = undefined
    
    #loop through each of the current items and set the title on the correct slice
    if @initialized
      i = 0
      while i < ln
        item = innerItems[i]
        item.setTitle newDayText  if (typeof item.title is "string" and item.title is oldDayText) or (item.title.html is oldDayText)
        i++

  
  ###
  Updates the yearText configuration
  ###
  updateYearText: (yearText) ->
    innerItems = @getInnerItems
    ln = innerItems.length
    item = undefined
    i = undefined
    
    #loop through each of the current items and set the title on the correct slice
    if @initialized
      i = 0
      while i < ln
        item = innerItems[i]
        item.setTitle yearText  if item.title is @yearText
        i++

  
  # @private
  constructor: ->
    @callParent arguments
    @createSlots()

  
  ###
  Generates all slots for all years specified by this component, and then sets them on the component
  @private
  ###
  createSlots: ->
    me = this
    slotOrder = @getSlotOrder()
    yearsFrom = me.getYearFrom()
    yearsTo = me.getYearTo()
    years = []
    days = []
    months = []
    hours = []
    minutes = []
    ampm = []
    ln = undefined
    tmp = undefined
    i = undefined
    daysInMonth = undefined
    unless @getAmpm()
      index = slotOrder.indexOf("ampm")
      slotOrder.splice index  if index >= 0
    
    # swap values if user mixes them up.
    if yearsFrom > yearsTo
      tmp = yearsFrom
      yearsFrom = yearsTo
      yearsTo = tmp
    i = yearsFrom
    while i <= yearsTo
      years.push
        text: i
        value: i

      i++
    daysInMonth = @getDaysInMonth(1, new Date().getFullYear())
    i = 0
    while i < daysInMonth
      days.push
        text: i + 1
        value: i + 1

      i++
    i = 0
    ln = Ext.Date.monthNames.length

    while i < ln
      months.push
        text: (if (Ext.os.deviceType.toLowerCase() is "phone") then Ext.Date.monthNames[i].substring(0, 3) else Ext.Date.monthNames[i])
        value: i + 1

      i++
    hourLimit = (if (@getAmpm()) then 12 else 23)
    hourStart = (if (@getAmpm()) then 1 else 0)
    i = hourStart
    while i <= hourLimit
      hours.push
        text: @pad2(i)
        value: i

      i++
    i = 0
    while i < 60
      minutes.push
        text: @pad2(i)
        value: i

      i += @getMinuteInterval()
    ampm.push
      text: "AM"
      value: "AM"
    ,
      text: "PM"
      value: "PM"

    slots = []
    slotOrder.forEach ((item) ->
      slots.push @createSlot(item, days, months, years, hours, minutes, ampm)
    ), this
    me.setSlots slots

  
  ###
  Returns a slot config for a specified date.
  @private
  ###
  createSlot: (name, days, months, years, hours, minutes, ampm) ->
    switch name
      when "year"
        name: "year"
        align: (if (Ext.os.deviceType.toLowerCase() is "phone") then "left" else "center")
        data: years
        title: @getYearText()
        flex: (if (Ext.os.deviceType.toLowerCase() is "phone") then 1.3 else 3)
      when "month"
        name: name
        align: (if (Ext.os.deviceType.toLowerCase() is "phone") then "left" else "right")
        data: months
        title: @getMonthText()
        flex: (if (Ext.os.deviceType.toLowerCase() is "phone") then 1.2 else 4)
      when "day"
        name: "day"
        align: (if (Ext.os.deviceType.toLowerCase() is "phone") then "left" else "center")
        data: days
        title: @getDayText()
        flex: (if (Ext.os.deviceType.toLowerCase() is "phone") then 0.9 else 2)
      when "hour"
        name: "hour"
        align: (if (Ext.os.deviceType.toLowerCase() is "phone") then "left" else "center")
        data: hours
        title: @getHourText()
        flex: (if (Ext.os.deviceType.toLowerCase() is "phone") then 0.9 else 2)
      when "minute"
        name: "minute"
        align: (if (Ext.os.deviceType.toLowerCase() is "phone") then "left" else "center")
        data: minutes
        title: @getMinuteText()
        flex: (if (Ext.os.deviceType.toLowerCase() is "phone") then 0.9 else 2)
      when "ampm"
        name: "ampm"
        align: (if (Ext.os.deviceType.toLowerCase() is "phone") then "left" else "center")
        data: ampm
        title: @getAmpmText()
        flex: (if (Ext.os.deviceType.toLowerCase() is "phone") then 1.1 else 2)

  onSlotPick: (pickedSlot, oldValue, htmlNode, eOpts) ->
    
    # We don't actually get passed the new value. I think this is an ST2 bug. Instead we get passed the slot,
    # the oldValue, the node in the slot which was moved to, and options for the event.
    #
    # However looking at the code that fires the slotpick event, the slot.selectedIndex is always set there
    # We can therefore use this to pull the underlying value that was picked out of the slot's store
    pickedValue = pickedSlot.getStore().getAt(pickedSlot.selectedIndex).get(pickedSlot.getValueField())
    pickedSlot.setValue pickedValue
    @repopulateDaySlot()  if pickedSlot.getName() is "month" or pickedSlot.getName() is "year"

  repopulateDaySlot: ->
    slot = @getDaySlot()
    days = []
    month = @getSlotByName("month").getValue()
    year = @getSlotByName("year").getValue()
    daysInMonth = undefined
    
    # Get the new days of the month for this new date
    daysInMonth = @getDaysInMonth(month, year)
    i = 0
    while i < daysInMonth
      days.push
        text: i + 1
        value: i + 1

      i++
    
    # We dont need to update the slot days unless it has changed
    return  if slot.getData().length is days.length
    slot.setData days

  getSlotByName: (name) ->
    @down "pickerslot[name=" + name + "]"

  getDaySlot: ->
    @getSlotByName "day"

  
  # @private
  getDaysInMonth: (month, year) ->
    daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    (if month is 2 and @isLeapYear(year) then 29 else daysInMonth[month - 1])

  
  # @private
  isLeapYear: (year) ->
    !!((year & 3) is 0 and (year % 100 or (year % 400 is 0 and year)))

  pad2: (number) ->
    ((if number < 10 then "0" else "")) + number
