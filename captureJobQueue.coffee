c = require('./container')
{CAPTURE_TASK_ID,
md5,cdnUrl,
imageExtension,
path,
tempDir,
uploader,
Capture,
rasterizer,
error}=c
module.exports =
    id: CAPTURE_TASK_ID
    perform: (params, cb)->
        d = new Date
        id = md5(params.url)
        filename = id + '.' + imageExtension
        filePath = path.join tempDir, filename
        console.log('rasterizing ',filePath)
        rasterizer.rasterize(params.url, filePath)
        .then ->
            console.log('upload file', filePath);
            uploader.upload(filePath, filename)
        .then (http_response)->
            if http_response.statusCode isnt 200 then throw "error #{http_response.statusCode}" else
                console.log "file #{filename} uploaded to #{cdnUrl + filename}"
                return http_response
        .then -> Capture.createFromUrl(params.url)
        .then -> cb()
        .catch (err)-> console.log('job error',err);cb(err)
