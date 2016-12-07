//
//  Replicator.m
//  Pods
//
//  Created by Patrick cremin on 12/4/16.
//
//

#import "Replicator.h"
#import "ReplicationManager.h"

@implementation Replicator
{
    NSURL * remoteDatabaseURL;
    CDTDatastore *datastore;
    CDTReplicatorFactory *replicatorFactory;
    CDTReplicator *replicator;
    RCTResponseSenderBlock callback;
}

@synthesize owner;

-(id)initWithData:(NSURL *)remoteDatabaseURL datastore:(CDTDatastore *)datastore replicatorFactory:(CDTReplicatorFactory *)replicatorFactory;
{
    self = [super init];
    if (self) {
        self->remoteDatabaseURL = remoteDatabaseURL;
        self->datastore = datastore;
        self->replicatorFactory = replicatorFactory;
    }
    return self;
}

- (void)pull: (RCTResponseSenderBlock)callback
{
    self->callback = callback;
    
    // bug in CDTPullReplication that has source and target reversed
    // https://github.com/cloudant/CDTDatastore/issues/347
    CDTPullReplication *pullReplication = [CDTPullReplication replicationWithSource:remoteDatabaseURL
                                                                             target:datastore];
    
    NSError *error;
    
    replicator = [replicatorFactory oneWay:pullReplication error:&error];
    replicator.delegate = self;
    
    [replicator startWithError: &error];
}

- (void)push: (RCTResponseSenderBlock)callback
{
    self->callback = callback;
    
    CDTPushReplication *pushReplication = [CDTPushReplication replicationWithSource:datastore
                                                                             target:remoteDatabaseURL];
    
    NSError *error;
    
    replicator = [replicatorFactory oneWay:pushReplication error:&error];
    replicator.delegate = self;
    
    [replicator startWithError: &error];
}

- (void)replicatorDidComplete:(CDTReplicator *)replicator
{
    if(callback)
    {
        callback(@[[NSNull null]]);
    }
    
    [self cleanupAfterCompletion];
}

- (void)replicatorDidError:(CDTReplicator *)replicator info:(NSError *)info
{
    if(callback)
    {
        callback(@[[NSNumber numberWithLong:info.code]]);
    }
    
    [self cleanupAfterCompletion];
}

- (void)cleanupAfterCompletion
{
    [[self owner] done:self];
}

@end
