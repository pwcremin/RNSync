//
//  Replicator.h
//  Pods
//
//  Created by Patrick cremin on 12/4/16.
//
//
#import "CloudantSync.h"
#import <React/RCTEventDispatcher.h>

@class ReplicationManager;

@interface Replicator : NSObject <CDTReplicatorDelegate>
@property (weak) ReplicationManager * owner;
-(id)initWithData:(NSURL *)remoteDatabaseURL datastore:(CDTDatastore *)datastore replicatorFactory:(CDTReplicatorFactory *)replicatorFactory;

- (void)pull: (RCTResponseSenderBlock)callback;
- (void)push: (RCTResponseSenderBlock)callback;
@end
