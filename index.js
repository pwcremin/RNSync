var RNSync = require( 'NativeModules' ).RNSync;


var Sync = {

    create: function ( body, callback )
    {
        RNSync.create( body, callback );
    },

    retrieve: function ( id, callback )
    {
        RNSync.retrieve( id, callback );
    },

    update: function ( id, rev, body, callback )
    {
        RNSync.update( id, rev, body, callback );
    },

    delete: function ( id, callback )
    {
        RNSync.delete( id, callback );
    }
};

module.exports = Sync;
