var RNSync = require( 'react-native' ).NativeModules.RNSync;
import { Platform } from 'react-native';

const noop = () => {};

function fail( error, reject, callback )
{
    var error = new Error( error );
    callback( error );
    reject( error );
}

function success( params, resolve, callback )
{
    var data = params;

    if(Platform.OS === "ios")
    {
        data = params ? params[ 0 ] : null;
    }

    callback( null, data );
    resolve( data );
}

function complete( error, params, resolve, reject, callback )
{
    if ( error )
    {
        fail( error, reject, callback );
    }
    else
    {
        success( params, resolve, callback );
    }
}

var Sync = {

    init: function ( cloudantServerUrl, databaseName, callback )
    {
        return new Promise( function ( resolve, reject )
        {
            callback = callback || noop;

            var databaseUrl = cloudantServerUrl + '/' + databaseName;

            RNSync.init( databaseUrl, function ( error )
            {
                if ( error )
                {
                    fail( error, reject, callback );
                }
                else
                {
                    success( null, resolve, callback );
                }
            } );
        } )
    },

    create: function ( body, id, callback )
    {
        return new Promise( function ( resolve, reject )
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
                complete( error, params, resolve, reject, callback );
            } );
        } )

    },

    retrieve: function ( id, callback )
    {
        return new Promise( function ( resolve, reject )
        {
            callback = callback || noop;

            RNSync.retrieve( id, function ( error, params )
            {
                complete( error, params, resolve, reject, callback );
            } );
        } )
    },

    findOrCreate: function ( id, callback )
    {
        return new Promise( function ( resolve, reject )
        {
            callback = callback || noop;

            RNSync.retrieve( id, function ( error, params )
            {
                if ( error === 404 )
                {
                    return this.create( null, id, callback )
                }
                else
                {
                    complete( error, params, resolve, reject, callback );
                }
            }.bind( this ) );
        }.bind( this ) )
    },

    update: function ( id, rev, body, callback )
    {
        return new Promise( function ( resolve, reject )
        {
            if ( typeof(id) === 'object' )
            {
                var doc = id;
                id = doc.id;
                rev = doc.rev;
                body = doc.body;
            }

            callback = callback || noop;

            RNSync.update( id, rev, body, function ( error, params )
            {
                complete( error, params, resolve, reject, callback );
            } );
        } )
    },

    delete: function ( id, callback )
    {
        return new Promise( function ( resolve, reject )
        {
            callback = callback || noop;

            if ( typeof(id) === 'object' )
            {
                id = id.id; // doc.id
            }

            RNSync.delete( id, function ( error )
            {
                complete( error, null, resolve, reject, callback );
            } );
        } );

    },

    replicate: function ( callback )
    {
        return new Promise( function ( resolve, reject )
        {
            callback = callback || noop;

            RNSync.replicate( function ()
            {
                // on success
                complete( null, null, resolve, reject, callback );
            }, function ( error )
            {
                // on failure
                complete( error, null, resolve, reject, callback );
            } );
        } );
    },

    // TODO currently you can only add attachments.  No modiify or delete
    addAttachment: function ( id, name, path, type, callback )
    {
        return new Promise( function ( resolve, reject )
        {
            callback = callback || noop;

            RNSync.addAttachment( id, name, path, type, function ( error, params )
            {
                complete( error, params, resolve, reject, callback );
            } );

        } );
    },

    find: function ( query, callback )
    {
        return new Promise( function ( resolve, reject )
        {
            callback = callback || noop;

            RNSync.find( query, function ( error, params )
            {
                if(Platform.OS === "android")
                {
                    params = params.map(function(doc)
                    {
                        return JSON.parse(doc);
                    })
                }

                complete( error, params, resolve, reject, callback );
            } );
        } );
    }
};

module.exports = Sync;
