
# RNSyncStorage


## About

RNSyncStorage was made for redux-persist, but you can use it as an alteranative to RNSync if you prefer its API.  You will still need to init and replicate using RNSync.

## Installation

Install with npm
```ruby
npm install --save rnsync
```

### iOS

Edit your Podfile (find help with setting up CocoaPods [here](https://guides.cocoapods.org/using/using-cocoapods.html). Hint: its easy)
```ruby
react-native link rnsync
```

Update your Podfile
```ruby
pod 'CDTDatastore'
```

Pod install

### Android

```ruby
react-native link rnsync
```

## Usage

#### setItem
```javascript
import rnsync, {rnsyncStorage} from 'rnsync'

rnsyncStorage.setItem(key, value, (error) =>
{
  console.log(error);
}
```

#### getItem
```javascript

rnsyncStorage.getItem(key, (error, value) =>
{
  console.log(value);
}
```

#### removeItem
```javascript

rnsyncStorage.removeItem(key, (error) =>
{
  console.log(error);
}
```

#### getAllKeys
```javascript

rnsyncStorage.getAllKeys((error, keys) =>
{
  console.log(JSON.stringify(keys));
}
```


## Usage with redux-persist

```javascript
import { createStore } from 'redux'
import reducer from './redux/reducers/index'


import {persistStore, autoRehydrate} from 'redux-persist'
import rnsync, {rnsyncStorage} from 'rnsync'


let dbUrl = "https://xxx:xxx-bluemix.cloudant.com";
let dbName = "rnsync";

rnsync.init(dbUrl, dbName, error => console.log(error) );

const store = createStore(reducer, undefined, autoRehydrate());

persistStore(store, {storage: rnsyncStorage});
```
If you want to do replication before loading the store then:

```javascript
rnsync.replicateSync().then(() => persistStore(store, {storage: rnsyncStorage}));
```
