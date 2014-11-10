var exec = require('cordova/exec');
/**
 * Constructor
 */
               function VideoCapture() {}
               
               VideoCapture.prototype.captureVideo = function(win,fail,options) {
               exec(win,fail, "VideoCapture", "captureVideo",options);
               }
               
               var videoCapture = new VideoCapture();
               module.exports = videoCapture
               });


