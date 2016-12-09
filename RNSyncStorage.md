
# RNSyncStorage


## About

RNSyncStorage was made for redux-persist, but you can use it as an alteranative to RNSync if you prefer its API.

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

rnsyncStorage.setItem(key, value, (error, doc) =>
{
  console.log(doc.id);
}
```
