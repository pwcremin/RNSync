var express = require( 'express' );
var path = require( 'path' );
var favicon = require( 'serve-favicon' );
var logger = require( 'morgan' );
var cookieParser = require( 'cookie-parser' );
var bodyParser = require( 'body-parser' );
var http = require( 'http' );
var debug = require( 'debug' )( 'cloudantApiKeyGenerator:server' );

var Promise = require( "bluebird" );
var request = Promise.promisify( require( "request" ) );

var app = express();

app.use( logger( 'dev' ) );
app.use( bodyParser.json() );
app.use( bodyParser.urlencoded( { extended: false } ) );
app.use( cookieParser() );


//var cloudantUrl = 'https://user:pass@xxxx.cloudant.com';
var dotenv = require( 'dotenv' ).config();
var cloudantUrl = process.env.CLOUDANT;


var port = 3000;
app.set( 'port', port );

var server = http.createServer( app );
server.listen( port );
server.on( 'error', onError );
server.on( 'listening', onListening );

function onListening()
{
    var addr = server.address();
    var bind = typeof addr === 'string'
        ? 'pipe ' + addr
        : 'port ' + addr.port;
    debug( 'Listening on ' + bind );
}

function onError( error )
{
    if ( error.syscall !== 'listen' )
    {
        throw error;
    }

    var bind = typeof port === 'string'
        ? 'Pipe ' + port
        : 'Port ' + port;

    // handle specific listen errors with friendly messages
    switch ( error.code )
    {
        case 'EACCES':
            console.error( bind + ' requires elevated privileges' );
            process.exit( 1 );
            break;
        case 'EADDRINUSE':
            console.error( bind + ' is already in use' );
            process.exit( 1 );
            break;
        default:
            throw error;
    }
}

function createDatabase( data )
{
    var url = cloudantUrl + '/' + data.dbname;

    return request( { url: url, method: 'PUT' } )
        .then( function ( response )
        {
            var DB_CREATION_SUCCESS = 202;
            var DATABASE_EXISTS = 412;

            if ( response.statusCode != DB_CREATION_SUCCESS && response.statusCode != DATABASE_EXISTS )
            {
                return Promise.reject( 'db creation failed: ' + response.statusCode );
            }

            return data;
        } );
}

function generateApiKey(data)
{
    var url = cloudantUrl + '/_api/v2/api_keys';

    /* response looks like
     {
     "password": "YPNCaIX1sJRX5upaL3eqvTfi",
     "ok": true,
     "key": "blentfortedsionstrindigl"
     }
     */

    return request( { url: url, method: 'POST' } )
        .then( function ( response )
        {
            if ( response.statusCode !== 201 )
            {
                return Promise.reject( 'api generation failed: ' + response.statusCode );
            }

            var apiKey = JSON.parse( response.body );

            data.key = apiKey.key;
            data.password = apiKey.password;

            return data;
        } )
}

function assignKeyToDatabase( data )
{
    // Docs: https://docs.cloudant.com/authorization.html

    var url = cloudantUrl + '/_api/v2/db/' + data.dbname + '/_security';

    var body = { cloudant: {} };
    body.cloudant[ data.key ] = [
        "_reader",
        "_writer"
    ];

    body.cloudant[ 'nobody' ] = [];

    return request( {
        url: url,
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify( body )
    } )
        .then( function ( response )
        {
            if ( response.statusCode !== 200 )
            {
                return Promise.reject( 'database security update failed: ' + response.statusCode );
            }

            return data;
        } );
}

app.get( '/genkey', function ( req, res )
{
    var dbname = req.query.dbname;

    if ( !dbname )
    {
        res.status( 500 ).send();
        return;
    }

    var data = { dbname: dbname };

    createDatabase( data )
        .then( generateApiKey )
        .then( assignKeyToDatabase )
        .then( function ( data )
        {
            res.json( data );
        } )
        .catch( function ( err )
        {
            res.status( 500 ).send( err );
        } )
} );
