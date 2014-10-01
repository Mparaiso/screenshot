c = require('./container')
{CAPTURE_TASK_ID,md5,cdnUrl,imageExtension,path,tempDir,uploader,Capture,rasterize}=c
module.exports =
  id: CAPTURE_TASK_ID
  perform: (params, cb)->
    d = new Date
    id = md5(params.url)
    filename = id + '.'+imageExtension
    filePath = path.join tempDir, filename
    rasterize(params.url, filePath)
    .then (r)->
        console.log('upload file', filePath);
        uploader.upload(filePath, filename)
    .then (r)->
        if r.statusCode != 200 then throw "error #{r.statusCode}"
        console.log "file #{filename} uploaded to #{cdnUrl + filename}"
        return r
    .then -> Capture.createFromUrl(params.url)
    .then -> cb()
    .catch cb
