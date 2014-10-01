console.log('starting script');
var page = require('webpage').create()
    , url = phantom.args[0]
    , path = phantom.args[1]
    , size = phantom.args[2] || '';

if (!url) throw new Error('url required');
if (!path) throw new Error('output path required');

size = size.split('x');

/*page.viewportSize = {
    width: ~~size[0] || 1024, height: ~~size[1] || 600
};*/
page.viewportSize = {
    width: 320, height: 240
};

page.open(url, function (status) {
    if (status == 'success') {
        page.render(path, {format: 'jpeg', quality: '50'});
        //page.render(path);

        phantom.exit();
    } else {
        throw new Error('failed to load ' + url);
    }
});
