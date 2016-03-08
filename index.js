var RNSync = require( 'react-native' ).NativeModules.RNSync;

var noop = function ()
{
};

var Sync = {

    init: function ( cloudantServerUrl, databaseName, callback )
    {
        callback = callback || noop;

        var databaseUrl = cloudantServerUrl + '/' + databaseName;

        // TODO handle case where there is no network connectivity
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
        if ( typeof(body) === 'string' )
        {
            callback = id;

            id = body;

            body = null;
        }
        else if ( typeof(body) === 'function' )
        {
            callback = body;

            body = id = null;
        }

        if ( typeof(id) === 'function' )
        {
            callback = id;

            id = null;
        }

        callback = callback || noop;

        RNSync.create( body, id, function ( error, params )
        {
            var doc = error ? null : params[ 0 ];

            callback( error, doc );
        } );
    },

    retrieve: function ( id, callback )
    {
        RNSync.retrieve( id, function ( error, params )
        {
            var doc = error ? null : params[0];

            callback( error, doc )
        } );
    },

    findOrCreate: function ( id, callback )
    {
        RNSync.retrieve( id, function ( error, params )
        {
            if ( error === 404 )
            {
                this.create( null, id, callback )
            }
            else
            {
                var doc = error ? null : params[0];

                callback( error, doc );
            }
        }.bind( this ) );
    },

    update: function ( id, rev, body, callback )
    {
        callback = callback || noop;

        RNSync.update( id, rev, body, function(error, params)
        {
            var doc = error ? null : params[ 0 ];

            callback( error, doc );
        });
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

    find: function ( query, callback )
    {
        RNSync.find( query, function ( err, params )
        {
            callback( err, params[ 0 ] );
        } );
    }
};

module.exports = Sync;
