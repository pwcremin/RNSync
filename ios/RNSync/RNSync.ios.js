/**
 * @providesModule RNSync
 * @flow
 */
'use strict';

var NativeRNSync = require('NativeModules').RNSync;

/**
 * High-level docs for the RNSync iOS API can be written here.
 */

var RNSync = {
  test: function() {
    NativeRNSync.test();
  }
};

module.exports = RNSync;
