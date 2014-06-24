# not beign used right now... / is broken

require '../touch/sencha-touch-all.js'
listUtilities = require '../src/app.coffee'

describe 'app.coffee', ->
  
  it 'Add commas to numbers as needed', ->
    expect(listUtilities.commaize_number(12000000)).toEqual '12,000,000'