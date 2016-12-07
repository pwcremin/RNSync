//
//  Replicator.m
//  Pods
//
//  Created by Patrick cremin on 12/4/16.
//
//

#import "ReplicationManager.h"
#import "Replicator.h"

@implementation ReplicationManager
{
    CDTReplicatorFactory *replicatorFactory;
    NSMutableArray * replicators;
    NSURL * remoteDatabaseURL;
    CDTDatastore *datastore;
    CDTReplicator *replicator;
}

-(id) initWithData: (NSURL *)remoteDatabaseURL datastore:(CDTDatastore *)datastore replicatorFactory:(CDTReplicatorFactory *)replicatorFactory
{
    self = [super init];
    if (self) {
        self->remoteDatabaseURL = remoteDatabaseURL;
        self->datastore = datastore;
        self->replicatorFactory = replicatorFactory;
        self->replicators = [NSMutableArray array];
    }
    return self;
}

- (void) pull: (RCTResponseSenderBlock)callback
{
    Replicator * replicator =  [[Replicator alloc] initWithData:remoteDatabaseURL datastore:datastore replicatorFactory:replicatorFactory];
    
    [replicators addObject:replicator];
    
    [replicator setOwner:self];
    [replicator pull: callback];
}

- (void) push: (RCTResponseSenderBlock)callback
{
    
    Replicator * replicator =  [[Replicator alloc] initWithData:remoteDatabaseURL datastore:datastore replicatorFactory:replicatorFactory];
    
    [replicators addObject:replicator];
    
    [replicator setOwner:self];
    [replicator push: callback];
}

- (void) done: (Replicator *)replicator
{
    [replicators removeObjectIdenticalTo:replicator];
}

@end

