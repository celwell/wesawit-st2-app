WeSawIt HTML5 Mobile App
========================

To Build
--------
### Prerequisites
- [CoffeeScript compiler](coffeescript.org)
- SASS compiler w/ compass ('gem install sass' and 'gem install compass')
- [Sencha Touch 2 SDK](http://www.sencha.com/products/touch/download/) (get the free Commercial version 2.1)
- [Sencha Cmd](http://www.sencha.com/products/sencha-cmd/download)
    
### Steps for Production
- Compile CoffeeScript from *./www-src/src* folder into the document root folder.
    - I use this for watching the folder: *coffee -o www-src -cwb www-src/src*
- in the www-src folder, with Sencha Cmd run: *sencha app build package*
    - this will add a folder *./build/WeSawIt/package*
- copy the contents of this package folder to the './www' folder
- continue as normal for phonegap
  
### Steps for Development/Debug
- Compile CoffeeScript from *./www-src/src* folder.
  - I use this for watching the folder: *coffee -o www-src -cwb www-src/src*
- See the result at './www-src/index-debug.html' in Chrome (or Safari)
  
  
Tips
----
- in Chrome developer tools use these Overrides:
    - User Agent: iPhone iOS 5
    - Device Metrics: 320 x 480
- you may need run Chrome with *--disable-web-security* flag because of PlacesAutocomplete from google doesn't send good access-control-allow-origin
