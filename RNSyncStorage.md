
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
pod 'rnsync', :path => '../node_modules/rnsync/ios'
```

Pod install
```ruby
pod install
```
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
