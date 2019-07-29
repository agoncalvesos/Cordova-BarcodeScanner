var argscheck = require('cordova/argscheck'),
    exec      = require('cordova/exec');

function ZBar () {};

ZBar.prototype = {

    scan: function (params, success, failure)
    {
        console.log("scan2!")
        console.log("params1", params);
        argscheck.checkArgs('*fF', 'CsZBar.scan', arguments);

        params = params || {};
        if(params.text_title === undefined) params.text_title = "Scan QR Code";
        if(params.text_instructions === undefined) params.text_instructions = "Please point your camera at the QR code.";
        if(params.camera != "front") params.camera = "back";
        if(params.flash != "on" && params.flash != "off") params.flash = "auto";
        // iOS only: The locked orientation to show the scanner in. Can be: "portrait", "landscapeLeft", "landscapeRight", "portraitUpsideDown".
        if(params.orientation == "") params.orientation = "auto";
        // defaults to true, create a red sight/line in the center of the scanner view.
        if(params.drawSight != "on" && params.drawSight != "off") params.drawSight = "auto";

        console.log("params2", params);

        exec(success, failure, 'CsZBar', 'scan', [params]);
    },

};

module.exports = new ZBar;
