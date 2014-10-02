Pimple = require 'pimple'
path = require 'path'


### classes ###
class RasterizerInterface
    rasterize:(url,outputFilePath,width,height)->
        throw "must be overloaded"


class Rasterizer extends RasterizerInterface

    ###
        @param Object q q module
        @param Object fs fs module
        @param Object child_process child_process module
        @param Object phantomjs phantomjs module
        @param Object rasterizeScript rasterizeScript
        @param Object defaultOutputFile defaultOutputFile
    ###
    constructor:(@q,@fs,@child_process,@phantomjs,@rasterizeScript,@defaultOutputFile)->

    ###
        rasterize url
        @return Promise
    ###
    rasterize:(url, outputFile = @defaultOutputFile, width = 320, height = 240)->
        cmd = [@phantomjs.path, @rasterizeScript, '"'+url+'"', outputFile, width, height]
        @q.ninvoke(@child_process, 'exec', cmd.join(' '))
        .then => @fileExists(outputFile)
        #.then (file_exists)-> if not file_exists then throw "#{outputFile} was not created from url #{url}." else file_exists
    fileExists:(filepath)->
        deferred = @q.defer()
        @fs.exists(filepath,(exists)->
            if exists then deferred.resolve(exists) else deferred.reject("#{filepath} doesnt exist")
        )
        deferred.promise
class ImageUploaderInterface

    ###
      upload a file
      @param string filepath
      @param string filename
      @return Promise<HttpResponse>
    ###
    upload: (filepath, filename)->
        throw "must me overloaded"

###
@class FreeImageUploader
###
class FreeImageUploader extends ImageUploaderInterface
    ###
      upload a file through a post request
      @param Object q 'q' npm module
      @param Object formData 'form-data' npm module
      @param string remoteScriptUrl
      @param string validationCode
    ###
    constructor: (@q, @formData, @fs, @remoteScriptUrl, @validationCode)->

    upload: (filepath, filename)->
        form = new @formData
        form.append 'code', @validationCode
        form.append 'filename', filename
        form.append 'filedata', @fs.createReadStream(filepath)
        @q.ninvoke(form, 'submit', @remoteScriptUrl)

class CaptureService
    ###
      upload a file through a post request
      @param Object redisClient
      @param Function md5 hashing function
      @param Object q q npm module
    ###
    constructor: (@redisClient, @md5, @q)->
        @prefix = "screenshot:capture:"

    ###
      register a new capture
      @return Promise
    ###
    createFromUrl: (url, expire = -1)->
        id = @md5(url)
        @q.ninvoke(@redisClient, 'set', @prefix + id, url)
        .then ->id

    ###
      get a capture by capture value(url)
      @return Promise
    ###
    getCaptureByUrl: (url)->
        id = @md5(url)
        @q.ninvoke(@redisClient, 'get', @prefix + id)
        .then (url)->if url then {url, id}



### configuration ###

c = new Pimple
    debug: if process.env.NODE_ENV is "production" then false else true
    tempDir: path.join(__dirname, 'temp')
    rasterizeScript: path.join(__dirname, 'scripts', 'rasterize-url.js')
    defaultOutputFile: path.join(__dirname, 'temp', 'image.jpg')
    remoteScriptUrl: process.env.SCREENSHOT_REMOTE_SCRIPT_URL
    remoteScriptToken: process.env.SCREENSHOT_REMOTE_SCRIPT_TOKEN
    cdnUrl: process.env.SCREENSHOT_CDN_URL
    imageExtension: 'jpg'
    redis_host: process.env.SCREENSHOT_REDIS_HOST
    redis_port: process.env.SCREENSHOT_REDIS_PORT
    redis_password: process.env.SCREENSHOT_REDISPASSWORD
    defaultImageFile: process.env.SCREENSHOT_DEFAULT_IMAGE_URL
    CAPTURE_TASK_ID: 'captureUrlTask'
    port: process.env.PORT || process.env.NODE_POST || 4000


### require libraries ###
['q',
'express',
'path',
'fs',
'crypto',
'form-data',
'redis',
'phantomjs',
'child_process',
'express'].forEach (lib)-> (c.set lib, c.share ((c)->require lib))

c.set 'captureJobQueue', c.share (c)->
    JobQueue = require 'redis-dist-job-queue'
    captureQueue = new JobQueue
        flushStaleTimeout: 50000
        redisConfig:
            host: c.redis_host
            port: c.redis_port
            auth_pass: c.redis_password
    captureQueue.registerTask('./captureJobQueue')
    captureQueue.on 'error', (err)->
        console.log('captureQueue error', err,err.stack)
    return captureQueue

c.set 'rasterizer', c.share (c)->
    new Rasterizer(c.q,c.fs,c.child_process,c.phantomjs,c.rasterizeScript,c.defaultOutputFile)

c.set 'uploader', c.share (c)->
    new FreeImageUploader(c.q, c['form-data'], c.fs, c.remoteScriptUrl, c.remoteScriptToken)

c.set 'redisClient', c.share (c)->
    if c.debug
        redis = require("redis")
        client = redis.createClient(13772, 'pub-redis-13772.eu-west-1-1.2.ec2.garantiadata.com',{auth_pass: 'defender'})
        return client
    else c.captureJobQueue.redisClient

c.set 'md5', c.share (c)->
    (string)->
        c.crypto.createHash('md5').update(string).digest("hex")

c.set "Capture", c.share (c)->
    new CaptureService(c.redisClient, c.md5, c.q)

c.set 'app', c.share (c)->
    {cdnUrl,
    express,
    Capture,
    imageExtension,
    captureJobQueue,
    CAPTURE_TASK_ID,
    defaultImageFile,
    q}=c
    app = express()
    app.use(express.bodyParser())
    app.use(express.logger("debug"))
    app.get '/', (req, res, next)->
        if not req.query.url
            do next
        else
            Capture.getCaptureByUrl(req.query.url)
            .then (capture)->
                if capture
                    res.redirect(301, cdnUrl + "#{capture.id}.#{imageExtension}")
                else
                    res.redirect(defaultImageFile)

                    captureJobQueue.submitJob CAPTURE_TASK_ID,
                        resourceId:req.query.url,
                        params: {url: req.query.url}
                    ,->

            .catch (err)->
                err.status = 500
                console.log(err)
                next(err)


    app.get '/', (req, res, next)->
        res.send('screenshot')


    return app
#export container
module.exports = c




