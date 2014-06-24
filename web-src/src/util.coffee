window.util =

  APP_VERSION: '1.4.0'
  API_VERSION: 4
  TO_BE_NATIVELY_PACKAGED: yes # mainly affects whether or not to use viewport resize to fullscreen 
  DEBUG: no # window.location.toString().indexOf('index-debug.html') isnt -1 # note that debug mode will turn off google analytics
  S3_BASE_URL: 'http://wweye1.s3.amazonaws.com/'

  commaize_number: (num) ->
    num.toString().replace /(\d)(?=(\d\d\d)+(?!\d))/g, "$1,"

  calc_time: (date, endDate = false, customDateFormat = false, abbrev = false) ->
    dateNow = new Date()
    diff = (dateNow.getTime() - date.getTime()) / 1000
    day_diff = Math.floor(diff / 86400)
    if isNaN(day_diff)
      return
    if endDate isnt false
      duration_of_event = (endDate.getTime() - date.getTime()) / 1000
      if day_diff < 0
        if day_diff < -1 then "<div class='not-now'>" + (Ext.util.Format.date date, 'j M Y') + "</div>"
        else if diff < -3600 then "<div class='not-now'>in " + Math.floor( -1 * diff / 3600 ) + " hr</div>"
        else if Math.floor( -1 * diff / 60 ) > 0 then "<div class='not-now'>in " + Math.floor( -1 * diff / 60 ) + " min</div>"
        else "<div class='now'>Now</div>"
      else if day_diff is 0
        if diff < duration_of_event then "<div class='now'>Now</div>"
        else "<div class='not-now'>" + Math.floor( diff / 3600 ) + " hr ago</div>"
      else if false and day_diff > 0
        if day_diff is 1 then "<div class='not-now'>Yesterday</div>"
        else if day_diff < 7 then "<div class='not-now'>" + day_diff + " day" + (if day_diff isnt 1 then 's' else '') + " ago</div>"
        else if day_diff < 14 then "<div class='not-now'>" + Math.ceil( day_diff / 7 ) + " wk" + (if Math.ceil(day_diff/7) isnt 1 then 's' else '') + " ago</div>"
        else "<div class='not-now'>" + (Ext.util.Format.date date, 'j M Y') + "</div>"
      else "<div class='not-now'>" + (Ext.util.Format.date date, 'j M Y') + "</div>"
    else
      if day_diff is 0
        if diff < 60
          Math.floor( diff ) + if abbrev then "s ago" else " second#{if Math.floor(diff) isnt 1 then 's' else ''} ago"
        else if diff < 3600
          Math.floor( diff / 60 ) + if abbrev then "m ago" else " minute#{if Math.floor( diff / 60 ) isnt 1 then 's' else ''} ago"
        else if diff < 7200
          Math.floor( diff / 3600 ) + if abbrev then "h ago" else " hour#{if Math.floor( diff / 3600 ) isnt 1 then 's' else ''} ago"
        else Ext.util.Format.date date, customDateFormat or 'M. j, Y \\a\\t g:i a'
      else if false and day_diff > 0
        if day_diff is 1 then "Yesterday" + ( Ext.util.Format.date date, ' \\a\\t g:i a' )
        else if day_diff < 7 then day_diff + " day#{if day_diff isnt 1 then 's' else ''} ago"
        else if day_diff < 365 then Math.ceil( day_diff / 7 ) + " week#{if Math.ceil( day_diff / 7 ) isnt 1 then 's' else ''} ago"
        else Math.ceil( day_diff / 365 ) + " year#{if Math.ceil( day_diff / 365 ) isnt 1 then 's' else ''} ago"
      else Ext.util.Format.date date, customDateFormat or 'M. j, Y \\a\\t g:i a'
  
  getTenseOfToBe: (date, endDate = false, singular = false) ->
    diff = ((new Date()).getTime() - date.getTime()) / 1000
    day_diff = Math.floor(diff / 86400)
    if isNaN(day_diff)
      return
    if endDate isnt false
      duration_of_event = (endDate.getTime() - date.getTime()) / 1000
      if day_diff < 0
        if singular then null
      else if day_diff is 0 and diff < duration_of_event
        if singular then "is" else "are" # present
      else
        if singular then "was" else "were" # past
    else
      if util.DEBUG then console.log 'error, endDate is false. line #63'
      null

  calc_distance: (lat, lng, abbrev = true, htmlBeforeUnits = '') ->
    if not lat? or not lng? or ( lat is '0' and lng is '0' ) or not window.localStorage.getItem('locationLat')? or not window.localStorage.getItem('locationLng')? or window.localStorage.getItem('locationLat') is '0' or window.localStorage.getItem('locationLng') is '0'
      return ""
    lat_diff = parseFloat(window.localStorage.getItem('locationLat')) - parseFloat(lat)
    lng_diff = parseFloat(window.localStorage.getItem('locationLng')) - parseFloat(lng)
    # approx conversion at 30 degrees north or south of equator, ref: http://www.zodiacal.com/tools/lat_table.php
    miles_lat_diff = lat_diff * 68.88
    miles_lng_diff = lng_diff * 59.95
    miles_away = Math.sqrt( miles_lat_diff * miles_lat_diff + miles_lng_diff * miles_lng_diff )
    if miles_away < 0.1
      feet_away = miles_away * 5280
      if Math.floor(feet_away) > 999
        feet_away = feet_away / 1000 # cut down to Ks
        @commaize_number(Math.floor(feet_away)) + "k#{htmlBeforeUnits}" + if abbrev then " ft" else ' feet'
      else
        @commaize_number(Math.floor(feet_away)) + "#{htmlBeforeUnits}" + if abbrev then ' ft' else (" #{if Math.floor(feet_away) isnt 1 then 'feet' else 'foot'}")
    else if miles_away < 20
      @commaize_number(Math.floor(miles_away*10)/10) + "#{htmlBeforeUnits}" + if abbrev then ' mi' else (" mile#{if Math.floor(miles_away*10)/10 isnt 1 then 's' else ''}") # get one decimal place
    else
      if Math.floor(miles_away) > 999
        miles_away = miles_away / 1000 # cut down to Ks
        @commaize_number(Math.floor(miles_away)) + "k#{htmlBeforeUnits}" + if abbrev then ' mi' else " miles"
      else
        @commaize_number(Math.floor(miles_away)) + "#{htmlBeforeUnits}" + if abbrev then ' mi' else (" mile#{if Math.floor(miles_away) isnt 1 then 's' else ''}")

  image_url: (values, size = 'small', event = no, allowLocalUrls = yes) ->
    # size can be:
    # large
    # medium - for wesawit photos is the same as small, but it uses 'low_resolution' for instagram
    # small
    if event
      values = values.top_photo ? values.top_video ? new Array()
    if values.thumbUrl? and values.thumbUrl isnt '' and (allowLocalUrls or values.thumbUrl.indexOf '/var/' is -1)
      switch size
        when 'large' then values.url ? values.mediumUrl ? values.thumbUrl
        when 'medium' then values.mediumUrl ? values.thumbUrl
        when 'small' then values.thumbUrl
    else
      if values.pid?
        "#{util.S3_BASE_URL}#{
        switch size
          when 'large', 'medium' then 'econ'
          #when 'medium' then 'medium' # add this line in later when we phase in medium_ urls for wesawit photos
          when 'small' then 'thumb'
        }_#{values.id}.jpg"
      else if values.vid?
        "#{util.S3_BASE_URL}#{
        switch size
          when 'large' then 'largethumb'
          when 'medium', 'small' then 'thumb'
        }_#{values.id}.jpg"
      else
        "resources/images/placeholder.jpg"
        
  customLocations: [
    # [ {Name of Building}, {Latitude of Top-left-corner}, {Longitude of Top-left-corner}, {Lat of bottom-right corner}, {Lng of bottom right corner} ]
    ["Parking Structure 3",34.078034,-118.440923,34.076737,-118.439249]
    ["East Melnitz",34.076639,-118.439527,34.076221,-118.439111]
    ["Melnitz Hall",34.076643,-118.440485,34.076223,-118.439535]
    ["MacGowan Hall", 34.076214,-118.440031,34.07547,-118.439219]
    ["Broad Art Center",34.076312,-118.441351,34.075892,-118.440495]
    ["Broad Art Center",34.075903,-118.441447,34.075424,-118.440814]
    ["Broad Art Center Plaza",34.075846,-118.440782,34.075501,-118.440511]
    ["Murphy Sculpture Garden",34.075408,-118.441059,34.074568,-118.439339]
    ["Charles E Young Research Library",34.075266,-118.441882,34.074588,-118.441067]
    ["Public Affairs",34.075097,-118.439326,34.074255,-118.438883]
    ["Arts Library",34.074237,-118.439438,34.074237,-118.439438]
    ["Lu Valle Commons",34.073822,-118.439573,34.073822,-118.439573]
    ["Bunche Hall",34.074553,-118.441045,34.073822,-118.439742]
    ["Campbell Hall",34.074208,-118.441391,34.073844,-118.441032]
    ["Campbell Hall",34.073828,-118.441587,34.073514,-118.440981]
    ["North Campus Student Center Terrace",34.074274,-118.44174,34.073893,-118.441429]
    ["Rolfe Hall",34.074195,-118.442544,34.07354,-118.441708]
    ["Haines Hall",34.07354,-118.441708,34.07244,-118.440901]
    ["Royce Hall",34.073353,-118.442714,34.072486,-118.441641]
    ["Perloff Hall",34.073676,-118.440729,34.073067,-118.439747]
    ["Dickson Court North",34.073054,-118.44074,34.072288,-118.439694]
    ["Dickson Court South",34.072105,-118.440724,34.071288,-118.439704]
    ["Schoenberg Hall",34.07132,-118.440713,34.070139,-118.439769]
    ["Dodd Hall",34.070139,-118.439769,34.072328,-118.439018]
    ["School of Law",34.073553,-118.438996,34.072372,-118.437891]
    ["North Campus Student Center",34.074663,-118.442376,34.074285,-118.441721]
    ["Anderson School of Management",34.074655,-118.444548,34.073392,-118.442998]
    ["UCLA Guest House",34.074946,-118.438701,34.074218,-118.438202]
    ["Murphy Hall",34.072107,-118.439554,34.071365,-118.437934]
    ["Faculty Center",34.070822,-118.439501,34.070035,-118.438975]
    ["Humanities",34.071944,-118.44155,34.07107,-118.440901]
    ["Dickson Plaza",34.072471,-118.442676,34.072019,-118.440858]
    ["Janss Steps",34.072358,-118.443486,34.071987,-118.442773]
    ["Powell Library",34.071935,-118.442558,34.071049,-118.441695]
    ["Bruin Walk East",34.071036,-118.44442,34.070911,-118.4431]
    ["Student Activities Center",34.071877,-118.444463,34.071022,-118.443701]
    ["Bruin Plaza",34.071117,-118.444951,34.070853,-118.444575]
    ["John Wooden Center",34.07202,-118.446056,34.071134,-118.444924]
    ["Ashe Center",34.07185,-118.444903,34.071228,-118.444677]
    ["Wilson Plaza",34.072433,-118.444876,34.071905,-118.443642]
    ["Bruin Walk West",34.071035,-118.447654,34.070941,-118.445021]
    ["Kaufman Hall",34.072956,-118.444473,34.072504,-118.443663]
    ["North Pool",34.073219,-118.44443,34.073024,-118.44405]
    ["Fowler Museum",34.073244,-118.443577,34.072653,-118.442864]
    ["North Athletic Field",34.073219,-118.445991,34.072063,-118.444962]
    ["Intramural Playing Fields",34.073092,-118.447644,34.071068,-118.446142]
    ["Drake Stadium",34.07294,-118.449269,34.071117,-118.447692]
    ["Sunset Recreation Center",34.075502,-118.453298,34.074482,-118.451426]
    ["Sunset Recreation Center",34.074708,-118.451984,34.073841,-118.451141]
    ["Easton Softball Stadium",34.076674,-118.454001,34.075907,-118.45282]
    ["Spieker Aquatic Center",34.074963,-118.45105,34.074767,-118.450353]
    ["Sunset Tennis Courts",34.074767,-118.450353,34.074126,-118.449956]
    ["Courtside",34.073999,-118.450272,34.073326,-118.449532]
    ["Covel Commons",34.07327,-118.450439,34.072786,-118.449591]
    ["Sproul Hall",34.072698,-118.450621,34.071674,-118.449698]
    ["Rieber Hall",34.072466,-118.451828,34.071612,-118.451184]
    ["Rieber Vista",34.072258,-118.452648,34.071747,-118.451938]
    ["Rieber Terrace",34.072751,-118.452487,34.072522,-118.451581]
    ["Rieber Terrace",34.072584,-118.452737,34.072349,-118.452171]
    ["Rieber Court",34.072484,-118.452131,34.072275,-118.451868]
    ["Hedrick Hall",34.073684,-118.452731,34.072797,-118.451905]
    ["Hedrick Summit",34.074117,-118.453051,34.073839,-118.452048]
    ["Delta Terrace",34.073204,-118.451667,34.072631,-118.450701]
    ["Canyon Point",34.073951,-118.451259,34.073351,-118.450465]
    ["Hitch Suites",34.074053,-118.454313,34.073235,-118.453368]
    ["Chancellor's Residence",34.077092,-118.442891,34.075866,-118.441577]
    ["UCLA Lab School",34.076181,-118.44442,34.074733,-118.443261]
    ["Stein Eye Research Center",34.064832,-118.444887,34.064281,-118.444205]
    ["Stein Eye Institute",34.065468,-118.444248,34.064761,-118.44361]
    ["Center for Health Science Plaza",34.065521,-118.443663,34.064712,-118.442601]
    ["Marion Davis Children's Center",34.065485,-118.442623,34.064903,-118.442199]
    ["Parking Structure E",34.065332,-118.442236,34.064779,-118.441797]
    ["Wasserman Building",34.066045,-118.444999,34.065143,-118.444323]
    ["Semel Institute for Neuroscience and Human Behavior",34.06569,-118.444565,34.065321,-118.444093]
    ["Biomedical Cyclotron Facility",34.066068,-118.444023,34.065592,-118.443438]
    ["Occupational Heath Facility",34.066072,-118.443154,34.065548,-118.442371]
    ["Clinical Research",34.066156,-118.442553,34.065721,-118.441829]
    ["David Geffen School of Medicine",34.06681,-118.443781,34.06601,-118.442494]
    ["UCLA School of Public Health",34.066996,-118.443857,34.066574,-118.443154]
    ["Center for Health Sciences",34.067005,-118.444538,34.06533,-118.441807]
    ["Botanical Garden",34.067032,-118.441791,34.065659,-118.440026]
    ["Botanical Garden",34.065783,-118.441786,34.065245,-118.440107]
    ["Botanical Garden",34.065334,-118.441732,34.064014,-118.440938]
    ["Botanical Garden",34.064246,-118.442333,34.063828,-118.441131]
    ["University Presbyterian Church",34.06397,-118.44104,34.063646,-118.440606]
    ["Terasaki Life Sciences Building",34.06757,-118.440482,34.066454,-118.439527]
    ["Terasaki Life Sciences Building",34.066547,-118.440482,34.066059,-118.440037]
    ["UCLA Neurosurgery",34.064623,-118.446464,34.063997,-118.445638]
    ["Medical Plaza 300",34.063997,-118.445638,34.064254,-118.445638]
    ["Ueberroth",34.064246,-118.447451,34.063854,-118.446517]
    ["Medical Plaza",34.063854,-118.446517,34.064481,-118.446276]
    ["Medical Plaza 100",34.065863,-118.44619,34.065134,-118.445487]
    ["Ronald Reagan UCLA Medical Center",34.067094,-118.447333,34.06597,-118.445283]
    ["Campus Services Building 1",34.067734,-118.447671,34.06717,-118.447016]
    ["Facilities Management Building",34.067712,-118.447102,34.067036,-118.44553]
    ["UCLA Police Department",34.067623,-118.445568,34.067139,-118.445305]
    ["Gonda Neuroscience and Genetic Research Center",34.067703,-118.444881,34.067059,-118.444532]
    ["MacDonald Medical Research Laboratories",34.067721,-118.44442,34.067081,-118.443883]
    ["Neuroscience Research",34.067721,-118.443706,34.067067,-118.442977]
    ["Life Sciences",34.067698,-118.44325,34.066996,-118.441662]
    ["Bio Med Building",34.067601,-118.441958,34.067116,-118.440649]
    ["Parking Structure 8",34.068632,-118.448309,34.067841,-118.445208]
    ["Strathmore",34.068636,-118.445359,34.067845,-118.445053]
    ["Parking Structure 9",34.068396,-118.444736,34.067721,-118.443355]
    ["California Nanosystems Institute",34.068378,-118.443679,34.067705,-118.442477]
    ["Court of Sciences Student Center",34.068601,-118.442523,34.067623,-118.441973]
    ["Boyer Hall",34.068518,-118.441962,34.067747,-118.441515]
    ["Molecular Sciences",34.068516,-118.441557,34.067652,-118.440477]
    ["Young Hall",34.068954,-118.441903,34.068225,-118.440428]
    ["Geology",34.069391,-118.441957,34.069003,-118.44045]
    ["Slichter Hall",34.069345,-118.441203,34.068598,-118.440353]
    ["Parking Structure 2",34.069423,-118.440198,34.067774,-118.439393]
    ["Engineering 4",34.06916,-118.444532,34.068383,-118.443492]
    ["Boelter Hall",34.069329,-118.443443,34.068485,-118.442505]
    ["Mathematical Sciences",34.069845,-118.443454,34.069116,-118.442537]
    ["Mathematical Sciences",34.069756,-118.442773,34.069494,-118.442011]
    ["Court of Sciences",34.069529,-118.442526,34.068552,-118.441941]
    ["Franz Hall",34.06984,-118.441941,34.069445,-118.440531]
    ["Engineering 5",34.069789,-118.444009,34.069209,-118.443489]
    ["Engineering 1",34.06984,-118.444553,34.069165,-118.444052]
    ["Parking Structure 6",34.069676,-118.446211,34.06888,-118.445235]
    ["Spaulding Field",34.069831,-118.447451,34.068565,-118.446217]
    ["Los Angeles Tennis Center",34.070214,-118.448915,34.069156,-118.447848]
    ["Straus Stadium",34.070769,-118.44899,34.070147,-118.448009]
    ["Acosta Center",34.070942,-118.447998,34.069907,-118.447499]
    ["Pauley Pavilion",34.070809,-118.447488,34.069925,-118.446115]
    ["James West Alumni Center",34.070476,-118.445713,34.069934,-118.444919]
    ["Central Ticket Office",34.070245,-118.445782,34.069978,-118.445632]
    ["Morgan Center",34.070969,-118.446008,34.07056,-118.444962]
    ["Ackerman Union",34.070927,-118.444693,34.069854,-118.44381]
    ["Kerckhoff Hall",34.070767,-118.443853,34.070107,-118.443143]
    ["Moore Hall",34.070807,-118.443027,34.070065,-118.442397]
    ["Portola Plaza Building",34.070509,-118.442129,34.069991,-118.44159]
    ["Knudsen Hall",34.070478,-118.441606,34.070054,-118.44097]
    ["Physics and Astronomy Building",34.070956,-118.441871,34.070418,-118.44097]
    ["Inverted Fountain",34.07016,-118.440927,34.069969,-118.440616]
    ["De Neve Commons",34.071218,-118.451619,34.069929,-118.449441]
    ["De Neve Commons",34.071116,-118.452209,34.070431,-118.451302]
    ["Saxon Suites",34.072155,-118.453555,34.070951,-118.45266]
    ["Saxon Basketball Court",34.071307,-118.452756,34.071089,-118.452198]
    ["Southern Regional Library",34.071542,-118.454805,34.070556,-118.453566]
    ["Saxon Tennis Courts",34.07256,-118.454773,34.071831,-118.453995]
    ["Tom Bradley International Hall",34.069916,-118.449875,34.06926,-118.448909]
    ["Sigma Chi Fraternity",34.070602,-118.452782,34.070125,-118.452206]
    ["Westwood Palm Apartment Building",34.070336,-118.452219,34.069851,-118.451707]
    ["Delta Kappa Epsilon Fraternity",34.070118,-118.452694,34.069596,-118.452144]
    ["Westwood Chateau Apartments",34.069729,-118.451975,34.069176,-118.451648]
    ["Westwood Chateau Apartments",34.069616,-118.451634,34.069045,-118.451463]
    ["Westwood Chateau Apartments",34.069496,-118.451449,34.069045,-118.451162]
    ["Alpha Tau Omega",34.06962,-118.451272,34.069263,-118.450924]
    ["Phi Delta Theta Fraternity",34.069263,-118.450924,34.068643,-118.450774]
    ["Coop",34.068903,-118.450934,34.068456,-118.450291]
    ["Theta Delta Chi Fraternity",34.069196,-118.450406,34.068785,-118.450033]
    ["Pi Kappa Alpha Fraternity",34.0691,-118.450122,34.068718,-118.449837]
    ["Gayley Towers Apartments",34.068794,-118.450028,34.068496,-118.449591]
    ["Gayley Towers Apartments",34.068945,-118.449891,34.068634,-118.449459]
    ["Beta Theta Pi Fraternity",34.06878,-118.449499,34.068412,-118.449234]
    ["Sigma Phi Epsilon Fraternity",34.068385,-118.450629,34.068076,-118.450232]
    ["Sigma Phi Epsilon Fraternity",34.068563,-118.450379,34.068034,-118.449913]
    ["Alpha Gamma Omega Fratenity",34.068032,-118.451004,34.067843,-118.450779]
    ["Alpha Gamma Omega Fratenity",34.068138,-118.450873,34.067956,-118.450677]
    ["Triangle Fraternity",34.067896,-118.45091,34.06769,-118.450527]
    ["Triangle Fraternity",34.067992,-118.450792,34.067783,-118.450497]
    ["Glenrock West Apartment Building",34.066936,-118.451573,34.066445,-118.450883]
    ["Glenrock 1",34.067092,-118.450993,34.066679,-118.450387]
    ["Glenrock 2",34.066732,-118.450835,34.066463,-118.450374]
    ["Zeta Beta Tau Fraternity",34.067378,-118.450312,34.066801,-118.449872]
    ["Sigma Nu Fraternity",34.068272,-118.449204,34.068009,-118.448904]
    ["Lambda Chi Alpha Fraternity",34.068007,-118.449355,34.067681,-118.449019]
    ["Zeta Beta Tau Fraternity",34.067783,-118.449435,34.067498,-118.449041]
    ["Phi Kappa Psi Fraternity",34.068005,-118.449041,34.067541,-118.448558]
    ["Theta Xi Fraternity",34.067583,-118.448891,34.06729,-118.448424]
    ["Sigma Pi Fraternity",34.06729,-118.449301,34.06701,-118.449038]
    ["Sigma Pi Fraternity",34.067372,-118.449293,34.067127,-118.448891]
    ["Delta Sigma Phi Fraternity",34.067065,-118.449188,34.066801,-118.448856]
    ["Delta Sigma Phi Fraternity",34.06721,-118.449043,34.066925,-118.448681]
    ["Pi Kappa Phi Fraternity",34.066987,-118.448883,34.066776,-118.448593]
    ["University Catholic Center",34.067285,-118.448644,34.066996,-118.448298]
    ["641 Gayley Ave. Apartments",34.067152,-118.448502,34.066756,-118.448207]
    ["641 Gayley Ave. Apartments",34.067163,-118.448301,34.066874,-118.448027]
    ["Delta Tau Delta Fraternity",34.066923,-118.448239,34.066565,-118.448032]
    ["Delta Tau Delta Fraternity",34.066901,-118.448075,34.066636,-118.447887]
    ["Sigma Alpha Epsilon Fraternity",34.066714,-118.44811,34.066456,-118.447702]
    ["Theta Chi Fraternity",34.066476,-118.447997,34.066303,-118.447681]
    ["Landfair",34.066739,-118.449419,34.066119,-118.449025]
    ["Landfair",34.066701,-118.449137,34.066181,-118.448912]
    ["Landfair",34.066516,-118.448947,34.066234,-118.44873]
    ["Alpha Epsilon Pi Fraternity",34.066196,-118.449065,34.066014,-118.448644]
    ["Alpha Epsilon Pi Fraternity",34.066241,-118.44888,34.066119,-118.44859]
    ["Faculty Apartments Gayley Ave.",34.065359,-118.448636,34.064765,-118.448046]
    ["UCLA Extension",34.064123,-118.448952,34.063728,-118.448349]
    ["Weyburn Terrace",34.063241,-118.450884,34.062335,-118.449301]
    ["Weyburn Terrace",34.062326,-118.450406,34.061637,-118.448599]
    ["Weyburn Terrace",34.061712,-118.450637,34.060939,-118.44958]
    ["West Medical",34.061188,-118.449666,34.060144,-118.447987]
    ["Parking Structure 32",34.060384,-118.448448,34.059499,-118.447134]
    ["Hammer Museum",34.05979,-118.444352,34.058995,-118.44288]
    ["Billy Wilder Theater",34.059666,-118.444352,34.059495,-118.443859]
    ["Weyburn Apartments",34.062368,-118.442703,34.061986,-118.442177]
    ["Tiverton House",34.063612,-118.442472,34.062772,-118.442008]
    ["Delta Delta Sorority",34.06511,-118.440611,34.064721,-118.440141]
    ["Church of Jesus Christ of LDS",34.065214,-118.440278,34.06491,-118.439916]
    ["824 Hilgard Ave.",34.065934,-118.43986,34.06559,-118.439449]
    ["Alpha Delta Pi Sorority",34.066228,-118.439664,34.065852,-118.439388]
    ["Alpha Delta Pi Sorority",34.066192,-118.439396,34.066001,-118.439216]
    ["Kappa Delta Sorority",34.066505,-118.439573,34.066112,-118.439149]
    ["Kappa Kappa Gamma Sorority",34.066814,-118.439334,34.066425,-118.438851]
    ["Kappa Alpha Theta",34.067081,-118.439151,34.066796,-118.438913]
    ["Kappa Alpha Theta",34.067056,-118.43894,34.066676,-118.438604]
    ["720 Hilgard Ave",34.067281,-118.439092,34.067001,-118.438588]
    ["720 Hilgard Ave",34.067423,-118.439042,34.067203,-118.438543]
    ["Alpha Phi Sorority",34.067612,-118.439033,34.067403,-118.43854]
    ["Chi Omega",34.067798,-118.43902,34.067603,-118.438537]
    ["Pi Beta",34.067981,-118.439015,34.067783,-118.438545]
    ["Delta Gamma",34.068178,-118.439017,34.067987,-118.438543]
    ["Alpha Chi Omega",34.068561,-118.438991,34.068352,-118.438508]
    ["Alpha Epsilon Phi",34.06874,-118.43895,34.068532,-118.438529]
    ["Gamma Phi Beta",34.069207,-118.438894,34.068905,-118.438545]
  ]
