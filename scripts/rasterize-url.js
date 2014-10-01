// Generated by CoffeeScript 1.8.0

/*
  rasterize
  usage

    phantomjs rasterize.coffee url [outputfile] [width] [height]

  example

    phantomjs rasterize.coffee http://google.com image.jpg 320 240
 */

(function() {
  var page, params, system;

  page = require('webpage').create();

  system = require('system');

  params = {
    url: system.args[1] || console.log('url missing.') && phantom.exit(1),
    outputfile: system.args[2] || "image.jpg",
    width: parseInt(system.args[3] || 800, 10),
    height: parseInt(system.args[4] || 600, 10)
  };

  console.log("screenshot with params: " + (JSON.stringify(params)) + ".");

  page.zoomFactor = params.width / 1024;

  page.viewportSize = {
    width: params.width,
    height: params.height
  };

  page.clipRect = {
    top: 0,
    left: 0,
    height: params.height,
    width: params.width
  };

  page.open(params.url, function(status) {
    if (status !== 'success') {
      console.log("Error opening " + params.url + ".");
      return phantom.exit(1);
    } else {
      return window.setTimeout(function() {
        page.render(params.outputfile);
        console.log("" + params.outputfile + " successfully created.");
        return phantom.exit(0);
      }, 1);
    }
  });

}).call(this);
