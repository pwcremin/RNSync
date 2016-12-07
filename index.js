var rnsyncModule = require( 'react-native' ).NativeModules.RNSync;
import {Platform} from 'react-native';

const promisify = require("es6-promisify");

const noop = () =>
{
};

class RNSyncStorage {

    setItem ( key, value, callback )
    {
        callback = callback || noop;

        // value is a string, but we need a data blob
        let body = { value }

        rnsyncModule.retrieve( key, ( error, doc ) =>
        {
            if(error)     // should be 404
            {
                rnsyncModule.create( body, key, callback );
            }
            else
            {
                rnsyncModule.update( doc.id, doc.key, body, callback );
            }
        } );
    }

    getItem ( key, callback )
    {
        callback = callback || noop;

        rnsyncModule.retrieve( key, ( error, doc ) =>
        {
            let item = error ? null : doc.body.value;

            callback(error, item);
        } );

    }

    removeItem ( key, callback )
    {
        callback = callback || noop;

        rnsyncModule.delete( key, callback );
    }

    getAllKeys ( callback )
    {
        callback = callback || noop;

        // using _id as the field isn't right (since the body doesn't contain an _id) but
        // it keeps the body from returning since the field doesn't exist
        // TODO try ' '?
        rnsyncModule.find( {'_id': {'$exists': true } }, ['_id'], ( error, docs ) =>
        {
            if(error)
            {
                callback(error);
                return;
            }

            if ( Platform.OS === "android" )
            {
                docs = docs.map( doc => JSON.parse( doc ) )
            }

            let keys = docs.map( doc => {
                return doc.id
            })

            callback( null, keys );
        } );
    }

    deleteAllKeys( callback )
    {
        this.getAllKeys( (error, keys ) =>
        {
            if(error)
            {
                callback(error)
            }
            else
            {
                for (let i = 0; i < keys.length; i++) {
                    let key = keys[i];
                    this.removeItem(key)
                }

                callback(null)
            }

        })
    }
}

class RNSyncWrapper
{
    // TODO specify the name of the local datastore
    init ( cloudantServerUrl, databaseName, callback )
    {
        callback = callback || noop;

        return new Promise( ( resolve, reject ) =>
        {
            var databaseUrl = cloudantServerUrl + '/' + databaseName;

            rnsyncModule.init( databaseUrl, error =>
            {
                callback( error );
                if(error) reject(error);
                else resolve()
            } );
        } )
    }

    create ( body, id, callback )
    {
        callback = callback || noop;

        if ( typeof(body) === 'string' && typeof(id) === 'function')
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

        return new Promise( (resolve, reject) =>
        {
            rnsyncModule.create( body, id, ( error, doc ) =>
            {
                callback( error, doc );
                if(error) reject(error);
                else resolve(doc)
            } );
        })
    }

    retrieve ( id, callback )
    {
        callback = callback || noop;

        return new Promise( (resolve, reject) =>
        {
            rnsyncModule.retrieve( id, ( error, doc ) =>
            {
                callback( error, doc );
                if(error) reject(error);
                else resolve(doc)
            } );
        })
    }

    findOrCreate ( id, callback )
    {
        callback = callback || noop;

        return new Promise( (resolve, reject) =>
        {
            rnsyncModule.retrieve( id,  ( error, doc ) =>
            {
                if ( error === 404 )
                {
                    this.create( null, id, (error, doc) =>
                    {
                        callback( error, doc );
                        if(error) reject(error);
                        else resolve(doc)
                    })
                }
                else
                {
                    callback( error, doc );
                    if(error) reject(error);
                    else resolve(doc)
                }
            });
        })
    }

    update ( id, rev, body, callback )
    {
        callback = callback || noop;

        if ( typeof(id) === 'object' )
        {
            var doc = id;
            id = doc.id;
            rev = doc.rev;
            body = doc.body;
        }

        return new Promise( (resolve, reject) =>
        {
            rnsyncModule.update( id, rev, body, ( error, doc ) =>
            {
                callback( error, doc );
                if(error) reject(error);
                else resolve(doc)
            } );
        })
    }

    delete ( id, callback )
    {
        callback = callback || noop;

        if ( typeof(id) === 'object' )
        {
            id = id.id; // doc.id
        }

        return new Promise( (resolve, reject) =>
        {
            rnsyncModule.delete( id, ( error ) =>
            {
                callback( error );
                if(error) reject(error);
                else resolve()
            } );
        });

    }

    replicateSync( callback )
    {
        callback = callback || noop;

        var pushPromise = this.replicatePush();
        var pullPromise = this.replicatePull();

        return Promise.all([pushPromise, pullPromise])
            .then(callback)
            .catch( e => {
                callback(e);
                throw(e);
            })
    }

    replicatePush ( callback )
    {
        callback = callback || noop;

        return new Promise( (resolve, reject) =>
        {
            rnsyncModule.replicatePush( (error) =>
            {
                callback( error );
                if(error) reject(error);
                else resolve()
            })
        });
    }

    replicatePull ( callback )
    {
        callback = callback || noop;

        return new Promise( (resolve, reject) =>
        {
            rnsyncModule.replicatePull( (error) =>
            {
                callback( error );
                if(error) reject(error);
                else resolve()
            })
        });
    }

    // For how to create a query: https://github.com/cloudant/CDTDatastore/blob/master/doc/query.md
    // The 'fields' arugment is for projection.  Its an array of fields that you want returned when you do not want the entire doc
    find ( query, fields, callback )
    {
        callback = callback || noop;

        if(typeof(fields) === 'function')
        {
            callback = fields;
            fields = null;
        }

        return new Promise( (resolve, reject) =>
        {
            rnsyncModule.find( query, fields, ( error, docs ) =>
            {
                if ( !error && Platform.OS === "android" )
                {
                    docs = docs.map( doc => JSON.parse( doc ) )
                }

                callback( error, docs );
                if(error) reject(error);
                else resolve(docs)
            } );

        });
    }
}

export const rnsyncStorage = new RNSyncStorage();
export default new RNSyncWrapper();

