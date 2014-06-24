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

License
-------
The MIT License (MIT) - modified to not require attribution

Copyright (c) 2013 WeSawIt Inc

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
