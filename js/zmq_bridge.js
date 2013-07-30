/*
ZMQ WebSocket bridge

// pull messages from a server
var w = new ZMQ.bridge('ws://my-server.com:8080/pull/weather_info');
w.receive( function(msg) { do_something(message) } );

// push something to a server
var a = new ZMQ.bridge('ws://my-server.com:8080/push/activity');
a.send('message');
*/

var ZMQ = {};

ZMQ.bridge = function(url) {
    this._url = url;
    this._socket = new WebSocket(url);

    this.send = function(text) {
        this._socket.send(text);
    };
    
    this.receive = function(callback) {
        this._socket.receive(function(message) {
            callback(message.data);
        });
    };
};
