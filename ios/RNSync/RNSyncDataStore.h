//
//  StoreManager.h
//  RNSync
//
//  Created by Patrick cremin on 2/21/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridge.h>
#import "ReplicationManager.h"

@interface RNSyncDataStore : NSObject

@property ReplicationManager *replicationManager;
@property CDTDatastore *datastore;
//@property CDTDatastoreManager *manager;

-(id)initWithData: (NSString *)databaseName manager:(CDTDatastoreManager *)manager databaseUrl: (NSString *)databaseUrl error:(NSError **)error;
@end
