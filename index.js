var RNSync = require( 'react-native' ).NativeModules.RNSync;


var Sync = {

    init: function ( cloudantServerUrl, databaseName, callback )
    {
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
                    callback( 'error: (' + response.status + ') ' + response._bodyInit );
                }
            } )
            .catch( ( error ) =>
            {
                callback( error );
            } )
    },

    create: function ( body, id, callback )
    {
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
        RNSync.update( id, rev, body, callback );
    },

    delete: function ( id, callback )
    {
        RNSync.delete( id, callback );
    },

    replicate: function ( successCallback, errorCallback )
    {
        RNSync.replicate( successCallback, errorCallback );
    }
};

module.exports = Sync;
