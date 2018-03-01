var rnsyncModule = require( 'react-native' ).NativeModules.RNSync;
import { Platform } from 'react-native';

const noop = () =>
{
};

class RNSyncStorage
{
    setItem( key, value, callback )
    {
        callback = callback || noop;

        // value is a string, but we need a data blob
        let body = { value }

        rnsyncModule.retrieve( key, ( error, doc ) =>
        {
            if ( error )     // should be 404
            {
                rnsyncModule.create( body, key, callback );
            }
            else
            {
                rnsyncModule.update( doc.id, doc.key, body, callback );
            }
        } );
    }

    getItem( key, callback )
    {
        callback = callback || noop;

        rnsyncModule.retrieve( key, ( error, doc ) =>
        {
            let item = error ? null : doc.body.value;

            callback( error, item );
        } );

    }

    removeItem( key, callback )
    {
        callback = callback || noop;

        rnsyncModule.delete( key, callback );
    }

    getAllKeys( callback )
    {
        callback = callback || noop;

        // using _id as the field isn't right (since the body doesn't contain an _id) but
        // it keeps the body from returning since the field doesn't exist
        // TODO try ' '?
        rnsyncModule.find( { '_id': { '$exists': true } }, [ '_id' ], ( error, docs ) =>
        {
            if ( error )
            {
                callback( error );
                return;
            }

            if ( Platform.OS === "android" )
            {
                docs = docs.map( doc => JSON.parse( doc ) )
            }

            let keys = docs.map( doc =>
            {
                return doc.id
            } )

            callback( null, keys );
        } );
    }

    deleteAllKeys( callback )
    {
        this.getAllKeys( ( error, keys ) =>
        {
            if ( error )
            {
                callback( error )
            }
            else
            {
                for ( let i = 0; i < keys.length; i++ )
                {
                    let key = keys[ i ];
                    this.removeItem( key )
                }

                callback( null )
            }

        } )
    }
}

export class RNSync
{
    constructor( cloudantServerUrl, databaseName )
    {
        this.databaseUrl = cloudantServerUrl + '/' + databaseName
        this.databaseName = databaseName
    }

    init( callback )
    {
        return new Promise( ( resolve, reject ) =>
        {
            callback = callback || noop;

            rnsyncModule.init( this.databaseUrl, this.databaseName, error =>
            {
                callback( error )

                error == null ? resolve() : reject( error )
            } )
        } )
    }

    create( body, id, callback )
    {
        callback = callback || noop;

        if ( typeof(body) === 'string' && typeof(id) === 'function' )
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

        return new Promise( ( resolve, reject ) =>
        {
            rnsyncModule.create( this.databaseName, body, id, ( error, doc ) =>
            {
                callback( error, doc );
                error == null ? resolve( doc ) : reject( error )
            } );
        } )
    }

    retrieve( id, callback )
    {
        callback = callback || noop;

        return new Promise( ( resolve, reject ) =>
        {
            rnsyncModule.retrieve( this.databaseName, id, ( error, doc ) =>
            {
                callback( error, doc );

                error == null ? resolve( doc ) : reject( error )
            } );
        } )
    }

    findOrCreate( id, callback )
    {
        callback = callback || noop;

        return new Promise( ( resolve, reject ) =>
        {
            rnsyncModule.retrieve( this.databaseName, id, ( error, doc ) =>
            {
                if ( error === 404 )
                {
                    this.create( null, id, ( error, doc ) =>
                    {
                        callback( error, doc );

                        error == null ? resolve( doc ) : reject( error )
                    } )
                }
                else
                {
                    callback( error, doc );

                    error == null ? resolve( doc ) : reject( error )
                }
            } );
        } )
    }

    update( id, rev, body, callback )
    {
        callback = callback || noop;

        if ( typeof(id) === 'object' )
        {
            var doc = id;
            id = doc.id;
            rev = doc.rev;
            body = doc.body;
        }

        return new Promise( ( resolve, reject ) =>
        {
            rnsyncModule.update( this.databaseName, id, rev, body, ( error, doc ) =>
            {
                callback( error, doc );

                error == null ? resolve( doc ) : reject( error )
            } );
        } )
    }

    delete( id, callback )
    {
        callback = callback || noop;

        if ( typeof(id) === 'object' )
        {
            id = id.id; // doc.id
        }

        return new Promise( ( resolve, reject ) =>
        {
            rnsyncModule.delete( this.databaseName, id, ( error ) =>
            {
                callback( error );
                error == null ? resolve() : reject( error )
            } );
        } );

    }

    replicateSync( callback )
    {
        callback = callback || noop;

        var pushPromise = this.replicatePush();
        var pullPromise = this.replicatePull();

        return Promise.all( [ pushPromise, pullPromise ] )
            .then( callback )
            .catch( e =>
            {
                callback( e );
                throw(e);
            } )
    }

    replicatePush( callback )
    {
        callback = callback || noop;

        return new Promise( ( resolve, reject ) =>
        {
            rnsyncModule.replicatePush( this.databaseName, ( error ) =>
            {
                callback( error );

                error == null ? resolve() : reject( error )
            } )
        } );
    }

    replicatePull( callback )
    {
        callback = callback || noop;

        return new Promise( ( resolve, reject ) =>
        {
            rnsyncModule.replicatePull( this.databaseName, ( error ) =>
            {
                callback( error );

                error == null ? resolve() : reject( error )
            } )
        } );
    }

    // For how to create a query: https://github.com/cloudant/CDTDatastore/blob/master/doc/query.md
    // The 'fields' arugment is for projection.  Its an array of fields that you want returned when you do not want the entire doc
    find( query, fields, callback )
    {
        callback = callback || noop;

        if ( typeof(fields) === 'function' )
        {
            callback = fields;
            fields = null;
        }

        return new Promise( ( resolve, reject ) =>
        {
            rnsyncModule.find( this.databaseName, query, fields, ( error, docs ) =>
            {
                if ( !error && Platform.OS === "android" )
                {
                    docs = docs.map( doc => JSON.parse( doc ) )
                }

                callback( error, docs );

                error == null ? resolve( docs ) : reject( error )
            } );

        } );
    }
}


// TODO This class exist only for the purpose of not screwing up backawards compat.  Should go away in next major release
class RNSyncWrapper extends RNSync
{
    constructor()
    {
        super()
    }

    init( cloudantUrl, databaseName, callback )
    {
        this.databaseUrl = cloudantUrl + '/' + databaseName
        this.databaseName = databaseName

        callback = callback || noop;

        return new Promise( ( resolve, reject ) =>
        {
            rnsyncModule.init( this.databaseUrl, this.databaseName, error =>
            {
                callback( error )

                error == null ? resolve() : reject( error )
            } )
        } )
    }
}

export const rnsyncStorage = new RNSyncStorage();
export default new RNSyncWrapper();

