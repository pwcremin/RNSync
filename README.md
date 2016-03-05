# RNSync

## About

RNSync is a React Native module that allows you to intereact with your Cloudant or CouchDB database locally on the mobile device and replicate to the remote database when needed.

RNSync is a wrapper for Cloudant Sync, which simplifies large-scale mobile development by enabling you to create a single database for every user; you simply replicate and sync the copy of this database in Cloudant with a local copy on their phone or tablet. This can reduce round-trip database requests with the server. If there’s no network connection, the app runs off the database on the device; when the network connection is restored, Cloudant re-syncs the device and server.

You can get your own instance of [Cloudant on Bluemix](https://console.ng.bluemix.net/catalog/services/cloudant-nosql-db/) (where a free tier is available).

## Installation

Install with npm
```ruby
npm install --save rnsync
```

Edit your Podfile
```ruby
pod 'rnsync', :path => '../node_modules/rnsync'
```

Pod install
```ruby
pod install
```

## Usage

#### Connect
```javascript
var rnsync = require('rnsync');

// connect to your cloudant or couchDB database
var dbUrl = "https://user:pass@xxxxx";
var dbName = "name_xxxx";

rnsync.init(dbUrl, dbName, function(error)
{
  console.log(error);
}
```

#### Create

Both the object and the id are optional.  If you leave out the object, it will create a new doc that is empty.  If you leave
out the id that will be autogenerated for you.
```javascript
var object = {x:10};
var id = "whatever";

rnsync.create(object, id, function(error, docs)
{
  console.log(docs[0].id);
}
```

#### Retrieve

```javascript

var id = "whatever";

rnsync.retrieve(id, function(error, docs)
{
  console.log(JSON.stringify(docs[0].body));
}
```

#### Update

When doing an update to a doc, you must include the revision.

```javascript

doc.body.somechange = "hi mom";

rnsync.update(doc.id, doc.rev, doc.body, function(error, docs)
{
  console.log(JSON.stringify(docs[0].body));
}
```

#### Delete

```javascript

rnsync.update(doc.id, function(error)
{
  console.log(error);
}
```

#### Add Attachment

Add files/binaries.

```javascript
rnsync.addAttachment('user' /*id*/, 'somepic'/*name*/, response.uri.replace('file://', '') /*uri*/, 'image/jpeg' /*type*/, function(error, docs)
{
  console.log(error);
});
```

#### Replicate

All of the CRUD functions only affect the local database.  To push your changes to the remote server you must replicate.

```javascript
rnsync.replicate(onSuccessFunc, onFailFunc);
```

## Author

Patrick Cremin, pwcremin@gmail.com

## License

RNSync is available under the MIT license. See the LICENSE file for more info.
