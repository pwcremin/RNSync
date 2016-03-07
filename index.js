var RNSync = require( 'react-native' ).NativeModules.RNSync;

var noop = function(){};

var Sync = {

    init: function ( cloudantServerUrl, databaseName, callback )
    {
        callback = callback || noop;

        var databaseUrl = cloudantServerUrl + '/' + databaseName;

        return fetch( databaseUrl, {
            method: 'PUT'
        } )
            .then( ( response ) =>
            {
                if ( response.status == 201 || response.status == 412 )
                {
                    RNSync.init( databaseUrl, callback );
                }
                else
                {
                    callback && callback( 'error: (' + response.status + ') ' + response._bodyInit );
                }
            } )
            .catch( ( error ) =>
            {
                callback && callback( error );
            } )
    },

    create: function ( body, id, callback )
    {
        callback = callback || noop;

        RNSync.create( body, id, callback );
    },

    retrieve: function ( id, callback )
    {
        RNSync.retrieve( id, callback );
    },

    findOrCreate: function ( id, callback )
    {
        RNSync.retrieve( id, function ( err, doc )
        {
            if ( err === 404 )
            {
                this.create( null, id, callback )
            }
            else
            {
                callback( err, doc );
            }
        }.bind( this ) );
    },

    update: function ( id, rev, body, callback )
    {
        callback = callback || noop;

        RNSync.update( id, rev, body, callback );
    },

    delete: function ( id, callback )
    {
        callback = callback || noop;

        RNSync.delete( id, callback );
    },

    replicate: function ( successCallback, errorCallback )
    {
        successCallback = successCallback || noop;
        errorCallback = errorCallback || noop;

        RNSync.replicate( successCallback, errorCallback );
    },

    addAttachment: function ( id, name, path, type, callback )
    {
        callback = callback || noop;

        RNSync.addAttachment( id, name, path, type, callback );
    },

    find: function( query, callback)
    {
        RNSync.find( query, function(err, params)
        {
            callback(err, params[0]);
        });
    }
};

module.exports = Sync;
