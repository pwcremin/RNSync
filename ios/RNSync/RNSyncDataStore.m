//
//  StoreManager.m
//  RNSync
//
//  Created by Patrick cremin on 2/21/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "RNSyncDataStore.h"
#import "ReplicationManager.h"
#import "CloudantSync.h"

@implementation RNSyncDataStore
{    
    CDTDatastore *datastore;
    NSString *databaseName;
}
@synthesize replicationManager;
@synthesize datastore;

-(id) initWithData: (NSString *)databaseName manager:(CDTDatastoreManager *)manager databaseUrl:(NSString *) databaseUrl error:(NSError **) error
{
    if (self = [super init] )
    {
        self->databaseName = databaseName;
        
        datastore = [manager datastoreNamed:databaseName error:error];
        
        if(*error)
        {            
            return nil;
        }
        
        CDTReplicatorFactory *replicatorFactory = [[CDTReplicatorFactory alloc] initWithDatastoreManager:manager];
        
        NSURL *remoteDatabaseURL = [NSURL URLWithString:databaseUrl];
        
        replicationManager = [[ReplicationManager alloc] initWithData:remoteDatabaseURL datastore:datastore replicatorFactory:replicatorFactory];
        
        return self;
    }
    else {
        return nil;
    }
}

@end
