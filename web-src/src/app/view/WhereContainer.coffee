Ext.define 'WSI.view.WhereContainer',
  extend: 'Ext.Panel'
  xtype: 'wherecontainer'
  id: 'wherecontainer'
  config:
    fullscreen: true
    padding: '0 10 0 10'
    width: '100%'
    scrollable: false
    listeners:
      activate: ->
        @popSuggestionsList()
        
  initialize: ->
    nearbyList = 
      xtype: 'list'
      baseCls: 'locations-list'
      cls: [
        'nearby'
      ]
      height: 135
      padding: 0
      margin: 0
      itemHeight: 35
      variableHeights: false
      itemTpl: Ext.create('Ext.XTemplate',
        "<div class='place-result-thumb-container'>{[this.imageHtml(values, 25, 25)]}</div>"
        "{locationName}"
        {
          imageHtml: (values, w, h) ->
            html = "<img src='"
            if no and values.photos?
              html += values.photos[0].raw_reference.fife_url
              if values.photos[0].width >= values.photos[0].height
                h *= values.photos[0].height / values.photos[0].width
              else
                w *= values.photos[0].width / values.photos[0].height
              html += "' width='#{w}' height='#{h}' />"
            else
              html += values.icon
              html += "' width='#{w}' height='#{h}' />"
            html
        }
      )
      data: [
        {
          locationName: ''
          locationVicinity: ''
          locationLat: ''
          locationLng: ''
          reference: ''
          photos: null
          icon: ''
        }
      ]
      listeners:
        initialize: (c) ->
          c.getStore().removeAll true, true
          c.setHtml '<div class="x-loading-spinner-outer" style="margin-top: 40px;"><div class="x-loading-spinner" style="margin: 0px auto;"><span class="x-loading-top"></span><span class="x-loading-right"></span><span class="x-loading-bottom"></span><span class="x-loading-left"></span></div></div>'
        refresh: (c) ->
          removeLoadingSpinner = -> c.setHtml ''
          setTimeout removeLoadingSpinner, 500
        itemtap: (list, index, target, record) ->
          @getParent().chooseLocation record.raw.locationName, record.raw.locationVicinity, record.raw.locationLat, record.raw.locationLng, record.raw.locationType
          
    searchSuggList =
      xtype: 'list'
      baseCls: 'locations-list'
      cls: [
        'autocomplete'
      ]
      height: 100
      padding: 0
      margin: 0
      itemHeight: 35
      variableHeights: false
      itemTpl: Ext.create('Ext.XTemplate',
        "{[values.locationName]}{[(values.locationVicinity != '' ? ', <span class=\"vicinity\">' + values.locationVicinity + '</span>' : '')]}"
      )
      data: [
        {
          locationName: ''
          locationVicinity: ''
          locationLat: ''
          locationLng: ''
          reference: ''
        }
      ]
      listeners:
        initialize: (c) ->
          c.getStore().removeAll true, true
        itemtap: (list, index, target, record) ->
          @getParent().chooseLocation record.raw.locationName, record.raw.locationVicinity, record.raw.locationLat, record.raw.locationLng, record.raw.locationType, record.raw.reference
    
    @add([
      {
        xtype: 'component'
        margin: '10 0 0 0'
        html: '<div class="event-details-facts" style="padding: 10px !important;text-transform: none !important;">Nearby Locations</div>'
      }
      nearbyList
      {
        xtype: 'component'
        height: 10
        style:
          fontSize: '13px'
          fontWeight: 'normal'
          background: '#f5f5f5'
          border: '1px solid #aaa'
          borderTop: 'none'
          borderBottomLeftRadius: '4px'
          borderBottomRightRadius: '4px'
      }
      {
        xtype: 'component'
        margin: '10 0 0 0'
        html: '<div class="event-details-facts" style="padding: 10px !important;text-transform: none !important;">Or, search for a location below:</div>'
      }
      {
        xtype: 'textfield'
        cls: 'event-details-facts'
        margin: '0 0 0 0'
        style:
          border: '1px solid #aaa'
          borderBottom: 'none'
          opacity: 1
          display: 'block'
          color: '#333'
          borderRadius: '0px'
          background: '#eee'
        placeHolder: 'Enter location'
        listeners:
          action: ->
            return false
          keyup: ->
            searchSuggList.getStore?().removeAll true, true
            s2 = new Array()
            # first check our custom locations
            input = @getValue()
            for loc in window.util.customLocations
              if input.toUpperCase().replace(' ','') is loc[0].toUpperCase().replace(' ','')
                maxRadius = Math.max( ( ( loc[1] - loc[3] ) * 68.88 * 1609.344 ), ( ( loc[2] - loc[4] ) * -1 * 59.95 * 1609.344 ) ) / 2 # in meters. 1609.344 meters in a mile. deg of lat = miles / 68.88. deg of lng = miles / 59.95. ONLY WORKS FOR northeast hemisphere of earth. the /2 is because we want radius not diameter
                s2.push
                  'locationName': loc[0]
                  'locationVicinity': 'UCLA, Los Angeles'
                  'locationLat': ( loc[3] + (loc[1]-loc[3]) / 2 ) # center point latitude
                  'locationLng': ( loc[4] + (loc[2]-loc[4]) / 2 ) # center point longitude
                  'locationType': "custom_radius:#{parseInt(maxRadius)}"
            # now get suggs from google
            Ext.Ajax.request
              url: 'https://maps.googleapis.com/maps/api/place/autocomplete/json?types=establishment|geocode&radius=1000&location='+window.localStorage.getItem('locationLat')+','+window.localStorage.getItem('locationLng')+'&sensor=true&key=---REMOVED---'
              params:
                'input': input
              timeout: 30000
              method: 'GET'
              scope: this
              success: (response) ->
                resp = Ext.JSON.decode response.responseText
                if resp.status is 'OK'
                  searchSuggList = @getParent().getItems().getAt(5)
                  for p in resp.predictions
                    isAddress = p.terms[0].value is ""+parseInt(p.terms[0].value)
                    locationName = if isAddress then p.terms[0].value + " " + p.terms[1]?.value else p.terms[0].value
                    s2.push
                      'locationName': locationName
                      'locationVicinity': p.description.replace locationName+', ', ''
                      'locationLat': '0'
                      'locationLng': '0'
                      'reference': p.reference
                  searchSuggList.getStore().setData s2
        }
        searchSuggList
        {
          xtype: 'component'
          height: 10
          style:
            fontSize: '13px'
            fontWeight: 'normal'
            background: '#f5f5f5'
            border: '1px solid #aaa'
            borderTop: 'none'
            borderBottomLeftRadius: '4px'
            borderBottomRightRadius: '4px'
        }
    ])
    
  chooseLocation: (locationName, locationVicinity, locationLat, locationLng, locationType = '', reference = '') ->
    @fireEvent 'newEventChooseLocation', locationName, locationVicinity, locationLat, locationLng, locationType, reference, true
    
  popSuggestionsList: ->
    @fireEvent 'generateSuggestions', @getAt(1)