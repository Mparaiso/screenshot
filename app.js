require('coffee-script').register();

var container = require('./container');
if (!module.parent) {
    if (process.env.NODE_ENV == 'production') {
        // use cluster in production
        var cluster = require('cluster');
        var numCPUs = require('os').cpus().length;
        if (cluster.isMaster) {
            //Fork
            for (var i = 0; i < numCPUs; i++) {
                cluster.fork();
                cluster.on('exit', function (worker, code, signal) {
                    console.log('worker ' + worker.process.id + ' died');
                });
            }
        } else {
            // Workers can share any TCP connection
            // In this case its a HTTP server
            require('http').createServer(container.app).listen(container.port, onServerListening);
        }
    } else {
        require('http').createServer(container.app).listen(container.port, onServerListening);
    }
} else {
    module.exports = container;
}

function onServerListening() {
    console.log('listening on port ' + container.port);
    container.captureJobQueue.start();
    container.captureJobQueue.on('error', function (err) {
        console.log('captureQueue error', err, err.stack)
    });
    console.log('captureJobQueue has started');
    process.on('exit', function (code) {
        container.redisClient.quit();
        console.log('closing redis connection');
    });
}